module align(
    input wire [31:0] addr,
    input wire [31:0] data_in,
    input wire [2:0] funct3,
    output wire [31:0] masked_addr,
    output wire [3:0] byte_mask,
    output wire [1:0] shift_amt_byte,
    output wire [31:0] data_out
);
    reg [3:0] byte_mask_reg;
    reg [1:0] shift_amt_byte_reg;
    reg [31:0] data_out_reg;

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
    always @(*) begin
        case (funct3[1:0])
            2'b00: byte_mask_reg = 4'b0001 << addr[1:0];            // byte
            2'b01: byte_mask_reg = 4'b0011 << {addr[1], 1'b0};      // halfword
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


    // Store Data Alignment -------------------------------------------------
    wire [5:0] shift_amt_bit = {shift_amt_byte, 3'b0}; // shift amount in bits

    // Align the data based on the shift amount and the size of the data type
    always @(*) begin
        case (funct3[1:0])
            2'b00: data_out_reg = data_in << (shift_amt_bit); // byte
            2'b01: data_out_reg = data_in << (shift_amt_bit); // half-word
            2'b10: data_out_reg = data_in; // word, no shift needed
            default: data_out_reg = 32'b0; // invalid
        endcase
    end

    // Assign the outputs
    assign byte_mask = byte_mask_reg;
    assign shift_amt_byte = shift_amt_byte_reg;
    assign data_out = data_out_reg;


endmodule