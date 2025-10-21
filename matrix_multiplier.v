`timescale 1ns/1ps

module matrix_multiplier #(
    parameter M1 = 3,
    parameter N1 = 3,
    parameter N2 = 3,
    parameter DATA_WIDTH = 16
)(
    input wire clk,
    input wire rst,
    input wire start,

    input wire [DATA_WIDTH-1:0] mat_a_data,
    input wire [$clog2(M1*N1)-1:0] mat_a_addr,
    input wire mat_a_wen,

    input wire [DATA_WIDTH-1:0] mat_b_data,
    input wire [$clog2(N1*N2)-1:0] mat_b_addr,
    input wire mat_b_wen,

    output reg [DATA_WIDTH-1:0] mat_c_data,
    output reg mat_c_valid,
    output reg done
);

    reg [DATA_WIDTH-1:0] matrix_a [0:M1*N1-1];
    reg [DATA_WIDTH-1:0] matrix_b [0:N1*N2-1];

    reg [$clog2(M1)-1:0] i;
    reg [$clog2(N2)-1:0] j;
    reg [$clog2(N1)-1:0] k;

    reg [2*DATA_WIDTH-1:0] accumulator;

    localparam S_IDLE = 0, S_CALC = 1, S_OUTPUT = 2, S_NEXT = 3, S_DONE = 4;
    reg [2:0] state;

    always @(posedge clk) begin
        if (mat_a_wen)
            matrix_a[mat_a_addr] <= mat_a_data;
        if (mat_b_wen)
            matrix_b[mat_b_addr] <= mat_b_data;
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= S_IDLE;
            mat_c_data <= 0;
            mat_c_valid <= 0;
            done <= 0;
            i <= 0; j <= 0; k <= 0;
            accumulator <= 0;
        end else begin
            case (state)
                S_IDLE: begin
                    mat_c_valid <= 0;
                    done <= 0;
                    if (start) begin
                        i <= 0; j <= 0; k <= 0;
                        accumulator <= 0;
                        state <= S_CALC;
                    end
                end
                S_CALC: begin
                    // Accumulate: acc += A[i*N1+k] * B[k*N2+j] in Q8.8
                    accumulator <= accumulator + $signed(matrix_a[i*N1 + k]) * $signed(matrix_b[k*N2 + j]);
                    if (k == N1-1) begin
                        state <= S_OUTPUT;
                    end else begin
                        k <= k + 1;
                    end
                end
                S_OUTPUT: begin
                    mat_c_data <= accumulator >>> 8;
                    mat_c_valid <= 1;
                    accumulator <= 0;
                    k <= 0;
                    state <= S_NEXT;
                end
                S_NEXT: begin
                    mat_c_valid <= 0;
                    if (j < N2-1) begin
                        j <= j + 1;
                        state <= S_CALC;
                    end else begin
                        j <= 0;
                        if (i < M1-1) begin
                            i <= i + 1;
                            state <= S_CALC;
                        end else begin
                            state <= S_DONE;
                        end
                    end
                end
                S_DONE: begin
                    done <= 1;
                    mat_c_valid <= 0;
                    if (!start)
                        state <= S_IDLE;
                end
            endcase
        end
    end

endmodule

