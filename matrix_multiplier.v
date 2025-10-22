`timescale 1ns/1ps

module linear_equation_solver_3x3 #(
    parameter DATA_WIDTH = 16,
    parameter MAX_ITER = 40  // Adjust as needed for required convergence
)(
    input wire clk,
    input wire rst,
    input wire start,

    // Matrix A and input vector b load interface
    input wire [DATA_WIDTH-1:0] a_data,
    input wire [3:0] a_addr,
    input wire a_wen,
    input wire [DATA_WIDTH-1:0] b_data,
    input wire [1:0] b_addr,
    input wire b_wen,

    // Solution output
    output reg [DATA_WIDTH-1:0] x0, x1, x2,
    output reg done
);

    // Internal registers and storage
    reg [DATA_WIDTH-1:0] A [0:8];
    reg [DATA_WIDTH-1:0] b [0:2];
    reg [DATA_WIDTH-1:0] x [0:2];
    reg [DATA_WIDTH-1:0] x_new [0:2];

    integer iter; // CORRECTED: Was reg[1:0], which is too small for MAX_ITER
    reg [2:0] state;
    localparam S_IDLE=0, S_LOAD=1, S_MVMUL=2, S_UPDATE=3, S_OUTPUT=4, S_DONE=5;

    // For matrix-vector multiply (Note: This logic appears unused by S_UPDATE)
    reg matmul_start;
    reg [DATA_WIDTH-1:0] mat_a_data, mat_b_data;
    reg [3:0] mat_a_addr, mat_b_addr;
    reg mat_a_wen, mat_b_wen;

    wire [DATA_WIDTH-1:0] mat_c_data;
    wire mat_c_valid;
    wire matmul_done;

    // Control for matrix-vector load
    reg [3:0] load_cnt;
    reg [1:0] updating_idx; // This reg is set but not used in S_UPDATE logic

    // Jacobi calculation variables
    integer i, j; // ADDED: For loops
    reg signed [2*DATA_WIDTH-1:0] sum;   // MOVED: From inside loop
    reg signed [2*DATA_WIDTH-1:0] num;   // MOVED: From inside loop
    reg signed [DATA_WIDTH-1:0] denom; // MOVED: From inside loop

    // Instance: 3x3 * 3x1 matrix-vector multiplication
    matrix_multiplier #(
        .M1(3), .N1(3), .N2(1), .DATA_WIDTH(DATA_WIDTH)
    ) matmul (
        .clk(clk), .rst(rst), .start(matmul_start),
        .mat_a_data(mat_a_data), .mat_a_addr(mat_a_addr), .mat_a_wen(mat_a_wen),
        .mat_b_data(mat_b_data), .mat_b_addr(mat_b_addr), .mat_b_wen(mat_b_wen),
        .mat_c_data(mat_c_data), .mat_c_valid(mat_c_valid), .done(matmul_done)
    );

    // Always block for outer FSM
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_IDLE;
            load_cnt <= 0;
            updating_idx <= 0;
            matmul_start <= 0; mat_a_wen <= 0; mat_b_wen <= 0;
            iter <= 0; done <= 0;
            x0 <= 0; x1 <= 0; x2 <= 0;
            x[0]<=0; x[1]<=0; x[2]<=0;
        end else begin
            case (state)
                S_IDLE: begin
                    done <= 0;
                    if (start) begin
                        x[0]<=0; x[1]<=0; x[2]<=0;
                        iter <= 0;
                        state <= S_LOAD;
                    end
                end
                S_LOAD: begin
                    // Wait for testbench to load A and b before starting
                    // This state now loads A and x into the matmul instance
                    if (~a_wen && ~b_wen) begin
                        mat_a_wen <= 1; mat_b_wen <= 1;
                        // Send A matrix to multiplier
                        if (load_cnt < 9) begin
                            mat_a_addr <= load_cnt;
                            mat_a_data <= A[load_cnt];
                        end else mat_a_wen <= 0;
                        // Send current x vector as column vector to multiplier
                        if (load_cnt < 3) begin
                            mat_b_addr <= load_cnt;
                            mat_b_data <= x[load_cnt];
                        end else mat_b_wen <= 0;
                        load_cnt <= load_cnt + 1;
                        if (load_cnt == 9) begin
                            mat_a_wen <= 0;
                            mat_b_wen <= 0;
                            load_cnt <= 0;
                            state <= S_MVMUL;
                            matmul_start <= 1;
                        end
                    end
                end
                S_MVMUL: begin
                    matmul_start <= 0;
                    if (matmul_done) begin
                        updating_idx <= 0; // This is set but not used
                        state <= S_UPDATE;
                    end
                end
                S_UPDATE: begin
                    // For each x_new[i]: x_new[i] = (b[i] - sum_{j!=i} A[i][j]*x[j]) / A[i][i]
                    // This calculation is done locally and does not use the matmul result.
                    
                    // CORRECTED: Use 'i' as loop variable
                    for (i = 0; i < 3; i = i + 1) begin
                        sum = 0;
                        // CORRECTED: Use 'j' as loop variable
                        for (j = 0; j < 3; j = j + 1) begin
                            if (j != i)
                                // CORRECTED: Use 'i' and 'j'
                                sum = sum + $signed(A[i*3+j]) * $signed(x[j]);
                        end
                        
                        // CORRECTED: Fixed-point math
                        num = ($signed(b[i]) << 8) - sum;
                        denom = $signed(A[i*3+i]);
                        
                        // CORRECTED: Use 'i'
                        x_new[i] <= (denom != 0) ? (num / denom) : 0;
                    end
                    
                    // Propagate for next iteration or finish
                    x[0] <= x_new[0];
                    x[1] <= x_new[1];
                    x[2] <= x_new[2];
                    iter <= iter + 1;
                    if (iter >= MAX_ITER)
                        state <= S_OUTPUT;
                    else
                        state <= S_LOAD; // This FSM reloads the multiplier every time
                end
                S_OUTPUT: begin
                    x0 <= x[0];
                    x1 <= x[1];
                    x2 <= x[2];
                    done <= 1;
                    state <= S_DONE;
                end
                S_DONE: begin
                    done <= 1;
                end
            endcase
        end
    end

    // Allow memory writes from testbench
    always @(posedge clk) begin
        if (a_wen)
            A[a_addr] <= a_data;
        if (b_wen)
            b[b_addr] <= b_data;
    end

endmodule

