package DP_SINK_sequencer_pkg;
    import uvm_pkg::*;
    import DP_SINK_sequence_item_pkg::*;
    `include "uvm_macros.svh"

    class DP_SINK_sequencer extends uvm_sequencer #(DP_SINK_sequence_item);
        `uvm_component_utils(DP_SINK_sequencer);

        function new(string name = "DP_SINK_sequencer", uvm_component parent = null);
            super.new(name, parent);
        endfunction
    endclass
endpackage