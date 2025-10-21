`timescale 1ns/1ps

module tb_matrix_multiplier;

    parameter M1 = 3;
    parameter N1 = 3;
    parameter N2 = 3;
    parameter DATA_WIDTH = 16;
    parameter CLK_PERIOD = 10;
    
    reg clk, rst, start;
    reg [DATA_WIDTH-1:0] mat_a_data, mat_b_data;
    reg [$clog2(M1*N1)-1:0] mat_a_addr;
    reg [$clog2(N1*N2)-1:0] mat_b_addr;
    reg mat_a_wen, mat_b_wen;
    
    wire [DATA_WIDTH-1:0] mat_c_data;
    wire mat_c_valid;
    wire done;
    
    // Instantiate matrix multiplier
    matrix_multiplier #(
        .M1(M1),
        .N1(N1),
        .N2(N2),
        .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .mat_a_data(mat_a_data),
        .mat_a_addr(mat_a_addr),
        .mat_a_wen(mat_a_wen),
        .mat_b_data(mat_b_data),
        .mat_b_addr(mat_b_addr),
        .mat_b_wen(mat_b_wen),
        .mat_c_data(mat_c_data),
        .mat_c_valid(mat_c_valid),
        .done(done)
    );
    
    // Clock generation
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;
    
    // Expected and result matrices
    reg [DATA_WIDTH-1:0] expected_matrix [0:M1*N2-1];
    reg [DATA_WIDTH-1:0] result_matrix [0:M1*N2-1];
    integer result_count;
    integer error_count;
    
    // Store results
    always @(posedge clk) begin
        if (mat_c_valid) begin
            result_matrix[result_count] <= mat_c_data;
            result_count <= result_count + 1;
        end
    end
    
    integer i;
    // --- FIX: Declarations moved from the for-loop to the top of the initial block ---
    integer int_part, frac_part, e_int_part, e_frac_part;
    integer diff;

    initial begin
        $dumpfile("matrix_mult.vcd");
        $dumpvars(0, tb_matrix_multiplier);
        
        // Initialize
        rst = 1;
        start = 0;
        mat_a_wen = 0;
        mat_b_wen = 0;
        result_count = 0;
        error_count = 0;
        
        #(CLK_PERIOD*2);
        rst = 0;
        
        // Load Matrix A (3x3)
        // [[1.0, 2.0, 3.0],
        //  [4.0, 5.0, 6.0],
        //  [7.0, 8.0, 9.0]]
        mat_a_wen = 1;
        for (i = 0; i < 9; i = i + 1) begin
            mat_a_addr = i;
            mat_a_data = (i+1) << 8; // Q8.8 fixed-point
            #CLK_PERIOD;
        end
        mat_a_wen = 0;
        
        // Load Matrix B (3x3) - Identity matrix
        mat_b_wen = 1;
        for (i = 0; i < 9; i = i + 1) begin
            mat_b_addr = i;
            if (i % 4 == 0)
                mat_b_data = 16'h0100; // 1.0 Q8.8
            else
                mat_b_data = 16'h0000; // 0.0
            #CLK_PERIOD;
        end
        mat_b_wen = 0;
        
        // Define Expected Matrix C (same as Matrix A for identity)
        expected_matrix[0] = 16'h0100; // 1.0
        expected_matrix[1] = 16'h0200; // 2.0
        expected_matrix[2] = 16'h0300; // 3.0
        expected_matrix[3] = 16'h0400; // 4.0
        expected_matrix[4] = 16'h0500; // 5.0
        expected_matrix[5] = 16'h0600; // 6.0
        expected_matrix[6] = 16'h0700; // 7.0
        expected_matrix[7] = 16'h0800; // 8.0
        expected_matrix[8] = 16'h0900; // 9.0
        
        // Start multiplication
        #(CLK_PERIOD*2);
        start = 1;
        #CLK_PERIOD;
        start = 0;
        
        // Wait for done
        wait(done);
        #(CLK_PERIOD*10); // Wait to capture all outputs
        
        // Compare results and calculate error
        $display("\n=== Matrix Multiplication Results ===");
        for (i = 0; i < M1*N2; i = i + 1) begin
            
            int_part = $signed(result_matrix[i]) >>> 8;
            frac_part = ((result_matrix[i] & 16'h00FF) * 100) >> 8;
            e_int_part = $signed(expected_matrix[i]) >>> 8;
            e_frac_part = ((expected_matrix[i] & 16'h00FF) * 100) >> 8;
            diff = (int_part - e_int_part)*100 + (frac_part - e_frac_part);
            if (diff < 0) diff = -diff;
            if (diff > 2) error_count = error_count + 1; // error threshold
            
            if (i % N2 == 0) $display("");
            $display("C[%0d] = %d.%02d (Expected %d.%02d) - Error: %d", i, int_part, frac_part, e_int_part, e_frac_part, diff);
        end
        
        if (error_count == 0) begin
            $display("\nAll values matched expected results within error threshold.");
        end else begin
            $display("\nSimulation failed with %0d errors.", error_count);
        end
        
        $display("\n=== Simulation Complete ===");
        $finish;
    end
    
    // Timeout
    initial begin
        #10000;
        $display("ERROR: Simulation timeout!");
        $finish;
    end

endmodule

