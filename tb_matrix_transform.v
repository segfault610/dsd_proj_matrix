`timescale 1ns / 1ps

module tb_matrix_transform;

    parameter DATA_WIDTH = 8;
    parameter CLK_PERIOD = 10;
    
    reg clk;
    reg rst_n;
    reg start;
    reg signed [DATA_WIDTH-1:0] x_in;
    reg signed [DATA_WIDTH-1:0] y_in;
    reg [1:0] transform_type;
    reg signed [DATA_WIDTH-1:0] param1;
    reg signed [DATA_WIDTH-1:0] param2;
    reg [2*DATA_WIDTH-1:0] matrix_result;
    reg matrix_valid;
    
    wire signed [DATA_WIDTH-1:0] x_out;
    wire signed [DATA_WIDTH-1:0] y_out;
    wire [2*DATA_WIDTH-1:0] combined_out;
    wire transform_valid;
    wire transform_done;
    
    matrix_transform #(DATA_WIDTH) dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .x_in(x_in),
        .y_in(y_in),
        .transform_type(transform_type),
        .param1(param1),
        .param2(param2),
        .matrix_result(matrix_result),
        .matrix_valid(matrix_valid),
        .x_out(x_out),
        .y_out(y_out),
        .combined_out(combined_out),
        .transform_valid(transform_valid),
        .transform_done(transform_done)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Test stimuli
    initial begin
        $dumpfile("tb_matrix_transform.vcd");
        $dumpvars(0, tb_matrix_transform);
        
        rst_n = 0;
        start = 0;
        matrix_valid = 0;
        x_in = 0;
        y_in = 0;
        transform_type = 2'b00;  // Rotation
        param1 = 8'sd45;
        param2 = 8'sd0;
        
        #(CLK_PERIOD * 2);
        rst_n = 1;
        #CLK_PERIOD;
        
        // =====================================================================
        // TEST 1: Rotation Transform
        // =====================================================================
        $display("\n========== TEST 1: Rotation (45 degrees) ==========");
        
        x_in = 8'sd10;
        y_in = 8'sd0;
        transform_type = 2'b00;
        
        start = 1;
        #CLK_PERIOD;
        start = 0;
        
        #(CLK_PERIOD * 3);
        
        // Simulate core output: rotation of (10,0) by 45° ? (7,7)
        matrix_result = 16'h0007;  // x' ? 7
        matrix_valid = 1;
        #CLK_PERIOD;
        
        matrix_result = 16'h0007;  // y' ? 7
        #CLK_PERIOD;
        matrix_valid = 0;
        
        wait(transform_done);
        #CLK_PERIOD;
        
        $display("Input: (10, 0), Transform: Rotation 45°");
        $display("Output: x=%0d, y=%0d", $signed(x_out), $signed(y_out));
        $display("Expected: x?7, y?7");
        
        #(CLK_PERIOD * 5);
        
        // =====================================================================
        // TEST 2: Scale Transform
        // =====================================================================
        $display("\n========== TEST 2: Scale (2x) ==========");
        
        x_in = 8'sd5;
        y_in = 8'sd5;
        transform_type = 2'b01;  // Scale
        param1 = 8'sd2;
        param2 = 8'sd2;
        
        start = 1;
        #CLK_PERIOD;
        start = 0;
        
        #(CLK_PERIOD * 3);
        
        // Simulate core output: scale (5,5) by 2x = (10,10)
        matrix_result = 16'h000A;  // x' = 10
        matrix_valid = 1;
        #CLK_PERIOD;
        
        matrix_result = 16'h000A;  // y' = 10
        #CLK_PERIOD;
        matrix_valid = 0;
        
        wait(transform_done);
        #CLK_PERIOD;
        
        $display("Input: (5, 5), Transform: Scale 2x");
        $display("Output: x=%0d, y=%0d", $signed(x_out), $signed(y_out));
        $display("Expected: x=10, y=10");
        
        #(CLK_PERIOD * 5);
        
        // =====================================================================
        // TEST 3: Translation Transform
        // =====================================================================
        $display("\n========== TEST 3: Translation (5, 10) ==========");
        
        x_in = 8'sd3;
        y_in = 8'sd4;
        transform_type = 2'b10;  // Translation
        param1 = 8'sd5;
        param2 = 8'sd10;
        
        start = 1;
        #CLK_PERIOD;
        start = 0;
        
        #(CLK_PERIOD * 3);
        
        // Simulate core output: translate (3,4) by (5,10) = (8,14)
        matrix_result = 16'h0008;  // x' = 8
        matrix_valid = 1;
        #CLK_PERIOD;
        
        matrix_result = 16'h000E;  // y' = 14
        #CLK_PERIOD;
        matrix_valid = 0;
        
        wait(transform_done);
        #CLK_PERIOD;
        
        $display("Input: (3, 4), Transform: Translate (5, 10)");
        $display("Output: x=%0d, y=%0d", $signed(x_out), $signed(y_out));
        $display("Expected: x=8, y=14");
        
        #(CLK_PERIOD * 5);
        
        $display("\n========== ALL TESTS COMPLETED ==========\n");
        $finish;
    end

endmodule

