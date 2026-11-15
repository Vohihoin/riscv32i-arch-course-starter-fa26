`default_nettype none

module mem (

    // Base signals
    input wire i_clk,
    input wire i_rst,

    // Inputs from EX/MEM Pipeline Register
    input  wire [31:0] EX_MEM_pc,
    input  wire [31:0] EX_MEM_pc_lui,
    input  wire [31:0] EX_MEM_alu_result,
    input  wire [31:0] EX_MEM_rf_read_2,
    input  wire [2:0]  EX_MEM_funct3,
    input  wire        EX_MEM_MemRead,
    input  wire [1:0]  EX_MEM_DataSel,
    input  wire        EX_MEM_MemWrite,
    input  wire        EX_MEM_LoadStoreActive,
    input  wire        EX_MEM_RegWrite,
    input  wire [4:0]  EX_MEM_rd,
    
    // Input from Data Memory (Read Data)
    input  wire        i_dmem_ready,
    input  wire        i_dmem_valid,
    input  wire [31:0] i_dmem_rdata,


    // Data Memory Bus Outputs
    output wire [31:0] o_dmem_addr,
    output wire        o_dmem_ren,
    output wire        o_dmem_wen,
    output wire [31:0] o_dmem_wdata,
    output wire [3:0]  o_dmem_mask,

    // Aligned Read Output to MEM/WB Pipeline Register
    output wire [1:0]  MEM_WB_DataSel,
    output wire        MEM_WB_RegWrite,
    output wire [31:0] MEM_WB_pc,
    output wire [31:0] MEM_WB_pc_lui,
    output wire [31:0] MEM_WB_read_align_data,
    output wire [31:0] MEM_WB_alu_result,
    output wire [4:0]  MEM_WB_rd,
    output wire [31:0] MEM_WB_pc_next,

    // Trap Signals
    output wire        retire_trap_unaligned_address,

    // Data Memory Traffic Controller Stall Signal
    output wire dmtc_stall
);

    wire [1:0] shift_amt;

    align u_align (
        .addr                          (EX_MEM_alu_result),
        .data_in                       (EX_MEM_rf_read_2),
        .funct3                        (EX_MEM_funct3),
        .load_store_active             (EX_MEM_LoadStoreActive),
        .masked_addr                   (o_dmem_addr),
        .byte_mask                     (o_dmem_mask),
        .data_out                      (o_dmem_wdata),
        .shift_amt_byte                (shift_amt),
        .retire_trap_unaligned_address (retire_trap_unaligned_address)
    );



    read_align u_read_align (
        .shift_amt_byte (shift_amt),
        .data_in        (i_dmem_rdata),
        .funct3         (EX_MEM_funct3),
        .data_out       (MEM_WB_read_align_data)
    );

    // Outputs to MEM/WB Pipeline Register
    assign MEM_WB_DataSel     = EX_MEM_DataSel;
    assign MEM_WB_RegWrite    = EX_MEM_RegWrite;
    assign MEM_WB_pc          = EX_MEM_pc;
    assign MEM_WB_pc_lui      = EX_MEM_pc_lui;
    assign MEM_WB_alu_result  = EX_MEM_alu_result;
    assign MEM_WB_rd          = EX_MEM_rd;
    assign MEM_WB_pc_next     = EX_MEM_pc + 32'd4;


    dmtc iDTMC(
        .i_clk(i_clk),
        .i_rst(i_rst),
        .EX_MEM_wen(EX_MEM_MemWrite),
        .EX_MEM_ren(EX_MEM_MemRead),
        .dmem_ready(i_dmem_ready),
        .dmem_valid(i_dmem_valid),
        .stall(dmtc_stall),
        .ren_actual(o_dmem_ren),
        .wen_actual(o_dmem_wen)
    );

endmodule

`default_nettype wire