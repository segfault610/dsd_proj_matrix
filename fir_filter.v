module fir_filter #(
    parameter TAPS = 8,          // Number of filter taps
    parameter DATA_WIDTH = 16    // 16-bit samples
)(
    input wire clk,
    input wire rst,
    input wire signed [DATA_WIDTH-1:0] sample_in,
    input wire sample_valid,
    
    // Filter coefficients (pre-loaded)
    input wire signed [DATA_WIDTH-1:0] coeffs [0:TAPS-1],
    
    output reg signed [2*DATA_WIDTH-1:0] filtered_out,
    output reg output_valid
);

    // Shift register for samples (TAPS deep)
    reg signed [DATA_WIDTH-1:0] sample_buffer [0:TAPS-1];
    
    integer i;
    
    // Matrix formulation: output = coeffs × samples
    // Use matrix multiplier: (1×TAPS) × (TAPS×1) = (1×1)
    
    simple_generic_matrix_mult #(
        .M(1), .N(TAPS), .P(1), .DATA_WIDTH(DATA_WIDTH)
    ) fir_core (
        .clk(clk), .rst(rst), .start(compute_start),
        .a_in(coeffs), .a_addr(coeff_addr), .a_wen(coeff_wen),
        .b_in(sample_buffer), .b_addr(sample_addr), .b_wen(sample_wen),
        .c_out(filtered_out), .c_valid(output_valid), .done(compute_done)
    );
    
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < TAPS; i = i + 1)
                sample_buffer[i] <= 0;
        end
        else if (sample_valid) begin
            // Shift samples through buffer
            for (i = TAPS-1; i > 0; i = i - 1)
                sample_buffer[i] <= sample_buffer[i-1];
            sample_buffer <= sample_in;
            
            compute_start <= 1;  // Trigger matrix multiply
        end
    end

endmodule

