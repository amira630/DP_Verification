class dp_tl_basic_flow_sequence extends dp_tl_base_sequence;
    `uvm_object_utils(dp_tl_basic_flow_sequence);
    
    function new(string name = "dp_tl_basic_flow_sequence");
        super.new(name);
    endfunction
    
    task body();
        `uvm_info(get_type_name(), "Testing Full Flow case", UVM_MEDIUM)
        basic_FLOW_FSM();
        `uvm_info(get_type_name(), "Completed Full Flow test", UVM_MEDIUM)
    endtask
endclass //dp_tl_basic_flow_sequence extends superClass