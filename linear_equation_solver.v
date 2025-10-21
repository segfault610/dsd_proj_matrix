`timescale 1ns/1ps

module linear_equation_solver_3x3 #(
    parameter DATA_WIDTH = 16,
    parameter MAX_ITER = 40         // Increased iterations for better accuracy
)(
    input wire clk,
    input wire rst,
    input wire start,
    // Matrix A and vector b inputs
    input wire [DATA_WIDTH-1:0] a_data,
    input wire [3:0] a_addr,
    input wire a_wen,
    input wire [DATA_WIDTH-1:0] b_data,
    input wire [1:0] b_addr,
    input wire b_wen,
    // Outputs
    output reg [DATA_WIDTH-1:0] x0, x1, x2,
    output reg done
);

    // Internal storage
    reg [DATA_WIDTH-1:0] A [0:8];
    reg [DATA_WIDTH-1:0] b [0:2];
    reg [DATA_WIDTH-1:0] x [0:2];
    reg [DATA_WIDTH-1:0] x_new [0:2];

    // FSM states
    localparam IDLE = 0, LOAD = 1, ITER = 2, OUTPUT = 3, DONE = 4;
    reg [2:0] state;

    integer iter;

    // Memory write for A and b
    always @(posedge clk) begin
        if (a_wen)
            A[a_addr] <= a_data;
        if (b_wen)
            b[b_addr] <= b_data;
    end

    // Jacobi computation variables
    integer i, j;
    reg signed [2*DATA_WIDTH-1:0] sum [0:2]; // separate sums for each variable
    reg signed [2*DATA_WIDTH-1:0] num;       // Temporary variable for numerator
    reg signed [DATA_WIDTH-1:0] denom;     // Temporary variable for denominator

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            done  <= 1'b0;
            x0 <= 0; x1 <= 0; x2 <= 0;
            x[0] <= 0; x[1] <= 0; x[2] <= 0;
            x_new[0] <= 0; x_new[1] <= 0; x_new[2] <= 0;
            iter <= 0;
        end else begin
            case (state)
                // Wait for start pulse
                IDLE: begin
                    done <= 1'b0;
                    if (start) begin
                        x[0] <= 0; x[1] <= 0; x[2] <= 0;
                        iter <= 0;
                        state <= LOAD;
                    end
                end
                // Just transition: matrices are already loaded
                LOAD: begin
                    state <= ITER;
                end
                // Jacobi iteration: one update per clock cycle
                ITER: begin
                    // Compute sums for each variable. Multiplying two Q8.8 numbers (A*x) results in a Q16.16 number.
                    for (i = 0; i < 3; i = i + 1) begin
                        sum[i] = 0;
                        for (j = 0; j < 3; j = j + 1) begin
                            if (j != i)
                                sum[i] = sum[i] + $signed(A[i*3 + j]) * $signed(x[j]);
                        end
                    end
                    // Jacobi updates: (b[i] - sum) / A[i][i]
                    for (i = 0; i < 3; i = i + 1) begin
                        // To subtract, we must align the fixed points.
                        // Convert b[i] from Q8.8 to Q16.16 by shifting left 8 bits.
                        // sum[i] is already Q16.16. The result (num) is Q16.16.
                        num = ($signed(b[i]) << 8) - sum[i];
                        
                        // The denominator is the Q8.8 value of A[i][i].
                        denom = $signed(A[i*3 + i]);
                        
                        // Avoid division by zero.
                        // The division of a Q16.16 number by a Q8.8 number results in a Q8.8 number,
                        // which is the correct format for x_new.
                        if (denom != 0)
                            x_new[i] <= num / denom;
                        else
                            x_new[i] <= 0;
                    end
                    // Update for next iteration
                    x[0] <= x_new[0];
                    x[1] <= x_new[1];
                    x[2] <= x_new[2];
                    iter <= iter + 1;
                    if (iter >= MAX_ITER)
                        state <= OUTPUT;
                end
                // Output the result
                OUTPUT: begin
                    x0 <= x[0];
                    x1 <= x[1];
                    x2 <= x[2];
                    done <= 1'b1;
                    state <= DONE;
                end
                DONE: begin
                    done <= 1'b1;
                end
            endcase
        end
    end

endmodule


