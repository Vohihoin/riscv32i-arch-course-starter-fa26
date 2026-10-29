`default_nettype none

module execute (
    input  wire [31:0] i_pc,
    input  wire [31:0] i_rf_read_1,
    input  wire [31:0] i_rf_read_2,
    input  wire [31:0] i_imm,
    input  wire [2:0]  i_funct3,
    input  wire [6:0]  i_funct7,
    input  wire [4:0]  i_rd,
    // Control Inputs
    input  wire        i_JALRsel,
    input  wire        i_LUIsel,
    input  wire        i_JALsel,
    input  wire        i_Branch,
    input  wire        i_MemRead,
    input  wire        i_MemWrite,
    input  wire [1:0]  i_DataSel,
    input  wire [1:0]  i_ALUop,
    input  wire        i_ALUSrc,
    input  wire        i_LoadStoreActive,
    input  wire        i_RegWrite,
    // Outputs
    output wire        o_pc_imm_sel,
    output wire [31:0] o_target_address,
    output wire [31:0] o_pc,
    output wire        o_MemRead,
    output wire [1:0]  o_DataSel,
    output wire        o_LoadStoreActive,
    output wire        o_MemWrite,
    output wire        o_RegWrite,
    output wire [31:0] o_pc_lui,
    output wire [31:0] o_alu_result,
    output wire [31:0] o_rf_read_2,
    output wire [2:0]  o_funct3,
    output wire [4:0]  o_rd
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

    wire o_jalsel_or;
    wire [31:0] o_result_and;
    wire [31:0] imm_adder;

    wire alu_mux_sel  = i_funct3[2];
    wire o_eq_slt_mux = alu_mux_sel ? slt : eq;
    wire o_xor        = o_eq_slt_mux ^ i_funct3[0];
    wire o_branch_and = o_xor & i_Branch;

    assign o_jalsel_or  = i_JALsel | o_branch_and;
    assign o_pc_imm_sel = o_jalsel_or | i_JALRsel;
    assign o_result_and = o_alu_result & ~32'd1;
    assign imm_adder  = i_pc + i_imm;
    assign o_pc_lui     = i_LUIsel ? i_imm : imm_adder;

    assign o_target_address = i_JALRsel ? o_result_and : imm_adder; 


    // Output the pipelined signals
    assign o_pc = i_pc;
    assign o_MemRead = i_MemRead;
    assign o_DataSel = i_DataSel;
    assign o_MemWrite = i_MemWrite;
    assign o_RegWrite = i_RegWrite;
    assign o_LoadStoreActive = i_LoadStoreActive;

    assign o_rf_read_2 = i_rf_read_2;
    assign o_funct3 = i_funct3;
    assign o_rd = i_rd;
endmodule

`default_nettype wire