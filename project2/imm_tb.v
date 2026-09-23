module imm_tb();

    reg [31:0] i_inst;
    reg [5:0] i_format;
    wire [31:0] o_immediate;

    localparam [5:0] R_TYPE = (1 << 0);
    localparam [5:0] I_TYPE = (1 << 1);
    localparam [5:0] S_TYPE = (1 << 2);
    localparam [5:0] B_TYPE = (1 << 3);
    localparam [5:0] U_TYPE = (1 << 4);
    localparam [5:0] J_TYPE = (1 << 5);


    imm iDUT(.i_inst(i_inst), .i_format(i_format), .o_immediate(o_immediate));
    
    initial begin

        // TEST 1
        i_inst = 32'hABCDDCBA;
        i_format = I_TYPE; #5;

        if (o_immediate != {{21{i_inst[31]}}, i_inst[30:25], i_inst[24:20]}) begin
            $display("Wrong Immediate for I_TYPE, expected: %h, got: %h", {{21{i_inst[31]}}, i_inst[30:25], i_inst[24:20]}, o_immediate);
            $stop();
        end

        // TEST 2
        i_inst = 32'h39821786;
        i_format = I_TYPE; #5;

        if (o_immediate != {{21{i_inst[31]}}, i_inst[30:25], i_inst[24:20]}) begin
            $display("Wrong Immediate for I_TYPE, expected: %h, got: %h", {{21{i_inst[31]}}, i_inst[30:25], i_inst[24:20]}, o_immediate);
            $stop();
        end

        // TEST 3
        i_inst = 32'hCD431285;
        i_format = S_TYPE; #5;

        if (o_immediate != {{21{i_inst[31]}}, i_inst[30:25], i_inst[11:7]}) begin
            $display("Wrong Immediate for S_TYPE, expected: %h, got: %h", {{21{i_inst[31]}}, i_inst[30:25], i_inst[11:7]}, o_immediate);
            $stop();
        end

        // TEST 4
        i_inst = 32'h39821786;
        i_format = S_TYPE; #5;

        if (o_immediate != {{21{i_inst[31]}}, i_inst[30:25], i_inst[11:7]}) begin
            $display("Wrong Immediate for S_TYPE, expected: %h, got: %h", {{21{i_inst[31]}}, i_inst[30:25], i_inst[11:7]}, o_immediate);
            $stop();
        end

        // TEST 5
        i_inst = 32'h35107DCF;
        i_format = B_TYPE; #5;

        if (o_immediate != {{20{i_inst[31]}}, i_inst[7], i_inst[30:25], i_inst[11:8], 1'b0}) begin
            $display("Wrong Immediate for B_TYPE, expected: %h, got: %h", {{20{i_inst[31]}}, i_inst[7], i_inst[30:25], i_inst[11:8], 1'b0}, o_immediate);
            $stop();
        end

        // TEST 6
        i_inst = 32'hFFA67128;
        i_format = B_TYPE; #5;

        if (o_immediate != {{20{i_inst[31]}}, i_inst[7], i_inst[30:25], i_inst[11:8], 1'b0}) begin
            $display("Wrong Immediate for B_TYPE, expected: %h, got: %h", {{20{i_inst[31]}}, i_inst[7], i_inst[30:25], i_inst[11:8], 1'b0}, o_immediate);
            $stop();
        end

        // TEST 7
        i_inst = 32'h12345613;
        i_format = U_TYPE; #5;

        if (o_immediate != {i_inst[31:12], 12'b0}) begin
            $display("Wrong Immediate for U_TYPE, expected: %h, got: %h", {i_inst[31:12], 12'b0}, o_immediate);
            $stop();
        end

        // TEST 8
        i_inst = 32'h98123116;
        i_format = U_TYPE; #5;

        if (o_immediate != {i_inst[31:12], 12'b0}) begin
            $display("Wrong Immediate for U_TYPE, expected: %h, got: %h", {i_inst[31:12], 12'b0}, o_immediate);
            $stop();
        end

        // TEST 9
        i_inst = 32'h98956116;
        i_format = J_TYPE; #5;

        if (o_immediate != {{12{i_inst[31]}}, i_inst[19:12], i_inst[20], i_inst[30:21], 1'b0}) begin
            $display("Wrong Immediate for J_TYPE, expected: %h, got: %h", {{12{i_inst[31]}}, i_inst[19:12], i_inst[20], i_inst[30:21], 1'b0}, o_immediate);
            $stop();
        end

        // TEST 10
        i_inst = 32'h89167023;
        i_format = J_TYPE; #5;

        if (o_immediate != {{12{i_inst[31]}}, i_inst[19:12], i_inst[20], i_inst[30:21], 1'b0}) begin
            $display("Wrong Immediate for J_TYPE, expected: %h, got: %h", {{12{i_inst[31]}}, i_inst[19:12], i_inst[20], i_inst[30:21], 1'b0}, o_immediate);
           $stop();
        end


        $display("All tests passed!! YAHOO!");
        $stop();

    end


endmodule
