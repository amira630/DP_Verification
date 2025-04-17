class dp_sink_base_sequence extends uvm_sequence #(dp_sink_sequence_item);
    `uvm_object_utils(dp_sink_base_sequence);

    dp_sink_sequence_item seq_item;
    dp_sink_sequence_item rsp_item;         // To capture responses

    int num_transactions = 1;

    function new(string name = "dp_sink_base_sequence");
        super.new(name);
    endfunction //new()

// Receive a request and process it
    task receive_request();
        `uvm_info(get_type_name(), "Receiving request transaction", UVM_MEDIUM)
        
        // Create and configure sequence item to receive a request
        seq_item = dp_sink_sequence_item::type_id::create("seq_item");
        start_item(seq_item);
        
        // Configure to receive 
        seq_item.is_reply = 1'b0;  // This is not a reply (we're receiving)
        
        finish_item(seq_item);
        
        // Get the response back
        get_response(rsp_item);

        // Wait for AUX_START_STOP = 1 (beginning of transaction)
            // Collect data until START_STOP = 0
            // Sample interface signals based on aux_start_stop signal
            while (dp_sink_vif.AUX_START_STOP) begin
                // Capture the current aux_in_out value from interface
                response_seq_item.aux_in_out.push_back(dp_sink_vif.AUX_IN_OUT);
                
                // Capture other signals as needed
                response_seq_item.cr_adj_lc = dp_sink_vif.CR_ADJ_LC;
                response_seq_item.cr_phy_instruct = dp_sink_vif.CR_PHY_Instruct;
                response_seq_item.eq_adj_lc = dp_sink_vif.EQ_ADJ_LC;
                response_seq_item.eq_phy_instruct = dp_sink_vif.EQ_PHY_Instruct;
                response_seq_item.cr_adj_bw = dp_sink_vif.CR_ADJ_BW;
                response_seq_item.eq_adj_bw = dp_sink_vif.EQ_ADJ_BW;
                
                @(posedge dp_sink_vif.clk);  // Wait for next clock cycle
            end
        
        // Process the received AUX data
        if (rsp_item.aux_in_out.size() > 0) begin
            process_aux_data(rsp_item.aux_in_out);
            `uvm_info(get_type_name(), $sformatf("Received request: cmd=0x%h, addr=0x%h, len=0x%h", 
                                          rsp_item.command, rsp_item.address, rsp_item.length), UVM_MEDIUM);
        end
        else begin
            `uvm_error(get_type_name(), "Received empty AUX data, cannot process request")
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
    
// Reply Transaction task
    // Use the command, address, length, and data extracted by process_aux_data
    // These are stored in rsp_item after processing the received AUX data
    task reply_transaction();
        // First receive a request
        receive_request();

        // Then send a reply based on the request
        `uvm_info(get_type_name(), "Starting reply transaction", UVM_MEDIUM)

        // Check if we have valid response data to reply to
        if (rsp_item == null) begin
            `uvm_error(get_type_name(), "Cannot send reply - no request data available in the reply_transaction task")
            return;
        end
        
        seq_item = dp_sink_sequence_item::type_id::create("seq_item");
    
        start_item(seq_item);

        // Set appropriate control signals for a reply transaction
        seq_item.is_reply = 1'b1;  // Indicate this is a reply transaction
        
        // Generate AUX data based on command, address, length and data
        seq_item.aux_in_out.delete();

        // Configure sequence item with parameters from the processed request
        // 1- Command:
        // I2C or Native AUX command
        if (rsp_item.command[3] == 1) begin     // Native command
            // Set the native reply command
            if (!std::randomize(seq_item.native_reply_cmd) with {
                seq_item.native_reply_cmd inside {AUX_ACK, AUX_NACK, AUX_DEFER};
            }) begin
                `uvm_error(get_type_name(), "Failed to randomize native reply command")
                seq_item.native_reply_cmd = AUX_ACK; // Default to ACK if randomization fails
            end
            `uvm_info(get_type_name(), $sformatf("Generated native reply command: %s", seq_item.native_reply_cmd.name()), UVM_MEDIUM)
        end else begin                          // I2C command
            // Set the I2C reply command
            if (!std::randomize(seq_item.i2c_reply_cmd) with {
                seq_item.i2c_reply_cmd inside {I2C_ACK, I2C_NACK, I2C_DEFER};
            }) begin
                `uvm_error(get_type_name(), "Failed to randomize I2C reply command")
                seq_item.i2c_reply_cmd = I2C_ACK; // Default to ACK if randomization fails
            end
            `uvm_info(get_type_name(), $sformatf("Generated I2C reply command: %s", seq_item.i2c_reply_cmd.name()), UVM_MEDIUM)
        end


        // Read OR Write command
        if (rsp_item.command[2:0] == 000) begin             // Write command
            pass
        end else if (rsp_item.command[2:0] == 001) begin    // Read command
            pass
        end begin  
            pass
        end

        seq_item.address = rsp_item.address;



        seq_item.length = rsp_item.length;



        seq_item.data = rsp_item.data;

        // RAL Calling
        // read_data = read_register(address, length);
        ///////////////////////////////////////////////////////////////////////////////////////////////////////
        ///////////////////////////// Correct the below code for sink not source //////////////////////////////
        ///////////////////////////////////////////////////////////////////////////////////////////////////////
        // First byte: command (lower 4 bits)
        seq_item.aux_in_out.push_back({4'b0000, rsp_item.command});
        
        // Next 2.5 bytes: address (20 bits)
        seq_item.aux_in_out.push_back(rsp_item.address[7:0]);        // First 8 bits
        seq_item.aux_in_out.push_back(rsp_item.address[15:8]);       // Next 8 bits
        seq_item.aux_in_out.push_back({4'b0000, rsp_item.address[19:16]}); // Last 4 bits + padding
        
        // Next byte: length
        seq_item.aux_in_out.push_back(rsp_item.length);
        
        // Add data bytes
        foreach(rsp_item.data[i])
            seq_item.aux_in_out.push_back(rsp_item.data[i]);
        
        `uvm_info(get_type_name(), $sformatf("Sending reply transaction: cmd=0x%h, addr=0x%h, len=0x%h, data_size=%0d", 
                rsp_item.command, rsp_item.address, rsp_item.length, rsp_item.data.size()), UVM_MEDIUM)

        // Send the response back
        finish_item(seq_item);
    
        // Get response
        get_response(rsp_item);
        
        `uvm_info(get_type_name(), "Reply transaction completed", UVM_MEDIUM)
    endtask

endclass //dp_sink_base_sequence extends superClass
