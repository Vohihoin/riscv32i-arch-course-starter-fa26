module decode(
    input i_clk,
    input i_rst, 

    // Data Signals
    input [31:0] instruction,
    input [31:0] input_PC,
    output [31:0] output_PC,
    input i_flush,
    input ID_FwdA,
    input ID_FwdB,
    output o_flush,
    
    output [4:0] IF_ID_rs1_addr,
    output [4:0] IF_ID_rs2_addr,
    output [4:0] IF_ID_rd,
    output [2:0] funct3,
    output [6:0] funct7,
    output [31:0] read_data_1,
    output [31:0] read_data_2,
    output [31:0] o_immediate,

    // From Writeback
    input reg_writeback,
    input [31:0] write_data,
    input [4:0] write_register,

    // Control Signals Output from our decode module
    output JALRsel,
    output LUIsel,
    output JALsel,
    output Branch,
    output MemRead,
    output [1:0] DataSel,
    output [1:0] ALUop,
    output MemWrite,
    output ALUSrc,
    output RegWrite,
    output retire_trap_illegal_instruction,
    output load_store_active,
    output [1:0] reg_read,
    output [4:0] ID_EX_rs1,
    output [4:0] ID_EX_rs2,

    output pc_imm_sel,
    output [31:0] o_branch_address

);


    control iCTRL(
        .instruction(instruction),
        .JALRsel(JALRsel),
        .LUIsel(LUIsel),
        .JALsel(JALsel),
        .Branch(Branch),
        .MemRead(MemRead),
        .DataSel(DataSel),
        .ALUop(ALUop),
        .MemWrite(MemWrite),
        .ALUSrc(ALUSrc),
        .RegWrite(RegWrite),
        .retire_trap_illegal_instruction(retire_trap_illegal_instruction),
        .load_store_active(load_store_active),
        .reg_read(reg_read)
    );

    rf #(.BYPASS_EN(1)) register_file (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_rs1_raddr(IF_ID_rs1_addr),
        .i_rs2_raddr(IF_ID_rs2_addr),
        .o_rs1_rdata(read_data_1),
        .o_rs2_rdata(read_data_2),
        .i_rd_wdata(write_data),
        .i_rd_waddr(write_register),
        .i_rd_wen(reg_writeback)
    );
    
    // funct3 and funct7 to pass on to the next stage
    assign funct3 = instruction[14:12];
    assign funct7 = instruction[31:25];

    wire [5:0] format;

    format_gen iFMT(
        .opcode(instruction[6:0]),
        .format(format)
    );

    imm iIMM(
        .i_inst(instruction),
        .i_format(format),
        .o_immediate(o_immediate)
    );

    wire o_eq, o_slt;
    wire mux_rs1, mux_rs2;
    assign mux_rs1 = ID_FwdA ? read_data_2 : read_data_1;
    assign mux_rs2 = ID_FwdB ? read_data_2 : read_data_1

    compare iCMPR(
        .i_rs1(mux_rs1),
        .i_rs2(mux_rs2),
        .i_unsigned(funct3[1]),
        .o_eq(o_eq),
        .o_slt(o_slt)
    );

    // checking if the branch condition is satisfied
    wire branch_resolved; 
    assign branch_resolved = (funct3[0] ^ (funct3[2] ? o_slt : o_eq));

    assign pc_imm_sel = JALRsel || JALsel || (Branch && branch_resolved);

    // pc_target calculation
    wire [31:0] pc_add, pc_target, add_src;

    assign add_src = (JALRsel) ? read_data_1 : input_PC;

    assign pc_add = o_immediate + add_src;
    assign pc_target = (JALRsel) ? (pc_add & ~32'b1) : pc_add;    

    // Output Signals
    assign output_PC = input_PC;
    assign o_branch_address = pc_target;
    assign o_flush = i_flush;

    // Output for the Hazard Detection Unit
    assign IF_ID_rd = instruction[11:7];
    assign IF_ID_rs1_addr = instruction[19:15];
    assign IF_ID_rs2_addr = instruction[24:20];
    assign ID_EX_rs1 = instruction[19:15];
    assign ID_EX_rs2 = instruction[24:20];


endmodule