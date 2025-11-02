`timescale 1ns / 1ps

module tb_image_filter;

    parameter M = 3;
    parameter N = 3;
    parameter P = 1;
    parameter DATA_WIDTH = 8;
    parameter CLK_PERIOD = 10;

    reg clk;
    reg rst_n;
    reg start;
    reg signed [DATA_WIDTH-1:0] kernel_in;
    reg [$clog2(M*N)-1:0] kernel_addr;
    reg kernel_wen;
    reg signed [DATA_WIDTH-1:0] pixel_in;
    reg pixel_valid;
    reg [2*DATA_WIDTH-1:0] matrix_result;
    reg matrix_valid;

    wire [2*DATA_WIDTH-1:0] filter_out;
    wire filter_valid;
    wire filter_done;

    // loop variables declared at module scope (Verilog)
    integer i;
    integer p;

    image_filter #(M, N, P, DATA_WIDTH) dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .kernel_in(kernel_in),
        .kernel_addr(kernel_addr),
        .kernel_wen(kernel_wen),
        .pixel_in(pixel_in),
        .pixel_valid(pixel_valid),
        .matrix_result(matrix_result),
        .matrix_valid(matrix_valid),
        .filter_out(filter_out),
        .filter_valid(filter_valid),
        .filter_done(filter_done)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    initial begin
        $dumpfile("tb_image_filter.vcd");
        $dumpvars(0, tb_image_filter);

        rst_n = 0;
        start = 0;
        kernel_wen = 0;
        pixel_valid = 0;
        matrix_valid = 0;
        pixel_in = 0;
        kernel_in = 0;
        kernel_addr = 0;
        matrix_result = 0;

        #(CLK_PERIOD * 2);
        rst_n = 1;
        #CLK_PERIOD;

        $display("\n========== TEST 1: Load Custom Kernel ==========");
        // Load identity-like kernel (center = 1)
        for (i = 0; i < 9; i = i + 1) begin
            if (i == 4) kernel_in = 8'sd1;
            else kernel_in = 8'sd0;
            kernel_addr = i;
            kernel_wen = 1;
            #CLK_PERIOD;
        end
        kernel_wen = 0;
        $display("? Kernel loaded");

        #(CLK_PERIOD * 2);

        $display("\n========== TEST 2: Feed Pixel Stream ==========");
        start = 1;
        #CLK_PERIOD;
        start = 0;

        // Feed 9 pixels (1..9)
        for (p = 0; p < 9; p = p + 1) begin
            pixel_in = p + 1; // signed assignment
            pixel_valid = 1;
            #CLK_PERIOD;
        end
        pixel_valid = 0;

        #(CLK_PERIOD * 3);

        $display("\n========== TEST 3: Convolution Result ==========");
        // If kernel is identity center=1, convolution sum = center * sum neighborhood
        // Here the testbench provides the external matrix result directly:
        matrix_result = 16'h0009;  // value 9
        matrix_valid = 1;
        #CLK_PERIOD;
        matrix_valid = 0;

        // wait for the module to assert done
        wait(filter_done);
        #CLK_PERIOD;

        $display("? Filter output: %0d", filter_out);
        $display("? Filter valid: %b", filter_valid);

        #(CLK_PERIOD * 5);

        $display("\n========== ALL TESTS COMPLETED ==========\n");
        $finish;
    end

endmodule

