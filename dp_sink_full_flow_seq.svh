class dp_sink_full_flow_seq extends dp_sink_base_sequence;
    `uvm_object_utils(dp_sink_full_flow_seq);

    function new(string name = "dp_sink_full_flow_seq");
        super.new(name);
    endfunction
 
    task body();
        `uvm_info(get_type_name(), "Starting Full Flow test sequence", UVM_MEDIUM)

        Sink_FSM();
    endtask    
endclass