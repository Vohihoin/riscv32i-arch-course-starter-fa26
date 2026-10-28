`default_nettype none

module writeback (
    // Input
    input  wire [1:0]  i_DataSel,
    input  wire        i_RegWrite,
    input  wire [31:0] i_pc,
    input  wire [31:0] i_pc_lui,
    input  wire [31:0] i_read_align_data,
    input  wire [31:0] i_alu_result,
    input  wire [4:0]  i_rd,
    // Output
    output wire        o_RegWrite,
    output wire [31:0] o_rf_write_data,
    output wire [4:0]  o_rd
);

    wire [31:0] i_incre_pc = i_pc + 32'd4;

    assign o_rf_write_data = (i_DataSel == 2'b00) ? i_alu_result :
                             (i_DataSel == 2'b01) ? i_read_align_data :
                             (i_DataSel == 2'b10) ? i_pc_lui :
                             (i_DataSel == 2'b11) ? i_incre_pc : 32'd0;

    assign o_RegWrite = i_RegWrite;
    assign o_rd = i_rd;

endmodule

`default_nettype wire