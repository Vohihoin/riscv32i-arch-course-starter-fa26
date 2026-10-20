module read_align (
    input  wire [1:0]  shift_amt_byte,
    input  wire [31:0] data_in,
    input  wire [2:0]  funct3,
    output wire  [31:0] data_out
);

    reg [31:0] data_out_reg;

    // Align the data based on the shift amount and the size of the data type
    wire [31:0] stage0_out, stage1_out, shifted;
    assign stage0_out = (shift_amt_byte[0]) ? {data_in >> 8} : data_in;
    assign stage1_out = (shift_amt_byte[1]) ? {stage0_out >> 16} : stage0_out;
    assign shifted = stage1_out;    

    // Determine the byte and half-word values for sign/zero extension
    wire [7:0]  curr_byte;
    assign curr_byte = shifted[7:0];
    wire [15:0] half_word;
    assign half_word = shifted[15:0];

    // Determine if the load is signed or unsigned based on funct3
    wire uns;
    assign uns = funct3[2];

    always @(*) begin
        case (funct3[1:0])
            // If unsigned, zero-extend; if signed, sign-extend
            2'b00:   data_out_reg = {{24{~uns & curr_byte[7]}},  curr_byte};   
            2'b01:   data_out_reg = {{16{~uns & half_word[15]}}, half_word};   
            2'b10:   data_out_reg = data_in;                   
            default: data_out_reg = 32'b0;
        endcase
    end

    // Assign the output
    assign data_out = data_out_reg;
endmodule