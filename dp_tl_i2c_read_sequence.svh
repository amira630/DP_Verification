class dp_tl_i2c_read_sequence extends dp_tl_base_sequence;
    `uvm_object_utils(dp_tl_base_sequence);

    dp_tl_sequence_item seq_item;

    function new(string name = "dp_tl_base_sequence");
        super.new(name);
    endfunction //new()

    task body();
        I2C_read_transaction();          
    endtask
endclass //dp_tl_base_sequence extends superClass