module alu_cntrl (
    input wire [1:0] alu_op,
    input wire [2:0] funct3,
    input wire [6:0] funct7,
    output wire [2:0] op_sel,
    output wire o_sub,
    output wire o_arith,
    output wire o_unsigned
);

    // alu_op
    // 2'b00: Load/Store, JALR -> Force Add
    // 2'b01: Branch           -> Force Subtract (compare)
    // 2'b10: R-type           -> Decode
    // 2'b11: I-type arith     -> Decode (no SUB)

    wire decode = alu_op[1];
    wire r_type = (alu_op == 2'b10);
    wire branch = (alu_op == 2'b01);

    assign op_sel     = decode ? funct3 : 3'b000;

    assign o_sub      = branch | (r_type & (funct3 == 3'b000) & funct7[5]);

    assign o_arith    = decode & (funct3 == 3'b101) & funct7[5];

    assign o_unsigned = (decode & (funct3 == 3'b011)) |   // sltu, sltiu
                        (branch & funct3[1]);             // bltu, bgeu
                                


endmodule