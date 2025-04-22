class dp_tl_reset_seq extends dp_tl_base_sequence;
    `uvm_object_utils(dp_tl_reset_seq);
    
    function new(string name = "dp_tl_reset_seq");
        super.new(name);
    endfunction
    
    task body();
        `uvm_info(get_type_name(), "Testing Rsest case", UVM_MEDIUM)
        
        reset_task();

        `uvm_info(get_type_name(), "Completed Reset test", UVM_MEDIUM)
    endtask
endclass //dp_tl_reset_seq extends superClass