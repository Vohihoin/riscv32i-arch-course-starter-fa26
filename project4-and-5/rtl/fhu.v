module fhu(
    // Decode stage inputs
    input  wire [4:0] i_decode_rs1,
    input  wire [4:0] i_decode_rs2,
    input  wire ID_EX_MemRead,
    input  wire [4:0] ID_EX_rd,
    input wire [1:0] reg_read,
    input wire [4:0] ID_EX_rs1,
    input wire [4:0] ID_EX_rs2,
    input wire       ID_EX_RegWrite,

    // EX stage inputs

    // MEM stage inputs
    input  wire [4:0] EX_MEM_rd,
    input  wire EX_MEM_RegWrite,
    input wire       EX_MEM_RegWrite,
    input wire       EX_MEM_MemRead,
    input wire [4:0] EX_MEM_rd,

    // WB stage inputs

    output wire stall,
    
    input wire       MEM_WB_RegWrite,
    input wire [4:0] MEM_WB_rd,

    input wire decode_branch,
    input wire decode_JALR,

    // 2'b00: no forwarding, 2'b01: MEM to EX forwarding, 2'b10: EX to EX forwarding
    output wire [1:0] EX_Fwd_A,
    output wire [1:0] EX_Fwd_B,
    output wire       ID_Fwd_A,
    output wire       ID_Fwd_B
);

    // Hazard Detection Unit
    // Checks EX stage with the current decode stage for data hazards (Assuming forwarding)
    wire [4:0] rs1;
    wire [4:0] rs2;

    assign rs1 = i_decode_rs1;
    assign rs2 = i_decode_rs2;

    assign stall = ID_EX_MemRead && (ID_EX_rd != 5'd0) &&
               (((ID_EX_rd == rs1) && reg_read[0]) || ((ID_EX_rd == rs2) && reg_read[1]));

    wire stall_branches;
    assign stall_branches = (decode_branch | decode_JALR) && (
                                (reg_read[0] && (rs1 == ID_EX_rd)) ||
                                (reg_read[1] && (rs2 == ID_EX_rd)) ||
                                (reg_read[0] && (rs1 == EX_MEM_rd) && EX_MEM_MemRead) ||
                                (reg_read[1] && (rs2 == EX_MEM_rd) && EX_MEM_MemRead)
                            );

    assign ID_Fwd_a = (decode_branch | decode_JALR) && (EX_MEM_RegWrite && (rs1 == EX_MEM_rd));
    assign ID_Fwd_b = (decode_branch | decode_JALR) && (EX_MEM_RegWrite && (rs2 == EX_MEM_rd));


    // Forwarding logic
    assign EX_Fwd_a = {
        EX_MEM_RegWrite && (EX_MEM_rd != 5'd0) && (EX_MEM_rd == ID_EX_rs1),        // EX to EX forwarding for rs1
        MEM_WB_RegWrite && (MEM_WB_rd != 5'd0) && (MEM_WB_rd == ID_EX_rs1)         // MEM to EX forwarding for rs1
    };

    assign EX_Fwd_b = {
        EX_MEM_RegWrite && (EX_MEM_rd != 5'd0) && (EX_MEM_rd == ID_EX_rs2),        // EX to EX forwarding for rs2
        MEM_WB_RegWrite && (MEM_WB_rd != 5'd0) && (MEM_WB_rd == ID_EX_rs2)         // MEM to EX forwarding for rs2
    };

endmodule