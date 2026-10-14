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

    // Stage-to-Stage Interconnect Wires
    wire [31:0] pc, incre_pc, next_pc;
    wire [4:0]  read_rs1, read_rs2, rf_write_reg;
    wire [31:0] o_rf_read_1, o_rf_read_2, rf_write_data, o_imm;
    wire [2:0]  i_funct3;
    wire [6:0]  i_funct7;
    wire        i_alu_mux_sel, inst_bit12;

    // Control Wires
    wire        EBREAKsel,JALRsel, LUIsel, JALsel, Branch, MemRead, memWrite, ALUSrc, RegWrite;
    wire [1:0]  ALUop;
    wire [1:0]  DataSel;

    // Execute & Memory Wires
    wire [31:0] o_alu_result, o_result_and, imm_adder, lui_mux, o_read_align_data;
    wire        jalsel_or;

    wire retire_trap_unaligned_address;
    wire retire_trap_illegal_instruction;
    wire retire_trap_unaligned_instruction_address;
    wire o_load_store_active;

    // 1. FETCH STAGE
    fetch #(
        .RESET_ADDR(RESET_ADDR)
    ) u_fetch (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_jalr_sel(JALRsel),
        .i_jalsel_or(jalsel_or),
        .i_imm_adder(imm_adder),
        .i_result_and(o_result_and),
        .i_EBREAKsel(EBREAKsel),
        .o_pc(pc),
        .o_incre_pc(incre_pc),
        .o_next_pc(next_pc),
        .o_imem_raddr(o_imem_raddr),
        .o_trap_unaligned_instruction_address(retire_trap_unaligned_instruction_address)
    );

    // 2. DECODE STAGE
    decode u_decode (
        .i_clk(i_clk),
        .i_rst(i_rst),
        .i_inst(i_imem_rdata),
        .i_wb_rd_addr(rf_write_reg),
        .i_wb_rd_data(rf_write_data),
        .i_wb_reg_write(RegWrite),
        .o_rs1_addr(read_rs1),
        .o_rs2_addr(read_rs2),
        .o_rd_addr(rf_write_reg),
        .o_rf_read_1(o_rf_read_1),
        .o_rf_read_2(o_rf_read_2),
        .o_imm(o_imm),
        .o_funct3(i_funct3),
        .o_funct7(i_funct7),
        .o_alu_mux_sel(i_alu_mux_sel),
        .o_inst_bit12(inst_bit12),
        .o_JALRsel(JALRsel),
        .o_LUIsel(LUIsel),
        .o_JALsel(JALsel),
        .o_Branch(Branch),
        .o_MemRead(MemRead),
        .o_DataSel(DataSel),
        .o_ALUop(ALUop),
        .o_memWrite(memWrite),
        .o_ALUSrc(ALUSrc),
        .o_RegWrite(RegWrite),
        .retire_trap_illegal_instruction(retire_trap_illegal_instruction),
        .o_load_store_active(o_load_store_active),
        .o_EBREAKsel(EBREAKsel)
    );

    // 3. EXECUTE STAGE
    execute u_execute (
        .i_pc(pc),
        .i_incre_pc(incre_pc),
        .i_rf_read_1(o_rf_read_1),
        .i_rf_read_2(o_rf_read_2),
        .i_imm(o_imm),
        .i_funct3(i_funct3),
        .i_funct7(i_funct7),
        .i_alu_mux_sel(i_alu_mux_sel),
        .i_inst_bit12(inst_bit12),
        .i_ALUop(ALUop),
        .i_ALUSrc(ALUSrc),
        .i_Branch(Branch),
        .i_JALsel(JALsel),
        .i_LUIsel(LUIsel),
        .o_alu_result(o_alu_result),
        .o_result_and(o_result_and),
        .o_imm_adder(imm_adder),
        .o_jalsel_or(jalsel_or),
        .o_lui_mux(lui_mux)
    );

    // 4. MEMORY STAGE
    memory u_memory (
        .i_alu_result(o_alu_result),
        .i_rf_read_2(o_rf_read_2),
        .i_funct3(i_funct3),
        .i_MemRead(MemRead),
        .i_memWrite(memWrite),
        .i_dmem_rdata(i_dmem_rdata),
        .i_load_store_active(o_load_store_active),
        .o_dmem_addr(o_dmem_addr),
        .o_dmem_ren(o_dmem_ren),
        .o_dmem_wen(o_dmem_wen),
        .o_dmem_wdata(o_dmem_wdata),
        .o_dmem_mask(o_dmem_mask),
        .o_read_align_data(o_read_align_data),
        .retire_trap_unaligned_address(retire_trap_unaligned_address)
    );

    // 5. WRITEBACK STAGE
    writeback u_writeback (
        .i_DataSel(DataSel),
        .i_alu_result(o_alu_result),
        .i_read_align_data(o_read_align_data),
        .i_lui_mux(lui_mux),
        .i_incre_pc(incre_pc),
        .o_rf_write_data(rf_write_data)
    );

    // ======================================================
    // Retire Interface (Testbench Hooks)
    // ======================================================
    assign o_retire_valid     = 1'b1; 
    assign o_retire_inst      = i_imem_rdata; 
    assign o_retire_pc        = pc;
    assign o_retire_next_pc   = next_pc;

    assign o_retire_halt      = (i_imem_rdata == 32'h00100073); 
    assign o_retire_trap      = retire_trap_unaligned_address || retire_trap_illegal_instruction || retire_trap_unaligned_instruction_address; 

    assign o_retire_rs1_raddr = read_rs1;
    assign o_retire_rs2_raddr = read_rs2;
    assign o_retire_rs1_rdata = o_rf_read_1;
    assign o_retire_rs2_rdata = o_rf_read_2;

    assign o_retire_rd_waddr  = RegWrite ? rf_write_reg : 5'd0;
    assign o_retire_rd_wdata  = rf_write_data;

endmodule

`default_nettype wire
