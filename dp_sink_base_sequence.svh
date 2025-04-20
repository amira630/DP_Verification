class dp_sink_base_sequence extends uvm_sequence #(dp_sink_sequence_item);
    `uvm_object_utils(dp_sink_base_sequence);

    dp_sink_sequence_item seq_item;
    dp_sink_sequence_item rsp_item;             // To capture responses
    dp_sink_sequence_item reply_seq_item;       // To rend the reply

    int num_transactions = 1;

    function new(string name = "dp_sink_base_sequence");
        super.new(name);
    endfunction //new()

    // Interrupt Sequence
    task Interrupt();
        // Create and configure sequence item
        seq_item = dp_sink_sequence_item::type_id::create("seq_item");

        if (seq_item == null) begin
            `uvm_info(get_type_name(), "seq_item creation failed", UVM_MEDIUM)
            wait(seq_item != null);
        end

        // Set the sequence item signals
        start_item(seq_item);
        `uvm_info(get_type_name(), "start_item for interrupt", UVM_MEDIUM)
        seq_item.sink_operation = Interrupt_operation;  // Set the operation type to IRQ
        finish_item(seq_item);                          // Send the sequence item to the driver
        `uvm_info(get_type_name(), "finish_item for interrupt", UVM_MEDIUM)
    endtask

    // This function is called to start the sequence
    // task Link_INIT();
    //     `uvm_info(get_type_name(), "Initialization transaction", UVM_MEDIUM)

    //     // Create and configure sequence item
    //     seq_item = dp_sink_sequence_item::type_id::create("seq_item");
    //     rsp_item = dp_sink_sequence_item::type_id::create("rsp_item");
    //     reply_seq_item = dp_sink_sequence_item::type_id::create("reply_seq_item");

    //     // Phase 1: HPD operation
    //     start_item(seq_item);
    //     `uvm_info(get_type_name(), "start HPD phase", UVM_MEDIUM)
    //     seq_item.sink_operation = HPD_operation;        // Set the operation type to HPD
    //     seq_item.HPD_Signal = 1'b1;                     // Set the HPD signal to high
    //     finish_item(seq_item);                          // Send the sequence item to the driver
    //     `uvm_info(get_type_name(), "finish HPD phase", UVM_MEDIUM)

    //     // Reply Operation in forever loop 
    //     // This is used to send the reply to the driver
    //     forever begin
    //         // wait for recieive transaction to be called
    //         receive_transaction(rsp_item);                        // Receive the request transaction from the driver

    //         // According to the command, set the operation type to Reply
    //         case (rsp_item.command[3:0])
    //             4'b0000: begin          // EDID Finished
    //                 start_item(reply_seq_item);                          // Start the response item
    //                 `uvm_info(get_type_name(), "Start EDID-Finish Reply", UVM_MEDIUM)
    //                 reply_seq_item.sink_operation = Reply_operation;     // Set the operation type to Reply
    //                 reply_seq_item.PHY_START_STOP = 1'b1;                // Set the PHY_START_STOP signal to high
    //                 reply_seq_item.AUX_IN_OUT = 8'h00;                   // Set the AUX_IN_OUT signal to 0
    //                 finish_item(reply_seq_item);                         // Send the sequence item to the driver
    //                 `uvm_info(get_type_name(), "Finish EDID-Finish Reply", UVM_MEDIUM) 
    //             end
    //             4'b0101: begin          // I2C Read Request (EDID)
    //                 edid_reading_transaction(rsp_item);
    //             end
    //             4'b1000: begin          // Native Write Request
                    
    //             end
    //             4'b1001: begin          // Native Read Request
                    
    //             end
    //             default: begin
    //                 `uvm_error(get_type_name(), "Unknown command type (Invalid command)")
    //             end
    //         endcase
            
    //         // Check if the Link training is finished to break the loop
    //         if (rsp_item.link_init_completed) begin
    //             `uvm_info(get_type_name(), "Link training finished", UVM_MEDIUM)
    //             break; // Exit the forever loop
    //         end
    //     end

    //     `uvm_info(get_type_name(), "Finished Link_INIT transaction", UVM_MEDIUM)
    // endtask




    // Helper function to process AUX data from response
    // function void process_aux_data(ref dp_sink_sequence_item rsp_item);
    //     // Check if the AUX data is valid
    //     if (rsp_item.aux_in_out.size() < 3) begin
    //         `uvm_error(get_type_name(), "AUX data too short, cannot process request")
    //         return;
    //     end

    //     // Clear previous values
    //     rsp_item.command = 0;
    //     rsp_item.address = 0;
    //     rsp_item.length = 0;
    //     rsp_item.data.delete();
        
    //     bit [7:0] aux_data = 0; 

    //     int i = 0;

    //     // Extract fields:
    //     for (i = 0; i < rsp_item.aux_in_out.size(); i++) begin
    //         aux_data = rsp_item.aux_in_out[i];
    //         if (i == 0) begin
    //             rsp_item.command = aux_data[7:4]; 
    //             rsp_item.address = aux_data[3:0]; 
    //         end 
    //         else if (i == 1 || i == 2) begin
    //             rsp_item.address = {rsp_item.address, aux_data[7:0]};
    //         end
    //         else if (i == 3) begin
    //             rsp_item.length = aux_data[7:0]; 
    //         end
    //         else begin
    //             rsp_item.data.push_back(aux_data); 
    //         end
    //     end
        
    //     rsp_item.aux_in_out.delete();

    //     `uvm_info(get_type_name(), $sformatf("process_aux_data - Processed AUX: cmd=0x%h, addr=0x%h, len=0x%h, data_size=%0d", 
    //               rsp_item.command, rsp_item.address, rsp_item.length, rsp_item.data.size()), UVM_MEDIUM)
    // endfunction

    // // Helper function to Receive a Request transaction
    // // This function is used to receive a request transaction from the driver and store it in the response sequence item then process it
    // function void receive_transaction(ref dp_sink_sequence_item rsp_item);
    //     get_response(rsp_item);                        // Get the response from the driver

    //     // Check if the response is valid
    //     if (rsp_item == null) begin
    //         `uvm_error(get_type_name(), "Received empty response, cannot process request")
    //         return;
    //     end

    //     `uvm_info(get_type_name(), "Received Byte 0 in new sequence", UVM_MEDIUM)


    //     while (rsp_item.AUX_START_STOP) begin
    //         // Check if the response is valid
    //         if (rsp_item == null) begin
    //             `uvm_error(get_type_name(), "Received empty response, cannot process request")
    //             return;
    //         end

    //         rsp_item.aux_in_out.push_back(rsp_item.AUX_IN_OUT);

    //         start_item(seq_item);                          // Start the response item
    //         seq_item.sink_operation = HPD_operation;       // Set the operation type to HPD
    //         seq_item.HPD_Signal = 1'b1;                     // Set the HPD signal to low
    //         finish_item(seq_item);                          // Send the sequence item to the driver

    //         get_response(rsp_item);                        // Get the response from the driver
    //         //`uvm_info(get_type_name(), "Receive ", UVM_MEDIUM)
    //     end

    //     // Process the response
    //     if (rsp_item.aux_in_out.size() > 0) begin
    //         process_aux_data(rsp_item);                 // Process the AUX data from the response
    //         `uvm_info(get_type_name(), $sformatf("Processed AUX: cmd=0x%h, addr=0x%h, len=0x%h", 
    //             rsp_item.command, rsp_item.address, rsp_item.length), UVM_MEDIUM)
    //     end else begin
    //         `uvm_error(get_type_name(), "Received empty AUX data, cannot process request")
    //     end
        
    // endfunction

    // function void edid_reading_transaction(ref dp_sink_sequence_item rsp_item);
    //     int k = 0; 
    //     int index = 0; 
    //     // ADDRESS-ONLY transaction

    //     // NOW: the rsp_item has the command and address of the transaction
    //     start_item(reply_seq_item);                          // Start the response item
    //     `uvm_info(get_type_name(), "Start address-only Reply", UVM_MEDIUM)
    //     reply_seq_item.sink_operation = Reply_operation;     // Set the operation type to Reply
    //     reply_seq_item.PHY_START_STOP = 1'b1;                // Set the PHY_START_STOP signal to high
    //     reply_seq_item.AUX_IN_OUT = 8'h00;                   // Set the AUX_IN_OUT signal to 0
    //     finish_item(reply_seq_item);                         // Send the sequence item to the driver
    //     `uvm_info(get_type_name(), "Finish address-only Reply", UVM_MEDIUM)

    //     // NOW: Sink is ready to send/receive the 128 bytes of data
    //     // Phase 3: EDID 128 bytes data transaction
    //     while (k<128 && rsp_item.command[2] == 1) begin
    //         `uvm_info(get_type_name(), "Received sequence to start EDID", UVM_MEDIUM)
    //         receive_transaction(rsp_item);                        // Receive the request transaction from the driver
            
    //         repeat(1+(rsp_item.length+1)) begin
    //             if (index == 0) begin
    //                 start_item(reply_seq_item);                          // Start the response item
    //                 `uvm_info(get_type_name(), "Start address-only Reply", UVM_MEDIUM)
    //                 reply_seq_item.rand_mode(0);                         // Disable randomization for the first byte
    //                 reply_seq_item.sink_operation = Reply_operation;     // Set the operation type to Reply
    //                 reply_seq_item.PHY_START_STOP = 1'b1;                // Set the PHY_START_STOP signal to high
    //                 reply_seq_item.i2c_reply_cmd = I2C_ACK;              // Set the I2C reply command to ACK
    //                 reply_seq_item.AUX_IN_OUT = {reply_seq_item.i2c_reply_cmd, 4'h0};   // I2C_ACK|AUX_ACK
    //                 finish_item(reply_seq_item);                         // Send the sequence item to the driver
    //                 `uvm_info(get_type_name(), "Finish address-only Reply", UVM_MEDIUM)
    //             end else begin
    //                 start_item(reply_seq_item);                          // Start the response item
    //                 `uvm_info(get_type_name(), "Start address-only Reply", UVM_MEDIUM)
    //                 reply_seq_item.sink_operation = Reply_operation;     // Set the operation type to Reply
    //                 reply_seq_item.PHY_START_STOP = 1'b1;                // Set the PHY_START_STOP signal to high
    //                 if (!std::randomize(reply_data)) begin
    //                     `uvm_error(get_type_name(), "Failed to randomize reply data")
    //                     reply_data = 8'h00;  // Default value if randomization fails
    //                 end
    //                 reply_seq_item.AUX_IN_OUT = reply_data;              // Set the AUX_IN_OUT signal to the data byte
    //                 finish_item(reply_seq_item);                         // Send the sequence item to the driver
    //                 `uvm_info(get_type_name(), "Finish address-only Reply", UVM_MEDIUM)
    //             end
    //             index++;                                    // Increment the loop counter 
    //         end
    //         k++;                                    // Increment the loop counter
    //     end

    //     // Last Sequence to know that the EDID Reading is finished
    //     receive_transaction(rsp_item);                        // Receive the request transaction from the driver

    //     if (rsp_item.command[2] == 0) begin                     // Indicate that the EDID Reading is finished
    //         start_item(reply_seq_item);                          // Start the response item
    //         `uvm_info(get_type_name(), "Start EDID-Finish Reply", UVM_MEDIUM)
    //         reply_seq_item.sink_operation = Reply_operation;     // Set the operation type to Reply
    //         reply_seq_item.PHY_START_STOP = 1'b1;                // Set the PHY_START_STOP signal to high
    //         reply_seq_item.AUX_IN_OUT = 8'h00;                   // Set the AUX_IN_OUT signal to 0
    //         finish_item(reply_seq_item);                         // Send the sequence item to the driver
    //         `uvm_info(get_type_name(), "Finish EDID-Finish Reply", UVM_MEDIUM) 
    //     end 
    //     else begin
    //         `uvm_error(get_type_name(), "ERROR, EDID Reading is not finished")
    //         return;
    //     end
    //     `uvm_info(get_type_name(), "Finished EDID transaction", UVM_MEDIUM)
        
    // endfunction
    
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
