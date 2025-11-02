`timescale 1ns/1ps
module tb_graphics_transform;

    parameter DATA_WIDTH = 16;
    reg clk;
    reg rst;
    reg start;
    reg signed [DATA_WIDTH-1:0] x_in;
    reg signed [DATA_WIDTH-1:0] y_in;
    reg [1:0] transform_type;
    reg signed [DATA_WIDTH-1:0] param;

    wire signed [DATA_WIDTH-1:0] x_out;
    wire signed [DATA_WIDTH-1:0] y_out;
    wire valid;
    wire done;

    // clock
    initial clk = 0;
    always #5 clk = ~clk;

    graphics_transform #(DATA_WIDTH) dut (
        .clk(clk), .rst(rst), .start(start),
        .x_in(x_in), .y_in(y_in),
        .transform_type(transform_type), .param(param),
        .x_out(x_out), .y_out(y_out),
        .valid(valid), .done(done)
    );

    initial begin
        $display("Graphics Transform Tests");
        rst = 1; start = 0;
        #20;
        rst = 0;
        #10;

        // Test 1: Rotate (10,0) by 90 degrees -> expect (0,10)
        x_in = 16'h0A00; // 10.0 Q8.8
        y_in = 16'h0000; // 0
        transform_type = 2'b00;
        param = 16'h005A; // 90 decimal (0x5A). we use lower byte for degrees
        start = 1;
        @(posedge clk); start = 0;
        wait(done);
        #2;
        $display("Rotation: x_out=%0d, y_out=%0d (Q8.8)", $signed(x_out), $signed(y_out));

        // Test 2: Scale (5,5) by 2.0 -> expect (10,10)
        x_in = 16'h0500; y_in = 16'h0500;
        transform_type = 2'b01;
        param = 16'h0200; // 2.0 in Q8.8
        start = 1;
        @(posedge clk); start = 0;
        wait(done);
        #2;
        $display("Scale: x_out=%0d, y_out=%0d (Q8.8)", $signed(x_out), $signed(y_out));

        // Test 3: Translate (3,4) by +5 in x -> expect (8,4)
        x_in = 16'h0300; y_in = 16'h0400;
        transform_type = 2'b10;
        param = 16'h0500; // translate +5.0
        start = 1;
        @(posedge clk); start = 0;
        wait(done);
        #2;
        $display("Translate: x_out=%0d, y_out=%0d (Q8.8)", $signed(x_out), $signed(y_out));

        $finish;
    end

endmodule

