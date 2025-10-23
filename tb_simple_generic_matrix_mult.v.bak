`timescale 1ns/1ps

// ===========================================================
// SIMPLE GENERIC MATRIX MULTIPLIER (DUT)
// (This is the fixed version you provided ? included here
//  so the testbench can run standalone. If you keep a
//  separate DUT file, remove this duplicate definition.)
// ===========================================================
module simple_generic_matrix_mult #(
    parameter integer M = 3,
    parameter integer N = 3,
    parameter integer P = 3,
    parameter integer DATA_WIDTH = 8
)(
    input  wire clk,
    input  wire rst,
    input  wire start,

    input  wire signed [DATA_WIDTH-1:0] a_in,
    input  wire [$clog2(M*N)-1:0] a_addr,
    input  wire a_wen,

    input  wire signed [DATA_WIDTH-1:0] b_in,
    input  wire [$clog2(N*P)-1:0] b_addr,
    input  wire b_wen,

    output reg [2*DATA_WIDTH-1:0] c_out,
    output reg c_valid,
    output reg done
);

    // Memories for A and B
    reg signed [DATA_WIDTH-1:0] A [0:M*N-1];
    reg signed [DATA_WIDTH-1:0] B [0:N*P-1];

    // Loop counters (give +1 bit for comparisons)
    reg [$clog2(M):0] row;
    reg [$clog2(P):0] col;
    reg [$clog2(N):0] k_count;

    // Accumulator sized to hold sum of N products
    reg signed [2*DATA_WIDTH + $clog2(N):0] accumulator;

    // FSM states
    localparam IDLE     = 0;
    localparam COMPUTE  = 1;
    localparam ACC_FINAL= 2;
    localparam OUTPUT   = 3;
    localparam DONE_ST  = 4;

    reg [2:0] state;

    // product wire (wide enough: 2*DATA_WIDTH)
    wire signed [2*DATA_WIDTH-1:0] product;
    assign product = $signed(A[row*N + k_count]) * $signed(B[k_count*P + col]);

    // write ports (synchronous)
    always @(posedge clk) begin
        if (a_wen) A[a_addr] <= a_in;
        if (b_wen) B[b_addr] <= b_in;
    end

    // Main FSM
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            row <= 0;
            col <= 0;
            k_count <= 0;
            accumulator <= 0;
            c_valid <= 0;
            done <= 0;
            c_out <= 0;
        end else begin
            
            // =======================================================
            // THE FIX:
            // Default c_valid to 0 at the start of every clock cycle.
            // It will only be asserted high if we are in the OUTPUT state.
            c_valid <= 0;
            // =======================================================

            case (state)
                IDLE: begin
                    // c_valid <= 0; // This is now handled by the default above
                    done <= 0;
                    if (start) begin
                        row <= 0;
                        col <= 0;
                        k_count <= 0;
                        accumulator <= 0;
                        state <= COMPUTE;
                    end
                end

                COMPUTE: begin
                    // c_valid is 0 (from default)
                    
                    // accumulate product (non-blocking)
                    accumulator <= accumulator + product;
                    if (k_count == N-1) begin
                        state <= ACC_FINAL;
                    end else begin
                        k_count <= k_count + 1;
                    end
                end

                ACC_FINAL: begin
                    // c_valid is 0 (from default)
                    
                    // allow last MAC to settle into accumulator
                    state <= OUTPUT;
                end

                OUTPUT: begin
                    // produce a 2*DATA_WIDTH truncated output (to match earlier behavior)
                    c_out <= accumulator[2*DATA_WIDTH-1:0];
                    
                    // Set c_valid to high ONLY for this single cycle
                    c_valid <= 1; 
                    
                    accumulator <= 0;
                    k_count <= 0;

                    if (col == P-1) begin
                        col <= 0;
                        if (row == M-1) begin
                            state <= DONE_ST;
                        end else begin
                            row <= row + 1;
                            state <= COMPUTE;
                        end
                    end else begin
                        col <= col + 1;
                        state <= COMPUTE;
                    end
                end

                DONE_ST: begin
                    // c_valid is 0 (from default)
                    done <= 1;
                    if (!start) begin
                        state <= IDLE;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule


// ===========================================================
// TESTBENCH
// (No changes needed below this line)
// ===========================================================
module tb_simple_generic_matrix_mult;

    // Parameters for this test
    parameter integer M = 3;
    parameter integer N = 3;
    parameter integer P = 3;
    parameter integer DATA_WIDTH = 8;

    // Compute address widths robustly (avoid zero-width)
    function integer clog2;
        input integer value;
        integer i;
        begin
            clog2 = 0;
            for (i = value - 1; i > 0; i = i >> 1)
                clog2 = clog2 + 1;
        end
    endfunction

    localparam AW = (M*N > 1) ? clog2(M*N) : 1;
    localparam BW = (N*P > 1) ? clog2(N*P) : 1;

    // Clock/control
    reg clk;
    reg rst;
    reg start;

    // Memory loading interface
    reg signed [DATA_WIDTH-1:0] a_in;
    reg signed [DATA_WIDTH-1:0] b_in;
    reg [AW-1:0] a_addr;
    reg [BW-1:0] b_addr;
    reg a_wen;
    reg b_wen;

    // DUT outputs
    wire [2*DATA_WIDTH-1:0] c_out;
    wire c_valid;
    wire done;

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

    // Testbench storage (sized with params)
    reg signed [DATA_WIDTH-1:0] matrix_A [0:M*N-1];
    reg signed [DATA_WIDTH-1:0] matrix_B [0:N*P-1];
    reg signed [2*DATA_WIDTH-1:0] result   [0:M*P-1];
    reg signed [2*DATA_WIDTH-1:0] expected [0:M*P-1];

    integer i, r, c, k;
    integer result_count;
    integer errors;

    // Clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // 10ns period
    end

    // Capture outputs (guard against overflow)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            result_count <= 0;
        end else begin
            if (c_valid && result_count < M*P) begin
                result[result_count] <= c_out;
                result_count <= result_count + 1;
            end
        end
    end

    // Compute expected (behavioral)
    task compute_expected;
        integer rr, cc, kk;
        reg signed [2*DATA_WIDTH + clog2(N):0] acc;
        begin
            for (rr = 0; rr < M; rr = rr + 1) begin
                for (cc = 0; cc < P; cc = cc + 1) begin
                    acc = 0;
                    for (kk = 0; kk < N; kk = kk + 1) begin
                        acc = acc + matrix_A[rr*N + kk] * matrix_B[kk*P + cc];
                    end
                    expected[rr*P + cc] = acc[2*DATA_WIDTH-1:0]; // match DUT truncation
                end
            end
        end
    endtask

    // Test sequence
    initial begin
        // Initialize
        rst = 1;
        start = 0;
        a_wen = 0;
        b_wen = 0;
        a_addr = 0;
        b_addr = 0;
        a_in = 0;
        b_in = 0;
        result_count = 0;
        errors = 0;

        // Hold reset for a few cycles
        repeat (3) @(posedge clk);
        rst = 0;
        @(posedge clk);

        // ----------------- create test matrices -----------------
        // A = identity
        for (i = 0; i < M*N; i = i + 1) begin
            if (i % (N+1) == 0) matrix_A[i] = 1;
            else matrix_A[i] = 0;
        end

        // B = sequential 1..N*P
        for (i = 0; i < N*P; i = i + 1) begin
            matrix_B[i] = i + 1;
        end

        // compute expected
        compute_expected();

        // ----------------- Load A -----------------
        a_wen = 1;
        for (i = 0; i < M*N; i = i + 1) begin
            @(posedge clk);
            a_addr <= i;
            a_in <= matrix_A[i];
        end
        @(posedge clk);
        a_wen = 0;

        // ----------------- Load B -----------------
        b_wen = 1;
        for (i = 0; i < N*P; i = i + 1) begin
            @(posedge clk);
            b_addr <= i;
            b_in <= matrix_B[i];
        end
        @(posedge clk);
        b_wen = 0;

        // ----------------- Start DUT -----------------
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;

        // Wait for DUT to finish
        wait(done);

        // Allow a few more cycles for any final c_valid pulses to be captured
        repeat (6) @(posedge clk);

        // ----------------- Display A -----------------
        $display("\nMatrix A (%0dx%0d):", M, N);
        for (r = 0; r < M; r = r + 1) begin
            for (c = 0; c < N; c = c + 1) begin
                $write("%4d ", matrix_A[r*N + c]);
            end
            $write("\n");
        end

        // ----------------- Display B -----------------
        $display("\nMatrix B (%0dx%0d):", N, P);
        for (r = 0; r < N; r = r + 1) begin
            for (c = 0; c < P; c = c + 1) begin
                $write("%4d ", matrix_B[r*P + c]);
            end
            $write("\n");
        end

        // ----------------- Display expected -----------------
        $display("\nExpected Result C (%0dx%0d):", M, P);
        for (r = 0; r < M; r = r + 1) begin
            for (c = 0; c < P; c = c + 1) begin
                $write("%6d ", expected[r*P + c]);
            end
            $write("\n");
        end

        // ----------------- Display DUT results captured -----------------
        $display("\nDUT Result C (%0dx%0d) (captured %0d values):", M, P, result_count);
        for (i = 0; i < result_count; i = i + 1) begin
            if ((i % P) == 0) $write("\n");
            $write("%6d ", result[i]);
        end
        $write("\n\n");

        // ----------------- Compare -----------------
        if (result_count != M*P) begin
            $display("ERROR: DUT produced %0d results, expected %0d", result_count, M*P);
            errors = errors + 1;
        end

        for (i = 0; i < M*P; i = i + 1) begin
            if (result[i] !== expected[i]) begin
                $display("Mismatch at idx %0d (r%0d c%0d): DUT=%0d expected=%0d", i, i/P, i%P, result[i], expected[i]);
                errors = errors + 1;
            end
        end

        if (errors == 0)
            $display(">>> TEST PASS: All %0d outputs match expected results.", M*P);
        else
            $display(">>> TEST FAIL: %0d errors found.", errors);

        $finish;
    end

endmodule

