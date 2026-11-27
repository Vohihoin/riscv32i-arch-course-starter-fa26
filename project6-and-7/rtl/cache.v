`default_nettype none

module cache (
    // Global clock.
    input  wire        i_clk,
    // Synchronous active-high reset.
    input  wire        i_rst,
    // External memory interface. See hart interface for details. This
    // interface is nearly identical to the phase 5 memory interface, with the
    // exception that the byte mask (`o_mem_mask`) has been removed. This is
    // no longer needed as the cache will only access the memory at word
    // granularity, and implement masking internally.
    input  wire        i_mem_ready,
    output wire [31:0] o_mem_addr,
    output wire        o_mem_ren,
    output wire        o_mem_wen,
    output wire [31:0] o_mem_wdata,
    input  wire [31:0] i_mem_rdata,
    input  wire        i_mem_valid,
    // Interface to CPU hart. This is nearly identical to the phase 5 hart memory
    // interface, but includes a stall signal (`o_busy`), and the input/output
    // polarities are swapped for obvious reasons.
    //
    // The CPU should use this as a stall signal for both instruction fetch
    // (IF) and memory (MEM) stages, from the instruction or data cache
    // respectively. If a memory request is made (`i_req_ren` for instruction
    // cache, or either `i_req_ren` or `i_req_wen` for data cache), this
    // should be asserted *combinationally* if the request results in a cache
    // miss.
    //
    // In case of a cache miss, the CPU must stall the respective pipeline
    // stage and deassert ren/wen on subsequent cycles, until the cache
    // deasserts `o_busy` to indicate it has serviced the cache miss. However,
    // the CPU must keep the other request lines constant. For example, the
    // CPU should not change the request address while stalling.
    output wire        o_busy,
    // 32-bit read/write address to access from the cache. This should be
    // 32-bit aligned (i.e. the two LSBs should be zero). See `i_req_mask` for
    // how to perform half-word and byte accesses to unaligned addresses.
    input  wire [31:0] i_req_addr,
    // When asserted, the cache should perform a read at the aligned address
    // specified by `i_req_addr` and return the 32-bit word at that address,
    // either immediately (i.e. combinationally) on a cache hit, or
    // synchronously on a cache miss. It is illegal to assert this and
    // `i_dmem_wen` on the same cycle.
    input  wire        i_req_ren,
    // When asserted, the cache should perform a write at the aligned address
    // specified by `i_req_addr` with the 32-bit word provided in
    // `o_req_wdata` (specified by the mask). This is necessarily synchronous,
    // but may either happen on the next clock edge (on a cache hit) or after
    // multiple cycles of latency (cache miss). As the cache is write-through
    // and write-allocate, writes must be applied to both the cache and
    // underlying memory.
    // It is illegal to assert this and `i_dmem_ren` on the same cycle.
    input  wire        i_req_wen,
    // The memory interface expects word (32 bit) aligned addresses. However,
    // the processor supports byte and half-word loads and stores at unaligned and
    // 16-bit aligned addresses, respectively. To support this, the access
    // mask specifies which bytes within the 32-bit word are actually read
    // from or written to memory.
    input  wire [ 3:0] i_req_mask,
    // The 32-bit word to write to memory, if the request is a write
    // (i_req_wen is asserted). Only the bytes corresponding to set bits in
    // the mask should be written into the cache (and to backing memory).
    input  wire [31:0] i_req_wdata,
    // THe 32-bit data word read from memory on a read request.
    output wire [31:0] o_res_rdata
);
    // These parameters are equivalent to those provided in the project
    // 6 specification. Feel free to use them, but hardcoding these numbers
    // rather than using the localparams is also permitted, as long as the
    // same values are used (and consistent with the project specification).
    //
    // 32 sets * 2 ways per set * 16 bytes per way = 1K cache
    localparam O = 4;            // 4 bit offset => 16 byte cache line
    localparam S = 5;            // 5 bit set index => 32 sets
    // ** and / are course-rules-banned (real hardware power/divide
    // operators synthesize poorly); O and S are fixed per the note above,
    // so these are equivalent shift-based constant expressions, not a
    // behavior change.
    localparam DEPTH = 1 << S;   // 32 sets
    localparam W = 2;            // 2 way set associative, NMRU
    localparam T = 32 - O - S;   // 23 bit tag
    localparam D = (1 << O) >> 2; // 16 bytes per line / 4 bytes per word = 4 words per line

    // The following memory arrays model the cache structure. As this is
    // an internal implementation detail, you are *free* to modify these
    // arrays as you please.

    // Backing memory, modeled as two separate ways.
    reg [   31:0] datas0 [DEPTH - 1:0][D - 1:0];
    reg [   31:0] datas1 [DEPTH - 1:0][D - 1:0];
    reg [T - 1:0] tags0  [DEPTH - 1:0];
    reg [T - 1:0] tags1  [DEPTH - 1:0];
    reg [1:0] valid [DEPTH - 1:0];
    reg       lru   [DEPTH - 1:0];

    // Fill in your implementation here.

    // Bit splice the address into tag, set index, and offset.
    wire [T - 1:0] tag;
    wire [S - 1:0] set;
    wire [O - 1:0] offset;

    assign tag    = i_req_addr[31:32 - T];
    assign set    = i_req_addr[O + S - 1: O];
    assign offset = i_req_addr[O - 1:0];

    // Determine if the request is a hit or miss.
    wire hit;
    wire hit0, hit1;

    assign hit0 = (valid[set][0] && (tags0[set] == tag));
    assign hit1 = (valid[set][1] && (tags1[set] == tag));

    assign hit = hit0 || hit1;

    // Sending Memory Access Request to the memory
    assign o_mem_addr = {i_req_addr[31:4], send_cnt[1:0], 2'b00};
    assign o_mem_ren = o_mem_ren_reg;
    assign o_mem_wen = o_mem_wen_reg;
    assign o_mem_wdata = i_req_wdata;

    // Write to cache logic
    always @(*) begin
        if (lru[set]) begin
            // Write to way 0
            tags0[set] = tag;
            valid[set][0] = 1'b1;

            // Byte 0
            datas0[set][send_cnt[1:0]] [7:0] = (i_req_mask[0] && i_req_wen) ? i_req_wdata[7:0] 
                                             : (load_word ? i_mem_rdata[7:0] 
                                             : datas0[set][send_cnt[1:0]][7:0]);
            // Byte 1
            datas0[set][send_cnt[1:0]] [15:8] = (i_req_mask[1] && i_req_wen) ? i_req_wdata[15:8] 
                                              : (load_word ? i_mem_rdata[15:8] 
                                              : datas0[set][send_cnt[1:0]][15:8]);
            // Byte 2
            datas0[set][send_cnt[1:0]] [23:16] = (i_req_mask[2] && i_req_wen) ? i_req_wdata[23:16] 
                                               : (load_word ? i_mem_rdata[23:16] 
                                               : datas0[set][send_cnt[1:0]][23:16]);
            // Byte 3
            datas0[set][send_cnt[1:0]] [31:24] = (i_req_mask[3] && i_req_wen) ? i_req_wdata[31:24] 
                                               : (load_word ? i_mem_rdata[31:24] 
                                               : datas0[set][send_cnt[1:0]][31:24]);

            // Update LRU
            lru[set] = 1'b1;

        end else begin
            // Write to way 1
            tags1[set] = tag;
            valid[set][1] = 1'b1;

            // Byte 0
            datas1[set][send_cnt[1:0]] [7:0] = (i_req_mask[0] && i_req_wen) ? i_req_wdata[7:0] 
                                             : (load_word ? i_mem_rdata[7:0] 
                                             : datas1[set][send_cnt[1:0]][7:0]);
            // Byte 1
            datas1[set][send_cnt[1:0]] [15:8] = (i_req_mask[1] && i_req_wen) ? i_req_wdata[15:8] 
                                              : (load_word ? i_mem_rdata[15:8] 
                                              : datas1[set][send_cnt[1:0]][15:8]);
            // Byte 2
            datas1[set][send_cnt[1:0]] [23:16] = (i_req_mask[2] && i_req_wen) ? i_req_wdata[23:16] 
                                               : (load_word ? i_mem_rdata[23:16] 
                                               : datas1[set][send_cnt[1:0]][23:16]);
            // Byte 3
            datas1[set][send_cnt[1:0]] [31:24] = (i_req_mask[3] && i_req_wen) ? i_req_wdata[31:24] 
                                               : (load_word ? i_mem_rdata[31:24] 
                                               : datas1[set][send_cnt[1:0]][31:24]);

            // Update LRU
            lru[set] = 1'b0;
        end
    end

    // STATE MACHINE LOGIC ------------------------------------------------------------------------
    reg rst_cnt;

    // Send count for counting how many load requests you've sent (3 bits)
    reg [2:0] send_cnt;
    reg inc_send_cnt;

    always @(posedge i_clk) begin
        if (i_rst) begin
            send_cnt <= 3'b000;
        end else if (inc_send_cnt) begin
            send_cnt <= send_cnt + 1;
        end else if (rst_cnt) begin
            send_cnt <= 3'b000;
        end
    end

    // Receive count for counting how many valid load requests have been satisfied (2 bits)
    reg [1:0] rec_cnt;
    reg inc_rec_cnt;

    always @(posedge i_clk) begin
        if (i_rst) begin
            rec_cnt <= 2'b00;
        end else if (inc_rec_cnt) begin
            rec_cnt <= rec_cnt + 1;
        end else if (rst_cnt) begin
            rec_cnt <= 2'b00;
        end
    end

    // State Machine for cache controller
    localparam IDLE = 2'b00;
    localparam LOAD_CACHE = 2'b10;
    localparam STORE_MEM = 2'b11;

    reg write_to_cache;
    reg o_mem_ren_reg;
    reg o_mem_wen_reg;
    reg o_busy_reg;
    reg load_word;

    wire active = (i_req_ren || i_req_wen);

    reg [1:0] state, next_state;

    // State Register
    always @(posedge i_clk) begin
        if (i_rst) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    
    // State Transition Logic
    always @(*) begin
        next_state = state;
        rst_cnt = 1'b0;
        inc_send_cnt = 1'b0;
        inc_rec_cnt = 1'b0;
        write_to_cache = 1'b0;
        load_word = 1'b0;
        o_mem_ren_reg = 1'b0;
        o_mem_wen_reg = 1'b0;
        o_busy_reg = 1'b1;

        case (state)
            IDLE: begin
                if (hit && i_req_ren) begin
                    // Cache hit on read request, stay in IDLE
                    next_state = IDLE;
                end else if (hit && i_req_wen && i_mem_ready) begin
                    // Cache hit on write request and memory is ready, write to cache and memory
                    write_to_cache = 1'b1;
                    o_mem_wen_reg = 1'b1;
                    next_state = IDLE;
                end else if (hit && i_req_wen && !i_mem_ready) begin
                    // Cache hit on write request but memory is not ready, wait in STORE_MEM state
                    write_to_cache = 1'b1;
                    next_state = STORE_MEM;
                end else if (!hit && active && i_mem_ready) begin
                    // Cache miss and memory is ready, start loading cache
                    o_mem_ren_reg = 1'b1;
                    inc_send_cnt = 1'b1;
                    next_state = LOAD_CACHE;
                end else if (!hit && active && !i_mem_ready) begin
                    // Cache miss and memory is not ready, wait in LOAD_CACHE state
                    next_state = LOAD_CACHE;
                end else begin
                    next_state = IDLE;
                end
            end

            LOAD_CACHE: begin
                if (i_mem_valid && (i_mem_ready && !send_cnt[2])) begin
                    // Received a valid memory response && memory is ready and we haven't sent all 4 words yet
                    // Accept data and send new request
                    o_mem_ren_reg = 1'b1;
                    inc_send_cnt = 1'b1;
                    load_word = 1'b1;
                    inc_rec_cnt = 1'b1;
                    next_state = LOAD_CACHE;
                end else if (!i_mem_valid && (i_mem_ready && !send_cnt[2])) begin
                    // Memory is ready, send new request
                    o_mem_ren_reg = 1'b1;
                    inc_send_cnt = 1'b1;
                    next_state = LOAD_CACHE;
                end else if (i_mem_valid && !i_mem_ready && !send_cnt[2]) begin
                    // Received a valid memory response but memory is not ready, accept data and wait
                    load_word = 1'b1;
                    inc_rec_cnt = 1'b1;
                    next_state = LOAD_CACHE;
                end else if (i_mem_valid && (rec_cnt == 2'b11) && i_req_ren) begin
                    // If we have received 3 words and got a valid read request
                    // Load the last word to cache, reset counters, and go back to IDLE
                    rst_cnt = 1'b1;
                    load_word = 1'b1;
                    next_state = IDLE;
                end else if (i_mem_valid && (rec_cnt == 2'b11) && i_req_wen && !i_mem_ready) begin
                    // If we have received 3 words and got a valid write request
                    // If not ready, load the last word to cache, write the store to cache, reset counters, and go to STORE_MEM
                    rst_cnt = 1'b1;
                    load_word = 1'b1;
                    write_to_cache = 1'b1;
                    next_state = STORE_MEM;
                end else if (i_mem_valid && (rec_cnt == 2'b11) && i_req_wen && i_mem_ready) begin
                    // If we have received 3 words and got a valid write request
                    // If ready, load the last word to cache, write the store to cache and memory, reset counters, and go back to IDLE
                    rst_cnt = 1'b1;
                    load_word = 1'b1;
                    write_to_cache = 1'b1;
                    o_mem_wen_reg = 1'b1;
                    next_state = IDLE;
                end else begin
                    next_state = LOAD_CACHE;
                end
            end

            STORE_MEM: begin
                if (i_mem_ready) begin
                    // Memory is ready, write to memory and go back to IDLE
                    o_mem_wen_reg = 1'b1;
                    o_busy_reg = 1'b0;
                    next_state = IDLE;
                end else begin
                    // Memory is not ready, stay in STORE_MEM
                    next_state = STORE_MEM;
                end
            end
        endcase
    end



endmodule

`default_nettype wire
                               