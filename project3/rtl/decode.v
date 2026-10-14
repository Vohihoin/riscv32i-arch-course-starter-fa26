`default_nettype none

module decode (
    input  wire        i_clk,
    input  wire        i_rst,
    input  wire [31:0] i_inst,
    // Writeback inputs coming from WB stage
    input  wire [4:0]  i_wb_rd_addr,
    input  wire [31:0] i_wb_rd_data,
    input  wire        i_wb_reg_write,
    // Register & Immediate outputs
    output wire [4:0]  o_rs1_addr,
    output wire [4:0]  o_rs2_addr,
    output wire [4:0]  o_rd_addr,
    output wire [31:0] o_rf_read_1,
    output wire [31:0] o_rf_read_2,
    output wire [31:0] o_imm,
    // Instruction field outputs for Execute/Memory
    output wire [2:0]  o_funct3,
    output wire [6:0]  o_funct7,
    output wire        o_alu_mux_sel,
    output wire        o_inst_bit12,
    // Control Signal outputs
    output wire        o_JALRsel,
    output wire        o_LUIsel,
    output wire        o_JALsel,
    output wire        o_Branch,
    output wire        o_MemRead,
    output wire [1:0]  o_DataSel,
    output wire [1:0]  o_ALUop,
    output wire        o_memWrite,
    output wire        o_ALUSrc,
    output wire        o_RegWrite,
    output wire retire_trap_illegal_instruction,
    output wire o_load_store_active
);

    assign o_rs1_addr    = i_inst[19:15];
    assign o_rs2_addr    = i_inst[24:20];
    assign o_rd_addr     = i_inst[11:7];
    assign o_funct3      = i_inst[14:12];
    assign o_funct7      = i_inst[31:25];
    assign o_alu_mux_sel = i_inst[14];
    assign o_inst_bit12  = i_inst[12];

    control u_ctrl (
        .instruction(i_inst),
        .JALRsel(o_JALRsel),
        .LUIsel(o_LUIsel),
        .JALsel(o_JALsel),
        .Branch(o_Branch),
        .MemRead(o_MemRead),
        .DataSel(o_DataSel),
        .ALUop(o_ALUop),
        .MemWrite(o_memWrite),
        .ALUSrc(o_ALUSrc),
        .RegWrite(o_RegWrite),
        .retire_trap_illegal_instruction(retire_trap_illegal_instruction),
        .load_store_active(o_load_store_active)
    );

    rf #(.BYPASS_EN(0)) register_file (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_rs1_raddr(o_rs1_addr),
        .i_rs2_raddr(o_rs2_addr),
        .o_rs1_rdata(o_rf_read_1),
        .o_rs2_rdata(o_rf_read_2),
        .i_rd_wdata(i_wb_rd_data),
        .i_rd_waddr(i_wb_rd_addr),
        .i_rd_wen(i_wb_reg_write)
    );

    wire [5:0] o_format;
    format_gen u_fmt (
        .opcode(i_inst[6:0]),
        .format(o_format)
    );

    imm u_imm (
        .i_inst(i_inst),
        .o_immediate(o_imm),
        .i_format(o_format)
    );

endmodule

`default_nettype wire