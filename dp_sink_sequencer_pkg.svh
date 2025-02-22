class DP_SINK_sequencer extends uvm_sequencer #(DP_SINK_sequence_item);
    `uvm_component_utils(DP_SINK_sequencer);

    function new(string name = "DP_SINK_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction
endclass