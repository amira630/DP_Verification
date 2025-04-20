// Project: DP Verification
// Description: Top module for the DisplayPort verification environment
// Time Scale: 1ns / 1ps
`timescale 1ns / 1ps

// Standard UVM import & include:
import uvm_pkg::*;
`include "uvm_macros.svh"

// Any further package imports:
import dp_source_test_pkg::*;

module top();
    bit clk;

    // Create the interfaces for Transport Layer and the Sink Link Layer
    dp_tl_if #(.AUX_ADDRESS_WIDTH(20), .AUX_DATA_WIDTH(8))  tl_if (clk);
    dp_sink_if #(.AUX_ADDRESS_WIDTH(20), .AUX_DATA_WIDTH(8)) sink_if (clk);

    dp_source DUT (tl_if, sink_if);


    // start the clock
    initial begin
        clk = 1;
        forever
            #10000 clk = ~clk;
    end

    initial begin
        // add virtual interfaces for each interface to the configurations database
        uvm_config_db #(virtual dp_tl_if)::set(null, "uvm_test_top", "dp_tl_vif", tl_if);
        uvm_config_db #(virtual dp_sink_if)::set(null, "uvm_test_top", "dp_sink_vif", sink_if);
        
        // Run the test
        run_test("dp_source_test");
    end
endmodule
