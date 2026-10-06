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
    reg [31:0] o_result_temp;
    reg        o_eq_temp;
    reg        o_slt_temp;

    assign o_result = o_result_temp;
    assign o_eq     = o_eq_temp;
    assign o_slt    = o_slt_temp;

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
    reg [31:0] left_stage0_out;
    reg [31:0] left_stage1_out;
    reg [31:0] left_stage2_out;
    reg [31:0] left_stage3_out;
    always @(*) begin
        left_stage0_out = (i_op2[0]) ? {i_op1[30:0], 1'b0} : i_op1;
        left_stage1_out = (i_op2[1]) ? {left_stage0_out[29:0], 2'b0} : left_stage0_out;
        left_stage2_out = (i_op2[2]) ? {left_stage1_out[27:0], 4'b0} : left_stage1_out;
        left_stage3_out = (i_op2[3]) ? {left_stage2_out[23:0], 8'b0} : left_stage2_out;
        o_result_shift_left_logical = (i_op2[4]) ? {left_stage3_out[15:0], 16'b0} : left_stage3_out;
    end

    // Always blocks to implement shift right logical and arithmetic
    reg [31:0] o_result_shift_right;
    reg [31:0] right_stage0_out;
    reg [31:0] right_stage1_out;
    reg [31:0] right_stage2_out;
    reg [31:0] right_stage3_out;
    always @(*) begin
        right_stage0_out = (i_op2[0]) ? { (i_arith ? i_op1[31] : 1'b0), i_op1[31:1]} : i_op1;
        right_stage1_out = (i_op2[1]) ? { (i_arith ? {2{i_op1[31]}} : 2'b0), right_stage0_out[31:2]} : right_stage0_out;
        right_stage2_out = (i_op2[2]) ? { (i_arith ? {4{i_op1[31]}} : 4'b0), right_stage1_out[31:4]} : right_stage1_out;
        right_stage3_out = (i_op2[3]) ? { (i_arith ? {8{i_op1[31]}} : 8'b0), right_stage2_out[31:8]} : right_stage2_out;
        o_result_shift_right = (i_op2[4]) ? { (i_arith ? {16{i_op1[31]}} : 16'b0), right_stage3_out[31:16]} : right_stage3_out;
    end

    // Always block to implement set less than and o_slt_temp
    always @(*) begin
        case (i_unsigned)
            1'b0: begin
                // If they have different signs, the negative one is less; otherwise, if they have the same sign,
                // we can compare their magnitudes and our regular comparism will work correctly.
                o_slt_temp = (i_op1[31] != i_op2[31]) ? ( (i_op1[31] == 1'b1) ? 1'b1 : 1'b0 ) : ( (i_op1 < i_op2) ? 1'b1 : 1'b0 );
            end
            1'b1: begin
                // For unsigned comparison, we can directly compare the magnitudes.
                o_slt_temp = (i_op1 < i_op2) ? 1'b1 : 1'b0;
            end
            default: begin // even though we should never reach this case, we set as 1'b0
                o_slt_temp = 1'b0;
            end
        endcase
    end

    // Logic for the outputs
    always @(*) begin
        // Set o_eq_temp based on the result of subtraction
        o_eq_temp = (o_result_subtraction == 0);

        // Set o_result_temp based on the operation selected
        case (i_opsel)
            3'b000: begin
                o_result_temp = (i_sub) ? o_result_subtraction : o_result_addition;
            end
            3'b001: begin 
                o_result_temp = o_result_shift_left_logical;
            end
            3'b010: begin 
                o_result_temp = (o_slt_temp) ? 32'b1 : 32'b0;
            end
            3'b011: begin 
                o_result_temp = (o_slt_temp) ? 32'b1 : 32'b0;
            end
            3'b100: begin 
                o_result_temp = i_op1 ^ i_op2;
            end
            3'b101: begin
                o_result_temp = o_result_shift_right;
             end
            3'b110: begin 
                o_result_temp = i_op1 | i_op2;
            end
            3'b111: begin 
                o_result_temp = i_op1 & i_op2;
            end
            default: begin // even though we should never hit this case, set the result to 0
                o_result_temp = 32'b0;
            end
        endcase

    end


endmodule

`default_nettype wire
