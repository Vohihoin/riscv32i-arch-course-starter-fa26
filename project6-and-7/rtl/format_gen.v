module format_gen (
    input wire [6:0] opcode,
    output wire [5:0] format
);

// [0] R-type
assign format[0] = (opcode == 7'b0110011);

// [1] I-type
assign format[1] = (opcode == 7'b0010011 | opcode == 7'b0000011 | opcode == 7'b1100111 | opcode == 7'b1110011);
// Last two opcodes are for JALR and ECALL/EBREAK, which are I-type instructions

// [2] S-type
assign format[2] = (opcode == 7'b0100011);

// [3] B-type
assign format[3] = (opcode == 7'b1100011);

// [4] U-type
assign format[4] = (opcode == 7'b0110111 | opcode == 7'b0010111);

// [5] J-type
assign format[5] = (opcode == 7'b1101111);


endmodule