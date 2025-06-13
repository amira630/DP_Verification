class dp_tl_native_ext_receiver_cap_sequence extends dp_tl_base_sequence;
    `uvm_object_utils(dp_tl_native_ext_receiver_cap_sequence);
    
    function new(string name = "dp_tl_native_ext_receiver_cap_sequence");
        super.new(name);
    endfunction
    
    task body();
        `uvm_info(get_type_name(), "Testing native_Extend_receiver_capability_read_request case", UVM_MEDIUM)
        for (int i = 0; i <16 ; i++) begin
            native_read_request(20'h0_22_00 + 16*i, 8'h0F);
        end
        `uvm_info(get_type_name(), "Completed native_Extend_receiver_capability_read_request test", UVM_MEDIUM)
        $finish;
    endtask
endclass //dp_tl_native_ext_receiver_cap_sequence extends superClass