module align(
    input wire [31:0] addr,
    input wire [31:0] data_in,
    input wire [2:0] funct3,
    output wire [31:0] masked_addr,
    output wire [3:0] byte_mask,
    output wire [1:0] shift_amt_byte,
    output wire [31:0] data_out,
    output reg retire_trap_unaligned_address
);
    reg [3:0] byte_mask_reg;
    reg [1:0] shift_amt_byte_reg;

    // LOAD Address Alignment -------------------------------------------------
    // Mask the last two bits of the address
    assign masked_addr = {addr[31:2], 2'b00};

    // for word funct3 = 3'b010, byte_mask = 4'b1111
    // for halfword funct3 = 3'b001, byte_mask = 4'b0011 or 4'b1100 based on addr[1]
    // for byte funct3 = 3'b000, byte_mask = 4'b0001

    // funct3[2] = 0 => signed, funct3[2] = 1 => unsigned

    // Signed unsigned is not relevant for byte_mask generation, only for data_out generation
    // hence we can ignore funct3[2] for byte_mask generation

    // Generate the byte mask based on funct3 and the last two bits of the address

    // Shift Logic for Byte
    wire [3:0] base_byte_mask;
    assign base_byte_mask = 4'b0001; // Base mask for a single byte

    wire [3:0] stage0_byte, stage1_byte, shifted_byte;
    assign stage0_byte = (addr[0]) ? {base_byte_mask << 1} : base_byte_mask;
    assign stage1_byte = (addr[1]) ? {stage0_byte << 2} : stage0_byte;
    assign shifted_byte = stage1_byte;

    // Shift logic for Halfword
    wire [3:0] base_halfword_mask;
    assign base_halfword_mask = 4'b0011; // Base mask for a halfword

    wire [3:0] stage1_halfword, shifted_halfword;
    assign stage1_halfword = (addr[1]) ? {base_halfword_mask << 2} : base_halfword_mask;
    assign shifted_halfword = stage1_halfword;


    always @(*) begin
        case (funct3[1:0])
            2'b00: byte_mask_reg = shifted_byte;                     // byte
            2'b01: byte_mask_reg = shifted_halfword;                 // halfword
            2'b10: byte_mask_reg = 4'b1111;                         // word
            default: byte_mask_reg = 4'b0000;                       // invalid
        endcase
    end

    // Generate the shift amount based on the last two bits of the address & size of the data type
    always @(*) begin
        case (funct3[1:0])
            2'b00: shift_amt_byte_reg = addr[1:0];                       // byte
            2'b01: shift_amt_byte_reg = {addr[1], 1'b0};                 // halfword
            2'b10: shift_amt_byte_reg = 2'b00;                           // word
            default: shift_amt_byte_reg = 2'b00;                         // invalid
        endcase
    end

    // Logic for determining unaligned address

    always @(*) begin
        case (funct3[1:0])
        2'b01: begin // half-word
            retire_trap_unaligned_address = addr[0];
        end
        2'b10: begin // full-word
            retire_trap_unaligned_address = (addr[1:0] != 2'b00);
        end
        default: begin
            retire_trap_unaligned_address = 1'b0;
        end
        endcase
    end


    // Store Data Alignment -------------------------------------------------
    // Align the data based on the shift amount and the size of the data type
    wire [31:0] stage0_out;
    assign stage0_out = (shift_amt_byte_reg[0]) ? {data_in << 8} : data_in;
    wire [31:0] stage1_out;
    assign stage1_out = (shift_amt_byte_reg[1]) ? {stage0_out << 16} : stage0_out;

    wire [31:0] shifted_data;
    assign shifted_data = stage1_out;

    // Assign the outputs
    assign byte_mask = byte_mask_reg;
    assign shift_amt_byte = shift_amt_byte_reg;
    assign data_out = shifted_data;


endmodule