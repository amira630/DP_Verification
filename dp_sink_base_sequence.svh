class dp_sink_base_sequence extends uvm_sequence #(dp_sink_sequence_item);
    `uvm_object_utils(dp_sink_sequence);

    dp_sink_sequence_item seq_item;

    function new(string name = "dp_sink_base_sequence");
        super.new(name);
    endfunction //new()

    task native_reply_ack_aux();
        seq_item = dp_sink_base_sequence::type_id::create("seq_item");
        start_item(seq_item);
        N_R_REP_seq: assert (
            seq_item_LPM.randomize() with {HPD_Signal = 1'b1;                // Native_Read
                                           AUX_IN_OUT = {AUX_ACK, 4'b0000};} // LPM is going to request a transaction
        )
        finish_item(seq_item);
        `uvm_info("SINK_BASE_SEQ", $sformatf("Native AUX R/W request has been ACKed."), UVM_MEDIUM)
    endtask

    task native_read_reply_defer_aux();
        seq_item = dp_sink_base_sequence::type_id::create("seq_item");
        start_item(seq_item);
        N_R_REP_seq: assert (
            seq_item_LPM.randomize() with {HPD_Signal = 1'b1;                  // Sink is connected
                                           AUX_IN_OUT = {AUX_DEFER, 4'b0000};} // Sink is not ready for a R/W request
        )
        /// WE STILL NEED TO ADD THE START
        `uvm_info("SINK_BASE_SEQ", $sformatf("Native AUX R/W request has been DEFERed."), UVM_MEDIUM)
        finish_item(seq_item);
    endtask

    task native_data_reply_aux(int LEN);
        seq_item = dp_sink_base_sequence::type_id::create("seq_item");
        repeat (LEN) begin
            start_item(seq_item);
            N_R_REP_seq: assert (
                seq_item_LPM.randomize() with {HPD_Signal = 1'b1;} // LPM is going to request a transaction
            )
            finish_item(seq_item);
            `uvm_info("BASE_SEQ", $sformatf("Native AUX READ requested data: addr=0x%0h, Data Length=0x%0d, Command = 0x%0b, Transaction Validity = 0x%0b", seq_item_LPM.LPM_Address, seq_item_LPM.LPM_LEN, seq_item_LPM.LPM_CMD, seq_item_LPM.LPM_Transaction_VLD), UVM_MEDIUM)
        end
    endtask

    task body();
        `uvm_fatal("BASE_SEQ", "Base sequence should not be executed directly!")
    endtask
endclass //dp_sink_base_sequence extends superClass
