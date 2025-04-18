class dp_sink_base_sequence extends uvm_sequence #(dp_sink_sequence_item);
    `uvm_object_utils(dp_sink_base_sequence);

    dp_sink_sequence_item seq_item;
    dp_sink_sequence_item rsp_item;             // To capture responses
    dp_sink_sequence_item reply_seq_item;       // To rend the reply

    int num_transactions = 1;

    function new(string name = "dp_sink_base_sequence");
        super.new(name);
    endfunction //new()

    // This function is called to start the sequence
    task Link_INIT();
        `uvm_info(get_type_name(), "Initialization transaction", UVM_MEDIUM)

        // Create and configure sequence item
        seq_item = dp_sink_sequence_item::type_id::create("seq_item");
        rsp_item = dp_sink_sequence_item::type_id::create("rsp_item");

        // Phase 1: HPD operation
        start_item(seq_item);
        `uvm_info(get_type_name(), "start HPD phase", UVM_MEDIUM)
        seq_item.sink_operation = HPD_operation;        // Set the operation type to HPD
        seq_item.HPD_Signal = 1'b1;                     // Set the HPD signal to high
        finish_item(seq_item);                          // Send the sequence item to the driver
        `uvm_info(get_type_name(), "finish HPD phase", UVM_MEDIUM)

        get_response(rsp_item);                        // Get the response from the driver
        `uvm_info(get_type_name(), "Received HPD response", UVM_MEDIUM)

        // ADDRESS-ONLY transaction
        while (rsp_item.AUX_START_STOP) begin
            // Check if the response is valid
            if (rsp_item == null) begin
                `uvm_error(get_type_name(), "Received empty response, cannot process request")
                return;
            end

            rsp_item.aux_in_out.push_back(rsp_item.AUX_IN_OUT);

            start_item(seq_item);                          // Start the response item
            seq_item.sink_operation = HPD_operation;       // Set the operation type to HPD
            seq_item.HPD_Signal = 1'b1;                     // Set the HPD signal to low
            finish_item(seq_item);                          // Send the sequence item to the driver

            get_response(rsp_item);                        // Get the response from the driver
            `uvm_info(get_type_name(), "Receive address-only", UVM_MEDIUM)
        end

        // After the last loop the rsp_item has the address-only transaction data and ready to be processed
        // Check if the response is valid
        if (rsp_item == null) begin
            `uvm_error(get_type_name(), "Received empty response, cannot process request")
            return;
        end


        // Process the response
        if (rsp_item.aux_in_out.size() > 0) begin
            process_aux_data(rsp_item);                 // Process the AUX data from the response
            `uvm_info(get_type_name(), $sformatf("Processed AUX: cmd=0x%h, addr=0x%h, len=0x%h", 
                rsp_item.command, rsp_item.address, rsp_item.length), UVM_MEDIUM)
        end else begin
            `uvm_error(get_type_name(), "Received empty AUX data, cannot process request")
        end
        

        int flag = 1;                       // Flag to go in/out the loop
        int i = 0;                          // Loop counter

        // EDID 
        while (i<128) begin
            while (flag) begin
                flag = 0;                // Reset the flag
                get_response(rsp_item);                        // Get the response from the driver
                `uvm_info(get_type_name(), "Received HPD response", UVM_MEDIUM)

                // Check if the response is valid
                if (rsp_item == null) begin
                    `uvm_error(get_type_name(), "Received empty response, cannot process request")
                    return;
                end

                // Store the response data in the response sequence item
                rsp_item.aux_in_out.push_back(rsp_item.AUX_IN_OUT);

                if (rsp_item.AUX_START_STOP == 1) begin
                    flag = 1;                               // Set the flag tos go in the loop
                    `uvm_info(get_type_name(), "AUX_START_STOP signal is high, continue processing", UVM_MEDIUM)
                end
                else begin
                    `uvm_info(get_type_name(), "AUX_START_STOP signal is low, stop processing", UVM_MEDIUM)
                end
                //@(posedge dp_sink_vif.clk);                 // Wait for the next clock edge
            end

            // Process the response
            if (rsp_item.aux_in_out.size() > 0) begin
                process_aux_data(rsp_item);                 // Process the AUX data from the response
                `uvm_info(get_type_name(), $sformatf("Processed AUX: cmd=0x%h, addr=0x%h, len=0x%h", 
                    rsp_item.command, rsp_item.address, rsp_item.length), UVM_MEDIUM)
            end else begin
                `uvm_error(get_type_name(), "Received empty AUX data, cannot process request")
            end


            // Phase 2: Reply operation
            // Create and configure sequence item for reply operation
            reply_seq_item = dp_sink_sequence_item::type_id::create("reply_seq_item");

            // Check if we have valid response data to reply to
            if (rsp_item == null) begin
                `uvm_error(get_type_name(), "Cannot send reply - no request data available in the reply_transaction task")
                return;
            end


            $cast(reply_seq_item, rsp_item.clone());                            // Clone the response item to the reply item

            int j = 0;
            // Loop to send the reply operation

            repeat(2) begin
                start_item(reply_seq_item);
                `uvm_info(get_type_name(), "Start reply phase", UVM_MEDIUM)
                reply_seq_item.sink_operation = Reply_operation;                    // Set the operation type to Reply
                if (i == 0) begin                                                   // Address-only transaction 
                    reply_seq_item.PHY_START_STOP = 1'b1;                           // Set the PHY_START_STOP signal to high
                    reply_seq_item.AUX_IN_OUT = 8'h00;                              // Set the AUX_IN_OUT signal to 0
                end

            end 
            
            // else begin                                                          // Data transaction
            //     while () begin
                    
            //     end
            // end
            
            end_item(reply_seq_item);                                           // Send the sequence item to the driver
            `uvm_info(get_type_name(), "Finish reply phase", UVM_MEDIUM)
                
        i++;                                                            // Increment the loop counter
        end
        `uvm_info(get_type_name(), "Finished Link_INIT transaction", UVM_MEDIUM)

    endtask




    // Helper function to process AUX data from response
    function void process_aux_data(ref dp_sink_sequence_item rsp_item);
        // Check if the AUX data is valid
        if (rsp_item.aux_in_out.size() < 3) begin
            `uvm_error(get_type_name(), "AUX data too short, cannot process request")
            return;
        end

        bit [31:0] combined_data = 0;
        int bit_index = 0;
        
        // Clear previous values
        rsp_item.command = 0;
        rsp_item.address = 0;
        rsp_item.length = 0;
        rsp_item.data.delete();
        
        // Combine the first 4 bytes into a 32-bit value
        for (int i = 0; i < rsp_item.aux_in_out.size(); i++) begin
            combined_data[bit_index+:8] = aux_in_out[i]; 
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
        for (int i = 4; i < aux_in_out.size(); i++) begin
            rsp_item.data.push_back(aux_in_out[i]);
        end
        
        `uvm_info(get_type_name(), $sformatf("process_aux_data - Processed AUX: cmd=0x%h, addr=0x%h, len=0x%h, data_size=%0d", 
                  rsp_item.command, rsp_item.address, rsp_item.length, rsp_item.data.size()), UVM_MEDIUM)
    endfunction
    
