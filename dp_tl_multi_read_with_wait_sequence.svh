class dp_tl_multi_read_with_wait_sequence extends dp_tl_base_sequence;
    `uvm_object_utils(dp_tl_multi_read_with_wait_sequence);
    
    function new(string name = "dp_tl_multi_read_with_wait_sequence");
        super.new(name);
    endfunction
    
    task body();
        `uvm_info(get_type_name(), "Testing multi read request with wait ACK case", UVM_MEDIUM)

        multi_read_request_with_waiting_ack();

        `uvm_info(get_type_name(), "Completed multi read request with wait ACK test", UVM_MEDIUM)
    endtask
endclass //dp_tl_multi_read_with_wait_sequence extends superClass