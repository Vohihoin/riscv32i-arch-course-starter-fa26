`default_nettype none

module execute (
    input  wire [31:0] i_pc,
    input  wire [31:0] i_incre_pc,
    input  wire [31:0] i_rf_read_1,
    input  wire [31:0] i_rf_read_2,
    input  wire [31:0] i_imm,
    input  wire [2:0]  i_funct3,
    input  wire [6:0]  i_funct7,
    input  wire        i_alu_mux_sel,
    input  wire        i_inst_bit12,
    // Control Inputs
    input  wire [1:0]  i_ALUop,
    input  wire        i_ALUSrc,
    input  wire        i_Branch,
    input  wire        i_JALsel,
    input  wire        i_LUIsel,
    // Outputs
    output wire [31:0] o_alu_result,
    output wire [31:0] o_result_and,
    output wire [31:0] o_imm_adder,
    output wire        o_jalsel_or,
    output wire [31:0] o_lui_mux
);

    wire       sub;
    wire       o_unsigned;
    wire       arith;
    wire [2:0] op_sel;

    alu_cntrl u_alu_ctrl (
        .alu_op(i_ALUop),
        .funct7(i_funct7),
        .funct3(i_funct3),
        .o_sub(sub),
        .o_unsigned(o_unsigned),
        .o_arith(arith),
        .op_sel(op_sel)
    );

    wire [31:0] op2 = i_ALUSrc ? i_imm : i_rf_read_2;
    wire        eq;
    wire        slt;

    alu u_alu (
        .i_op1(i_rf_read_1),
        .i_op2(op2),
        .i_sub(sub),
        .i_unsigned(o_unsigned),
        .i_arith(arith),
        .i_opsel(op_sel),
        .o_result(o_alu_result),
        .o_eq(eq),
        .o_slt(slt)
    );

    wire o_eq_slt_mux = i_alu_mux_sel ? slt : eq;
    wire o_xor        = o_eq_slt_mux ^ i_inst_bit12;
    wire o_branch_and = o_xor & i_Branch;

    assign o_jalsel_or  = i_JALsel | o_branch_and;
    assign o_result_and = o_alu_result & ~32'd1;
    assign o_imm_adder  = i_pc + i_imm;
    assign o_lui_mux    = i_LUIsel ? i_imm : o_imm_adder;

endmodule

`default_nettype wire