// // Reply Transaction task
//     // Use the command, address, length, and data extracted by process_aux_data
//     // These are stored in rsp_item after processing the received AUX data
//     task reply_transaction();
//         // First receive a request
//         receive_request();

//         // Then send a reply based on the request
//         `uvm_info(get_type_name(), "Starting reply transaction", UVM_MEDIUM)

//         // Check if we have valid response data to reply to
//         if (rsp_item == null) begin
//             `uvm_error(get_type_name(), "Cannot send reply - no request data available in the reply_transaction task")
//             return;
//         end
        
//         seq_item = dp_sink_sequence_item::type_id::create("seq_item");
    
//         start_item(seq_item);

//         // Set appropriate control signals for a reply transaction
//         seq_item.is_reply = 1'b1;  // Indicate this is a reply transaction
        
//         // Generate AUX data based on command, address, length and data
//         seq_item.aux_in_out.delete();

//         // Configure sequence item with parameters from the processed request
//         // 1- Command:
//         // I2C or Native AUX command
//         if (rsp_item.command[3] == 1) begin     // Native command
//             // Set the native reply command
//             if (!std::randomize(seq_item.native_reply_cmd) with {
//                 seq_item.native_reply_cmd inside {AUX_ACK, AUX_NACK, AUX_DEFER};
//             }) begin
//                 `uvm_error(get_type_name(), "Failed to randomize native reply command")
//                 seq_item.native_reply_cmd = AUX_ACK; // Default to ACK if randomization fails
//             end
//             `uvm_info(get_type_name(), $sformatf("Generated native reply command: %s", seq_item.native_reply_cmd.name()), UVM_MEDIUM)
//         end else begin                          // I2C command
//             // Set the I2C reply command
//             if (!std::randomize(seq_item.i2c_reply_cmd) with {
//                 seq_item.i2c_reply_cmd inside {I2C_ACK, I2C_NACK, I2C_DEFER};
//             }) begin
//                 `uvm_error(get_type_name(), "Failed to randomize I2C reply command")
//                 seq_item.i2c_reply_cmd = I2C_ACK; // Default to ACK if randomization fails
//             end
//             `uvm_info(get_type_name(), $sformatf("Generated I2C reply command: %s", seq_item.i2c_reply_cmd.name()), UVM_MEDIUM)
//         end


//         // Read OR Write command
//         if (rsp_item.command[2:0] == 000) begin             // Write command
//             pass
//         end else if (rsp_item.command[2:0] == 001) begin    // Read command
//             pass
//         end begin  
//             pass
//         end

//         seq_item.address = rsp_item.address;



//         seq_item.length = rsp_item.length;



//         seq_item.data = rsp_item.data;

//         // RAL Calling
//         // read_data = read_register(address, length);
//         ///////////////////////////////////////////////////////////////////////////////////////////////////////
//         ///////////////////////////// Correct the below code for sink not source //////////////////////////////
//         ///////////////////////////////////////////////////////////////////////////////////////////////////////
//         // First byte: command (lower 4 bits)
//         seq_item.aux_in_out.push_back({4'b0000, rsp_item.command});
        
//         // Next 2.5 bytes: address (20 bits)
//         seq_item.aux_in_out.push_back(rsp_item.address[7:0]);        // First 8 bits
//         seq_item.aux_in_out.push_back(rsp_item.address[15:8]);       // Next 8 bits
//         seq_item.aux_in_out.push_back({4'b0000, rsp_item.address[19:16]}); // Last 4 bits + padding
        
//         // Next byte: length
//         seq_item.aux_in_out.push_back(rsp_item.length);
        
//         // Add data bytes
//         foreach(rsp_item.data[i])
//             seq_item.aux_in_out.push_back(rsp_item.data[i]);
        
//         `uvm_info(get_type_name(), $sformatf("Sending reply transaction: cmd=0x%h, addr=0x%h, len=0x%h, data_size=%0d", 
//                 rsp_item.command, rsp_item.address, rsp_item.length, rsp_item.data.size()), UVM_MEDIUM)

//         // Send the response back
//         finish_item(seq_item);
    
//         // Get response
//         get_response(rsp_item);
        
//         `uvm_info(get_type_name(), "Reply transaction completed", UVM_MEDIUM)
//     endtask

endclass //dp_sink_base_sequence extends superClass
