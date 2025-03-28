class dp_tl_native_receiver_cap_sequence extends dp_tl_base_sequence;
    `uvm_object_utils(dp_tl_native_receiver_cap_sequence);
    
    function new(string name = "dp_tl_native_receiver_cap_sequence");
        super.new(name);
    endfunction
    
    task body();
        `uvm_info(get_type_name(), "Testing native_receiver_capability_read_request case", UVM_MEDIUM)
        for (int i = 0; i <16 ; i++) begin
            native_request(AUX_NATIVE_READ, 16*i, 8'hFF);
        end
        `uvm_info(get_type_name(), "Completed native_receiver_capability_read_request test", UVM_MEDIUM)
    endtask
endclass //dp_tl_native_receiver_cap_sequence extends superClass