class dp_tl_base_sequence extends uvm_sequence #(dp_tl_sequence_item);
    `uvm_object_utils(dp_tl_base_sequence);

    dp_tl_sequence_item seq_item;

    function new(string name = "dp_tl_base_sequence");
        super.new(name);
    endfunction //new()

    task I2C_read_transaction();
        seq_item = dp_tl_sequence_item::type_id::create("seq_item");
        start_item(seq_item);
            //seq_item.operation = "I2C_READ";
            WR_seq: assert (seq_item.randomize() with {spm_trans_valid == 1'b1; spm_cmd == 2'b01; spm_length == 8'b1;})
                        else `uvm_fatal("body", "Randomization with I2C-read constraints failed!");
            finish_item(seq_item);                
    endtask
endclass //dp_tl_base_sequence extends superClass