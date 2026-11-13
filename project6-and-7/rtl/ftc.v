// flight_traffic_controller.v
//helps us to have multiple memory reads inflight

module ftc(
    input wire i_clk,
    input wire i_rst, 

    //input signals
    input wire ebreak,
    input wire ready,
    input wire branch,
    input wire valid,
    input wire [31:0] inflight_cnt,

    //output signals
    output reg ebreak_flush,
    output reg branch_flush,
    output wire flush_invalid,
    output reg ren,
    output reg pc_increment,
    output reg pc_target,
    output reg inc,
    output reg dec
);
    
    // Flush if the current instruction is invalid
    assign flush_invalid = ~valid;

    // FSM enums
    localparam INIT = 2'b00;
    localparam RUN = 2'b01;
    localparam EBREAK = 2'b10;
    localparam FLUSH = 2'b11;

    reg [1:0] state, next_state;
    
    // State registers
    always @(posedge i_clk) begin
        if (i_rst) begin
            // Reset logic
            state <= INIT;
        end else begin
            // State machine logic based on the current state and input signals
            state <= next_state;
        end
    end

    // State transition logic
    always @(*) begin
        next_state = state; // Default to current state
        ebreak_flush = 1'b0;
        branch_flush = 1'b0;
        ren = 1'b0;
        pc_increment = 1'b0;
        pc_target = 1'b0;
        inc = 1'b0;
        dec = 1'b0;

        case (state)
            INIT: begin
                if (ready) begin
                    next_state = RUN;
                    ren = 1'b1; // Enable memory read
                    pc_increment = 1'b1; // Increment PC
                end
            end
            RUN: begin
                if (branch) begin
                    if (valid) begin
                        dec = 1'b1; // Decrement inflight count
                        pc_target = 1'b1; // Set PC to branch target
                    end else begin
                        pc_target = 1'b1; // Set PC to branch target 
                    end
                    next_state = FLUSH; // Transition to FLUSH state
                end

                if (ebreak && valid) begin
                    dec = 1'b1; // Decrement inflight count
                    next_state = EBREAK; // Transition to EBREAK state
                end

                if (!branch) begin
                    if (valid) begin
                        dec = 1'b1; // Decrement inflight count
                    end
                    if (ready) begin
                        ren = 1'b1; // Enable memory read
                        pc_increment = 1'b1; // Increment PC
                    end
                    next_state = RUN; // Stay in RUN state
                end
            end

            EBREAK: begin
                if (branch) begin
                    if (valid) begin
                        dec = 1'b1; // Decrement inflight count
                        pc_target = 1'b1; // Set PC to branch target
                    end else begin
                        pc_target = 1'b1; // Set PC to branch target 
                    end
                    next_state = FLUSH; // Transition to FLUSH state
                end
                if (valid && ~branch) begin
                    dec = 1'b1; // Decrement inflight count
                    next_state = EBREAK; // Stay in EBREAK state
                end
            end

            FLUSH: begin
                if (valid && inflight_cnt != 0) begin
                    dec = 1'b1; // Decrement inflight count
                    branch_flush = 1'b1; // Flush due to branch
                    next_state = FLUSH; // Stay in FLUSH state
                end
                if (ready && inflight_cnt == 0) begin
                    ren = 1'b1; // Enable memory read
                    pc_increment = 1'b1; // Increment PC
                    next_state = RUN; // Transition back to RUN state
                end
            end


        endcase            


    end



















endmodule