// matrix_transform_fixed.v
// Simple 2D transform module (DATA_WIDTH = integer width; uses integer arithmetic, not full arbitrary-angle rotation)

module matrix_transform #(
    parameter DATA_WIDTH = 16   // use Q8.8 if desired
)(
    input  wire                       clk,
    input  wire                       rst_n,
    input  wire                       start,

    input  wire signed [DATA_WIDTH-1:0] x_in,
    input  wire signed [DATA_WIDTH-1:0] y_in,

    input  wire [1:0]                 transform_type, // 00 rotate, 01 scale, 10 translate
    input  wire signed [DATA_WIDTH-1:0] param1,       // degrees (for rotate lower byte) or scale Q8.8 or tx
    input  wire signed [DATA_WIDTH-1:0] param2,       // ty for translate (or ignored)

    output reg signed [DATA_WIDTH-1:0] x_out,
    output reg signed [DATA_WIDTH-1:0] y_out,
    output reg [2*DATA_WIDTH-1:0]      combined_out,
    output reg                         transform_valid,
    output reg                         transform_done
);

    localparam [2:0] IDLE = 3'd0,
                     COMPUTE = 3'd1,
                     OUTPUT  = 3'd2;

    reg [2:0] state;

    // multiply Q8.8 helper (if DATA_WIDTH is Q8.8)
    function signed [DATA_WIDTH-1:0] qmul;
        input signed [DATA_WIDTH-1:0] a;
        input signed [DATA_WIDTH-1:0] b;
        reg signed [2*DATA_WIDTH-1:0] prod;
    begin
        prod = a * b;
        qmul = prod >>> 8;
    end
    endfunction

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            x_out <= 0;
            y_out <= 0;
            combined_out <= 0;
            transform_valid <= 1'b0;
            transform_done <= 1'b0;
        end
        else begin
            transform_valid <= 1'b0;
            case (state)
                IDLE: begin
                    transform_done <= 1'b0;
                    if (start) state <= COMPUTE;
                end

                COMPUTE: begin
                    case (transform_type)
                        2'b00: begin
                            // rotate by multiples of 90 degrees (param1[7:0] degrees)
                            case (param1[7:0])
                                8'd0: begin x_out <= x_in; y_out <= y_in; end
                                8'd90: begin x_out <= -y_in; y_out <= x_in; end
                                8'd180: begin x_out <= -x_in; y_out <= -y_in; end
                                8'd270: begin x_out <= y_in; y_out <= -x_in; end
                                default: begin x_out <= x_in; y_out <= y_in; end
                            endcase
                        end

                        2'b01: begin
                            // scale: param1 is Q8.8 scale factor
                            x_out <= qmul(x_in, param1);
                            y_out <= qmul(y_in, param1);
                        end

                        2'b10: begin
                            // translate: param1 = tx (Q8.8), param2 = ty (Q8.8)
                            x_out <= x_in + param1;
                            y_out <= y_in + param2;
                        end

                        default: begin
                            x_out <= x_in;
                            y_out <= y_in;
                        end
                    endcase
                    state <= OUTPUT;
                end

                OUTPUT: begin
                    combined_out <= { y_out, x_out };
                    transform_valid <= 1'b1;
                    transform_done <= 1'b1;
                    state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule

