
// =========================================
// SIMPLE GENERIC MATRIX MULTIPLIER (DUT)
// =========================================
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

    reg signed [DATA_WIDTH-1:0] A [0:M*N-1];
    reg signed [DATA_WIDTH-1:0] B [0:N*P-1];
    reg [$clog2(M):0] row;
    reg [$clog2(P):0] col;
    reg [$clog2(N):0] k_count;
    reg signed [2*DATA_WIDTH + $clog2(N):0] accumulator;

    localparam IDLE     = 0;
    localparam COMPUTE  = 1;
    localparam ACC_FINAL= 2;
    localparam OUTPUT   = 3;
    localparam DONE_ST  = 4;
    reg [2:0] state;

    wire signed [2*DATA_WIDTH-1:0] product;
    assign product = $signed(A[row*N + k_count]) * $signed(B[k_count*P + col]);

    always @(posedge clk) begin
        if (a_wen) A[a_addr] <= a_in;
        if (b_wen) B[b_addr] <= b_in;
    end

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
            c_valid <= 0;
            case (state)
                IDLE: begin
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
                    accumulator <= accumulator + product;
                    if (k_count == N-1) state <= ACC_FINAL;
                    else k_count <= k_count + 1;
                end
                ACC_FINAL: state <= OUTPUT;
                OUTPUT: begin
                    c_out <= accumulator[2*DATA_WIDTH-1:0];
                    c_valid <= 1;
                    accumulator <= 0;
                    k_count <= 0;
                    if (col == P-1) begin
                        col <= 0;
                        if (row == M-1) state <= DONE_ST;
                        else begin
                            row <= row + 1;
                            state <= COMPUTE;
                        end
                    end else begin
                        col <= col + 1;
                        state <= COMPUTE;
                    end
                end
                DONE_ST: begin
                    done <= 1;
                    if (!start) state <= IDLE;
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule
