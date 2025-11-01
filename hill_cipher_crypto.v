
// ----------------------------------------------------------
// Hill Cipher Encryption using matrix_multiplier
// Performs: C = K × P (mod 26)
// where K is 3x3 key matrix, P is 3x1 plaintext vector.
// ----------------------------------------------------------
module hill_cipher_crypto #(
    parameter BLOCK_SIZE = 3,
    parameter DATA_WIDTH = 8,      // external character width (ASCII)
    parameter MM_DWIDTH  = 16      // internal multiplier data width
)(
    input  wire clk,
    input  wire rst,
    input  wire start,
    input  wire mode,              // 0 = Encrypt (default), 1 = Decrypt (not used)

    // --- Key matrix (3x3) ---
    input  wire [DATA_WIDTH-1:0] key_data,
    input  wire [$clog2(BLOCK_SIZE*BLOCK_SIZE)-1:0] key_addr,
    input  wire key_wen,

    // --- Plaintext / Ciphertext vector (3x1) ---
    input  wire [DATA_WIDTH-1:0] text_in,
    input  wire [$clog2(BLOCK_SIZE)-1:0] text_in_addr,
    input  wire text_in_wen,

    // --- Ciphertext / Plaintext output ---
    output reg [DATA_WIDTH-1:0] text_out,
    output reg text_out_valid,
    output reg done
);

    // Internal storage
    reg [DATA_WIDTH-1:0] key_matrix  [0:BLOCK_SIZE*BLOCK_SIZE-1];
    reg [DATA_WIDTH-1:0] input_block [0:BLOCK_SIZE-1];
    reg [DATA_WIDTH-1:0] output_block[0:BLOCK_SIZE-1];

    // FSM states
    localparam IDLE   = 0,
               LOAD_A = 1,
               LOAD_B = 2,
               START_MUL = 3,
               WAIT_DONE = 4,
               OUTPUT = 5;

    reg [2:0] state;

    // Counters
    reg [3:0] a_cnt;
    reg [$clog2(BLOCK_SIZE)-1:0] b_cnt, recv_cnt, out_idx;

    // --- Matrix Multiplier Interface ---
    reg  mm_start, mm_a_wen, mm_b_wen;
    reg  [3:0] mm_a_addr;
    reg  [$clog2(BLOCK_SIZE)-1:0] mm_b_addr;
    reg  [MM_DWIDTH-1:0] mm_a_data, mm_b_data;
    wire [MM_DWIDTH-1:0] mm_c_data;
    wire mm_c_valid, mm_done;

    // Instantiate multiplier (same as in solver)
    matrix_multiplier #(
        .M1(BLOCK_SIZE), .N1(BLOCK_SIZE), .N2(1), .DATA_WIDTH(MM_DWIDTH)
    ) mm_inst (
        .clk(clk),
        .rst(rst),
        .start(mm_start),
        .mat_a_data(mm_a_data),
        .mat_a_addr(mm_a_addr),
        .mat_a_wen(mm_a_wen),
        .mat_b_data(mm_b_data),
        .mat_b_addr(mm_b_addr),
        .mat_b_wen(mm_b_wen),
        .mat_c_data(mm_c_data),
        .mat_c_valid(mm_c_valid),
        .done(mm_done)
    );

    // ----------------------------------------------------------
    // Utility functions
    // ----------------------------------------------------------
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

    function [7:0] mod26;
        input [15:0] val;
        begin
            mod26 = val % 26;
        end
    endfunction

    // ----------------------------------------------------------
    // Write interfaces for testbench
    // ----------------------------------------------------------
    always @(posedge clk) begin
        if (key_wen)
            key_matrix[key_addr] <= key_data;
        if (text_in_wen)
            input_block[text_in_addr] <= char_to_num(text_in);
    end

    // ----------------------------------------------------------
    // Main FSM
    // ----------------------------------------------------------
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            done <= 0;
            text_out_valid <= 0;
            mm_start <= 0;
            mm_a_wen <= 0;
            mm_b_wen <= 0;
            a_cnt <= 0;
            b_cnt <= 0;
            recv_cnt <= 0;
            out_idx <= 0;
        end else begin
            // default signal deassertions
            mm_start <= 0;
            mm_a_wen <= 0;
            mm_b_wen <= 0;
            text_out_valid <= 0;

            case (state)
                // -------------------------------
                IDLE: begin
                    done <= 0;
                    if (start) begin
                        a_cnt <= 0;
                        b_cnt <= 0;
                        recv_cnt <= 0;
                        out_idx <= 0;
                        state <= LOAD_A;
                    end
                end

                // -------------------------------
                LOAD_A: begin
                    // Load key matrix (3x3)
                    mm_a_wen <= 1;
                    mm_a_addr <= a_cnt;
                    mm_a_data <= key_matrix[a_cnt];
                    if (a_cnt == (BLOCK_SIZE*BLOCK_SIZE - 1)) begin
                        a_cnt <= 0;
                        state <= LOAD_B;
                    end else begin
                        a_cnt <= a_cnt + 1;
                    end
                end

                // -------------------------------
                LOAD_B: begin
                    // Load plaintext vector (3x1)
                    mm_b_wen <= 1;
                    mm_b_addr <= b_cnt;
                    mm_b_data <= input_block[b_cnt];
                    if (b_cnt == (BLOCK_SIZE - 1)) begin
                        b_cnt <= 0;
                        state <= START_MUL;
                    end else begin
                        b_cnt <= b_cnt + 1;
                    end
                end

                // -------------------------------
                START_MUL: begin
                    // Pulse start
                    mm_start <= 1;
                    recv_cnt <= 0;
                    state <= WAIT_DONE;
                end

                // -------------------------------
                WAIT_DONE: begin
                    if (mm_c_valid) begin
                        // Collect result vector (3 values)
                        output_block[recv_cnt] <= mod26(mm_c_data);
                        recv_cnt <= recv_cnt + 1;
                    end

                    if (mm_done) begin
                        recv_cnt <= 0;
                        state <= OUTPUT;
                    end
                end

                // -------------------------------
                OUTPUT: begin
                    text_out <= num_to_char(output_block[out_idx]);
                    text_out_valid <= 1;
                    if (out_idx == (BLOCK_SIZE - 1)) begin
                        done <= 1;
                        state <= IDLE;
                    end else begin
                        out_idx <= out_idx + 1;
                    end
                end

            endcase
        end
    end

endmodule

