class dp_tl_sequencer extends uvm_sequencer #(dp_tl_sequence_item);
    `uvm_component_utils(dp_tl_sequencer);

    function new(string name = "dp_tl_sequencer", uvm_component parent = null);
        super.new(name, parent);
    endfunction
endclass
