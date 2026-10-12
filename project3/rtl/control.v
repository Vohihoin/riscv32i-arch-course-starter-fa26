module control(
    input [31:0] instruction,
    output reg JALRsel
    output reg [2:0] ALUop,
    output reg Branch,
    output reg MemRead,
    output reg MemWrite,
    output reg MemtoReg,
    output reg ALUSrc,
    output reg RegWrite
);


endmodule