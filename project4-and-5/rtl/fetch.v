`default_nettype none

module fetch #(
    parameter RESET_ADDR = 32'h00000000
) (
    input  wire        i_clk,
    input  wire        i_rst,
    input  wire        i_jalr_sel,
    input  wire        i_jalsel_or,
    input  wire        i_EBREAKsel,
    input  wire [31:0] i_imm_adder,
    input  wire [31:0] i_result_and,
    input  wire [31:0] i_mem_rdata,
    input wire         stall,
    output wire [31:0] o_pc,
    output wire [31:0] o_incre_pc,
    output wire [31:0] o_next_pc,
    output wire [31:0] o_imem_raddr,
    output wire        o_trap_unaligned_instruction_address
);

    reg [31:0] pc;

    always @(posedge i_clk) begin
        if (i_rst) begin
            pc <= RESET_ADDR;
        end else begin
            pc <= o_next_pc;
        end
    end

    assign o_pc         = pc;
    assign o_imem_raddr = pc;
    assign o_incre_pc   = pc + 32'd4;

    wire [31:0] pc_mux_1 = pc_imm_sel ? i_jalr_sel : o_incre_pc;
    wire ebreak_or = i_imem_rdata | stall;
    assign o_next_pc  = ebreak_or ? pc : pc_mux_1;

    // Trap if the lowest bit of address is a 1 (unaligned instruction address - assuming 16-bit alignment)
    assign o_trap_unaligned_instruction_address = o_next_pc[0]; 

endmodule

`default_nettype wire