
// Testbench: graphics_transform_tb.v
module tb_graphics_transform;
    
    // Test 1: Rotate point (10, 0) by 90 degrees
    // Expected: (0, 10)
    
    // Test 2: Scale point (5, 5) by 2x
    // Expected: (10, 10)
    
    // Test 3: Translate point (3, 4) by (5, 7)
    // Expected: (8, 11)
    
    initial begin
        $display("Graphics Transform Tests");
        
        // Rotation test
        x_in = 16'h0A00;  // 10.0 in Q8.8
        y_in = 16'h0000;  // 0.0
        transform_type = 2'b00;
        param = 16'h0059;  // 90 degrees (?/2 radians)
        start = 1;
        @(posedge clk); start = 0;
        
        wait(done);
        $display("Rotation Result: x=%d, y=%d", x_out, y_out);
        // Expected: x?0, y?10
        
        // Scale test
        x_in = 16'h0500;  // 5.0
        y_in = 16'h0500;  // 5.0
        transform_type = 2'b01;
        param = 16'h0200;  // 2x scale
        start = 1;
        @(posedge clk); start = 0;
        
        wait(done);
        $display("Scale Result: x=%d, y=%d", x_out, y_out);
        // Expected: x=10, y=10
    end

endmodule
