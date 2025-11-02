module graphics_transform #(
    parameter DATA_WIDTH = 16  // Fixed-point Q8.8
)(
    input wire clk,
    input wire rst,
    input wire start,
    
    // Input: Original coordinate (x, y)
    input wire signed [DATA_WIDTH-1:0] x_in,
    input wire signed [DATA_WIDTH-1:0] y_in,
    
    // Transform selection
    input wire [1:0] transform_type,  // 00=rotate, 01=scale, 10=translate
    input wire signed [DATA_WIDTH-1:0] param,  // Angle/scale factor/offset
    
    // Output: Transformed coordinate
    output reg signed [DATA_WIDTH-1:0] x_out,
    output reg signed [DATA_WIDTH-1:0] y_out,
    output reg valid,
    output reg done
);

    // State machine
    localparam IDLE = 0, LOAD_MATRIX = 1, COMPUTE = 2, OUTPUT = 3;
    reg [1:0] state;
    
    // Matrix multiplier instantiation (3x3 for homogeneous coordinates)
    wire [2*DATA_WIDTH-1:0] result;
    wire result_valid;
    wire mult_done;
    
    simple_generic_matrix_mult #(.M(3), .N(3), .P(1), .DATA_WIDTH(DATA_WIDTH)) 
    core (
        .clk(clk), .rst(rst), .start(matrix_start),
        .a_in(transform_matrix), .a_addr(mat_addr), .a_wen(mat_wen),
        .b_in(coord_vector), .b_addr(vec_addr), .b_wen(vec_wen),
        .c_out(result), .c_valid(result_valid), .done(mult_done)
    );
    
    // Transform matrices (pre-computed)
    reg signed [DATA_WIDTH-1:0] transform_matrix;
    
    always @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            valid <= 0;
            done <= 0;
        end else begin
            case (state)
                IDLE: if (start) state <= LOAD_MATRIX;
                
                LOAD_MATRIX: begin
                    // Load appropriate transformation matrix
                    case (transform_type)
                        2'b00: load_rotation_matrix(param);
                        2'b01: load_scale_matrix(param);
                        2'b10: load_translation_matrix(param);
                    endcase
                    state <= COMPUTE;
                end
                
                COMPUTE: begin
                    if (mult_done) state <= OUTPUT;
                end
                
                OUTPUT: begin
                    x_out <= result[DATA_WIDTH-1:0];
                    y_out <= result[2*DATA_WIDTH-1:DATA_WIDTH];
                    valid <= 1;
                    done <= 1;
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule

