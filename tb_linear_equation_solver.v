`timescale 1ns/1ps

module tb_linear_equation_solver;

    // Parameters
    localparam DATA_WIDTH = 16;
    localparam CLK_PERIOD = 10; // 10 ns clock period
    localparam FRAC_BITS  = 8;  // Number of fractional bits for fixed-point

    //======================================================================
    //== EDIT EQUATION COEFFICIENTS HERE
    //======================================================================
    // Define the system of equations: Ax = b
    // Example: 10x - y + 2z = 26
    
    // Matrix A coefficients
    localparam A00 = 10; localparam A01 = -1; localparam A02 =  2;
    localparam A10 =  1; localparam A11 = 11; localparam A12 = -1;
    localparam A20 =  2; localparam A21 = -1; localparam A22 = 10;

    // Vector b coefficients
    localparam B0 = 26;
    localparam B1 = 35;
    localparam B2 = 48;

    // Expected integer solution (for verification)
    // Solution for the above system is x=2, y=3, z=4
    localparam EXP_X0 = 2;
    localparam EXP_X1 = 3;
    localparam EXP_X2 = 4;
    //======================================================================

    // Testbench signals
    reg clk;
    reg rst;
    reg start;
    reg [DATA_WIDTH-1:0] a_data;
    reg [3:0] a_addr;
    reg a_wen;
    reg [DATA_WIDTH-1:0] b_data;
    reg [1:0] b_addr;
    reg b_wen;

    wire [DATA_WIDTH-1:0] x0, x1, x2;
    wire done;

    // Instantiate the DUT (Device Under Test)
    linear_equation_solver_3x3 #(
        .DATA_WIDTH(DATA_WIDTH),
        .MAX_ITER(100) // CORRECTED: Use the higher iteration count
    ) dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .a_data(a_data),
        .a_addr(a_addr),
        .a_wen(a_wen),
        .b_data(b_data),
        .b_addr(b_addr),
        .b_wen(b_wen),
        .x0(x0),
        .x1(x1),
        .x2(x2),
        .done(done)
    );

    // Clock generator
    always begin
        clk = 1'b0;
        #(CLK_PERIOD / 2);
        clk = 1'b1;
        #(CLK_PERIOD / 2);
    end

    // Test sequence
    initial begin
        $display("Starting Testbench...");

        // 1. Initialize all inputs
        rst = 1'b1; // Assert reset
        start = 1'b0;
        a_wen = 1'b0;
        b_wen = 1'b0;
        a_data = 0;
        a_addr = 0;
        b_data = 0;
        b_addr = 0;
        
        // 2. Apply and release reset
        #(CLK_PERIOD * 2);
        rst = 1'b0; // De-assert reset
        $display("Reset released. Loading matrices...");
        #(CLK_PERIOD);

        // 3. Load Matrix A values from parameters
        // Row 0
        a_addr <= 0; a_data <= A00 << FRAC_BITS; a_wen <= 1; @(posedge clk);
        a_addr <= 1; a_data <= A01 << FRAC_BITS; a_wen <= 1; @(posedge clk);
        a_addr <= 2; a_data <= A02 << FRAC_BITS; a_wen <= 1; @(posedge clk);
        // Row 1
        a_addr <= 3; a_data <= A10 << FRAC_BITS; a_wen <= 1; @(posedge clk);
        a_addr <= 4; a_data <= A11 << FRAC_BITS; a_wen <= 1; @(posedge clk);
        a_addr <= 5; a_data <= A12 << FRAC_BITS; a_wen <= 1; @(posedge clk);
        // Row 2
        a_addr <= 6; a_data <= A20 << FRAC_BITS; a_wen <= 1; @(posedge clk);
        a_addr <= 7; a_data <= A21 << FRAC_BITS; a_wen <= 1; @(posedge clk);
        a_addr <= 8; a_data <= A22 << FRAC_BITS; a_wen <= 1; @(posedge clk);
        a_wen <= 0; // Disable write for A
        $display("Matrix A loaded.");

        // 4. Load Vector b values from parameters
        b_addr <= 0; b_data <= B0 << FRAC_BITS; b_wen <= 1; @(posedge clk);
        b_addr <= 1; b_data <= B1 << FRAC_BITS; b_wen <= 1; @(posedge clk);
        b_addr <= 2; b_data <= B2 << FRAC_BITS; b_wen <= 1; @(posedge clk);
        b_wen <= 0; // Disable write for b
        $display("Vector b loaded.");

        // 5. Start the solver
        start <= 1;
        @(posedge clk);
        start <= 0;
        $display("Start signal pulsed. Waiting for 'done'...");

        // 6. Wait for the 'done' signal
        wait (done == 1'b1);
        $display("Solver finished.");
        
        // Wait for the next clock edge to ensure outputs are stable before sampling.
        @(posedge clk); 
        
        // 7. Display the results
        $display("-----------------------------------------");
        $display("Expected solution (fixed-point): x0=%d, x1=%d, x2=%d", 
                 EXP_X0 << FRAC_BITS, EXP_X1 << FRAC_BITS, EXP_X2 << FRAC_BITS);
        $display("Actual solution (fixed-point):   x0=%d, x1=%d, x2=%d", x0, x1, x2);
        
        // Also display the integer-equivalent result
        $display("Actual solution (integer approx): x0=%d, x1=%d, x2=%d", 
                 $signed(x0) >>> FRAC_BITS, $signed(x1) >>> FRAC_BITS, $signed(x2) >>> FRAC_BITS);
        $display("-----------------------------------------");

        // 8. End the simulation
        $finish;
    end

endmodule


