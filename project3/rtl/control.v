module control(
    input [31:0] instruction,
    output reg JALRsel,
    output reg LUIsel,
    output reg JALsel,
    output reg Branch,
    output reg MemRead,
    output reg [1:0] DataSel,
    output reg [1:0] ALUop,
    output reg MemWrite,
    output reg ALUSrc,
    output reg RegWrite
);

localparam 
    OPCODE_R     = 7'b011_0011,
    OPCODE_I     = 7'b001_0011,
    OPCODE_LOAD  = 7'b000_0011,
    OPCODE_STORE = 7'b010_0011,
    OPCODE_BRANCH= 7'b110_0011,
    OPCODE_JAL   = 7'b110_1111,
    OPCODE_JALR  = 7'b110_0111,
    OPCODE_LUI   = 7'b011_0111,
    OPCODE_AUIPC = 7'b001_0111,
    OPCODE_EBREAK = 7'b111_0011;

localparam
    DATASEL_ALU = 2'b00,
    DATASEL_MEM = 2'b01,
    DATASEL_LUI_AUIPC = 2'b10,
    DATASEL_PC_PLUS_4 = 2'b11;

// alu_op
// 2'b00: Load/Store, JALR -> Force Add
// 2'b01: Branch           -> Force Subtract (compare)
// 2'b10: R-type           -> Decode
// 2'b11: I-type arith     -> Decode (no SUB)
localparam
    ALUOP_FORCE_ADD = 2'b00, // Load/Store, JALR -> Force Add
    ALUOP_FORCE_SUB = 2'b01, // Branch -> Force Subtract (compare)
    ALUOP_R_TYPE = 2'b10, // R-type           -> Decode
    ALUOP_I_TYPE = 2'b11; // I-type arith     -> Decode (no SUB)

always @(*) begin
    JALRsel = 1'b0; // Default to 0 since we don't want to do JALR unless explicitly specified
    LUIsel = 1'bx; // Default to don't care, since if we don't pick the
                   // LUI/AUIPC datapath to send back to our register,
                   // we don't care what this value is
    JALsel = 1'b0; // Default to 0 since we don't want to do JAL unless explicitly specified
    Branch = 1'b0; // Default to 0 since we don't want to do a branch unless explicitly specified
    MemRead = 1'b0; // For safety, default to 0 unless we specifically want to read from memory
    DataSel = 2'b00;
    ALUop = 2'b00;
    MemWrite = 1'b0;
    ALUSrc = 1'b0; // 1 means select immediate, 0 means select register
    RegWrite = 1'b0;

    case (instruction[6:0])
        OPCODE_R: begin
            DataSel = DATASEL_ALU;
            ALUop = ALUOP_R_TYPE;
            RegWrite = 1'b1; // R-type instructions write back to the register file
            ALUSrc = 1'b0; // R-type instructions select register as the second ALU operand
        end
        OPCODE_I: begin
            DataSel = DATASEL_ALU;
            ALUop = ALUOP_I_TYPE;
            RegWrite = 1'b1; // I-type arithmetic instructions write back to the register file
            ALUSrc = 1'b1; // I-type arithmetic instructions select immediate as the second ALU operand
        end
        OPCODE_LOAD: begin
            MemRead = 1'b1; // Enable memory read for load instructions
            RegWrite = 1'b1; // Load instructions write back to the register file
            DataSel = DATASEL_MEM;
            ALUop = ALUOP_FORCE_ADD;
            ALUSrc = 1'b1; // Load instructions select immediate as the second ALU operand (offset)
        end
        OPCODE_STORE: begin
            RegWrite = 1'b0; // Store instructions do not write back to the register file
            MemWrite = 1'b1; // Enable memory write for store instructions
            DataSel = 2'bxx;
            ALUop = ALUOP_FORCE_ADD; // Store instructions use ALU to calculate the address, which is essentially an addition
            ALUSrc = 1'b1; // Store instructions select immediate as the second ALU operand (offset)
        end
        OPCODE_BRANCH: begin
            ALUop = ALUOP_FORCE_SUB; // Branch instructions typically use the ALU to compare values, which can be implemented as a subtraction
            ALUSrc = 1'b0; // Branch instructions select register as the second ALU operand
            RegWrite = 1'b0; // Branch instructions do not write back to the register file
            DataSel = 2'bxx;
            Branch = 1'b1;
        end
        OPCODE_JAL: begin
            ALUop = 2'bxx; // Still need to test out this decision to have ALUop and ALUSrc be don't care for JAL
            ALUSrc = 1'bx;
            RegWrite = 1'b1; // JAL instructions write back to the register file
            DataSel = DATASEL_PC_PLUS_4; // JAL "links" the return address by writing back PC + 4 to the register file, thus the jump and link
            JALsel = 1'b1;
        end
        OPCODE_JALR: begin
            ALUop = ALUOP_FORCE_ADD; // JALR instructions use the ALU to calculate the target address, which is essentially an addition
            ALUSrc = 1'b1; // JALR instructions select immediate as the second ALU operand (offset)
            RegWrite = 1'b1; // JALR instructions write back to the register file
            DataSel = DATASEL_PC_PLUS_4; // JALR "links" the return address by writing back PC + 4 to the register file
            JALRsel = 1'b1;
        end
        OPCODE_LUI: begin
            // For LUI operation, we need to select LUI over AUIPC using LUIsel and then 
            // select the LUI/AUIPC datapath to send back to our register file
            ALUop = 2'bxx; // LUI operation does not use the ALU in a meaningful way, so we don't use ALUop or ALUSrc
            ALUSrc = 1'bx;
            LUIsel = 1'b1;
            RegWrite = 1'b1;
            DataSel = DATASEL_LUI_AUIPC;
        end
        OPCODE_AUIPC: begin
            // For AUIPC operation, we need to select AUIPC over LUI using LUIsel and then 
            // select the LUI/AUIPC datapath to send back to our register file
            ALUop = 2'bxx; // AUIPC operation does not use the ALU in a meaningful way, so we don't use ALUop or ALUSrc
            ALUSrc = 1'bx;
            LUIsel = 1'b0; // We're selecting AUIPC instead of LUI
            RegWrite = 1'b1;
            DataSel = DATASEL_LUI_AUIPC;
        end
        OPCODE_EBREAK: begin
            // Don't use ALUop or ALUSrc for EBREAK but leave as defaults for safety
            RegWrite = 1'b0; // EBREAK instructions do not write back to the register file
            DataSel = 2'bxx; // EBREAK does not write back to the register file
            JALsel = 1'b1; // We shall treat EBREAK as a special case that triggers a jump-like behavior, but with immediate as 0
                           // To do this, we treat EBREAK as an I-type for generating the immediate (using the func12 parameter), check format_gen.v 
                           // and trigger a jump with an offset of 0, effectively causing a trap for EBREAK, since we're executing the same
                           // instruction over and over again.
        end
        default: begin
            // Do nothing for now, but will trigger o_retire_trap
            // if incorrect opcode
        end
    endcase
end


endmodule