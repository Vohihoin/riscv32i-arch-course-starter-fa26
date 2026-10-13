`default_nettype none

module fetch #(
    parameter RESET_ADDR = 32'h00000000
) (
    input  wire        i_clk,
    input  wire        i_rst,
    input  wire        i_jalr_sel,
    input  wire        i_jalsel_or,
    input  wire [31:0] i_imm_adder,
    input  wire [31:0] i_result_and,
    output wire [31:0] o_pc,
    output wire [31:0] o_incre_pc,
    output wire [31:0] o_next_pc,
    output wire [31:0] o_imem_raddr
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

    wire [31:0] jal_mux = i_jalsel_or ? i_imm_adder : o_incre_pc;
    assign o_next_pc    = i_jalr_sel  ? i_result_and : jal_mux;

endmodule

`default_nettype wire