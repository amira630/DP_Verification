class dp_sink_hpd_test_seq extends dp_sink_base_sequence;
    `uvm_object_utils(dp_sink_hpd_test_seq);

    function new(string name = "dp_sink_hpd_test_seq");
        super.new(name);
    endfunction
 
    task body();
        `uvm_info(get_type_name(), "Starting HPD test sequence", UVM_MEDIUM)

        Random_HPD();
    endtask    
endclass