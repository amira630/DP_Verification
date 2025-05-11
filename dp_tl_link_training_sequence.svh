class dp_tl_link_training_sequence extends dp_tl_base_sequence;
    `uvm_object_utils(dp_tl_link_training_sequence);
    
    function new(string name = "dp_tl_link_training_sequence");
        super.new(name);
    endfunction
    
    task body();
        `uvm_info(get_type_name(), "Testing Link Training only case", UVM_MEDIUM)
        CR_LT();
        EQ_LT();
        `uvm_info(get_type_name(), "Completed Link Training only test", UVM_MEDIUM)
    endtask
endclass //dp_tl_link_training_sequence extends superClass