class dp_tl_base_sequence extends uvm_sequence #(dp_tl_sequence_item);
    `uvm_object_utils(dp_tl_sequence);

    dp_tl_sequence_item seq_item_SPM;
    dp_tl_sequence_item seq_item_LPM;

    function new(string name = "dp_tl_base_sequence");
        super.new(name);
    endfunction //new()

    // NATIVE AUX READ REQUEST TRANSACTION
    task native_read_req_aux ();
        seq_item_LPM = dp_tl_sequence_item::type_id::create("seq_item_LPM");
        start_item(seq_item_LPM);
        N_R_REQ_seq: assert (
            seq_item_LPM.randomize() with {LPM_CMD = 2'b11;             // Native_Read
                                           LPM_Transaction_VLD = 1'b1;} // LPM is going to request a transaction
        )    
        finish_item(seq_item_LPM);
        `uvm_info("BASE_SEQ", $sformatf("Native AUX read request transaction sent: addr=0x%0h, Data Length=0x%0d, Command = 0x%0b, Transaction Validity = 0x%0b", seq_item_LPM.LPM_Address, seq_item_LPM.LPM_LEN, seq_item_LPM.LPM_CMD, seq_item_LPM.LPM_Transaction_VLD), UVM_MEDIUM)
    endtask

    task native_write_req_aux ();
        seq_item_LPM = dp_tl_sequence_item::type_id::create("seq_item_LPM");
        start_item(seq_item_LPM);
        N_W_REQ_seq: assert(
            seq_item_LPM.randomize() with {LPM_CMD = 2'b10;             // Native_Write
                                           LPM_Transaction_VLD = 1'b1;} // LPM is going to request a transaction
        )
        finish_item(seq_item_LPM);
        `uvm_info("BASE_SEQ", $sformatf("Native AUX write request transaction sent: addr=0x%0h, Data Length=0x%0d, Command = 0x%0b, Transaction Validity = 0x%0b", seq_item_LPM.LPM_Address, seq_item_LPM.LPM_LEN, seq_item_LPM.LPM_CMD, seq_item_LPM.LPM_Transaction_VLD), UVM_MEDIUM)
    endtask
    // Prevent the base sequence from running directly
    task body();
        `uvm_fatal("BASE_SEQ", "Base sequence should not be executed directly!")
    endtask
endclass //dp_tl_sequence extends superClass