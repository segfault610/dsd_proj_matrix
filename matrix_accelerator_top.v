
// ============================================================================
// COMPLETE TOP MODULE - INTEGRATES EVERYTHING
// ============================================================================

module matrix_accelerator_top #(
    parameter M = 3,
    parameter N = 3,
    parameter P = 3,
    parameter DATA_WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire [1:0] app_select,
    input wire [DATA_WIDTH-1:0] a_data_in,
    input wire [$clog2(M*N)-1:0] a_addr,
    input wire a_wen,
    input wire [DATA_WIDTH-1:0] b_data_in,
    input wire [$clog2(N*P)-1:0] b_addr,
    input wire b_wen,
    input wire start_computation,
    output reg computation_done,
    output wire [2*DATA_WIDTH-1:0] result_out,
    output wire result_valid
);

    wire mm_start, mm_done;
    wire [2*DATA_WIDTH-1:0] mm_result;
    wire mm_result_valid;
    
    wire [2*DATA_WIDTH-1:0] app_result;
    wire app_valid, app_done;
    
    // Core multiplier
    matrix_mult_core #(M, N, P, DATA_WIDTH) core (
        .clk(clk),
        .rst(~rst_n),
        .start(mm_start),
        .a_in(a_data_in),
        .a_addr(a_addr),
        .a_wen(a_wen),
        .b_in(b_data_in),
        .b_addr(b_addr),
        .b_wen(b_wen),
        .c_out(mm_result),
        .c_valid(mm_result_valid),
        .done(mm_done)
    );
    
    // Applications
    neural_layer nn (
        .clk(clk), .rst_n(rst_n), .start(mm_start),
        .activation_type(2'b00),
        .matrix_result(mm_result), .matrix_valid(mm_result_valid),
        .bias_in(8'd0), .bias_wen(0), .bias_addr(0),
        .app_result(app_result), .app_valid(app_valid), .app_done(app_done)
    );
    
    image_filter filt (
        .clk(clk), .rst_n(rst_n), .start(mm_start),
        .kernel_in(8'd0), .kernel_addr(0), .kernel_wen(0),
        .pixel_in(8'd0), .pixel_valid(0),
        .matrix_result(mm_result), .matrix_valid(mm_result_valid),
        .filter_out(app_result), .filter_valid(app_valid), .filter_done(app_done)
    );
    
    matrix_transform trans (
        .clk(clk), .rst_n(rst_n), .start(mm_start),
        .x_in(8'd0), .y_in(8'd0),
        .transform_type(2'b00), .param1(8'd0), .param2(8'd0),
        .matrix_result(mm_result), .matrix_valid(mm_result_valid),
        .x_out(), .y_out(), .combined_out(app_result),
        .transform_valid(app_valid), .transform_done(app_done)
    );
    
    // Control
    reg [1:0] state;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= 0;
            computation_done <= 0;
        end else begin
            case (state)
                0: begin
                    computation_done <= 0;
                    if (start_computation) begin
                        state <= 1;
                    end
                end
                1: begin
                    if (app_done || mm_done) begin
                        computation_done <= 1;
                        state <= 0;
                    end
                end
            endcase
        end
    end
    
    assign mm_start = start_computation;
    assign result_out = (app_select < 3) ? app_result : mm_result;
    assign result_valid = (app_select < 3) ? app_valid : mm_result_valid;

endmodule
