`default_nettype none

module memory (
    input  wire [31:0] i_alu_result,
    input  wire [31:0] i_rf_read_2,
    input  wire [2:0]  i_funct3,
    input  wire        i_MemRead,
    input  wire        i_memWrite,
    input  wire [31:0] i_dmem_rdata,
    // Data Memory Bus Outputs
    output wire [31:0] o_dmem_addr,
    output wire        o_dmem_ren,
    output wire        o_dmem_wen,
    output wire [31:0] o_dmem_wdata,
    output wire [3:0]  o_dmem_mask,
    // Aligned Read Output to Writeback
    output wire [31:0] o_read_align_data,
    output wire retire_trap_unaligned_address
);

    wire [1:0] o_shift_amt_byte;

    align u_align (
        .addr(i_alu_result),
        .data_in(i_rf_read_2),
        .funct3(i_funct3),
        .masked_addr(o_dmem_addr),
        .byte_mask(o_dmem_mask),
        .data_out(o_dmem_wdata),
        .shift_amt_byte(o_shift_amt_byte),
        .retire_trap_unaligned_address(retire_trap_unaligned_address)
    );

    assign o_dmem_ren = i_MemRead;
    assign o_dmem_wen = i_memWrite;

    read_align u_read_align (
        .shift_amt_byte(o_shift_amt_byte),
        .data_in(i_dmem_rdata),
        .funct3(i_funct3),
        .data_out(o_read_align_data)
    );

endmodule

`default_nettype wire