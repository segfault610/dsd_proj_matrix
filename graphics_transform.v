// graphics_transform_fixed.v
// Simple transform module using Q8.8 fixed point (DATA_WIDTH=16).
// transform_type: 2'b00 rotate (param = degrees, only 0/90/180/270 supported)
//                 2'b01 scale  (param = Q8.8 scale factor, e.g. 2.0 => 16'h0200)
//                 2'b10 translate (param = offset in Q8.8; for translation X and Y pass via param_x/param_y ? here we use param as X and input Y as y_in)

module graphics_transform #(
    parameter DATA_WIDTH = 16  // Q8.8
)(
    input  wire                       clk,
    input  wire                       rst,
    input  wire                       start,

    input  wire signed [DATA_WIDTH-1:0] x_in,
    input  wire signed [DATA_WIDTH-1:0] y_in,

    input  wire [1:0]                 transform_type, // 00=rotate,01=scale,10=translate
    input  wire signed [DATA_WIDTH-1:0] param,        // degrees for rotate (integer in lower byte), scale factor Q8.8, translate offset Q8.8

    output reg signed [DATA_WIDTH-1:0] x_out,
    output reg signed [DATA_WIDTH-1:0] y_out,
    output reg                         valid,
    output reg                         done
);

    localparam IDLE = 2'd0, COMPUTE = 2'd1, OUTPUT = 2'd2;
    reg [1:0] state;

    // intermediate results (wider for multiplication)
    reg signed [2*DATA_WIDTH-1:0] mult_tmp;
    // helpers
    function signed [DATA_WIDTH-1:0] qmul;
        input signed [DATA_WIDTH-1:0] a;
        input signed [DATA_WIDTH-1:0] b;
        reg signed [2*DATA_WIDTH-1:0] prod;
    begin
        prod = a * b; // product is Q16.16
        // reduce back to Q8.8 by shifting right 8
        qmul = prod >>> 8;
    end
    endfunction

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            x_out <= 0;
            y_out <= 0;
            valid <= 1'b0;
            done <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    valid <= 1'b0;
                    done <= 1'b0;
                    if (start) state <= COMPUTE;
                end

                COMPUTE: begin
                    case (transform_type)
                        2'b00: begin
                            // rotate: param (lowest 8 bits) interpreted as degrees integer
                            case (param[7:0])
                                8'd0: begin x_out <= x_in;           y_out <= y_in;           end
                                8'd90: begin x_out <= -y_in;         y_out <= x_in;           end
                                8'd180: begin x_out <= -x_in;        y_out <= -y_in;          end
                                8'd270: begin x_out <= y_in;         y_out <= -x_in;          end
                                default: begin x_out <= x_in;        y_out <= y_in;           end
                            endcase
                        end

                        2'b01: begin
                            // scale: param is Q8.8 scale factor
                            x_out <= qmul(x_in, param);
                            y_out <= qmul(y_in, param);
                        end

                        2'b10: begin
                            // translate: param is X-offset in Q8.8, y translation provided in y_in param?
                            // For simplicity treat 'param' as X offset and use y_in as Y offset only when start serves to indicate translation:
                            // Here we'll interpret param as tx (Q8.8) and use an additional register: since we only have single param we will treat y_in as input coordinate (unchanged)
                            // Better API would have separate tx/ty inputs. For now, shift x by param and y by 0.
                            x_out <= x_in + param;
                            y_out <= y_in;
                        end

                        default: begin
                            x_out <= x_in;
                            y_out <= y_in;
                        end
                    endcase
                    state <= OUTPUT;
                end

                OUTPUT: begin
                    valid <= 1'b1;
                    done <= 1'b1;
                    state <= IDLE;
                end
            endcase
        end
    end

endmodule

