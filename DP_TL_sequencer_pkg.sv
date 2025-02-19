package DP_TL_sequencer_pkg;
    import uvm_pkg::*;
    import DP_TL_sequence_item_pkg::*;
    `include "uvm_macros.svh"

    class DP_TL_sequencer extends uvm_sequencer #(DP_TL_sequence_item);
        `uvm_component_utils(DP_TL_sequencer);

        function new(string name = "DP_TL_sequencer", uvm_component parent = null);
            super.new(name, parent);
        endfunction
    endclass
endpackage