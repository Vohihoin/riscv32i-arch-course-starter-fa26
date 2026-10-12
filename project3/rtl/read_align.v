module read_align (
    input  wire [1:0]  shift_amt_byte,
    input  wire [31:0] data_in,
    input  wire [2:0]  funct3,
    output wire  [31:0] data_out
);

    reg [31:0] data_out_reg;

    // Align the data based on the shift amount and the size of the data type
    wire [31:0] shifted = data_in >> {shift_amt_byte, 3'b0};

    // Determine the byte and half-word values for sign/zero extension
    wire [7:0]  byte = shifted[7:0];
    wire [15:0] half_word = shifted[15:0];

    // Determine if the load is signed or unsigned based on funct3
    wire uns = funct3[2];

    always @(*) begin
        case (funct3[1:0])
            // If unsigned, zero-extend; if signed, sign-extend
            2'b00:   data_out_reg = {{24{~uns & byte[7]}},  byte};   
            2'b01:   data_out_reg = {{16{~uns & half_word[15]}}, half_word};   
            2'b10:   data_out_reg = data_in;                   
            default: data_out_reg = 32'b0;
        endcase
    end

    // Assign the output
    assign data_out = data_out_reg;
endmodule