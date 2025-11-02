
// ============================================================================
// TESTBENCH - Test All Three Application Modules
// ============================================================================

`timescale 1ns / 1ps

module tb_applications;

    parameter M = 3;
    parameter N = 3;
    parameter P = 3;
    parameter DATA_WIDTH = 8;
    parameter CLK_PERIOD = 10;
    
    reg clk;
    reg rst_n;
    reg start;
    
    // =========================================================================
    // TEST 1: NEURAL LAYER
    // =========================================================================
    
    reg [2*DATA_WIDTH-1:0] matrix_result_nn;
    reg matrix_valid_nn;
    wire [2*DATA_WIDTH-1:0] app_result_nn;
    wire app_valid_nn;
    wire app_done_nn;
    
    neural_layer #(M, N, P, DATA_WIDTH) nn_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .activation_type(2'b00),  // ReLU
        .matrix_result(matrix_result_nn),
        .matrix_valid(matrix_valid_nn),
        .bias_in(8'sd0),
        .bias_wen(0),
        .bias_addr(0),
        .app_result(app_result_nn),
        .app_valid(app_valid_nn),
        .app_done(app_done_nn)
    );
    
    // =========================================================================
    // TEST 2: IMAGE FILTER
    // =========================================================================
    
    reg [2*DATA_WIDTH-1:0] matrix_result_filt;
    reg matrix_valid_filt;
    wire [2*DATA_WIDTH-1:0] filter_out;
    wire filter_valid;
    wire filter_done;
    
    image_filter #(3, 3, 1, DATA_WIDTH) filt_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .kernel_in(8'sd0),
        .kernel_addr(0),
        .kernel_wen(0),
        .pixel_in(8'sd1),
        .pixel_valid(1),
        .matrix_result(matrix_result_filt),
        .matrix_valid(matrix_valid_filt),
        .filter_out(filter_out),
        .filter_valid(filter_valid),
        .filter_done(filter_done)
    );
    
    // =========================================================================
    // TEST 3: MATRIX TRANSFORM
    // =========================================================================
    
    reg [2*DATA_WIDTH-1:0] matrix_result_trans;
    reg matrix_valid_trans;
    wire signed [DATA_WIDTH-1:0] x_out, y_out;
    wire [2*DATA_WIDTH-1:0] combined_out;
    wire transform_valid;
    wire transform_done;
    
    matrix_transform #(DATA_WIDTH) trans_inst (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .x_in(8'sd10),
        .y_in(8'sd0),
        .transform_type(2'b00),  // Rotation
        .param1(8'sd45),
        .param2(8'sd0),
        .matrix_result(matrix_result_trans),
        .matrix_valid(matrix_valid_trans),
        .x_out(x_out),
        .y_out(y_out),
        .combined_out(combined_out),
        .transform_valid(transform_valid),
        .transform_done(transform_done)
    );
    
    // =========================================================================
    // CLOCK GENERATION
    // =========================================================================
    
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // =========================================================================
    // TEST STIMULI
    // =========================================================================
    
    initial begin
        $dumpfile("tb_applications.vcd");
        $dumpvars(0, tb_applications);
        
        rst_n = 0;
        start = 0;
        matrix_valid_nn = 0;
        matrix_valid_filt = 0;
        matrix_valid_trans = 0;
        
        #(CLK_PERIOD * 2);
        rst_n = 1;
        #CLK_PERIOD;
        
        // =====================================================================
        // TEST 1: NEURAL LAYER - ReLU ACTIVATION
        // =====================================================================
        $display("\n========== TEST 1: NEURAL LAYER (ReLU) ==========");
        
        start = 1;
        #CLK_PERIOD;
        start = 0;
        
        // Test positive number
        #CLK_PERIOD;
        matrix_result_nn = 16'h0050;  // +80
        matrix_valid_nn = 1;
        #CLK_PERIOD;
        matrix_valid_nn = 0;
        
        wait(app_done_nn);
        $display("Input: +80, Output (ReLU): %0d (Expected: 80)", app_result_nn);
        
        #(CLK_PERIOD * 5);
        
        // Test negative number
        start = 1;
        #CLK_PERIOD;
        start = 0;
        #CLK_PERIOD;
        
        matrix_result_nn = 16'hFFB0;  // -80 (two's complement)
        matrix_valid_nn = 1;
        #CLK_PERIOD;
        matrix_valid_nn = 0;
        
        wait(app_done_nn);
        $display("Input: -80, Output (ReLU): %0d (Expected: 0)", app_result_nn);
        
        #(CLK_PERIOD * 5);
        
        // =====================================================================
        // TEST 2: IMAGE FILTER - CONVOLUTION
        // =====================================================================
        $display("\n========== TEST 2: IMAGE FILTER (Convolution) ==========");
        
        start = 1;
        #CLK_PERIOD;
        start = 0;
        
        // Wait for filter to fill buffers
        #(CLK_PERIOD * 20);
        
        matrix_result_filt = 16'h0042;  // Convolution result
        matrix_valid_filt = 1;
        #CLK_PERIOD;
        matrix_valid_filt = 0;
        
        wait(filter_done);
        $display("Filter Output (Edge Detection): %0d", filter_out);
        
        #(CLK_PERIOD * 5);
        
        // =====================================================================
        // TEST 3: MATRIX TRANSFORM - ROTATION
        // =====================================================================
        $display("\n========== TEST 3: MATRIX TRANSFORM (Rotation) ==========");
        
        start = 1;
        #CLK_PERIOD;
        start = 0;
        
        // Simulate matrix multiplier output for rotation
        #(CLK_PERIOD * 5);
        matrix_result_trans = 16'h0000;  // x' after rotation
        matrix_valid_trans = 1;
        #CLK_PERIOD;
        
        matrix_result_trans = 16'h000A;  // y' after rotation
        #CLK_PERIOD;
        matrix_valid_trans = 0;
        
        wait(transform_done);
        $display("Input: (10, 0), Rotation: 45°");
        $display("Output: x=%0d, y=%0d", x_out, y_out);
        $display("Expected: x?7, y?7 (rotated to 45°)");
        
        #(CLK_PERIOD * 5);
        
        $display("\n========== ALL APPLICATION TESTS COMPLETED ==========\n");
        $finish;
    end

endmodule
