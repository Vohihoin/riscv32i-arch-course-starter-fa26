`default_nettype none

module fetch #(
    parameter RESET_ADDR = 32'h00000000
) (
    input  wire        i_clk,
    input  wire        i_rst,
    input  wire [31:0] i_pc_target,
    input  wire        i_pc_sel,
    input  wire        stall,

    // Instruction Memory Interface
    input  wire [31:0] i_instruction,
    output wire [31:0] o_instruction,
    output wire [31:0] o_pc,

    // Trap Signals
    output wire        o_trap_unaligned_instruction_address,
    output wire        o_ebreak_occured
);

    reg [31:0] pc;
    wire [31:0] o_next_pc, pc_resolved;

    always @(posedge i_clk) begin
        if (i_rst) begin
            pc <= RESET_ADDR;
        end else begin
            pc <= o_next_pc;
        end
    end

    // If we are stalling, keep  the same PC
    assign o_next_pc = (stall || (i_instruction[6:0] == 7'b1110011 /*E-BREAK OPCODE*/)) ? pc : pc_resolved;

    // Calculate the next PC based on the selection signal
    assign pc_resolved = i_pc_sel ? i_pc_target : (pc + 32'd4);

    // Output assignment (driving o_instruction because)
    assign o_instruction = i_instruction;
    assign o_pc = pc;

    // Trap if the lowest bit of address is a 1 (unaligned instruction address - assuming 16-bit alignment)
    assign o_trap_unaligned_instruction_address = o_next_pc[0]; 

endmodule

`default_nettype wire