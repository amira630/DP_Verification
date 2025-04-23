class dp_sink_reply_transaction extends dp_sink_base_sequence;
    `uvm_object_utils(dp_sink_reply_transaction);

    function new(string name = "dp_sink_reply_transaction");
        super.new(name);
    endfunction
 
    task body();
        `uvm_info(get_type_name(), "Starting Reply Transaction", UVM_MEDIUM)

        // Wait to ensure we've received and processed a request
        // Only needed if this sequence might run before receiving any request
        if (rsp_item == null) begin
            `uvm_info(get_type_name(), "Waiting for request to reply to...", UVM_MEDIUM)
            wait(rsp_item != null);
        end
        
        // Call the reply_transaction task with the sequence item signals
        sink_operation = Reply_operation; // Set the operation type to REPLY
        reply_transaction();

        `uvm_info(get_type_name(), "Completed Reply Transaction", UVM_MEDIUM)
    endtask
    
endclass