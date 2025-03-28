package dp_sink_agent_pkg;

    // Standard UVM import & include:
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // Any further package imports:
    import dp_transactions_pkg::*;
    import test_parameters_pkg::*;
    
    // Includes:
    `include "dp_sink_sequencer.svh"
    `include "dp_sink_driver.svh"
    `include "dp_sink_monitor.svh"
    `include "dp_sink_agent.svh"

endpackage
