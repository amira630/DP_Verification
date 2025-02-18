import uvm_pkg::*;
import DP_SOURCE_test_pkg::*;
`include "uvm_macros.svh"

module TOP();
    bit clk;

    // start the clock
    initial begin
        forever
            #1 clk = ~clk;
    end

    // Create the interfaces for Transport Layer and the Sink Link Layer
    DP_TL_if tl_if (clk);
    DP_SINK_if sink_if (clk);

    DP_SOURCE DP_SOURCE_DUT (
        .tl_if(tl_if),
        .sink_if(sink_if)    // make sure the DP_SOURCE can take two interfaces
    );

    initial begin
        // add virtual interfaces for each interface to the configurations database
        uvm_config_db #(virtual DP_TL_if)::set(null, "uvm_test_top", "DP_TL_vif", tl_if);
        uvm_config_db #(virtual DP_SINK_if)::set(null, "uvm_test_top", "DP_SINK_vif", sink_if);
        
        // Run the test
        run_test("DP_SOURCE_test");
        
    end
endmodule