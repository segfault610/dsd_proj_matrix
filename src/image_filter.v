// image_filter_fixed.v
// 3x3 convolution controller (receives matrix_result externally)

module image_filter #(
    parameter M = 3,
    parameter N = 3,
    parameter P = 1,
    parameter DATA_WIDTH = 8
)(
    input  wire                       clk,
    input  wire                       rst_n,
    input  wire                       start,

    input  wire signed [DATA_WIDTH-1:0] kernel_in,
    input  wire [$clog2(M*N)-1:0]      kernel_addr,
    input  wire                       kernel_wen,

    input  wire signed [DATA_WIDTH-1:0] pixel_in,
    input  wire                       pixel_valid,

    input  wire [2*DATA_WIDTH-1:0]    matrix_result,
    input  wire                       matrix_valid,

    output reg [2*DATA_WIDTH-1:0]    filter_out,
    output reg                       filter_valid,
    output reg                       filter_done
);

    // Kernel memory 3x3 (M*N)
    reg signed [DATA_WIDTH-1:0] kernel_mem [0:M*N-1];

    // 3 line buffers (each holds 3 pixels)
    reg signed [DATA_WIDTH-1:0] line0 [0:2];
    reg signed [DATA_WIDTH-1:0] line1 [0:2];
    reg signed [DATA_WIDTH-1:0] line2 [0:2];

    localparam [2:0] IDLE         = 3'd0;
    localparam [2:0] FILL_BUFFERS = 3'd1;
    localparam [2:0] CONVOLVE     = 3'd2;
    localparam [2:0] WAIT_RESULT  = 3'd3;
    localparam [2:0] OUTPUT       = 3'd4;

    reg [2:0] state;
    reg [9:0] pixel_counter;

    integer i;

    // ===== KERNEL INITIALIZATION - example: Sobel X =====
    initial begin
        // Default Sobel-X
        kernel_mem[0] = -8'sd1; kernel_mem[1] =  8'sd0; kernel_mem[2] =  8'sd1;
        kernel_mem[3] = -8'sd2; kernel_mem[4] =  8'sd0; kernel_mem[5] =  8'sd2;
        kernel_mem[6] = -8'sd1; kernel_mem[7] =  8'sd0; kernel_mem[8] =  8'sd1;
    end

    // ===== KERNEL MEMORY WRITE =====
    always @(posedge clk) begin
        if (kernel_wen) begin
            kernel_mem[kernel_addr] <= kernel_in;
        end
    end

    // ===== FSM =====
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            filter_out <= { (2*DATA_WIDTH){1'b0} };
            filter_valid <= 1'b0;
            filter_done <= 1'b0;
            pixel_counter <= 0;
            for (i = 0; i < 3; i = i + 1) begin
                line0[i] <= 0;
                line1[i] <= 0;
                line2[i] <= 0;
            end
        end
        else begin
            // default de-assert
            filter_valid <= 1'b0;

            case (state)
                IDLE: begin
                    filter_done <= 1'b0;
                    pixel_counter <= 0;
                    if (start) begin
                        state <= FILL_BUFFERS;
                    end
                end

                FILL_BUFFERS: begin
                    if (pixel_valid) begin
                        // shift each line to left (index 0 is left-most older)
                        // We want to push new pixel into rightmost position [2]
                        // shift elements: [0]<=[1], [1]<=[2], [2]<=new
                        line2[0] <= line2[1];
                        line2[1] <= line2[2];
                        line2[2] <= line1[2]; // bring previous line1 rightmost down

                        line1[0] <= line1[1];
                        line1[1] <= line1[2];
                        line1[2] <= line0[2];

                        line0[0] <= line0[1];
                        line0[1] <= line0[2];
                        line0[2] <= pixel_in;

                        pixel_counter <= pixel_counter + 1;

                        // After 9 pixels (0..8) we have a full 3x3 available
                        if (pixel_counter == 10'd8) begin
                            state <= CONVOLVE;
                        end
                    end
                end

                CONVOLVE: begin
                    // In this design the actual multiply-accumulate is done elsewhere;
                    // we simply wait for matrix_result to appear.
                    state <= WAIT_RESULT;
                end

                WAIT_RESULT: begin
                    if (matrix_valid) begin
                        filter_out <= matrix_result;
                        filter_valid <= 1'b1;
                        state <= OUTPUT;
                    end
                end

                OUTPUT: begin
                    filter_done <= 1'b1;
                    state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule

