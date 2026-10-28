`default_nettype none

module memory (
    // Inputs from EX/MEM Pipeline Register
    input  wire [31:0] EX_MEM_alu_result,
    input  wire [31:0] EX_MEM_rf_read_2,
    input  wire [2:0]  EX_MEM_funct3,
    input  wire        EX_MEM_MemRead,
    input  wire        EX_MEM_MemWrite,
    input  wire        EX_MEM_LoadStoreActive,
    
    // Input from Data Memory (Read Data)
    input  wire [31:0] i_dmem_rdata,

    // Data Memory Bus Outputs
    output wire [31:0] o_dmem_addr,
    output wire        o_dmem_ren,
    output wire        o_dmem_wen,
    output wire [31:0] o_dmem_wdata,
    output wire [3:0]  o_dmem_mask,

    // Aligned Read Output to MEM/WB Pipeline Register
    output wire [31:0] MEM_WB_read_align_data,
    output wire        retire_trap_unaligned_address
);

    wire [1:0] shift_amt;

    align u_align (
        .addr                          (EX_MEM_alu_result),
        .data                          (EX_MEM_rf_read_2),
        .funct3                        (EX_MEM_funct3),
        .LoadStoreActive               (EX_MEM_LoadStoreActive),
        .masked_addr                   (o_dmem_addr),
        .byte_mask                     (o_dmem_mask),
        .wdata                         (o_dmem_wdata),
        .shift_amt                     (shift_amt),
        .retire_trap_unaligned_address (retire_trap_unaligned_address)
    );

    assign o_dmem_ren = EX_MEM_MemRead;
    assign o_dmem_wen = EX_MEM_MemWrite;

    read_align u_read_align (
        .shift_amt (shift_amt),
        .idata     (i_dmem_rdata),
        .funct3    (EX_MEM_funct3),
        .odata     (MEM_WB_read_align_data)
    );

endmodule

`default_nettype wire