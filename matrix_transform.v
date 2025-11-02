// ============================================================================
// MATRIX TRANSFORM MODULE - 2D Coordinate Transformations
// ============================================================================
// Implements: Rotation, Scaling, Translation of 2D points
// Y = T × X  where T is transformation matrix, X is homogeneous coordinates
// ============================================================================

module matrix_transform #(
    parameter DATA_WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire start,
    
    // Input coordinates (x, y)
    input wire signed [DATA_WIDTH-1:0] x_in,
    input wire signed [DATA_WIDTH-1:0] y_in,
    
    // Transformation parameters
    input wire [1:0] transform_type,  // 00=rotate, 01=scale, 10=translate
    input wire signed [DATA_WIDTH-1:0] param1,  // Angle / scale_x / tx
    input wire signed [DATA_WIDTH-1:0] param2,  // Scale_y / ty (unused for rotate)
    
    // From matrix multiplier core (transformed coordinates)
    input wire [2*DATA_WIDTH-1:0] matrix_result,
    input wire matrix_valid,
    
    // Output
    output reg signed [DATA_WIDTH-1:0] x_out,
    output reg signed [DATA_WIDTH-1:0] y_out,
    output reg [2*DATA_WIDTH-1:0] combined_out,  // For systems that want full result
    output reg transform_valid,
    output reg transform_done
);

    // =========================================================================
    // PRE-COMPUTED TRANSFORMATION MATRICES
    // =========================================================================
    
    // Rotation matrices (in fixed-point Q8.8 format for better precision)
    // cos(0°)=256, cos(45°)=181, cos(90°)=0, sin(45°)=181, sin(90°)=256
    
    reg signed [DATA_WIDTH-1:0] rotation_matrix [0:8];
    reg signed [DATA_WIDTH-1:0] scale_matrix [0:8];
    reg signed [DATA_WIDTH-1:0] translation_matrix [0:8];
    
    // =========================================================================
    // INITIALIZATION - PRE-COMPUTED TRANSFORMATION MATRICES
    // =========================================================================
    
    initial begin
        // Rotation matrix for 45 degrees (in Q8.8 fixed point)
        // [cos45  -sin45  0]   [181  -181  0]
        // [sin45   cos45  0] = [181   181  0]
        // [0       0      1]   [0     0   256]
        rotation_matrix = 8'sd91;    // cos45 = 91 (scaled)
        rotation_matrix = -8'sd91;   // -sin45
        rotation_matrix = 8'sd0;     // 0
        rotation_matrix = 8'sd91;    // sin45
        rotation_matrix = 8'sd91;    // cos45
        rotation_matrix = 8'sd0;     // 0
        rotation_matrix = 8'sd0;     // 0
        rotation_matrix = 8'sd0;     // 0
        rotation_matrix = 8'sd1;     // 1 (homogeneous)
        
        // Scale matrix (2x scale)
        // [2  0  0]
        // [0  2  0]
        // [0  0  1]
        scale_matrix = 8'sd2;
        scale_matrix = 8'sd0;
        scale_matrix = 8'sd0;
        scale_matrix = 8'sd0;
        scale_matrix = 8'sd2;
        scale_matrix = 8'sd0;
        scale_matrix = 8'sd0;
        scale_matrix = 8'sd0;
        scale_matrix = 8'sd1;
        
        // Translation matrix (tx=5, ty=10)
        // [1  0  5]
        // [0  1  10]
        // [0  0  1]
        translation_matrix = 8'sd1;
        translation_matrix = 8'sd0;
        translation_matrix = 8'sd5;
        translation_matrix = 8'sd0;
        translation_matrix = 8'sd1;
        translation_matrix = 8'sd10;
        translation_matrix = 8'sd0;
        translation_matrix = 8'sd0;
        translation_matrix = 8'sd1;
    end
    
    // =========================================================================
    // STATE MACHINE (FSM - Module 6)
    // =========================================================================
    
    localparam [2:0] IDLE              = 3'd0;
    localparam [2:0] LOAD_TRANSFORM    = 3'd1;
    localparam [2:0] LOAD_INPUT        = 3'd2;
    localparam [2:0] TRIGGER_COMPUTE   = 3'd3;
    localparam [2:0] WAIT_RESULT       = 3'd4;
    localparam [2:0] OUTPUT_X          = 3'd5;
    localparam [2:0] OUTPUT_Y          = 3'd6;
    
    reg [2:0] state;
    reg signed [DATA_WIDTH-1:0] stored_x, stored_y;
    reg [2*DATA_WIDTH-1:0] x_result, y_result;
    reg [1:0] result_count;
    
    // =========================================================================
    // FSM - STATE TRANSITIONS
    // =========================================================================
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            x_out <= 0;
            y_out <= 0;
            combined_out <= 0;
            transform_valid <= 0;
            transform_done <= 0;
            stored_x <= 0;
            stored_y <= 0;
            result_count <= 0;
        end
        else begin
            transform_valid <= 0;
            
            case (state)
                // =========================================================
                // IDLE: Wait for start signal
                // =========================================================
                IDLE: begin
                    transform_done <= 1'b0;
                    result_count <= 0;
                    if (start) begin
                        state <= LOAD_INPUT;
                    end
                end
                
                // =========================================================
                // LOAD_INPUT: Store input coordinates
                // =========================================================
                LOAD_INPUT: begin
                    stored_x <= x_in;
                    stored_y <= y_in;
                    state <= LOAD_TRANSFORM;
                end
                
                // =========================================================
                // LOAD_TRANSFORM: Select and load transformation matrix
                // =========================================================
                LOAD_TRANSFORM: begin
                    // In real hardware, here we'd load the appropriate matrix
                    // For now, matrices are pre-loaded in module
                    // Transition to trigger matrix multiply
                    state <= TRIGGER_COMPUTE;
                end
                
                // =========================================================
                // TRIGGER_COMPUTE: Start matrix multiplication
                // =========================================================
                TRIGGER_COMPUTE: begin
                    // Matrix multiplier core will compute:
                    // [x']   [T]   [x]
                    // [y'] = [  ] × [y]
                    // [1 ]   [  ]   
                    state <= WAIT_RESULT;
                end
                
                // =========================================================
                // WAIT_RESULT: Wait for first result (x coordinate)
                // =========================================================
                WAIT_RESULT: begin
                    if (matrix_valid) begin
                        if (result_count == 2'd0) begin
                            x_result <= matrix_result;
                            result_count <= 2'd1;
                        end
                        else if (result_count == 2'd1) begin
                            y_result <= matrix_result;
                            result_count <= 2'd2;
                            state <= OUTPUT_X;
                        end
                    end
                end
                
                // =========================================================
                // OUTPUT_X: Output X coordinate
                // =========================================================
                OUTPUT_X: begin
                    x_out <= x_result[DATA_WIDTH-1:0];
                    transform_valid <= 1'b1;
                    state <= OUTPUT_Y;
                end
                
                // =========================================================
                // OUTPUT_Y: Output Y coordinate and complete
                // =========================================================
                OUTPUT_Y: begin
                    y_out <= y_result[DATA_WIDTH-1:0];
                    combined_out <= {y_result, x_result};
                    transform_valid <= 1'b1;
                    transform_done <= 1'b1;
                    state <= IDLE;
                end
                
                default: state <= IDLE;
            endcase
        end
    end

endmodule

