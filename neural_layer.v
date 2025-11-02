// ============================================================================
// NEURAL LAYER MODULE - FIXED FSM LOGIC (Syntax Corrected)
// ============================================================================
`timescale 1ns/1ps

module neural_layer #(
    parameter M = 3,
    parameter N = 3,
    parameter P = 3,
    parameter DATA_WIDTH = 8
)(
    input  wire clk,
    input  wire rst_n,
    input  wire start,

    input  wire [1:0] activation_type,
    input  wire [2*DATA_WIDTH-1:0] matrix_result,
    input  wire matrix_valid,

    input  wire signed [DATA_WIDTH-1:0] bias_in,
    input  wire bias_wen,
    input  wire [$clog2(M)-1:0] bias_addr,

    output reg  [2*DATA_WIDTH-1:0] app_result,
    output reg  app_valid,
    output reg  app_done
);

    // ------------------------------------------------------------------------
    // Bias Memory
    // ------------------------------------------------------------------------
    reg signed [DATA_WIDTH-1:0] bias_mem [0:M-1];

    integer i;
    initial begin
        for (i = 0; i < M; i = i + 1)
            bias_mem[i] = 0;
    end

    always @(posedge clk) begin
        if (bias_wen)
            bias_mem[bias_addr] <= bias_in;
    end

    // ------------------------------------------------------------------------
    // FSM States
    // ------------------------------------------------------------------------
    localparam [1:0] IDLE     = 2'd0;
    localparam [1:0] WAIT_MAT = 2'd1;
    localparam [1:0] PROCESS  = 2'd2;
    localparam [1:0] OUTPUT   = 2'd3;

    reg [1:0] state;
    reg [2*DATA_WIDTH-1:0] temp_result;
    reg [$clog2(M)-1:0] current_idx;

    // ------------------------------------------------------------------------
    // Activation Functions
    // ------------------------------------------------------------------------
    function automatic [2*DATA_WIDTH-1:0] activate_relu;
        input [2*DATA_WIDTH-1:0] x;
        begin
            if (x[2*DATA_WIDTH-1])
                activate_relu = {2*DATA_WIDTH{1'b0}};
            else
                activate_relu = x;
        end
    endfunction

    function automatic [2*DATA_WIDTH-1:0] activate_linear;
        input [2*DATA_WIDTH-1:0] x;
        begin
            activate_linear = x;
        end
    endfunction

    function automatic [2*DATA_WIDTH-1:0] apply_activation;
        input [2*DATA_WIDTH-1:0] x;
        input [1:0] act_type;
        begin
            case (act_type)
                2'b00: apply_activation = activate_relu(x);
                2'b01: apply_activation = activate_relu(x);
                2'b10: apply_activation = activate_linear(x);
                default: apply_activation = activate_linear(x);
            endcase
        end
    endfunction

    // ------------------------------------------------------------------------
    // FSM
    // ------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state       <= IDLE;
            app_result  <= 0;
            app_valid   <= 0;
            app_done    <= 0;
            temp_result <= 0;
            current_idx <= 0;
        end
        else begin
            app_valid <= 0;

            case (state)
                // =============================================================
                IDLE: begin
                    app_done <= 0;
                    if (start) begin
                        state       <= WAIT_MAT;
                        current_idx <= 0;
                        $display("[NEURAL] State: IDLE -> WAIT_MAT");
                    end
                end

                // =============================================================
                WAIT_MAT: begin
                    if (matrix_valid) begin
                        temp_result <= matrix_result;
                        state       <= PROCESS;
                        $display("[NEURAL] Received matrix_result = %h", matrix_result);
                        $display("[NEURAL] State: WAIT_MAT -> PROCESS");
                    end
                end

                // =============================================================
                PROCESS: begin
                    // Add bias for current neuron
                    temp_result <= temp_result + $signed(bias_mem[current_idx]);

                    // Apply activation
                    app_result <= apply_activation(temp_result + $signed(bias_mem[current_idx]), activation_type);

                    state <= OUTPUT;
                    $display("[NEURAL] Applied activation, bias[%0d] = %d", current_idx, $signed(bias_mem[current_idx]));
                    $display("[NEURAL] State: PROCESS -> OUTPUT");
                end

                // =============================================================
                OUTPUT: begin
                    app_valid <= 1;
                    app_done  <= 1;
                    $display("[NEURAL] Output: app_result = %h (%d)", app_result, $signed(app_result));
                    state <= IDLE;
                    $display("[NEURAL] State: OUTPUT -> IDLE");
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule

