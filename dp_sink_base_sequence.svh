class dp_sink_base_sequence extends uvm_sequence #(dp_sink_sequence_item);
    `uvm_object_utils(dp_sink_base_sequence);

    dp_sink_sequence_item seq_item;
    dp_sink_sequence_item rsp_item;         // To capture responses

    int num_transactions = 1;

    function new(string name = "dp_sink_base_sequence");
        super.new(name);
    endfunction //new()

// Default body task - implement to run a sequence of commands if needed
    task body();
        `uvm_info(get_type_name(), "Starting dp_sink_base_sequence", UVM_MEDIUM)
        `uvm_info(get_type_name(), "Base sequence - override in child classes", UVM_MEDIUM)
        repeat(num_transactions) begin
            // First transaction - set start_stop to 1
            seq_item = dp_sink_sequence_item::type_id::create("seq_item");
            start_item(seq_item);

            // Configure seq_item parameters...
            

            finish_item(seq_item);

            // ensure that the response is received
            if (rsp_item == null) begin
                `uvm_warning(get_type_name(), "No valid response received!")
                continue;
            end

            // Get the response back
            get_response(rsp_item);

            // Process the response data
            if (rsp_item.aux_in_out.size() > 0) begin
                process_aux_data(rsp_item.aux_in_out);
                // Now you can use rsp_item.command, rsp_item.address, etc.
                
                // And make decisions for the next transaction based on the response
                `uvm_info(get_type_name(), $sformatf("Received command: %0h, address: %0h", 
                                                rsp_item.command, rsp_item.address), UVM_MEDIUM);
            end
            // Wait a bit before next transaction if needed
            #10;
        end
    endtask

// Helper function to process AUX data from response
    function void process_aux_data(bit [7:0] aux_queue[$]);
        bit [31:0] combined_data = 0;
        int bit_index = 0;
        
        // Create response item if not already available
        if (rsp_item == null)
            rsp_item = dp_sink_sequence_item::type_id::create("rsp_item");
        
        // Clear previous values
        rsp_item.command = 0;
        rsp_item.address = 0;
        rsp_item.length = 0;
        rsp_item.data.delete();
        
        // Need at least 4 bytes for command, address, and length
        if (aux_queue.size() < 4) begin
            `uvm_warning(get_type_name(), $sformatf("AUX data too short: %0d bytes", aux_queue.size()))
            return;
        end
        
        // Combine the first 4 bytes into a 32-bit value
        for (int i = 0; i < 4; i++) begin
            combined_data[bit_index+:8] = aux_queue[i];
            bit_index += 8;
        end
        
        // Extract fields:
        // First 4 bits (0-3) = command
        rsp_item.command = combined_data[3:0];
        
        // Next 20 bits (4-23) = address
        rsp_item.address = combined_data[23:4];
        
        // Next 8 bits (24-31) = length
        rsp_item.length = combined_data[31:24];
        
        // Remaining bytes are data
        for (int i = 4; i < aux_queue.size(); i++) begin
            rsp_item.data.push_back(aux_queue[i]);
        end
        
        `uvm_info(get_type_name(), $sformatf("Processed AUX: cmd=0x%h, addr=0x%h, len=0x%h, data_size=%0d", 
                  rsp_item.command, rsp_item.address, rsp_item.length, rsp_item.data.size()), UVM_MEDIUM)
    endfunction
    


endclass //dp_sink_base_sequence extends superClass
