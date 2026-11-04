module compare(
    input  wire [31:0] i_rs1,
    input  wire [31:0] i_rs2,
    input  wire  i_unsigned,
    output wire        o_eq,
    output wire        o_slt
);

    reg o_eq_temp;
    reg o_slt_temp;

    assign o_eq  = o_eq_temp;
    assign o_slt = o_slt_temp;

    // Always block to implement equality comparison
    always @(*) begin
        o_eq_temp = (i_rs1 == i_rs2) ? 1'b1 : 1'b0;
    end
    
    // Always block to implement set less than and o_slt_temp
    always @(*) begin
        case (i_unsigned)
            1'b0: begin
                // If they have different signs, the negative one is less; otherwise, if they have the same sign,
                // we can compare their magnitudes and our regular comparism will work correctly.
                o_slt_temp = (i_rs1[31] != i_rs2[31]) ? ( (i_rs1[31] == 1'b1) ? 1'b1 : 1'b0 ) : ( (i_rs1 < i_rs2) ? 1'b1 : 1'b0 );
            end
            1'b1: begin
                // For unsigned comparison, we can directly compare the magnitudes.
                o_slt_temp = (i_rs1 < i_rs2) ? 1'b1 : 1'b0;
            end
        endcase
    end

endmodule