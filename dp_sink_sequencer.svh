class dp_sink_sequencer extends uvm_sequencer #(dp_sink_sequence_item);
    `uvm_component_utils(dp_sink_sequencer);

    function new(string name = "dp_sink_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction
endclass
