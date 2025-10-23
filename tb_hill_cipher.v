`timescale 1ns/1ps

module tb_hill_cipher;

    parameter BLOCK_SIZE = 3;
    parameter DATA_WIDTH = 8;
    parameter CLK_PERIOD = 10;
    
    reg clk, rst, start, mode;
    reg [DATA_WIDTH-1:0] key_data, text_in;
    reg [$clog2(BLOCK_SIZE*BLOCK_SIZE)-1:0] key_addr;
    reg [$clog2(BLOCK_SIZE)-1:0] text_in_addr;
    reg key_wen, text_in_wen;
    
    wire [DATA_WIDTH-1:0] text_out;
    wire text_out_valid;
    wire done;
    
    hill_cipher_crypto #(
        .BLOCK_SIZE(BLOCK_SIZE),
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .mode(mode),
        .key_data(key_data),
        .key_addr(key_addr),
        .key_wen(key_wen),
        .text_in(text_in),
        .text_in_addr(text_in_addr),
        .text_in_wen(text_in_wen),
        .text_out(text_out),
        .text_out_valid(text_out_valid),
        .done(done)
    );
    
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;
    
    reg [DATA_WIDTH-1:0] output_text [0:BLOCK_SIZE-1];
    integer output_idx;
    
    always @(posedge clk) begin
        if (text_out_valid) begin
            output_text[output_idx] <= text_out;
            output_idx <= output_idx + 1;
        end
    end
    
    integer i;
    initial begin
        $dumpfile("hill_cipher.vcd");
        $dumpvars(0, tb_hill_cipher);
        
        rst = 1;
        start = 0;
        key_wen = 0;
        text_in_wen = 0;
        mode = 0;
        output_idx = 0;
        
        #(CLK_PERIOD*2);
        rst = 0;
        
        $display("\n=== Hill Cipher Cryptography Test ===");
        $display("Block size: %0d characters\n", BLOCK_SIZE);
        
        // Key: GYBNQKURP
        $display("Loading encryption key matrix...");
        key_wen = 1;
        key_addr = 0; key_data = 8'd6;  @(posedge clk);  // G
        key_addr = 1; key_data = 8'd24; @(posedge clk);  // Y
        key_addr = 2; key_data = 8'd1;  @(posedge clk);  // B
        key_addr = 3; key_data = 8'd13; @(posedge clk);  // N
        key_addr = 4; key_data = 8'd16; @(posedge clk);  // Q
        key_addr = 5; key_data = 8'd10; @(posedge clk);  // K
        key_addr = 6; key_data = 8'd20; @(posedge clk);  // U
        key_addr = 7; key_data = 8'd17; @(posedge clk);  // R
        key_addr = 8; key_data = 8'd15; @(posedge clk);  // P
        key_wen = 0;
        
        $display("Loading plaintext: ACT");
        text_in_wen = 1;
        text_in_addr = 0; text_in = "A"; @(posedge clk);
        text_in_addr = 1; text_in = "C"; @(posedge clk);
        text_in_addr = 2; text_in = "T"; @(posedge clk);
        text_in_wen = 0;
        
        #(CLK_PERIOD*2);
        $display("\nStarting encryption...");
        start = 1;
        @(posedge clk);
        start = 0;
        
        wait(done);
        #(CLK_PERIOD*2);
        
        $display("\n--- Encryption Result ---");
        $write("Ciphertext: ");
        for (i = 0; i < BLOCK_SIZE; i = i + 1) begin
            $write("%c", output_text[i]);
        end
        $display("\n");
        
        $display("=== Hill Cipher Test Complete ===");
        #(CLK_PERIOD*10);
        $finish;
    end

endmodule

