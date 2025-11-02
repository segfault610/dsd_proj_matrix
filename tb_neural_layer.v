
`timescale 1ns / 1ps

module tb_neural_layer;

    parameter M = 3;
    parameter N = 3;
    parameter P = 3;
    parameter DATA_WIDTH = 8;
    parameter CLK_PERIOD = 10;
    
    reg clk;
    reg rst_n;
    reg start;
    reg [1:0] activation_type;
    reg [2*DATA_WIDTH-1:0] matrix_result;
    reg matrix_valid;
    reg signed [DATA_WIDTH-1:0] bias_in;
    reg bias_wen;
    reg [$clog2(M)-1:0] bias_addr;
    
    wire [2*DATA_WIDTH-1:0] app_result;
    wire app_valid;
    wire app_done;
    
    neural_layer #(M, N, P, DATA_WIDTH) dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .activation_type(activation_type),
        .matrix_result(matrix_result),
        .matrix_valid(matrix_valid),
        .bias_in(bias_in),
        .bias_wen(bias_wen),
        .bias_addr(bias_addr),
        .app_result(app_result),
        .app_valid(app_valid),
        .app_done(app_done)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    // Test stimuli
    initial begin
        $dumpfile("tb_neural_layer.vcd");
        $dumpvars(0, tb_neural_layer);
        
        rst_n = 0;
        start = 0;
        matrix_valid = 0;
        bias_wen = 0;
        activation_type = 2'b00;  // ReLU
        
        #(CLK_PERIOD * 2);
        rst_n = 1;
        #CLK_PERIOD;
        
        // =====================================================================
        // TEST 1: ReLU Activation - Positive Number
        // =====================================================================
        $display("\n========== TEST 1: ReLU - Positive Number ==========");
        
        start = 1;
        #CLK_PERIOD;
        start = 0;
        
        #CLK_PERIOD;
        matrix_result = 16'h0050;  // +80
        matrix_valid = 1;
        #CLK_PERIOD;
        matrix_valid = 0;
        
        wait(app_done);
        #CLK_PERIOD;
        
        if (app_result == 16'h0050) begin
            $display("? PASS: Input +80 ? Output %0d (Expected 80)", app_result);
        end else begin
            $display("? FAIL: Input +80 ? Output %0d (Expected 80)", app_result);
        end
        
        #(CLK_PERIOD * 5);
        
        // =====================================================================
        // TEST 2: ReLU Activation - Negative Number
        // =====================================================================
        $display("\n========== TEST 2: ReLU - Negative Number ==========");
        
        start = 1;
        #CLK_PERIOD;
        start = 0;
        
        #CLK_PERIOD;
        matrix_result = 16'hFFB0;  // -80
        matrix_valid = 1;
        #CLK_PERIOD;
        matrix_valid = 0;
        
        wait(app_done);
        #CLK_PERIOD;
        
        if (app_result == 16'h0000) begin
            $display("? PASS: Input -80 ? Output %0d (Expected 0)", app_result);
        end else begin
            $display("? FAIL: Input -80 ? Output %0d (Expected 0)", app_result);
        end
        
        #(CLK_PERIOD * 5);
        
        // =====================================================================
        // TEST 3: Linear Activation
        // =====================================================================
        $display("\n========== TEST 3: Linear Activation ==========");
        
        activation_type = 2'b10;  // Linear
        
        start = 1;
        #CLK_PERIOD;
        start = 0;
        
        #CLK_PERIOD;
        matrix_result = 16'hFF80;  // -128
        matrix_valid = 1;
        #CLK_PERIOD;
        matrix_valid = 0;
        
        wait(app_done);
        #CLK_PERIOD;
        
        if (app_result == 16'hFF80) begin
            $display("? PASS: Linear: Input -128 ? Output %d (Expected -128)", $signed(app_result));
        end else begin
            $display("? FAIL: Linear: Input -128 ? Output %d (Expected -128)", $signed(app_result));
        end
        
        #(CLK_PERIOD * 5);
        
        $display("\n========== ALL TESTS COMPLETED ==========\n");
        $finish;
    end

endmodule
