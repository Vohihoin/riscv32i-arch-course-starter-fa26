`default_nettype none

module fetch #(
    parameter RESET_ADDR = 32'h00000000
) (
    input  wire        i_clk,
    input  wire        i_rst,

    // Inputs
    input  wire [31:0] i_pc_target,
    input  wire        i_pc_sel,
    input  wire        stall,

    // Instruction Memory Interface
    output wire [31:0] o_pc,
    output wire        o_imem_ren,
    input  wire [31:0] i_instruction,
    input  wire        i_imem_ready,
    input  wire        i_imem_valid,

    // Outputs
    output wire [31:0] o_instruction,
    output wire        o_ebreak_flush,
    output wire        o_branch_flush,
    output wire        o_flush_invalid,
    output wire [31:0] imem_output_pc,

    // Trap Signals
    output wire        o_trap_unaligned_instruction_address
);

    reg [31:0] pc;
    wire [31:0] o_next_pc;
    reg [31:0] inflight_counter;

    wire inc, dec;
    wire ebreak;
    wire pc_increment, pc_target, imem_output_pc_en;

    // PC register
    always @(posedge i_clk) begin
        if (i_rst) begin
            pc <= RESET_ADDR;
        end else if (imem_output_pc_en) begin
            pc <= imem_output_pc;
        end else if (pc_target) begin
            pc <= i_pc_target;
        end else if (stall | !pc_increment) begin
            pc <= pc;
        end else begin
            pc <= pc + 4;
        end
    end

    // In Flight Counter register
    always @(posedge i_clk) begin
        if (i_rst) begin
            inflight_counter <= 32'b0;
        end else if (inc & !dec) begin
            inflight_counter <= inflight_counter + 1;
        end else if (dec & !inc) begin
            inflight_counter <= inflight_counter - 1;
        end else begin
            inflight_counter <= inflight_counter;
        end
    end

    assign imem_output_pc = pc - (inflight_counter << 2);    // Subtract pc by inflight_counter multiplied by 4
    assign ebreak = (i_instruction[6:0] == 7'b1110011);

    // Flight Traffic Control FSM
    ftc fsm_ftc(
        .i_clk(i_clk),
        .i_rst(i_rst),
        
        // Inputs Signal
        .stall(stall),
        .ebreak(ebreak),
        .ready(i_imem_ready),
        .branch(i_pc_sel),
        .valid(i_imem_valid),
        .inflight_cnt(inflight_counter),

        // Output Signals
        .ebreak_flush(o_ebreak_flush),
        .branch_flush(o_branch_flush),
        .flush_invalid(o_flush_invalid),
        .ren(o_imem_ren),
        .pc_increment(pc_increment),
        .pc_target(pc_target),
        .inc(inc),
        .dec(dec),
        .imem_output_pc(imem_output_pc_en)
    );

    // Output assignment (driving o_instruction because)
    assign o_instruction = i_instruction;
    assign o_pc = pc;

    // Trap if the lowest bit of address is a 1 (unaligned instruction address - assuming 16-bit alignment)
    assign o_trap_unaligned_instruction_address = o_next_pc[0]; 

endmodule

`default_nettype wire