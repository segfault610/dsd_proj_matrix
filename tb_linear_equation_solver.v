`timescale 1ns/1ps

module tb_linear_equation_solver;

    parameter DATA_WIDTH = 16;
    parameter CLK_PERIOD = 10;
    parameter FRAC_BITS  = 8;

    localparam A00 = 10, A01 = -1, A02 = 2;
    localparam A10 =  1, A11 = 11, A12 = -1;
    localparam A20 =  2, A21 = -1, A22 = 10;
    localparam B0 = 26, B1 = 35, B2 = 48;
    localparam EXP_X0 = 2, EXP_X1 = 3, EXP_X2 = 4;

    reg clk;
    reg rst, start, a_wen, b_wen;
    reg [DATA_WIDTH-1:0] a_data, b_data;
    reg [3:0] a_addr;
    reg [1:0] b_addr;

    wire [DATA_WIDTH-1:0] x0, x1, x2;
    wire done;

    linear_equation_solver_3x3 #(
        .DATA_WIDTH(DATA_WIDTH),
        .MAX_ITER(100)
    ) dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .a_data(a_data),
        .a_addr(a_addr),
        .a_wen(a_wen),
        .b_data(b_data),
        .b_addr(b_addr),
        .b_wen(b_wen),
        .x0(x0),
        .x1(x1),
        .x2(x2),
        .done(done)
    );

    always begin
        clk = 0; #(CLK_PERIOD/2);
        clk = 1; #(CLK_PERIOD/2);
    end

    initial begin
        $display("Starting Testbench...");
        rst = 1; start = 0; a_wen = 0; b_wen = 0;
        a_data = 0; a_addr = 0; b_data = 0; b_addr = 0;

        #(CLK_PERIOD*2); rst = 0;
        $display("Reset released. Loading matrices..."); #(CLK_PERIOD);

        a_addr = 0; a_data = A00 << FRAC_BITS; a_wen = 1; @(posedge clk);
        a_addr = 1; a_data = A01 << FRAC_BITS; a_wen = 1; @(posedge clk);
        a_addr = 2; a_data = A02 << FRAC_BITS; a_wen = 1; @(posedge clk);
        a_addr = 3; a_data = A10 << FRAC_BITS; a_wen = 1; @(posedge clk);
        a_addr = 4; a_data = A11 << FRAC_BITS; a_wen = 1; @(posedge clk);
        a_addr = 5; a_data = A12 << FRAC_BITS; a_wen = 1; @(posedge clk);
        a_addr = 6; a_data = A20 << FRAC_BITS; a_wen = 1; @(posedge clk);
        a_addr = 7; a_data = A21 << FRAC_BITS; a_wen = 1; @(posedge clk);
        a_addr = 8; a_data = A22 << FRAC_BITS; a_wen = 1; @(posedge clk);
        a_wen = 0;

        b_addr = 0; b_data = B0 << FRAC_BITS; b_wen = 1; @(posedge clk);
        b_addr = 1; b_data = B1 << FRAC_BITS; b_wen = 1; @(posedge clk);
        b_addr = 2; b_data = B2 << FRAC_BITS; b_wen = 1; @(posedge clk);
        b_wen = 0;

        $display("Matrix A loaded.");
        $display("Vector b loaded.");

        start = 1; @(posedge clk); start = 0;
        $display("Start signal pulsed. Waiting for 'done'...");

        wait (done == 1'b1); $display("Solver finished.");
        @(posedge clk); 
        $display("-----------------------------------------");
        $display("Expected solution (fixed-point): x0=%d, x1=%d, x2=%d",
            EXP_X0<<FRAC_BITS, EXP_X1<<FRAC_BITS, EXP_X2<<FRAC_BITS);
        $display("Actual solution (fixed-point):   x0=%d, x1=%d, x2=%d", x0, x1, x2);
        $display("Actual solution (integer approx): x0=%d, x1=%d, x2=%d",
            $signed(x0)>>>FRAC_BITS, $signed(x1)>>>FRAC_BITS, $signed(x2)>>>FRAC_BITS);
        $display("-----------------------------------------");

        $finish;
    end

endmodule

