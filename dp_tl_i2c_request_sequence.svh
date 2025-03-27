class dp_tl_i2c_sequence extends dp_tl_base_sequence;
    `uvm_object_utils(dp_tl_i2c_sequence);
    
    function new(string name = "dp_tl_i2c_sequence");
        super.new(name);
    endfunction
    
    task body();
        `uvm_info(get_type_name(), "Testing i2c_request case", UVM_MEDIUM)
        i2c_request(AUX_I2C_READ, 20'b0, 8'h7F); // Read 128 bytes from Legacy EDID registers
        `uvm_info(get_type_name(), "Completed i2c_request test", UVM_MEDIUM)
    endtask
endclass //dp_tl_i2c_sequence extends superClass