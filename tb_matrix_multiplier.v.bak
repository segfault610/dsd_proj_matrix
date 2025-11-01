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

    // Arrays to hold input and output matrices
    reg [DATA_WIDTH-1:0] matrix_a [0:M1*N1-1];
    reg [DATA_WIDTH-1:0] matrix_b [0:N1*N2-1];
    reg [DATA_WIDTH-1:0] result_matrix [0:M1*N2-1];

    integer i;
    integer result_count;

    // Clock generation
    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

    // Capture results when valid
    always @(posedge clk) begin
        if (mat_c_valid) begin
            result_matrix[result_count] <= mat_c_data;
            result_count <= result_count + 1;
        end
    end

    initial begin
        $dumpfile("matrix_mult.vcd");
        $dumpvars(0, tb_matrix_multiplier);

        // === Customize your matrices here ===
        // Matrix A (row-major order)
        matrix_a[0] = 16'h0100; // 1.0
        matrix_a[1] = 16'h0200; // 2.0
        matrix_a[2] = 16'h0300; // 3.0
        matrix_a[3] = 16'h0400; // 4.0
        matrix_a[4] = 16'h0500; // 5.0
        matrix_a[5] = 16'h0600; // 6.0
        matrix_a[6] = 16'h0700; // 7.0
        matrix_a[7] = 16'h0800; // 8.0
        matrix_a[8] = 16'h0900; // 9.0

        // Matrix B (row-major order)
        matrix_b[0] = 16'h0100; // 1.0
        matrix_b[1] = 16'h0100; // 1.0
        matrix_b[2] = 16'h0000; // 0.0
        matrix_b[3] = 16'h0000; // 0.0
        matrix_b[4] = 16'h0100; // 1.0
        matrix_b[5] = 16'h0100; // 1.0
        matrix_b[6] = 16'h0100; // 1.0
        matrix_b[7] = 16'h0000; // 0.0
        matrix_b[8] = 16'h0100; // 1.0

        // Reset and init
        rst = 1;
        mat_a_wen = 0;
        mat_b_wen = 0;
        start = 0;
        result_count = 0;

        #(CLK_PERIOD * 2);
        rst = 0;

        // Load Matrix A
        mat_a_wen = 1;
        for (i = 0; i < M1*N1; i = i + 1) begin
            mat_a_addr = i;
            mat_a_data = matrix_a[i];
            #(CLK_PERIOD);
        end
        mat_a_wen = 0;

        // Load Matrix B
        mat_b_wen = 1;
        for (i = 0; i < N1*N2; i = i + 1) begin
            mat_b_addr = i;
            mat_b_data = matrix_b[i];
            #(CLK_PERIOD);
        end
        mat_b_wen = 0;

        // Start multiplication
        #(CLK_PERIOD);
        start = 1;
        #(CLK_PERIOD);
        start = 0;

        // Wait for done
        wait(done);
        #(CLK_PERIOD * 5);

        // Print Matrix A
        $display("\nMatrix A:");
        for (i = 0; i < M1*N1; i = i + 1)
            $display("A[%0d] = %d.%02d", i, $signed(matrix_a[i]) >>> 8, ((matrix_a[i] & 16'h00FF)*100) >>>8);

        // Print Matrix B
        $display("\nMatrix B:");
        for (i = 0; i < N1*N2; i = i + 1)
            $display("B[%0d] = %d.%02d", i, $signed(matrix_b[i]) >>> 8, ((matrix_b[i] & 16'h00FF)*100) >>>8);

        // Print Matrix C
        $display("\nMatrix C = A * B:");
        for (i = 0; i < M1*N2; i = i + 1)
            $display("C[%0d] = %d.%02d", i, $signed(result_matrix[i]) >>> 8, ((result_matrix[i] & 16'h00FF)*100) >>> 8);

        $display("\nSimulation complete.");
        $finish;
    end

    // Timeout
    initial begin
        #10000;
        $display("ERROR: Simulation timeout.");
        $finish;
    end

endmodule

