module hazard_detection_unit(
input  wire [31:0] i_mem_rdata,
input  wire ID_EX_RegWrite,
input  wire [4:0] ID_EX_rd,
input  wire [4:0] EX_MEM_rd,
input  wire EX_MEM_RegWrite,
output wire stall
)

    wire [4:0] rs1 = i_mem_rdata[19:15];
    wire [4:0] rs2 = i_mem_rdata[24:20];



    assign stall = (ID_EX_RegWrite && (ID_EX_rd != 5'd0) && ((ID_EX_rd == rs1) || (ID_EX_rd == rs2))) || (EX_MEM_RegWrite && (EX_MEM_rd != 5'd0) && ((EX_MEM_rd == rs1) || (EX_MEM_rd == rs2)));
    


endmodule