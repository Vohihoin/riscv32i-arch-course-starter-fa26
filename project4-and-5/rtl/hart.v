`default_nettype none

module hart #(
    // After reset, the program counter (PC) should be initialized to this
    // address and start executing instructions from there.
    parameter RESET_ADDR = 32'h00000000
) (
    // Global clock.
    input  wire        i_clk,
    // Synchronous active-high reset.
    input  wire        i_rst,
    // Instruction fetch goes through a read only instruction memory (imem)
    // port. The port accepts a 32-bit address (e.g. from the program counter)
    // per cycle and combinationally returns a 32-bit instruction word. This
    // is not representative of a realistic memory interface; it has been
    // modeled as more similar to a DFF or SRAM to simplify phase 3. In
    // later phases, you will replace this with a more realistic memory.
    //
    // 32-bit read address for the instruction memory. This is expected to be
    // 4 byte aligned - that is, the two LSBs should be zero.
    output wire [31:0] o_imem_raddr,
    // Instruction word fetched from memory, available on the same cycle.
    input  wire [31:0] i_imem_rdata,
    // Data memory accesses go through a separate read/write data memory (dmem)
    // that is shared between read (load) and write (stored). The port accepts
    // a 32-bit address, read or write enable, and mask (explained below) each
    // cycle. Reads are combinational - values are available immediately after
    // updating the address and asserting read enable. Writes occur on (and
    // are visible at) the next clock edge.
    //
    // Read/write address for the data memory. This should be 32-bit aligned
    // (i.e. the two LSB should be zero). See `o_dmem_mask` for how to perform
    // half-word and byte accesses at unaligned addresses.
    output wire [31:0] o_dmem_addr,
    // When asserted, the memory will perform a read at the aligned address
    // specified by `i_addr` and return the 32-bit word at that address
    // immediately (i.e. combinationally). It is illegal to assert this and
    // `o_dmem_wen` on the same cycle.
    output wire        o_dmem_ren,
    // When asserted, the memory will perform a write to the aligned address
    // `o_dmem_addr`. When asserted, the memory will write the bytes in
    // `o_dmem_wdata` (specified by the mask) to memory at the specified
    // address on the next rising clock edge. It is illegal to assert this and
    // `o_dmem_ren` on the same cycle.
    output wire        o_dmem_wen,
    // The 32-bit word to write to memory when `o_dmem_wen` is asserted. When
    // write enable is asserted, the byte lanes specified by the mask will be
    // written to the memory word at the aligned address at the next rising
    // clock edge. The other byte lanes of the word will be unaffected.
    output wire [31:0] o_dmem_wdata,
    // The dmem interface expects word (32 bit) aligned addresses. However,
    // the processor supports byte and half-word loads and stores at unaligned and
    // 16-bit aligned addresses, respectively. To support this, the access
    // mask specifies which bytes within the 32-bit word are actually read
    // from or written to memory.
    //
    // To perform a half-word read at address 0x00001002, align `o_dmem_addr`
    // to 0x00001000, assert `o_dmem_ren`, and set the mask to 0b1100 to
    // indicate that only the upper two bytes should be read. Only the upper
    // two bytes of `i_dmem_rdata` can be assumed to have valid data; to
    // calculate the final value of the `lh[u]` instruction, shift the rdata
    // word right by 16 bits and sign/zero extend as appropriate.
    //
    // To perform a byte write at address 0x00002003, align `o_dmem_addr` to
    // `0x00002000`, assert `o_dmem_wen`, and set the mask to 0b1000 to
    // indicate that only the upper byte should be written. On the next clock
    // cycle, the upper byte of `o_dmem_wdata` will be written to memory, with
    // the other three bytes of the aligned word unaffected. Remember to shift
    // the value of the `sb` instruction left by 24 bits to place it in the
    // appropriate byte lane.
    output wire [ 3:0] o_dmem_mask,
    // The 32-bit word read from data memory. When `o_dmem_ren` is asserted,
    // this will immediately reflect the contents of memory at the specified
    // address, for the bytes enabled by the mask. When read enable is not
    // asserted, or for bytes not set in the mask, the value is undefined.
    input  wire [31:0] i_dmem_rdata,
	// The output `retire` interface is used to signal to the testbench that
    // the CPU has completed and retired an instruction. A single cycle
    // implementation will assert this every cycle; however, a pipelined
    // implementation that needs to stall (due to internal hazards or waiting
    // on memory accesses) will not assert the signal on cycles where the
    // instruction in the writeback stage is not retiring.
    //
    // Asserted when an instruction is being retired this cycle. If this is
    // not asserted, the other retire signals are ignored and may be left invalid.
    output wire        o_retire_valid,
    // The 32 bit instruction word of the instrution being retired. This
    // should be the unmodified instruction word fetched from instruction
    // memory.
    output wire [31:0] o_retire_inst,
    // Asserted if the instruction produced a trap, due to an illegal
    // instruction, unaligned data memory access, or unaligned instruction
    // address on a taken branch or jump.
    output wire        o_retire_trap,
    // Asserted if the instruction is an `ebreak` instruction used to halt the
    // processor. This is used for debugging and testing purposes to end
    // a program.
    output wire        o_retire_halt,
    // The first register address read by the instruction being retired. If
    // the instruction does not read from a register (like `lui`), this is
    // don't-care -- the grading testbench doesn't look at it in that case.
    output wire [ 4:0] o_retire_rs1_raddr,
    // The second register address read by the instruction being retired. If
    // the instruction does not read from a second register (like `addi`),
    // this is don't-care -- the grading testbench doesn't look at it in that
    // case.
    output wire [ 4:0] o_retire_rs2_raddr,
    // The first source register data read from the register file (in the
    // decode stage) for the instruction being retired. If rs1 is 5'd0, this
    // should also be 32'd0.
    output wire [31:0] o_retire_rs1_rdata,
    // The second source register data read from the register file (in the
    // decode stage) for the instruction being retired. If rs2 is 5'd0, this
    // should also be 32'd0.
    output wire [31:0] o_retire_rs2_rdata,
    // The destination register address written by the instruction being
    // retired. If the instruction does not write to a register (like `sw`),
    // this should be 5'd0.
    output wire [ 4:0] o_retire_rd_waddr,
    // The destination register data written to the register file in the
    // writeback stage by this instruction. If rd is 5'd0, this field is
    // ignored and can be treated as a don't care.
    output wire [31:0] o_retire_rd_wdata,
    output wire [31:0] o_retire_dmem_addr,
    output wire [ 3:0] o_retire_dmem_mask,
    output wire        o_retire_dmem_ren,
    output wire        o_retire_dmem_wen,
    output wire [31:0] o_retire_dmem_rdata,
    output wire [31:0] o_retire_dmem_wdata,
    // The current program counter of the instruction being retired - i.e.
    // the instruction memory address that the instruction was fetched from.
    output wire [31:0] o_retire_pc,
    // the next program counter after the instruction is retired. For most
    // instructions, this is `o_retire_pc + 4`, but must be the branch or jump
    // target for *taken* branches and jumps.
    output wire [31:0] o_retire_next_pc

`ifdef RISCV_FORMAL
    ,`RVFI_OUTPUTS,
`endif
);
    // 
    wire pc_imm_sel;
    wire i_IF_ID_flush;
    wire [31:0] i_IF_ID_instruction;
    wire [31:0] i_IF_ID_output_PC;

    reg o_IF_ID_flush;
    reg [31:0] o_IF_ID_instruction;
    reg [31:0] o_IF_ID_input_PC;

    wire [31:0] target_address;
    wire stall, flush;

    wire trap_unaligned_instruction_address;

    // Institate the Fetch Stage
    fetch u_fetch (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_pc_target(target_address),
        .i_pc_sel(pc_imm_sel),
        .stall(stall),
        .i_instruction(i_imem_rdata),
        .o_instruction(i_IF_ID_instruction),
        .o_pc(o_imem_raddr),
        .o_trap_unaligned_instruction_address(trap_unaligned_instruction_address)
    );

    
    assign i_IF_ID_output_PC = o_imem_raddr;
    
    assign i_IF_ID_flush = pc_imm_sel;
    
    // IF/ID Pipeline Register
    // If stall, should hold the value
    always @(posedge i_clk) begin
        if (i_rst) begin
            o_IF_ID_instruction <= 32'd0;
            o_IF_ID_input_PC <= RESET_ADDR;
        end else if (stall) begin
            o_IF_ID_instruction <= o_IF_ID_instruction;
            o_IF_ID_input_PC <= o_IF_ID_input_PC;
        end else begin
            o_IF_ID_instruction <= i_IF_ID_instruction;
            o_IF_ID_input_PC <= i_IF_ID_output_PC;
        end
    end

    // Save flush signal to make a nop in ID/EX
    always @(posedge i_clk) begin
        if (i_rst) begin
            o_IF_ID_flush <= 1'b0;
        end else begin
            o_IF_ID_flush <= i_IF_ID_flush;
        end
    end
    


    wire IF_ID_prev_flush;
    wire [4:0] o_decode_rs1;
    wire [4:0] o_decode_rs2;

    //control signal imputs for ID/EX pipeline register
    wire i_ID_EX_JALRsel;
    wire i_ID_EX_LUIsel;
    wire i_ID_EX_JALsel;
    wire i_ID_EX_Branch;  
    wire i_ID_EX_MemRead;
    wire [1:0] i_ID_EX_DataSel;
    wire [1:0] i_ID_EX_ALUop;
    wire i_ID_EX_ALUSrc;
    wire i_ID_EX_MemWrite;
    wire i_ID_EX_RegWrite;
    wire i_ID_EX_LoadStoreActive;
    
    wire [31:0] i_ID_EX_output_pc;
    wire [31:0] i_ID_EX_read_data_1;
    wire [31:0] i_ID_EX_read_data_2;
    wire [31:0] i_ID_EX_immediate;
    wire [4:0] i_ID_EX_rd;
    wire [2:0] i_ID_EX_funct3;
    wire [6:0] i_ID_EX_funct7;

    wire o_WB_RegWrite;
    wire [31:0] o_WB_rf_write_data;
    wire [4:0] o_WB_rf_rd;
    wire trap_illegal_instruction;
    
    wire [31:0] decode_output_PC;

    
    
    // Instantiate the Decode Stage
    decode u_decode (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .instruction(o_IF_ID_instruction),
        .input_PC(o_IF_ID_input_PC),
        .output_PC(decode_output_PC),
        .i_flush(o_IF_ID_flush),
        .o_flush(IF_ID_prev_flush),
        .IF_ID_rs1_addr(o_decode_rs1),
        .IF_ID_rs2_addr(o_decode_rs2),
        .IF_ID_rd(i_ID_EX_rd),
        .funct3(i_ID_EX_funct3),
        .funct7(i_ID_EX_funct7),
        .read_data_1(i_ID_EX_read_data_1),
        .read_data_2(i_ID_EX_read_data_2),
        .o_immediate(i_ID_EX_immediate),
        .JALRsel(i_ID_EX_JALRsel),
        .LUIsel(i_ID_EX_LUIsel),
        .JALsel(i_ID_EX_JALsel),
        .Branch(i_ID_EX_Branch),
        .MemRead(i_ID_EX_MemRead),
        .DataSel(i_ID_EX_DataSel),
        .ALUop(i_ID_EX_ALUop),
        .MemWrite(i_ID_EX_MemWrite),
        .ALUSrc(i_ID_EX_ALUSrc),
        .RegWrite(i_ID_EX_RegWrite),
        .load_store_active(i_ID_EX_LoadStoreActive),

        // Inputs from Writeback
        .write_data(o_WB_rf_write_data),
        .write_register(o_WB_rf_rd),
        .reg_writeback(o_WB_RegWrite),

        // trap signals
        .retire_trap_illegal_instruction(trap_illegal_instruction)
    );
    

    // Retire Signal Logic
    // We are gonna override the pc of the instruction after a Branch/Jump (Taken) Instruction,
    // as the nop instruction doesnt matter and we use the current pc value datapath to hold the pc 
    // target address and then when we retire the branch in the WB stage we use the pc in 
    //the MEM stage (which is the PC+target value)
    assign i_ID_EX_output_pc = (pc_imm_sel) ? target_address : decode_output_PC; 

    //outputs for ID/EX pipeline register
    //control signal outputs for ID/EX pipeline register
    reg o_ID_EX_JALRsel;
    reg o_ID_EX_LUIsel;
    reg o_ID_EX_JALsel;
    reg o_ID_EX_Branch;  
    reg o_ID_EX_MemRead;
    reg [1:0] o_ID_EX_DataSel;
    reg [1:0] o_ID_EX_ALUop;
    reg o_ID_EX_ALUSrc;
    reg o_ID_EX_MemWrite;
    reg o_ID_EX_RegWrite;
    reg o_ID_EX_LoadStoreActive;
    
    reg [31:0] o_ID_EX_output_pc;
    reg [31:0] o_ID_EX_read_data_1;
    reg [31:0] o_ID_EX_read_data_2;
    reg [31:0] o_ID_EX_immediate;
    reg [4:0] o_ID_EX_rd;
    reg [2:0] o_ID_EX_funct3;
    reg [6:0] o_ID_EX_funct7;


    assign flush = pc_imm_sel;

    // ID/EX Pipeline Register
    always @(posedge i_clk) begin
        if (i_rst) begin
            o_ID_EX_JALRsel <= 1'b0;
            o_ID_EX_LUIsel <= 1'b0;
            o_ID_EX_JALsel <= 1'b0;
            o_ID_EX_Branch <= 1'b0;  
            o_ID_EX_MemRead <= 1'b0;
            o_ID_EX_DataSel <= 2'b00;
            o_ID_EX_ALUop <= 2'b00;
            o_ID_EX_ALUSrc <= 1'b0;
            o_ID_EX_MemWrite <= 1'b0;
            o_ID_EX_RegWrite <= 1'b0;
            o_ID_EX_LoadStoreActive <= 1'b0;
        end else if (stall || flush || IF_ID_prev_flush) begin
            // Force Control Signals to 0 on Stall
            o_ID_EX_JALRsel <= 1'b0;
            o_ID_EX_LUIsel <= 1'b0;
            o_ID_EX_JALsel <= 1'b0;
            o_ID_EX_Branch <= 1'b0;  
            o_ID_EX_MemRead <= 1'b0;
            o_ID_EX_DataSel <= 2'b00;
            o_ID_EX_ALUop <= 2'b00;
            o_ID_EX_ALUSrc <= 1'b0;
            o_ID_EX_MemWrite <= 1'b0;
            o_ID_EX_RegWrite <= 1'b0;
            o_ID_EX_LoadStoreActive <= 1'b0;
        end else begin
            o_ID_EX_JALRsel <= i_ID_EX_JALRsel;
            o_ID_EX_LUIsel <= i_ID_EX_LUIsel;
            o_ID_EX_JALsel <= i_ID_EX_JALsel;
            o_ID_EX_Branch <= i_ID_EX_Branch;
            o_ID_EX_MemRead <= i_ID_EX_MemRead;
            o_ID_EX_DataSel <= i_ID_EX_DataSel;
            o_ID_EX_ALUop <= i_ID_EX_ALUop;
            o_ID_EX_ALUSrc <= i_ID_EX_ALUSrc;
            o_ID_EX_MemWrite <= i_ID_EX_MemWrite;
            o_ID_EX_RegWrite <= i_ID_EX_RegWrite;
            o_ID_EX_LoadStoreActive <= i_ID_EX_LoadStoreActive;
        end
    end

    always @(posedge i_clk) begin
        if (i_rst) begin
            o_ID_EX_output_pc <= 32'd0;
            o_ID_EX_read_data_1 <= 32'd0;
            o_ID_EX_read_data_2 <= 32'd0;
            o_ID_EX_immediate <= 32'd0;
            o_ID_EX_rd <= 5'd0;
            o_ID_EX_funct3 <= 3'd0;
            o_ID_EX_funct7 <= 7'd0;
        end else begin
            o_ID_EX_output_pc <= i_ID_EX_output_pc;
            o_ID_EX_read_data_1 <= i_ID_EX_read_data_1;
            o_ID_EX_read_data_2 <= i_ID_EX_read_data_2;
            o_ID_EX_immediate <= i_ID_EX_immediate;
            o_ID_EX_rd <= i_ID_EX_rd;
            o_ID_EX_funct3 <= i_ID_EX_funct3;
            o_ID_EX_funct7 <= i_ID_EX_funct7;
        end
    end

    //inputs for EX/MEM pipeline register
    wire [31:0] i_EX_MEM_pc;
    wire i_EX_MEM_MemRead;
    wire [1:0] i_EX_MEM_DataSel;
    wire i_EX_MEM_LoadStoreActive;
    wire i_EX_MEM_MemWrite;
    wire i_EX_MEM_RegWrite;
    wire [31:0] i_EX_MEM_pc_lui;
    wire [31:0] i_EX_MEM_alu_result;
    wire [31:0] i_EX_MEM_rf_read_2;
    wire [2:0] i_EX_MEM_funct3;
    wire [4:0] i_EX_MEM_rd;

    execute u_execute(
        .i_pc(o_ID_EX_output_pc),
        .i_rf_read_1(o_ID_EX_read_data_1),
        .i_rf_read_2(o_ID_EX_read_data_2),
        .i_imm(o_ID_EX_immediate),
        .i_funct3(o_ID_EX_funct3),
        .i_funct7(o_ID_EX_funct7),
        .i_rd(o_ID_EX_rd),
        .i_JALRsel(o_ID_EX_JALRsel),
        .i_LUIsel(o_ID_EX_LUIsel),
        .i_JALsel(o_ID_EX_JALsel),
        .i_Branch(o_ID_EX_Branch),
        .i_MemRead(o_ID_EX_MemRead),
        .i_MemWrite(o_ID_EX_MemWrite),
        .i_DataSel(o_ID_EX_DataSel),
        .i_ALUop(o_ID_EX_ALUop),
        .i_ALUSrc(o_ID_EX_ALUSrc),
        .i_LoadStoreActive(o_ID_EX_LoadStoreActive),
        .i_RegWrite(o_ID_EX_RegWrite),

        // Outputs
        .o_pc(i_EX_MEM_pc),
        .o_MemRead(i_EX_MEM_MemRead),
        .o_DataSel(i_EX_MEM_DataSel),
        .o_LoadStoreActive(i_EX_MEM_LoadStoreActive),
        .o_MemWrite(i_EX_MEM_MemWrite),
        .o_RegWrite(i_EX_MEM_RegWrite),
        .o_pc_lui(i_EX_MEM_pc_lui),
        .o_alu_result(i_EX_MEM_alu_result),
        .o_rf_read_2(i_EX_MEM_rf_read_2),
        .o_funct3(i_EX_MEM_funct3),
        .o_rd(i_EX_MEM_rd),

        // outputs going to fetch stage
        .o_pc_imm_sel(pc_imm_sel),
        .o_target_address(target_address)
    );
    
    //outputs for EX/MEM pipeline register
    reg [31:0] o_EX_MEM_pc;
    reg o_EX_MEM_MemRead;
    reg [1:0] o_EX_MEM_DataSel;
    reg o_EX_MEM_LoadStoreActive;
    reg o_EX_MEM_RegWrite;
    reg o_EX_MEM_MemWrite;
    reg [31:0] o_EX_MEM_pc_lui;
    reg [31:0] o_EX_MEM_alu_result;
    reg [31:0] o_EX_MEM_rf_read_2;
    reg [2:0] o_EX_MEM_funct3;
    reg [4:0] o_EX_MEM_rd;
    
    // EX/MEM Pipeline Register
    always @(posedge i_clk) begin
        if (i_rst) begin
            o_EX_MEM_pc <= 32'd0;
            o_EX_MEM_MemRead <= 1'b0;
            o_EX_MEM_DataSel <= 2'b00;
            o_EX_MEM_LoadStoreActive <= 1'b0;
            o_EX_MEM_RegWrite <= 1'b0;
            o_EX_MEM_MemWrite <= 1'b0;
            o_EX_MEM_pc_lui <= 32'd0;
            o_EX_MEM_alu_result <= 32'd0;
            o_EX_MEM_rf_read_2 <= 32'd0;
            o_EX_MEM_funct3 <= 3'd0;
            o_EX_MEM_rd <= 5'd0;
        end else begin
            o_EX_MEM_pc <= i_EX_MEM_pc;
            o_EX_MEM_MemRead <= i_EX_MEM_MemRead;
            o_EX_MEM_DataSel <= i_EX_MEM_DataSel;
            o_EX_MEM_LoadStoreActive <= i_EX_MEM_LoadStoreActive;
            o_EX_MEM_RegWrite <= i_EX_MEM_RegWrite;
            o_EX_MEM_MemWrite <= i_EX_MEM_MemWrite;
            o_EX_MEM_pc_lui <= i_EX_MEM_pc_lui;
            o_EX_MEM_alu_result <= i_EX_MEM_alu_result;
            o_EX_MEM_rf_read_2 <= i_EX_MEM_rf_read_2;
            o_EX_MEM_funct3 <= i_EX_MEM_funct3;
            o_EX_MEM_rd <= i_EX_MEM_rd;
        end
    end
    
    //inputs for MEM/WB pipeline register
    wire [1:0] i_MEM_WB_DataSel;
    wire i_MEM_WB_RegWrite;
    wire [31:0] i_MEM_WB_pc;
    wire [31:0] i_MEM_WB_pc_lui;
    wire [31:0] i_MEM_WB_read_align_data;
    wire [31:0] i_MEM_WB_alu_result;
    wire [4:0] i_MEM_WB_rd;

    // instatiate trap signal
    wire trap_unaligned_address;
    
    //instantiate memory stage
    memory u_memory (
        // Inputs from EX/MEM Pipeline Register
        .EX_MEM_pc(o_EX_MEM_pc),
        .EX_MEM_pc_lui(o_EX_MEM_pc_lui),
        .EX_MEM_alu_result(o_EX_MEM_alu_result),
        .EX_MEM_rf_read_2(o_EX_MEM_rf_read_2),
        .EX_MEM_funct3(o_EX_MEM_funct3),
        .EX_MEM_MemRead(o_EX_MEM_MemRead),
        .EX_MEM_DataSel(o_EX_MEM_DataSel),
        .EX_MEM_MemWrite(o_EX_MEM_MemWrite),
        .EX_MEM_LoadStoreActive(o_EX_MEM_LoadStoreActive),
        .EX_MEM_RegWrite(o_EX_MEM_RegWrite),
        .EX_MEM_rd(o_EX_MEM_rd),

        // Input from Data Memory (Read Data)
        .i_dmem_rdata(i_dmem_rdata),

        // Data Memory Bus Outputs
        .o_dmem_addr(o_dmem_addr),
        .o_dmem_ren(o_dmem_ren),
        .o_dmem_wen(o_dmem_wen),
        .o_dmem_wdata(o_dmem_wdata),
        .o_dmem_mask(o_dmem_mask),

        // Aligned Read Output to MEM/WB Pipeline Register
        .MEM_WB_DataSel(i_MEM_WB_DataSel),
        .MEM_WB_RegWrite(i_MEM_WB_RegWrite),
        .MEM_WB_pc(i_MEM_WB_pc),
        .MEM_WB_pc_lui(i_MEM_WB_pc_lui),
        .MEM_WB_read_align_data(i_MEM_WB_read_align_data),
        .MEM_WB_alu_result(i_MEM_WB_alu_result),
        .MEM_WB_rd(i_MEM_WB_rd),

        // Trap Signal
        .retire_trap_unaligned_address(trap_unaligned_address)
    );



    //outputs for MEM/WB pipeline register
    reg [1:0] o_MEM_WB_DataSel;
    reg o_MEM_WB_RegWrite;
    reg [31:0] o_MEM_WB_pc;
    reg [31:0] o_MEM_WB_pc_lui;
    reg [31:0] o_MEM_WB_read_align_data;
    reg [31:0] o_MEM_WB_alu_result;
    reg [4:0] o_MEM_WB_rd;

    // MEM/WB Pipeline Register
    always @(posedge i_clk) begin
        if (i_rst) begin
            o_MEM_WB_DataSel <= 2'b00;
            o_MEM_WB_RegWrite <= 1'b0;
            o_MEM_WB_pc <= 32'd0;
            o_MEM_WB_pc_lui <= 32'd0;
            o_MEM_WB_read_align_data <= 32'd0;
            o_MEM_WB_alu_result <= 32'd0;
            o_MEM_WB_rd <= 5'd0;
        end else begin
            o_MEM_WB_DataSel <= i_MEM_WB_DataSel;
            o_MEM_WB_RegWrite <= i_MEM_WB_RegWrite;
            o_MEM_WB_pc <= i_MEM_WB_pc;
            o_MEM_WB_pc_lui <= i_MEM_WB_pc_lui;
            o_MEM_WB_read_align_data <= i_MEM_WB_read_align_data;
            o_MEM_WB_alu_result <= i_MEM_WB_alu_result;
            o_MEM_WB_rd <= i_MEM_WB_rd;
        end
    end

    wire [31:0] retire_pc;
    wire [31:0] retire_next_pc;

    //instantiate writeback stage
    writeback u_writeback (
        .i_DataSel(o_MEM_WB_DataSel),
        .i_RegWrite(o_MEM_WB_RegWrite),
        .i_pc(o_MEM_WB_pc),
        .i_pc_lui(o_MEM_WB_pc_lui),
        .i_read_align_data(o_MEM_WB_read_align_data),
        .i_alu_result(o_MEM_WB_alu_result),
        .i_rd(o_MEM_WB_rd),
        .o_RegWrite(o_WB_RegWrite),
        .o_rf_write_data(o_WB_rf_write_data),
        .o_rd(o_WB_rf_rd),
        .o_retire_pc(retire_pc)
    );


    //instantiate hazard detection unit
    hazard_detection_unit u_hazard_detection(
        .i_decode_rs1(o_decode_rs1),
        .i_decode_rs2(o_decode_rs2),
        .ID_EX_RegWrite(o_ID_EX_RegWrite),
        .ID_EX_rd(o_ID_EX_rd),
        .EX_MEM_rd(o_EX_MEM_rd),
        .EX_MEM_RegWrite(o_EX_MEM_RegWrite),
        .stall(stall)
    );

    // Retire Logic
    // input wires
    wire [31:0] i_ID_EX_instruction;
    wire [31:0] i_EX_MEM_instruction;
    wire [31:0] i_MEM_WB_instruction;

    wire        i_IF_ID_nop_signal;
    wire        i_ID_EX_nop_signal;
    wire        i_EX_MEM_nop_signal;
    wire        i_MEM_WB_nop_signal;

    wire [31:0] i_EX_MEM_rs1_rdata;
    wire [31:0] i_MEM_WB_rs1_rdata;

    wire [31:0] i_EX_MEM_rs2_rdata;
    wire [31:0] i_MEM_WB_rs2_rdata;

    wire [31:0] i_MEM_WB_dmem_addr;
    wire [ 3:0] i_MEM_WB_dmem_mask;
    wire        i_MEM_WB_dmem_ren;
    wire        i_MEM_WB_dmem_wen;
    wire [31:0] i_MEM_WB_dmem_rdata;
    wire [31:0] i_MEM_WB_dmem_wdata;
    
    // trap signal inputs
    wire        i_IF_ID_trap_unaligned_instruction_address;
    wire        i_ID_EX_trap_unaligned_instruction_address;
    wire        i_EX_MEM_trap_unaligned_instruction_address;
    wire        i_MEM_WB_trap_unaligned_instruction_address;

    wire        i_ID_EX_trap_illegal_instruction;
    wire        i_EX_MEM_trap_illegal_instruction;
    wire        i_MEM_WB_trap_illegal_instruction;

    wire        i_MEM_WB_trap_unaligned_address;

    // output regs
    reg [31:0] o_ID_EX_instruction;
    reg [31:0] o_EX_MEM_instruction;
    reg [31:0] o_MEM_WB_instruction;

    reg        o_IF_ID_nop_signal;  
    reg        o_ID_EX_nop_signal;
    reg        o_EX_MEM_nop_signal;
    reg        o_MEM_WB_nop_signal;

    reg [31:0] o_EX_MEM_rs1_rdata;
    reg [31:0] o_MEM_WB_rs1_rdata;

    reg [31:0] o_EX_MEM_rs2_rdata;
    reg [31:0] o_MEM_WB_rs2_rdata;

    reg [31:0] o_MEM_WB_dmem_addr;
    reg [ 3:0] o_MEM_WB_dmem_mask;
    reg        o_MEM_WB_dmem_ren;
    reg        o_MEM_WB_dmem_wen;
    reg [31:0] o_MEM_WB_dmem_rdata;
    reg [31:0] o_MEM_WB_dmem_wdata;

    reg        o_IF_ID_trap_unaligned_instruction_address;
    reg        o_ID_EX_trap_unaligned_instruction_address;
    reg        o_EX_MEM_trap_unaligned_instruction_address;
    reg        o_MEM_WB_trap_unaligned_instruction_address;

    reg        o_ID_EX_trap_illegal_instruction;
    reg        o_EX_MEM_trap_illegal_instruction;
    reg        o_MEM_WB_trap_illegal_instruction;

    reg        o_MEM_WB_trap_unaligned_address;

    always @(posedge i_clk) begin
        if (i_rst) begin
            o_ID_EX_instruction <= 32'd0;
            o_EX_MEM_instruction <= 32'd0;
            o_MEM_WB_instruction <= 32'd0;
            
            o_IF_ID_nop_signal <= 1'b1;
            o_ID_EX_nop_signal <= 1'b1;
            o_EX_MEM_nop_signal <= 1'b1;
            o_MEM_WB_nop_signal <= 1'b1;

            o_EX_MEM_rs1_rdata <= 32'd0;
            o_MEM_WB_rs1_rdata <= 32'd0;

            o_EX_MEM_rs2_rdata <= 32'd0;
            o_MEM_WB_rs2_rdata <= 32'd0;

            o_MEM_WB_dmem_addr <= 32'd0;
            o_MEM_WB_dmem_mask <= 4'd0;
            o_MEM_WB_dmem_ren <= 1'b0;
            o_MEM_WB_dmem_wen <= 1'b0;
            o_MEM_WB_dmem_rdata <= 32'd0;
            o_MEM_WB_dmem_wdata <= 32'd0;

            o_IF_ID_trap_unaligned_instruction_address <= 1'b0;
            o_ID_EX_trap_unaligned_instruction_address <= 1'b0;
            o_EX_MEM_trap_unaligned_instruction_address <= 1'b0;
            o_MEM_WB_trap_unaligned_instruction_address <= 1'b0;

            o_ID_EX_trap_illegal_instruction <= 1'b0;
            o_EX_MEM_trap_illegal_instruction <= 1'b0;
            o_MEM_WB_trap_illegal_instruction <= 1'b0;

            o_MEM_WB_trap_unaligned_address <= 1'b0;

        end else begin
            o_ID_EX_instruction <= o_IF_ID_instruction;
            o_EX_MEM_instruction <= o_ID_EX_instruction;
            o_MEM_WB_instruction <= o_EX_MEM_instruction;

            o_IF_ID_nop_signal <= 1'b0;
            o_ID_EX_nop_signal <= flush || IF_ID_prev_flush || stall || o_IF_ID_nop_signal;
            o_EX_MEM_nop_signal <= o_ID_EX_nop_signal;
            o_MEM_WB_nop_signal <= o_EX_MEM_nop_signal;

            o_EX_MEM_rs1_rdata <= o_ID_EX_read_data_1;
            o_MEM_WB_rs1_rdata <= o_EX_MEM_rs1_rdata;

            o_EX_MEM_rs2_rdata <= o_ID_EX_read_data_2;
            o_MEM_WB_rs2_rdata <= o_EX_MEM_rs2_rdata;

            o_MEM_WB_dmem_addr <= o_dmem_addr;
            o_MEM_WB_dmem_mask <= o_dmem_mask;
            o_MEM_WB_dmem_ren <= o_dmem_ren;
            o_MEM_WB_dmem_wen <= o_dmem_wen;
            o_MEM_WB_dmem_rdata <= i_dmem_rdata;
            o_MEM_WB_dmem_wdata <= o_dmem_wdata;

            o_IF_ID_trap_unaligned_instruction_address <= trap_unaligned_instruction_address;
            o_ID_EX_trap_unaligned_instruction_address <= o_IF_ID_trap_unaligned_instruction_address;
            o_EX_MEM_trap_unaligned_instruction_address <= o_ID_EX_trap_unaligned_instruction_address;
            o_MEM_WB_trap_unaligned_instruction_address <= o_EX_MEM_trap_unaligned_instruction_address;

            o_ID_EX_trap_illegal_instruction <= trap_illegal_instruction;
            o_EX_MEM_trap_illegal_instruction <= o_ID_EX_trap_illegal_instruction;
            o_MEM_WB_trap_illegal_instruction <= o_EX_MEM_trap_illegal_instruction;

            o_MEM_WB_trap_unaligned_address <= trap_unaligned_address;

        end
    end


    // Retire signals
    // assign o_retire_valid = !o_MEM_WB_DataSel[1] && !o_MEM_WB_DataSel[0] && !o_MEM_WB_RegWrite;
    

    assign o_retire_valid     = !(o_MEM_WB_nop_signal);
    assign o_retire_inst      = o_MEM_WB_instruction; 
    assign o_retire_pc        = retire_pc;
    assign o_retire_next_pc   = o_EX_MEM_pc;
    assign o_retire_halt      = (o_MEM_WB_instruction == 32'h00100073) && o_retire_valid;
    assign o_retire_trap      = (o_MEM_WB_trap_illegal_instruction || o_MEM_WB_trap_unaligned_address || o_MEM_WB_trap_unaligned_instruction_address);

    assign o_retire_rs1_raddr = o_MEM_WB_instruction[19:15];
    assign o_retire_rs2_raddr = o_MEM_WB_instruction[24:20];
    assign o_retire_rs1_rdata = o_MEM_WB_rs1_rdata;
    assign o_retire_rs2_rdata = o_MEM_WB_rs2_rdata;

    assign o_retire_rd_waddr  = o_WB_RegWrite ? o_WB_rf_rd : 5'd0;
    assign o_retire_rd_wdata  = o_WB_rf_write_data;

    assign o_retire_dmem_addr = o_MEM_WB_dmem_addr;
    assign o_retire_dmem_mask = o_MEM_WB_dmem_mask;
    assign o_retire_dmem_ren  = o_MEM_WB_dmem_ren;
    assign o_retire_dmem_wen  = o_MEM_WB_dmem_wen;
    assign o_retire_dmem_rdata = o_MEM_WB_dmem_rdata;
    assign o_retire_dmem_wdata = o_MEM_WB_dmem_wdata;

endmodule

`default_nettype wire
