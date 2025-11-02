`timescale 1ns/1ps

module tb_simple_generic_matrix_mult;
    // Change these parameters for different matrix orders!
    parameter integer M = 2;    // Rows of A
    parameter integer N = 3;    // Cols of A / Rows of B
    parameter integer P = 4;    // Cols of B
    parameter integer DATA_WIDTH = 8; // Element width

    // Address widths
    localparam AW = (M*N < 2) ? 1 : $clog2(M*N);
    localparam BW = (N*P < 2) ? 1 : $clog2(N*P);

    // Signals
    reg clk, rst, start;
    reg signed [DATA_WIDTH-1:0] a_in, b_in;
    reg [AW-1:0] a_addr;
    reg [BW-1:0] b_addr;
    reg a_wen, b_wen;
    wire [2*DATA_WIDTH-1:0] c_out;
    wire c_valid, done;

    // Matrices for behavioral and captured results
    reg signed [DATA_WIDTH-1:0] matrix_A [0:M*N-1];
    reg signed [DATA_WIDTH-1:0] matrix_B [0:N*P-1];
    reg signed [2*DATA_WIDTH-1:0] result   [0:M*P-1];
    reg signed [2*DATA_WIDTH-1:0] expected [0:M*P-1];

    integer i, r, c, k;
    integer result_count, errors;

    // Instantiate DUT
    simple_generic_matrix_mult #(
        .M(M), .N(N), .P(P), .DATA_WIDTH(DATA_WIDTH)
    ) dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .a_in(a_in),
        .a_addr(a_addr),
        .a_wen(a_wen),
        .b_in(b_in),
        .b_addr(b_addr),
        .b_wen(b_wen),
        .c_out(c_out),
        .c_valid(c_valid),
        .done(done)
    );

    // Clock generator (10ns)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Immediate capture of valid output
    always @(posedge clk or posedge rst) begin
        if (rst) result_count <= 0;
        else if (c_valid && result_count < M*P) begin
            result[result_count] <= c_out;
            result_count <= result_count + 1;
        end
    end

    // Behavioral reference computation
    task compute_expected;
        integer rr, cc, kk;
        reg signed [2*DATA_WIDTH + $clog2(N):0] acc;
        begin
            for (rr = 0; rr < M; rr = rr + 1)
                for (cc = 0; cc < P; cc = cc + 1) begin
                    acc = 0;
                    for (kk = 0; kk < N; kk = kk + 1)
                        acc = acc + matrix_A[rr*N + kk] * matrix_B[kk*P + cc];
                    expected[rr*P + cc] = acc[2*DATA_WIDTH-1:0];
                end
        end
    endtask

    // Main test sequence (easy to modify for any demo)
    initial begin
        // Reset and setup
        rst = 1; start = 0;
        a_wen = 0; b_wen = 0; a_addr = 0; b_addr = 0;
        a_in = 0; b_in = 0; errors = 0; result_count = 0;

        repeat (3) @(posedge clk);
        rst = 0; @(posedge clk);

        // ----------- Init: Example for Non-uniform sizes ----------
        // You can easily edit these values for any demo
        // A: M x N     B: N x P
        // Let's use:
        //   A = [1 2 3; 4 5 6]    (2x3)
        //   B = [1 0 -1 2; -2 3 0 1; 2 1 1 -1] (3x4)
        matrix_A[0]=1; matrix_A[1]=2; matrix_A[2]=3;
        matrix_A[3]=4; matrix_A[4]=5; matrix_A[5]=6;
        matrix_B[0]=1; matrix_B[1]=0; matrix_B[2]=-1; matrix_B[3]=2;
        matrix_B[4]=-2; matrix_B[5]=3; matrix_B[6]=0; matrix_B[7]=1;
        matrix_B[8]=2; matrix_B[9]=1; matrix_B[10]=1; matrix_B[11]=-1;

        compute_expected();

        // ----------- Load Matrices into DUT ----------
        a_wen = 1;
        for (i = 0; i < M*N; i = i + 1) begin
            @(posedge clk); a_addr <= i; a_in <= matrix_A[i];
        end
        @(posedge clk); a_wen = 0;

        b_wen = 1;
        for (i = 0; i < N*P; i = i + 1) begin
            @(posedge clk); b_addr <= i; b_in <= matrix_B[i];
        end
        @(posedge clk); b_wen = 0;

        // ----------- Start Computation ----------
        @(posedge clk); start = 1;
        @(posedge clk); start = 0;

        // Wait for DUT to complete
        wait(done);
        repeat (4) @(posedge clk); // Extra cycles for last c_valid

        // ----------- Print Input A ----------
        $display("\nMatrix A (%0dx%0d):", M, N);
        for (r = 0; r < M; r = r + 1) begin
            for (c = 0; c < N; c = c + 1)
                $write("%4d ", matrix_A[r*N + c]);
            $write("\n");
        end

        // ----------- Print Input B ----------
        $display("\nMatrix B (%0dx%0d):", N, P);
        for (r = 0; r < N; r = r + 1) begin
            for (c = 0; c < P; c = c + 1)
                $write("%4d ", matrix_B[r*P + c]);
            $write("\n");
        end

        // ----------- Print Expected Reference ----------
        $display("\nExpected Result C (%0dx%0d):", M, P);
        for (r = 0; r < M; r = r + 1) begin
            for (c = 0; c < P; c = c + 1)
                $write("%6d ", expected[r*P + c]);
            $write("\n");
        end

        // ----------- Print Actual DUT Result ----------
        $display("\nDUT Result C (%0dx%0d) (captured %0d values):", M, P, result_count);
        for (i = 0; i < result_count; i = i + 1) begin
            if (i % P == 0) $write("\n");
            $write("%6d ", result[i]);
        end
        $write("\n\n");

        // ----------- Comparison ----------
        if (result_count != M*P) begin
            $display("ERROR: DUT produced %0d results, expected %0d", result_count, M*P);
            errors = errors + 1;
        end
        for (i = 0; i < M*P; i = i + 1)
            if (result[i] !== expected[i]) begin
                $display("Mismatch @ idx %0d (r%0d c%0d): DUT=%0d expected=%0d", i, i/P, i%P, result[i], expected[i]);
                errors = errors + 1;
            end

        if (errors == 0)
            $display(">>> TEST PASS: All %0d outputs match expected results.", M*P);
        else
            $display(">>> TEST FAIL: %0d errors found.", errors);

        $finish;
    end
endmodule
