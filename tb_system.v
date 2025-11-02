
`timescale 1ns / 1ps

module tb_system;
    parameter M = 3;
    parameter N = 3;
    parameter P = 3;
    parameter DATA_WIDTH = 8;
    parameter CLK_PERIOD = 10;
    
    reg clk, rst_n;
    reg [1:0] app_select;
    reg [DATA_WIDTH-1:0] a_data_in, b_data_in;
    reg [$clog2(M*N)-1:0] a_addr;
    reg [$clog2(N*P)-1:0] b_addr;
    reg a_wen, b_wen;
    reg start_computation;
    
    wire computation_done;
    wire [2*DATA_WIDTH-1:0] result_out;
    wire result_valid;
    
    matrix_accelerator_top #(M, N, P, DATA_WIDTH) top (
        .clk(clk), .rst_n(rst_n), .app_select(app_select),
        .a_data_in(a_data_in), .a_addr(a_addr), .a_wen(a_wen),
        .b_data_in(b_data_in), .b_addr(b_addr), .b_wen(b_wen),
        .start_computation(start_computation),
        .computation_done(computation_done),
        .result_out(result_out), .result_valid(result_valid)
    );
    
    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end
    
    initial begin
        $dumpfile("tb_system.vcd");
        $dumpvars(0, tb_system);
        
        rst_n = 0; a_wen = 0; b_wen = 0; start_computation = 0;
        #(CLK_PERIOD * 2); rst_n = 1; #CLK_PERIOD;
        
        // Load identity matrices
        for (int i = 0; i < M*N; i = i + 1) begin
            a_data_in = (i % (N+1) == 0) ? 1 : 0;
            a_addr = i;
            a_wen = 1;
            #CLK_PERIOD;
        end
        a_wen = 0;
        
        for (int i = 0; i < N*P; i = i + 1) begin
            b_data_in = (i % (P+1) == 0) ? 1 : 0;
            b_addr = i;
            b_wen = 1;
            #CLK_PERIOD;
        end
        b_wen = 0;
        
        // Run
        app_select = 0;
        start_computation = 1;
        #CLK_PERIOD;
        start_computation = 0;
        
        wait(computation_done);
        $display("SYSTEM TEST PASSED");
        
        #(CLK_PERIOD * 10);
        $finish;
    end

endmodule
