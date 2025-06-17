// Project: DP Verification
// Description: Top module for the DisplayPort verification environment
// Time Scale: 1ns / 1fs

// add wave -r /top/tl_if/*
// add wave -r /top/sink_if/*
// add wave -r /top/*

`timescale 1us / 1ns

// Standard UVM import & include:
import uvm_pkg::*;
`include "uvm_macros.svh"

// Any further package imports:
import dp_source_test_pkg::*;

module top();
    bit clk_AUX, clk_RBR, clk_HBR, clk_HBR2, clk_HBR3, MS_Stm_CLK;

    // Create the interfaces for Transport Layer and the Sink Link Layer
    dp_tl_if #(.AUX_ADDRESS_WIDTH(20), .AUX_DATA_WIDTH(8))  tl_if (clk_AUX, clk_RBR, clk_HBR, clk_HBR2, clk_HBR3, MS_Stm_CLK);
    dp_sink_if #(.AUX_ADDRESS_WIDTH(20), .AUX_DATA_WIDTH(8)) sink_if (clk_AUX, clk_RBR, clk_HBR, clk_HBR2, clk_HBR3);
    dp_ref_if #(.AUX_DATA_WIDTH(8)) ref_if ();

    dp_source DUT (tl_if, sink_if);

    // bind dp_source dp_sva SVA (tl_if, sink_if);

    // start the clocks
    initial begin
        clk_AUX = 1; clk_RBR = 1; clk_HBR = 1; clk_HBR2 = 1; clk_HBR3 = 1; MS_Stm_CLK = 1;

        fork
            begin
                forever
                    #5 clk_AUX = ~clk_AUX;
            end
            begin
                forever
                    #0.003 clk_RBR = ~clk_RBR; // will round to 3.086420ns
                    // #3.086419753
            end
            begin
                forever
                    #0.002 clk_HBR = ~clk_HBR; // will round to 1.851852ns
                    // #1.851851852
            end
            begin
                forever
                    #0.001 clk_HBR2 = ~clk_HBR2; // will round to 0.925926ns
                    // #0.925925926
            end
            begin
                forever
                    #0.001 clk_HBR3 = ~clk_HBR3; // will round to 0.061728ns
                    // #0.06172839505
            end
            begin
                forever
                    #(0.00625) MS_Stm_CLK = ~MS_Stm_CLK; // Pixel Stream Clock 
                    // #3.086419753
                    // #(tl_if.CLOCK_PERIOD/2)
            end
        join
    end

    initial begin
        // add virtual interfaces for each interface to the configurations database
        uvm_config_db #(virtual dp_tl_if)::set(null, "uvm_test_top", "dp_tl_vif", tl_if);
        uvm_config_db #(virtual dp_sink_if)::set(null, "uvm_test_top", "dp_sink_vif", sink_if);
        
        uvm_config_db #(virtual dp_ref_if)::set(null, "uvm_test_top", "dp_ref_vif", ref_if);
        // Run the test
        run_test("dp_source_test");
        $dumpfile("test.vcd");
        $dumpvars(0, top);
    end
endmodule