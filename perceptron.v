module perceptron #(
    parameter INPUT_SIZE = 4,   // 4 inputs
    parameter OUTPUT_SIZE = 2,  // 2 outputs (binary classification)
    parameter DATA_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire start,
    
    // Input vector (e.g., 4 features)
    input wire signed [DATA_WIDTH-1:0] input_vec [0:INPUT_SIZE-1],
    
    // Weights matrix (4x2)
    input wire signed [DATA_WIDTH-1:0] weights [0:INPUT_SIZE*OUTPUT_SIZE-1],
    
    // Output (2 class scores)
    output reg signed [2*DATA_WIDTH-1:0] output_vec [0:OUTPUT_SIZE-1],
    output reg done
);

    // Instantiate matrix multiplier
    // Compute: output = weights^T × input
    // (4x2)^T × (4x1) = (2x4) × (4x1) = (2x1)
    
    simple_generic_matrix_mult #(
        .M(OUTPUT_SIZE), 
        .N(INPUT_SIZE), 
        .P(1), 
        .DATA_WIDTH(DATA_WIDTH)
    ) nn_core (
        .clk(clk), .rst(rst), .start(start),
        .a_in(weights_transposed), .a_addr(weight_addr), .a_wen(weight_wen),
        .b_in(input_vec), .b_addr(input_addr), .b_wen(input_wen),
        .c_out(output_vec), .c_valid(output_valid), .done(done)
    );
    
    // FSM to load weights and compute
    // (Implementation similar to previous examples)

endmodule

