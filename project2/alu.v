`default_nettype none

// The arithmetic logic unit (ALU) is responsible for performing the core
// calculations of the processor. It takes two 32-bit operands and outputs
// a 32 bit result based on the selection operation - addition, comparison,
// shift, or logical operation. This ALU is a purely combinational block, so
// you should not attempt to add any registers or pipeline it.
module alu (
    // NOTE: Both 3'b010 and 3'b011 are used for set less than operations and
    // your implementation should output the same result for both codes. The
    // reason for this will become clear in project 3.
    //
    // Major operation selection.
    // 3'b000: addition/subtraction if `i_sub` asserted
    // 3'b001: shift left logical
    // 3'b010,
    // 3'b011: set less than/unsigned if `i_unsigned` asserted
    // 3'b100: exclusive or
    // 3'b101: shift right logical/arithmetic if `i_arith` asserted
    // 3'b110: or
    // 3'b111: and
    input  wire [ 2:0] i_opsel,
    // When asserted, addition operations should subtract instead.
    // This is only used for `i_opsel == 3'b000` (addition/subtraction).
    input  wire        i_sub,
    // When asserted, comparison operations should be treated as unsigned.
    // This is used for branch comparisons and set less than unsigned. For
    // b ranch operations, the ALU result is not used, only the comparison
    // results.
    input  wire        i_unsigned,
    // When asserted, right shifts should be treated as arithmetic instead of
    // logical. This is only used for `i_opsel == 3'b101` (shift right).
    input  wire        i_arith,
    // First 32-bit input operand.
    input  wire [31:0] i_op1,
    // Second 32-bit input operand.
    input  wire [31:0] i_op2,
    // 32-bit output result. Any carry out should be ignored.
    output wire [31:0] o_result,
    // Equality result. This is used externally to determine if a branch
    // should be taken.
    output wire        o_eq,
    // Set less than result. This is used externally to determine if a branch
    // should be taken.
    output wire        o_slt
);
    output reg [31:0] o_result_temp;
    output reg        o_eq_temp;
    output reg        o_slt_temp;

    // Always blocks to implement addition and subtraction
    reg [31:0] o_result_addition;
    always @(*) begin
        o_result_addition = i_op1 + i_op2;
    end

    reg [31:0] o_result_subtraction;
    always @(*) begin
        o_result_subtraction = i_op1 - i_op2;
    end

    // Always blocks to implement shift left logical
    reg [31:0] o_result_shift_left_logical;
    reg [31:0] stage0_out;
    reg [31:0] stage1_out;
    reg [31:0] stage2_out;
    reg [31:0] stage3_out;
    always @(*) begin
        stage0_out = (i_op2[0]) ? {i_op1[31:1], 1'b0} : i_op1;
        stage1_out = (i_op2[1]) ? {stage0_out[31:2], 2'b0} : stage0_out;
        stage2_out = (i_op2[2]) ? {stage1_out[31:4], 4'b0} : stage1_out;
        stage3_out = (i_op2[3]) ? {stage2_out[31:8], 8'b0} : stage2_out;
        o_result_shift_left_logical = (i_op2[4]) ? {stage3_out[31:16], 16'b0} : stage3_out;
    end

    // Logic for the outputs
    always @(*) begin
        o_eq_temp = (o_result_subtraction == 0);
        case (i_opsel)
            3'b000: begin
                o_result_temp = (i_sub) ? o_result_subtraction : o_result_addition;
            end
            3'b001: begin 
                o_result_temp = o_result_shift_left_logical;
            end
            3'b010: begin 
                case (i_unsigned)
                    1'b0: begin
                        o_result_temp = (i_op1[31] != i_op2[31]) ? ( (i_op1[31] == 1'b1) ? 31'b1 : 32'b0 ) :
                                        ((i_op1[31] == 1'b0) ? ((i_op1 < i_op2) ? 32'b1 : 32'b0) : ((i_op1 > i_op2) ? 32'b1 : 32'b0));
                                        
                    end
                    1'b1: begin
                        o_result_temp = (i_op1 < i_op2) ? 32'b1 : 32'b0;
                    end
                endcase
            end
            3'b011: begin 

            end
            3'b100: begin 

            end
            3'b101: begin

             end
            3'b110: begin 

            end
            3'b111: begin 

            end

        endcase

    end


endmodule

`default_nettype wire
