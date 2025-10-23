`timescale 1ns/1ps

module hill_cipher_crypto #(
    parameter BLOCK_SIZE = 3,
    parameter DATA_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire start,
    input wire mode,

    input wire [DATA_WIDTH-1:0] key_data,
    input wire [$clog2(BLOCK_SIZE*BLOCK_SIZE)-1:0] key_addr,
    input wire key_wen,

    input wire [DATA_WIDTH-1:0] text_in,
    input wire [$clog2(BLOCK_SIZE)-1:0] text_in_addr,
    input wire text_in_wen,

    output reg [DATA_WIDTH-1:0] text_out,
    output reg text_out_valid,
    output reg done
);

    reg [DATA_WIDTH-1:0] key_matrix [0:BLOCK_SIZE*BLOCK_SIZE-1];
    reg [DATA_WIDTH-1:0] input_block [0:BLOCK_SIZE-1];
    reg [DATA_WIDTH-1:0] output_block [0:BLOCK_SIZE-1];

    localparam IDLE = 0, COMPUTE = 1, OUTPUT = 2;
    reg [1:0] state;

    reg [$clog2(BLOCK_SIZE)-1:0] i, j;
    reg [15:0] accumulator;
    reg [$clog2(BLOCK_SIZE)-1:0] output_counter;

    function [7:0] char_to_num;
        input [7:0] ch;
        begin
            if (ch >= "A" && ch <= "Z")      char_to_num = ch - "A";
            else if (ch >= "a" && ch <= "z") char_to_num = ch - "a";
            else                             char_to_num = 0;
        end
    endfunction

    function [7:0] num_to_char;
        input [7:0] num;
        begin
            num_to_char = (num % 26) + "A";
        end
    endfunction

    always @(posedge clk) begin
        if (key_wen)
            key_matrix[key_addr] <= key_data;
        if (text_in_wen)
            input_block[text_in_addr] <= char_to_num(text_in);
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            i <= 0; j <= 0;
            accumulator <= 0;
            text_out_valid <= 0;
            done <= 0;
            output_counter <= 0;
        end else begin
            case (state)
                IDLE: begin
                    text_out_valid <= 0;
                    done <= 0;
                    if (start) begin
                        state <= COMPUTE;
                        i <= 0;
                        j <= 0;
                        accumulator <= 0;
                    end
                end

                COMPUTE: begin
                    if (i < BLOCK_SIZE) begin
                        if (j < BLOCK_SIZE) begin
                            accumulator <= accumulator + 
                                          (key_matrix[i*BLOCK_SIZE + j] * input_block[j]);
                            j <= j + 1;
                        end else begin
                            output_block[i] <= (accumulator % 26);
                            accumulator <= 0;
                            j <= 0;
                            i <= i + 1;
                        end
                    end else begin
                        state <= OUTPUT;
                        output_counter <= 0;
                    end
                end

                OUTPUT: begin
                    text_out <= num_to_char(output_block[output_counter]);
                    text_out_valid <= 1;

                    if (output_counter == BLOCK_SIZE - 1) begin
                        done <= 1;
                        state <= IDLE;
                    end else begin
                        output_counter <= output_counter + 1;
                    end
                end
            endcase
        end
    end

endmodule
