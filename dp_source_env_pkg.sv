package dp_source_env_pkg;

    // Standard UVM import & include:
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // Any further package imports:
    import dp_transactions_pkg::*;
    
    import dp_tl_agent_pkg::*;
    //import dp_sink_agent_pkg::*;

    // Includes:
    //`include "dp_source_ref.svh"
    //`include "dp_scoreboard.svh"
    `include "dp_tl_coverage.svh"
    //`include "dp_sink_coverage.svh"
    `include "dp_source_env.svh"

endpackage
