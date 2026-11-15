// flight_traffic_controller.v
//helps us to have multiple memory reads inflight

module ftc(
    input wire i_clk,
    input wire i_rst, 

    //input signals
    input wire stall,
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
    output wire inc,
    output reg dec,
    output reg imem_output_pc
);
    
    // Flush if the current instruction is invalid
    assign flush_invalid = ~valid;

    // FSM enums
    localparam INIT = 3'b000;
    localparam RUN = 3'b001;
    localparam EBREAK = 3'b010;
    localparam FLUSH = 3'b011;
    localparam STALL = 3'b100;

    reg [2:0] state, next_state;
    
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


    // 'inc' and 'ren' are the same signal
    assign inc = ren;

    // State transition logic
    always @(*) begin
        next_state = state; // Default to current state
        ebreak_flush = 1'b0;
        branch_flush = 1'b0;
        ren = 1'b0;
        pc_increment = 1'b0;
        pc_target = 1'b0;
        dec = 1'b0;
        imem_output_pc = 1'b0;

        case (state)
            INIT: begin
                case (ready)
                    1'b0: begin end
                    1'b1: begin 
                        next_state = RUN;
                        ren = 1'b1; // Enable memory read
                        pc_increment = 1'b1; // Increment PC
                    end
                endcase

                // // Original "if" based implementation for INIT state
                // if (ready) begin
                //     next_state = RUN;
                //     ren = 1'b1; // Enable memory read
                //     pc_increment = 1'b1; // Increment PC
                // end
            end
            RUN: begin
                casez ({stall, branch, ebreak, valid})
                    4'b1??1: begin
                        next_state = STALL;
                        imem_output_pc = 1'b1;
                    end
                    4'b01??: begin  // Case when branch is 1, ebreak may or may not be asserted
                        case (valid)
                            1'b0: begin 
                                pc_target = 1'b1; // Set PC to branch target
                            end
                            1'b1: begin 
                                dec = 1'b1; // Decrement inflight count
                                pc_target = 1'b1; // Set PC to branch target
                            end
                        endcase
                        next_state = FLUSH; // Transition to FLUSH state
                    end
                    4'b0011: begin  // Case when branch is 0 and ebreak is asserted (i.e ebreak = 1 and valid = 1)
                        dec = 1'b1; // Decrement inflight count
                        next_state = EBREAK; // Transition to EBREAK state
                    end
                    4'b0001: begin  // Case when branch is 0 and ebreak is not asserted, but we have a new valid word (default case)
                        dec = 1'b1; // Decrement inflight count
                        case (ready) // And if a new instruction is ready to be fetched, send it
                            1'b0: begin end
                            1'b1: begin
                                ren = 1'b1; // Enable memory read
                                pc_increment = 1'b1; // Increment PC
                            end
                        endcase
                        next_state = RUN; // Stay in RUN state
                    end
                    default: begin /*Use the default values in any other unspecified case */end
                endcase
                
                // // Original "if" based implementation
                // if (branch) begin
                //     if (valid) begin
                //         dec = 1'b1; // Decrement inflight count
                //         pc_target = 1'b1; // Set PC to branch target
                //     end else begin
                //         pc_target = 1'b1; // Set PC to branch target 
                //     end
                //     next_state = FLUSH; // Transition to FLUSH state
                // end

                // if (ebreak && valid) begin
                //     dec = 1'b1; // Decrement inflight count
                //     next_state = EBREAK; // Transition to EBREAK state
                // end

                // if (!branch) begin
                //     if (valid) begin
                //         dec = 1'b1; // Decrement inflight count
                //     end
                //     if (ready) begin
                //         ren = 1'b1; // Enable memory read
                //         pc_increment = 1'b1; // Increment PC
                //     end
                //     next_state = RUN; // Stay in RUN state
                // end
            end

            EBREAK: begin
                casez ({branch, valid})
                    2'b1?: begin
                        case(valid)
                            1'b1: begin
                                dec = 1'b1; // Decrement inflight count
                                pc_target = 1'b1; // Set PC to branch target
                            end
                            1'b0: begin
                                pc_target = 1'b1; // Set PC to branch target
                            end
                        endcase
                        next_state = FLUSH; // Transition to FLUSH state
                    end

                    2'b01: begin
                        dec = 1'b1; // Decrement inflight count
                        next_state = EBREAK; // Stay in EBREAK state
                    end

                    default: begin /*Stay in the same state if no other case matches*/ end

                endcase

                // // Original "if" based implementation
                // if (branch) begin
                //     if (valid) begin
                //         dec = 1'b1; // Decrement inflight count
                //         pc_target = 1'b1; // Set PC to branch target
                //     end else begin
                //         pc_target = 1'b1; // Set PC to branch target 
                //     end
                //     next_state = FLUSH; // Transition to FLUSH state
                // end
                // if (valid && ~branch) begin
                //     dec = 1'b1; // Decrement inflight count
                //     next_state = EBREAK; // Stay in EBREAK state
                // end
            end

            FLUSH: begin

                casez({((inflight_cnt == 0) && ready), (valid && (inflight_cnt != 0))})
                    2'b1?: begin
                        // Ready and inflight count is zero, take appropriate action
                        ren = 1'b1; // Send a memory request with the branch address
                        pc_increment = 1'b1; // Increment PC
                        next_state = RUN; // Transition back to RUN state
                    end
                    2'b01: begin
                        // Valid word and inflight_cnt is not zero, take appropriate action
                        dec = 1'b1; // Decrement inflight count
                        branch_flush = 1'b1; // We are flushing the memory due to branch
                        next_state = FLUSH; // Stay in FLUSH state
                    end
                    default: begin /*Stay in the same state if no other case matches*/ end
                endcase

                // // Original "if" based implementation for reference
                // if (valid && inflight_cnt != 0) begin
                //     dec = 1'b1; // Decrement inflight count
                //     branch_flush = 1'b1; // Flush due to branch
                //     next_state = FLUSH; // Stay in FLUSH state
                // end
                // if (ready && inflight_cnt == 0) begin
                //     ren = 1'b1; // Enable memory read
                //     pc_increment = 1'b1; // Increment PC
                //     next_state = RUN; // Transition back to RUN state
                // end
            end

            STALL: begin
                casez ({valid, stall})
                    2'b10: begin
                        dec = 1'b1;
                        next_state = FLUSH;
                    end
                    2'b00: begin
                        next_state = FLUSH;
                    end
                    2'b11: begin
                        dec = 1'b1;
                        next_state = STALL;
                    end
                    2'b01: begin
                        next_state = STALL;
                    end
                    default: begin /*Stay in the same state if no other case matches*/ end
                endcase
            end

        endcase            


    end



















endmodule