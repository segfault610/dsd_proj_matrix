// ============================================================================
// IMAGE FILTER MODULE - 3x3 Convolution (Sobel Edge Detection)
// ============================================================================
// Uses: Shift registers (line buffers), 3x3 sliding window, FSM control
// Demonstrates: Module 5 (Sequential - shift registers, registers)
//               Module 6 (FSM - pixel scanning)
// ============================================================================

module image_filter #(
    parameter M = 3,              // Kernel height
    parameter N = 3,              // Kernel width  
    parameter P = 1,              // Output channels
    parameter DATA_WIDTH = 8      // 8-bit pixel values
)(
    input wire clk,
    input wire rst_n,
    input wire start,
    
    // Kernel coefficients (e.g., Sobel operator)
    input wire signed [DATA_WIDTH-1:0] kernel_in,
    input wire [$clog2(M*N)-1:0] kernel_addr,
    input wire kernel_wen,
    
    // Input pixel stream
    input wire signed [DATA_WIDTH-1:0] pixel_in,
    input wire pixel_valid,
    
    // From matrix multiplier core (convolution result)
    input wire [2*DATA_WIDTH-1:0] matrix_result,
    input wire matrix_valid,
    
    // Output
    output reg [2*DATA_WIDTH-1:0] filter_out,
    output reg filter_valid,
    output reg filter_done
);

    // =========================================================================
    // KERNEL MEMORY (Sequential - Module 5)
    // =========================================================================
    
    reg signed [DATA_WIDTH-1:0] kernel_mem [0:M*N-1];
    
    // Sobel X operator (pre-loaded)
    initial begin
        kernel_mem = -8'sd1;  kernel_mem = 8'sd0;  kernel_mem = 8'sd1;
        kernel_mem = -8'sd2;  kernel_mem = 8'sd0;  kernel_mem = 8'sd2;
        kernel_mem = -8'sd1;  kernel_mem = 8'sd0;  kernel_mem = 8'sd1;
    end
    
    // =========================================================================
    // LINE BUFFERS - Sliding Window (Shift Registers - Module 5)
    // =========================================================================
    // Store 3 lines of pixels for 3x3 convolution
    // Each line has 3 pixels (for 3x3 kernel)
    
    reg signed [DATA_WIDTH-1:0] line0 [0:2];  // Top row
    reg signed [DATA_WIDTH-1:0] line1 [0:2];  // Middle row
    reg signed [DATA_WIDTH-1:0] line2 [0:2];  // Bottom row
    
    // =========================================================================
    // STATE MACHINE (FSM - Module 6)
    // =========================================================================
    
    localparam [2:0] IDLE          = 3'd0;
    localparam [2:0] LOAD_KERNEL   = 3'd1;
    localparam [2:0] FILL_BUFFERS  = 3'd2;
    localparam [2:0] SHIFT_WINDOW  = 3'd3;
    localparam [2:0] CONVOLVE      = 3'd4;
    localparam [2:0] WAIT_RESULT   = 3'd5;
    localparam [2:0] OUTPUT        = 3'd6;
    
    reg [2:0] state;
    reg [9:0] pixel_counter;
    reg [2:0] kernel_load_idx;
    
    // =========================================================================
    // KERNEL MEMORY WRITE
    // =========================================================================
    
    always @(posedge clk) begin
        if (kernel_wen) begin
            kernel_mem[kernel_addr] <= kernel_in;
        end
    end
    
    // =========================================================================
    // SHIFT REGISTER UPDATES (Combinational connections for next cycle)
    // =========================================================================
    
    wire signed [DATA_WIDTH-1:0] shifted_line0_0, shifted_line0_1, shifted_line0_2;
    wire signed [DATA_WIDTH-1:0] shifted_line1_0, shifted_line1_1, shifted_line1_2;
    wire signed [DATA_WIDTH-1:0] shifted_line2_0, shifted_line2_1, shifted_line2_2;
    
    // Shift left: position 2 gets position 1, position 1 gets position 0, position 0 gets new pixel
    assign shifted_line0_0 = pixel_in;
    assign shifted_line0_1 = line0;
    assign shifted_line0_2 = line0;
    
    assign shifted_line1_0 = line0;
    assign shifted_line1_1 = line1;
    assign shifted_line1_2 = line1;
    
    assign shifted_line2_0 = line1;
    assign shifted_line2_1 = line2;
    assign shifted_line2_2 = line2;
    
    // =========================================================================
    // FSM - STATE TRANSITIONS (Sequential - Module 5)
    // =========================================================================
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            filter_out <= 0;
            filter_valid <= 0;
            filter_done <= 0;
            pixel_counter <= 0;
            kernel_load_idx <= 0;
            
            // Clear line buffers
            for (int i = 0; i < 3; i = i + 1) begin
                line0[i] <= 0;
                line1[i] <= 0;
                line2[i] <= 0;
            end
        end
        else begin
            filter_valid <= 0;
            
            case (state)
                // =========================================================
                // IDLE: Waiting for start
                // =========================================================
                IDLE: begin
                    filter_done <= 1'b0;
                    pixel_counter <= 0;
                    if (start) begin
                        state <= FILL_BUFFERS;
                    end
                end
                
                // =========================================================
                // FILL_BUFFERS: Load first 9 pixels into shift registers
                // =========================================================
                FILL_BUFFERS: begin
                    if (pixel_valid) begin
                        pixel_counter <= pixel_counter + 1;
                        
                        // Shift all pixels
                        line0 <= shifted_line0_0;
                        line0 <= shifted_line0_1;
                        line0 <= shifted_line0_2;
                        
                        line1 <= shifted_line1_0;
                        line1 <= shifted_line1_1;
                        line1 <= shifted_line1_2;
                        
                        line2 <= shifted_line2_0;
                        line2 <= shifted_line2_1;
                        line2 <= shifted_line2_2;
                        
                        // After 9 pixels, start convolution
                        if (pixel_counter == 10'd8) begin
                            state <= CONVOLVE;
                        end
                    end
                end
                
                // =========================================================
                // CONVOLVE: Apply 3x3 convolution (matrix multiply with kernel)
                // The core will compute: kernel . image_patch
                // This state just triggers the computation
                // =========================================================
                CONVOLVE: begin
                    // Matrix multiplier core now computes convolution
                    // core: (1x9) kernel × (9x1) patch = (1x1) result
                    state <= WAIT_RESULT;
                end
                
                // =========================================================
                // WAIT_RESULT: Wait for matrix multiplier result
                // =========================================================
                WAIT_RESULT: begin
                    if (matrix_valid) begin
                        filter_out <= matrix_result;
                        filter_valid <= 1'b1;
                        state <= OUTPUT;
                    end
                end
                
                // =========================================================
                // OUTPUT: Convolution result ready
                // =========================================================
                OUTPUT: begin
                    filter_done <= 1'b1;
                    
                    // Can continue to next pixel or stop
                    if (pixel_valid) begin
                        // Shift to next position
                        line0 <= shifted_line0_0;
                        line0 <= shifted_line0_1;
                        line0 <= shifted_line0_2;
                        
                        line1 <= shifted_line1_0;
                        line1 <= shifted_line1_1;
                        line1 <= shifted_line1_2;
                        
                        line2 <= shifted_line2_0;
                        line2 <= shifted_line2_1;
                        line2 <= shifted_line2_2;
                        
                        pixel_counter <= pixel_counter + 1;
                        state <= CONVOLVE;  // Process next pixel
                    end
                    else begin
                        state <= IDLE;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end

endmodule

