// ============================================================================
// NEURAL LAYER MODULE - Single Layer Perceptron with ReLU Activation
// ============================================================================

module neural_layer #(
    parameter M = 3,
    parameter N = 3,
    parameter P = 3,
    parameter DATA_WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire start,
    
    input wire [1:0] activation_type,
    input wire [2*DATA_WIDTH-1:0] matrix_result,
    input wire matrix_valid,
    input wire signed [DATA_WIDTH-1:0] bias_in,
    input wire bias_wen,
    input wire [$clog2(M)-1:0] bias_addr,
    
    output reg [2*DATA_WIDTH-1:0] app_result,
    output reg app_valid,
    output reg app_done
);

    reg signed [DATA_WIDTH-1:0] bias_mem [0:M-1];
    
    localparam [2:0] IDLE           = 3'd0;
    localparam [2:0] WAIT_MATRIX    = 3'd1;
    localparam [2:0] ADD_BIAS       = 3'd2;
    localparam [2:0] APPLY_ACTIVATION = 3'd3;
    localparam [2:0] OUTPUT_RESULT  = 3'd4;
    
    reg [2:0] state;
    reg [2*DATA_WIDTH-1:0] biased_result;
    reg [2*DATA_WIDTH-1:0] activated_result;
    reg [$clog2(M):0] neuron_idx;
    
    // ===== BIAS MEMORY WRITE =====
    always @(posedge clk) begin
        if (bias_wen) begin
            bias_mem[bias_addr] <= bias_in;
        end
    end
    
    // ===== ACTIVATION FUNCTIONS (COMBINATIONAL) =====
    // ReLU: max(0, x)
    function [2*DATA_WIDTH-1:0] activate_relu;
        input [2*DATA_WIDTH-1:0] x;
        begin
            if (x[2*DATA_WIDTH-1] == 1'b1)
                activate_relu = {2*DATA_WIDTH{1'b0}};
            else
                activate_relu = x;
        end
    endfunction
    
    // Linear: return as-is
    function [2*DATA_WIDTH-1:0] activate_linear;
        input [2*DATA_WIDTH-1:0] x;
        begin
            activate_linear = x;
        end
    endfunction
    
    // Apply activation based on type
    function [2*DATA_WIDTH-1:0] apply_activation;
        input [2*DATA_WIDTH-1:0] x;
        input [1:0] act_type;
        begin
            case (act_type)
                2'b00: apply_activation = activate_relu(x);
                2'b10: apply_activation = activate_linear(x);
                default: apply_activation = activate_relu(x);
            endcase
        end
    endfunction
    
    // ===== FSM =====
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            app_result <= 0;
            app_valid <= 0;
            app_done <= 0;
            neuron_idx <= 0;
            biased_result <= 0;
            activated_result <= 0;
        end
        else begin
            app_valid <= 0;
            
            case (state)
                IDLE: begin
                    app_done <= 1'b0;
                    neuron_idx <= 0;
                    if (start) begin
                        state <= WAIT_MATRIX;
                    end
                end
                
                WAIT_MATRIX: begin
                    if (matrix_valid) begin
                        biased_result <= matrix_result + $signed(bias_mem[neuron_idx]);
                        state <= APPLY_ACTIVATION;
                    end
                end
                
                APPLY_ACTIVATION: begin
                    activated_result <= apply_activation(biased_result, activation_type);
                    state <= OUTPUT_RESULT;
                end
                
                OUTPUT_RESULT: begin
                    app_result <= activated_result;
                    app_valid <= 1'b1;
                    app_done <= 1'b1;
                    state <= IDLE;
                end
                
                default: state <= IDLE;
            endcase
        end
    end

endmodule

