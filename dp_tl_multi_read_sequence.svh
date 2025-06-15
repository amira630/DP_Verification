class dp_tl_multi_read_sequence extends dp_tl_base_sequence;
    `uvm_object_utils(dp_tl_multi_read_sequence);
    
    function new(string name = "dp_tl_multi_read_sequence");
        super.new(name);
    endfunction
    
    task body();
        `uvm_info(get_type_name(), "Testing multi read request case", UVM_MEDIUM)

        multi_read_request();

        `uvm_info(get_type_name(), "Completed multi read request test", UVM_MEDIUM)
    endtask
endclass //dp_tl_multi_read_sequence extends superClass