`default_nettype none

// Data Memory Traffic Controller
module dmtc(
    input i_clk,
    input i_rst,
    input wire EX_MEM_wen,
    input wire EX_MEM_ren,
    input wire dmem_ready,
    input wire dmem_valid,
    output reg stall,
    output reg ren_actual,
    output reg wen_actual
);

    reg state, next_state;

    localparam CHILLIN = 1'b0;
    localparam READ_DATA = 1'b1;

    always @(posedge i_clk) begin
        if (i_rst)
            state <= CHILLIN;
        else
            state <= next_state;
    end

    always @(*) begin

        stall = 1'b0;
        ren_actual = 1'b0;
        wen_actual = 1'b0;
        next_state = state;

        case (state)
            CHILLIN: begin
                casez({EX_MEM_wen, EX_MEM_ren, dmem_ready})
                    3'b00?: begin
                        next_state = CHILLIN;
                    end
                    3'b010: begin 
                        next_state = CHILLIN;
                        stall = 1'b1;
                    end
                    3'b100: begin 
                        next_state = CHILLIN;
                        stall = 1'b1;
                    end
                    3'b110: begin 
                        next_state = CHILLIN;
                        stall = 1'b1;
                    end
                    3'b101: begin
                        next_state = CHILLIN;
                        wen_actual = 1'b1;
                    end
                    3'b?11: begin
                        next_state = READ_DATA;
                        stall = 1'b1;
                        ren_actual = 1'b1;
                    end
                endcase
            end
            READ_DATA: begin
                case (dmem_valid)
                    1'b0: begin
                        stall = 1'b1;
                        next_state = READ_DATA;
                    end
                    1'b1: begin
                        next_state = CHILLIN;
                    end
                endcase
            end
        endcase
    end

endmodule

`default_nettype wire