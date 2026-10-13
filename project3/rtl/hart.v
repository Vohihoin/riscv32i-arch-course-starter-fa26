module hart #(
    // After reset, the program counter (PC) should be initialized to this
    // address and start executing instructions from there.
    parameter RESET_ADDR = 32'h00000000
) (
    // Global clock.
    input  wire        i_clk,
    // Synchronous active-high reset.
    input  wire        i_rst,
    // Instruction fetch goes through a read only instruction memory (imem)
    // port. The port accepts a 32-bit address (e.g. from the program counter)
    // per cycle and combinationally returns a 32-bit instruction word. This
    // is not representative of a realistic memory interface; it has been
    // modeled as more similar to a DFF or SRAM to simplify phase 3. In
    // later phases, you will replace this with a more realistic memory.
    //
    // 32-bit read address for the instruction memory. This is expected to be
    // 4 byte aligned - that is, the two LSBs should be zero.
    output wire [31:0] o_imem_raddr,
    // Instruction word fetched from memory, available on the same cycle.
    input  wire [31:0] i_imem_rdata,
    // Data memory accesses go through a separate read/write data memory (dmem)
    // that is shared between read (load) and write (stored). The port accepts
    // a 32-bit address, read or write enable, and mask (explained below) each
    // cycle. Reads are combinational - values are available immediately after
    // updating the address and asserting read enable. Writes occur on (and
    // are visible at) the next clock edge.
    //
    // Read/write address for the data memory. This should be 32-bit aligned
    // (i.e. the two LSB should be zero). See `o_dmem_mask` for how to perform
    // half-word and byte accesses at unaligned addresses.
    output wire [31:0] o_dmem_addr,
    // When asserted, the memory will perform a read at the aligned address
    // specified by `i_addr` and return the 32-bit word at that address
    // immediately (i.e. combinationally). It is illegal to assert this and
    // `o_dmem_wen` on the same cycle.
    output wire        o_dmem_ren,
    // When asserted, the memory will perform a write to the aligned address
    // `o_dmem_addr`. When asserted, the memory will write the bytes in
    // `o_dmem_wdata` (specified by the mask) to memory at the specified
    // address on the next rising clock edge. It is illegal to assert this and
    // `o_dmem_ren` on the same cycle.
    output wire        o_dmem_wen,
    // The 32-bit word to write to memory when `o_dmem_wen` is asserted. When
    // write enable is asserted, the byte lanes specified by the mask will be
    // written to the memory word at the aligned address at the next rising
    // clock edge. The other byte lanes of the word will be unaffected.
    output wire [31:0] o_dmem_wdata,
    // The dmem interface expects word (32 bit) aligned addresses. However,
    // the processor supports byte and half-word loads and stores at unaligned and
    // 16-bit aligned addresses, respectively. To support this, the access
    // mask specifies which bytes within the 32-bit word are actually read
    // from or written to memory.
    //
    // To perform a half-word read at address 0x00001002, align `o_dmem_addr`
    // to 0x00001000, assert `o_dmem_ren`, and set the mask to 0b1100 to
    // indicate that only the upper two bytes should be read. Only the upper
    // two bytes of `i_dmem_rdata` can be assumed to have valid data; to
    // calculate the final value of the `lh[u]` instruction, shift the rdata
    // word right by 16 bits and sign/zero extend as appropriate.
    //
    // To perform a byte write at address 0x00002003, align `o_dmem_addr` to
    // `0x00002000`, assert `o_dmem_wen`, and set the mask to 0b1000 to
    // indicate that only the upper byte should be written. On the next clock
    // cycle, the upper byte of `o_dmem_wdata` will be written to memory, with
    // the other three bytes of the aligned word unaffected. Remember to shift
    // the value of the `sb` instruction left by 24 bits to place it in the
    // appropriate byte lane.
    output wire [ 3:0] o_dmem_mask,
    // The 32-bit word read from data memory. When `o_dmem_ren` is asserted,
    // this will immediately reflect the contents of memory at the specified
    // address, for the bytes enabled by the mask. When read enable is not
    // asserted, or for bytes not set in the mask, the value is undefined.
    input  wire [31:0] i_dmem_rdata,
	// The output `retire` interface is used to signal to the testbench that
    // the CPU has completed and retired an instruction. A single cycle
    // implementation will assert this every cycle; however, a pipelined
    // implementation that needs to stall (due to internal hazards or waiting
    // on memory accesses) will not assert the signal on cycles where the
    // instruction in the writeback stage is not retiring.
    //
    // Asserted when an instruction is being retired this cycle. If this is
    // not asserted, the other retire signals are ignored and may be left invalid.
    output wire        o_retire_valid,
    // The 32 bit instruction word of the instrution being retired. This
    // should be the unmodified instruction word fetched from instruction
    // memory.
    output wire [31:0] o_retire_inst,
    // Asserted if the instruction produced a trap, due to an illegal
    // instruction, unaligned data memory access, or unaligned instruction
    // address on a taken branch or jump.
    output wire        o_retire_trap,
    // Asserted if the instruction is an `ebreak` instruction used to halt the
    // processor. This is used for debugging and testing purposes to end
    // a program.
    output wire        o_retire_halt,
    // The first register address read by the instruction being retired. If
    // the instruction does not read from a register (like `lui`), this is
    // don't-care -- the grading testbench doesn't look at it in that case.
    output wire [ 4:0] o_retire_rs1_raddr,
    // The second register address read by the instruction being retired. If
    // the instruction does not read from a second register (like `addi`),
    // this is don't-care -- the grading testbench doesn't look at it in that
    // case.
    output wire [ 4:0] o_retire_rs2_raddr,
    // The first source register data read from the register file (in the
    // decode stage) for the instruction being retired. If rs1 is 5'd0, this
    // should also be 32'd0.
    output wire [31:0] o_retire_rs1_rdata,
    // The second source register data read from the register file (in the
    // decode stage) for the instruction being retired. If rs2 is 5'd0, this
    // should also be 32'd0.
    output wire [31:0] o_retire_rs2_rdata,
    // The destination register address written by the instruction being
    // retired. If the instruction does not write to a register (like `sw`),
    // this should be 5'd0.
    output wire [ 4:0] o_retire_rd_waddr,
    // The destination register data written to the register file in the
    // writeback stage by this instruction. If rd is 5'd0, this field is
    // ignored and can be treated as a don't care.
    output wire [31:0] o_retire_rd_wdata,
    // The current program counter of the instruction being retired - i.e.
    // the instruction memory address that the instruction was fetched from.
    output wire [31:0] o_retire_pc,
    // the next program counter after the instruction is retired. For most
    // instructions, this is `o_retire_pc + 4`, but must be the branch or jump
    // target for *taken* branches and jumps.
    output wire [31:0] o_retire_next_pc

`ifdef RISCV_FORMAL
    ,`RVFI_OUTPUTS,
`endif
);
    // Fill in your implementation here.

// Fill in your implementation here.

// PC counter
reg [31:0] pc;
wire [31:0] next_pc;

always @(posedge i_clk) begin
    if (i_rst) begin
        pc <= RESET_ADDR;
    end else begin
        pc <= next_pc;
    end
end

assign o_imem_raddr = pc; 

// ======================================================
// Instruction Slicing (Notice the 'wire' keyword!)
// ======================================================
wire [4:0] read_rs1     = i_imem_rdata[19:15];
wire [4:0] read_rs2     = i_imem_rdata[24:20];
wire [4:0] rf_write_reg = i_imem_rdata[11:7];

wire [2:0] i_funct3      = i_imem_rdata[14:12];
wire [6:0] i_funct7      = i_imem_rdata[31:25];
wire       i_alu_mux_sel = i_imem_rdata[14];

// ======================================================
// Control Unit
// ======================================================
wire JALRsel;
wire LUIsel;
wire JALsel;
wire Branch;
wire MemRead;
wire [1:0] DataSel;
wire ALUop;
wire memWrite;
wire ALUSrc;
wire RegWrite;

control_unit (.i_opcode(i_imem_rdata),
              .JALRsel(JALRsel),
              .LUIsel(LUIsel),
              .JALsel(JALsel),
              .Branch(Branch),
              .MemRead(MemRead),
              .DataSel(DataSel),
              .ALUop(ALUop),
              .memWrite(memWrite),
              .ALUSrc(ALUSrc),
              .RegWrite(RegWrite)
             );

// ======================================================
// Register File
// ======================================================
wire [31:0] o_rf_read_1;
wire [31:0] o_rf_read_2;
wire [31:0] rf_write_data;

rf #(.BYPASS_EN(0))
    register_file (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_rs1_raddr(read_rs1),
        .i_rs2_raddr(read_rs2),
        .o_rs1_rdata(o_rf_read_1),
        .o_rs2_rdata(o_rf_read_2),
        .i_rd_wdata(rf_write_data),
        .i_rd_waddr(rf_write_reg),
        .i_rd_wen(RegWrite)
    );

// ======================================================
// Format & Immediate Generation
// ======================================================
wire [6:0] format_gen_input = i_imem_rdata[6:0];
wire [2:0] o_format; // Kept as 3 bits, standard for format gen

format_gen (.opcode(format_gen_input),
            .format(o_format)
           );

wire [31:0] o_imm;
imm (.i_inst(i_imem_rdata),
     .o_immediate(o_imm),
     .i_format(o_format)
    );

// ======================================================
// ALU & ALU Control
// ======================================================
wire sub;
wire o_unsigned;
wire arith;
wire [2:0] op_sel; // Ensure this width matches what your ALU needs!

alu_control (.aluop(ALUop),
             .funct7(i_funct7),
             .funct3(i_funct3),
             .o_sub(sub),
             .o_unsigned(o_unsigned),
             .o_arith(arith),
             .op_sel(op_sel)
            );

//op2 mux
wire [31:0] op2 = ALUSrc ? o_imm : o_rf_read_2;

// ALU file instantiate
wire [31:0] o_alu_result;
wire eq;
wire slt;

alu (.i_op1(o_rf_read_1),
     .i_op2(op2),
     .i_sub(sub),
     .i_unsigned(o_unsigned),
     .i_arith(arith),
     .i_op_sel(op_sel),
     .o_result(o_alu_result),
     .o_eq(eq),
     .o_slt(slt)
    );

// ======================================================
// Branch Evaluation Logic
// ======================================================
wire o_eq_slt_mux = i_alu_mux_sel ? slt : eq;
wire o_xor = o_eq_slt_mux ^ i_imem_rdata[12];
wire o_branch_and = o_xor & Branch;
wire jalsel_or = JALsel | o_branch_and;

// =======================================
// PC Datapaths (JAL, JALR, Branch Target)
// ==========================================
wire [31:0] o_result_and = o_alu_result & ~32'd1; // JALR mask
wire [31:0] incre_pc = pc + 32'd4;
wire [31:0] imm_adder = pc + o_imm;

wire [31:0] jal_mux = jalsel_or ? imm_adder : incre_pc;
assign next_pc = JALRsel ? o_result_and : jal_mux;  

// ======================================================
// Memory & Writeback
// ======================================================
wire [31:0] lui_mux = LUIsel ? o_imm : incre_pc;

wire [1:0] o_shift_amt_byte; 
align (.addr(o_alu_result),
       .data_in(o_rf_read_2),
       .func3(i_funct3),
       .masked_addr(o_dmem_addr),
       .byte_mask(o_dmem_mask),
       .data_out(o_dmem_wdata),
       .shift_amt_byte(o_shift_amt_byte)
      );

assign o_dmem_ren = MemRead;
assign o_dmem_wen = memWrite;

wire [31:0] o_read_align_data;
read_align(.shift_amt_byte(o_shift_amt_byte),
           .data_in(i_dmem_rdata),
           .func3(i_funct3),
           .data_out(o_read_align_data)
          );

// Final Writeback 4-to-1 Mux
assign rf_write_data = (DataSel == 2'b00) ? o_alu_result :
                       (DataSel == 2'b01) ? o_read_align_data :
                       (DataSel == 2'b10) ? lui_mux :
                       (DataSel == 2'b11) ? incre_pc : 32'd0;

// ======================================================
// Retire Interface (Testbench Hooks)
// ======================================================
assign o_retire_valid     = 1'b1; 
assign o_retire_inst      = i_imem_rdata; 
assign o_retire_pc        = pc;
assign o_retire_next_pc   = next_pc;

assign o_retire_halt      = (i_imem_rdata == 32'h00100073); 
assign o_retire_trap      = 1'b0; 

assign o_retire_rs1_raddr = read_rs1;
assign o_retire_rs2_raddr = read_rs2;
assign o_retire_rs1_rdata = o_rf_read_1;
assign o_retire_rs2_rdata = o_rf_read_2;

assign o_retire_rd_waddr  = RegWrite ? rf_write_reg : 5'd0;
assign o_retire_rd_wdata  = rf_write_data;

endmodule

`default_nettype wire
