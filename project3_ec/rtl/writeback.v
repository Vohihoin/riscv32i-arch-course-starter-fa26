`default_nettype none

module writeback (
    input  wire [1:0]  i_DataSel,
    input  wire [31:0] i_alu_result,
    input  wire [31:0] i_read_align_data,
    input  wire [31:0] i_lui_mux,
    input  wire [31:0] i_incre_pc,
    output wire [31:0] o_rf_write_data
);

    assign o_rf_write_data = (i_DataSel == 2'b00) ? i_alu_result :
                             (i_DataSel == 2'b01) ? i_read_align_data :
                             (i_DataSel == 2'b10) ? i_lui_mux :
                             (i_DataSel == 2'b11) ? i_incre_pc : 32'd0;

endmodule

`default_nettype wire