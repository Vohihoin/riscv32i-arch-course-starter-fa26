module hazard_detection_unit(
    input  wire [4:0] i_decode_rs1,
    input  wire [4:0] i_decode_rs2,
    input  wire ID_EX_MemRead,
    input  wire [4:0] ID_EX_rd,
    input  wire [4:0] EX_MEM_rd,
    input  wire EX_MEM_RegWrite,
    input wire [1:0] reg_read,
    output wire stall,

    input wire [4:0] ID_EX_rs1,
    input wire [4:0] ID_EX_rs2,
    input wire MEM_WB_RegWrite,
    input wire [4:0] MEM_WB_rd,

    // 2'b00: no forwarding, 2'b01: MEM to EX forwarding, 2'b10: EX to EX forwarding
    output wire [1:0] Fwd_a,
    output wire [1:0] Fwd_b
);

    // Hazard Detection Unit
    // Checks EX stage with the current decode stage for data hazards (Assuming forwarding)
    wire [4:0] rs1;
    wire [4:0] rs2;

    assign rs1 = i_decode_rs1;
    assign rs2 = i_decode_rs2;

    assign stall = ID_EX_MemRead && (ID_EX_rd != 5'd0) &&
               (((ID_EX_rd == rs1) && reg_read[0]) || ((ID_EX_rd == rs2) && reg_read[1]));

    // Forwarding logic
    assign Fwd_a = {
        EX_MEM_RegWrite && (EX_MEM_rd != 5'd0) && (EX_MEM_rd == ID_EX_rs1),        // EX to EX forwarding for rs1
        MEM_WB_RegWrite && (MEM_WB_rd != 5'd0) && (MEM_WB_rd == ID_EX_rs1)         // MEM to EX forwarding for rs1
    };

    assign Fwd_b = {
        EX_MEM_RegWrite && (EX_MEM_rd != 5'd0) && (EX_MEM_rd == ID_EX_rs2),        // EX to EX forwarding for rs2
        MEM_WB_RegWrite && (MEM_WB_rd != 5'd0) && (MEM_WB_rd == ID_EX_rs2)         // MEM to EX forwarding for rs2
    };

endmodule