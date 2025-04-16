// Standard UVM import & include:
import uvm_pkg::*;
`include "uvm_macros.svh"

// Any further package imports:
import dp_source_test_pkg::*;

module top();
    bit clk;

    // start the clock
    initial begin
        forever
            #0 clk = ~clk;
    end

    // Create the interfaces for Transport Layer and the Sink Link Layer
    dp_tl_if tl_if (clk);
    dp_sink_if sink_if (clk);

    // dp_source DP_SOURCE_DUT (
    //     .tl_if(tl_if),
    //     .sink_if(sink_if)    // make sure the DP_SOURCE can take two interfaces
    // );

    initial begin
        // add virtual interfaces for each interface to the configurations database
        uvm_config_db #(virtual dp_tl_if)::set(null, "uvm_test_top", "dp_tl_vif", tl_if);
        uvm_config_db #(virtual dp_sink_if)::set(null, "uvm_test_top", "dp_sink_vif", sink_if);
        
        // Run the test
        run_test("dp_source_test");
    end
endmodule
