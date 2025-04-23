package dp_source_test_pkg;

    // Standard UVM import & include:
    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // Any further package imports:
    import dp_transactions_pkg::*;
    import dp_source_env_pkg::*;

    // Includes:
    `include "dp_tl_base_sequence.svh"
    `include "dp_tl_reset_seq.svh"
    //`include "dp_tl_i2c_sequence.svh"
    `include "dp_tl_native_ext_receiver_cap_sequence.svh"
    `include "dp_tl_native_link_config_sequence.svh"
    `include "dp_tl_native_receiver_cap_sequence.svh"

    `include "dp_sink_base_sequence.svh"
    `include "dp_sink_interrupt_seq.svh"
    `include "dp_source_test.svh"
    
endpackage
