class dp_tl_native_read_sequence extends dp_tl_base_sequence;
    `uvm_object_utils(dp_tl_i2c_sequence);
    
    function new(string name = "dp_tl_native_read_sequence");
        super.new(name);
    endfunction
    
    task body();
        `uvm_info(get_type_name(), "Testing native_read_request case", UVM_MEDIUM)
        native_request( , , AUX_NATIVE_READ); //
        `uvm_info(get_type_name(), "Completed native_read_request test", UVM_MEDIUM)
    endtask
endclass //dp_tl_native_read_sequence extends superClass