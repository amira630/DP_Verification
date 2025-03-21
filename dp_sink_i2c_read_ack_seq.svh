class dp_sink_i2c_read_ack_seq extends dp_sink_base_sequence;
    `uvm_object_utils(dp_sink_i2c_read_ack_seq);
    
    function new(string name = "dp_sink_i2c_read_ack_seq");
        super.new(name);
    endfunction
    
    task body();
        `uvm_info(get_type_name(), "Testing I2C ACK case", UVM_MEDIUM)
        I2C_Reply_command_transaction(I2C_ACK);
        `uvm_info(get_type_name(), "Completed I2C ACK test", UVM_MEDIUM)
    endtask
endclass