class dp_sink_interrupt_seq extends dp_sink_base_sequence;
    `uvm_object_utils(dp_sink_interrupt_seq);

    function new(string name = "dp_sink_interrupt_seq");
        super.new(name);
    endfunction
 
    task body();
        `uvm_info(get_type_name(), "Starting Interrupt sequence", UVM_MEDIUM)

        Interrupt();
        // Set the sink operation to Interrupt
    endtask    
endclass