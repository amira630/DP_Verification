// Add timeout timer maybe
// Function to generate the expected transaction for Native AUX Read Transaction
task generate_native_aux_read_transaction(
    input dp_sink_sequence_item sink_item,  // Transaction from dp_sink_monitor
    input dp_tl_sequence_item tl_item,      // Transaction from dp_tl_monitor
    output dp_transaction expected_transaction, // Generated expected transaction
    input bit [3:0] override_command = 4'b0000,  // Default: Use tl_item.LPM_CMD
    input bit [19:0] override_address = 20'h00000, // Default: Use tl_item.LPM_Address
    input bit [7:0] override_length = 8'h00       // Default: Use tl_item.LPM_LEN
);

    // FSM states
    typedef enum logic [2:0] {
    IDLE_MODE,
    NATIVE_TALK_MODE,
    NATIVE_LISTEN_MODE_WAIT_ACK,
    NATIVE_LISTEN_MODE_WAIT_DATA
    } native_aux_fsm_state_e;

    native_aux_fsm_state_e current_state, next_state;

    bit [3:0] command;
    bit [19:0] address;
    bit [7:0] length;
    bit [7:0] data;
    int defer_counter = 0;
    bit [7:0] data_counter = 8'b00000000; // Counter for the number of data bytes received

    // Initialize the FSM
    current_state = IDLE_MODE;

    forever begin
        case (current_state)
            IDLE_MODE: begin
                // Wait for the next transaction
                ref_model_in_port.get(tl_item);

                if (tl_item.LPM_Transaction_VLD) begin
                    command = (override_command != 4'b0000) ? override_command : tl_item.LPM_CMD;
                    address = (override_address != 20'h00000) ? override_address : tl_item.LPM_Address;
                    length = (override_length != 8'h00) ? override_length : tl_item.LPM_LEN;

                    // Allocate the dynamic array based on the length
                    data = new[length];

                    if (command == AUX_NATIVE_READ) begin
                        `uvm_info(get_type_name(), "Starting Native AUX Read Transaction", UVM_LOW);
                        next_state = NATIVE_TALK_MODE;
                    end else begin
                        `uvm_error(get_type_name(), "Invalid LPM_CMD for Native AUX Read Transaction");
                        next_state = IDLE_MODE;
                    end
                end else begin
                    next_state = IDLE_MODE;
                end
            end

            NATIVE_TALK_MODE: begin

                // Assign the encoded value to aux_in_out
                // Encoded value: 1001|Address -> Address -> Address -> Length
    
                // Transmit the first byte of the read request
                expected_transaction.aux_in_out = {4'b1001, address[19:16]};
                // Raise the PHY_START_STOP signal
                expected_transaction.PHY_START_STOP = 1'b1;
                ;
                ref_model_out_port.write(expected_transaction);

                // Transmit the next two bytes of the address
                expected_transaction.aux_in_out = address[15:8];
                // Raise the PHY_START_STOP signal
                expected_transaction.PHY_START_STOP = 1'b1;

                ref_model_out_port.write(expected_transaction);

                expected_transaction.aux_in_out = address[7:0];
                // Raise the PHY_START_STOP signal
                expected_transaction.PHY_START_STOP = 1'b1;

                ref_model_out_port.write(expected_transaction);

                // Transmit the length byte
                expected_transaction.aux_in_out = length;
                // Raise the PHY_START_STOP signal
                expected_transaction.PHY_START_STOP = 1'b1;
                
                ref_model_out_port.write(expected_transaction);

                // // Lower the PHY_START_STOP signal
                // expected_transaction.PHY_START_STOP = 1'b0; 
                
                // // Send the expected transaction to the scoreboard
                // ref_model_out_port.write(expected_transaction);

                next_state = NATIVE_LISTEN_MODE_WAIT_ACK; // Wait for ACK/NACK/DEFER
            end

            NATIVE_LISTEN_MODE_WAIT_ACK: begin
    
                    // Wait for the next transaction
                    ref_model_in_port.get(sink_item);
    
                    // Extract the command
                    command = sink_item.aux_in_out[3:0]; // Second 4 bits

                    case (command)
                        AUX_ACK: begin // ACK
                            `uvm_info(get_type_name(), "Received AUX_ACK Command", UVM_LOW);
                            data_counter = length;
                            next_state = NATIVE_LISTEN_MODE_WAIT_DATA;
                        end

                        AUX_NACK: begin // NACK
                            `uvm_info(get_type_name(), "Received AUX_NACK Command", UVM_LOW);
                            next_state = NATIVE_TALK_MODE; //Retry the transaction
                        end

                        AUX_DEFER: begin // DEFER
                            `uvm_info(get_type_name(), "Received AUX_DEFER Command", UVM_LOW);
                            defer_counter = defer_counter + 1;
                            if (defer_counter == 8) 
                            begin
                                next_state = IDLE_MODE; // Restart from IDLE_MODE state after 8 DEFERs
                                expected_transaction.CTRL_Native_Failed = 1'b1; // Set CTRL_Native_Failed to indicate failure
                                `uvm_error(get_type_name(), "Native AUX Write Transaction Failed", UVM_LOW)
                                `uvm_info(get_type_name(), "Restarting from IDLE state after 8 DEFERs", UVM_LOW);
                            end 
                            else
                            begin
                                next_state = NATIVE_TALK_MODE; //Retry the transaction
                            end
                        end

                        AUX_RESERVED: begin // RESERVED
                            `uvm_info(get_type_name(), "Received AUX_RESERVED Command", UVM_LOW);
                            next_state = NATIVE_TALK_MODE; //Retry the transaction
                        end

                        default: begin // Invalid or unsupported command
                            `uvm_error(get_type_name(), $sformatf("Invalid or unsupported command: 0x%h", command));
                        end
                    endcase

                    //Note : Maybe add timeout timeout here to move to IDLE state if no response is received
 
            end

            NATIVE_LISTEN_MODE_WAIT_DATA: begin

                // Wait for the next transaction
                ref_model_in_port.get(sink_item);

                if (data_counter > 8'b00000000) begin
                
                    ref_model_in_port.get(sink_item);
                    data = sink_item.aux_in_out[7:0]; // Extract the data byte
                    data_counter = data_counter - 1'b1; // Decrement the data counter
                
                end

                      // Take action based on the command
                    if (command == AUX_ACK) begin // ACK
                            `uvm_info(get_type_name(), "Processing AUX_ACK Command", UVM_LOW);
                
                            // Populate the expected transaction
                            expected_transaction.SPM_Reply_ACK = I2C_ACK[3:2];
                            expected_transaction.SPM_Reply_ACK_VLD = 1'b1;
                            expected_transaction.SPM_Reply_Data = data;
                            expected_transaction.SPM_Reply_Data_VLD = 1'b0;
                
                            // Log the data being sent
                            `uvm_info(get_type_name(), $sformatf("Sending I2C_ACK Response: data_size=%0d", data.size()), UVM_LOW);

                            // Send the expected transaction to the scoreboard
                            ref_model_out_port.write(expected_transaction);

                            if (data_counter == 0) begin
                                // If all data bytes have been sent, move to IDLE state
                                `uvm_info(get_type_name(), "All data bytes sent, moving to IDLE state", UVM_LOW);
                                next_state = IDLE_MODE; // Move to IDLE_MODE state
                                break; // Exit the loop
                            end else begin
                                // Continue to wait for more data
                                next_state = NATIVE_LISTEN_MODE_WAIT_DATA;
                            end
                    end  
            end

            default: begin
                next_state = IDLE_MODE;
            end
        endcase

        // Update the current state
        current_state = next_state;

    end
endtask

// Add timeout timer maybe
// not sure what to do if 2 consecutive nacks happen
// Function to generate the expected transaction for Native AUX Write Transaction
task generate_native_aux_write_transaction(
    input dp_sink_sequence_item sink_item,  // Transaction from dp_sink_monitor
    input dp_tl_sequence_item tl_item,      // Transaction from dp_tl_monitor
    output dp_transaction expected_transaction, // Generated expected transaction
    input bit [3:0] override_command = 4'b0000,  // Default: Use tl_item.LPM_CMD
    input bit [19:0] override_address = 20'h00000, // Default: Use tl_item.LPM_Address
    input bit [7:0] override_length = 8'h00,      // Default: Use tl_item.LPM_LEN
    input bit [7:0] override_data[$] = {}         // Default: Use tl_item.LPM_Data
);

    // FSM states
    typedef enum logic [3:0] {
        IDLE_MODE,
        NATIVE_TALK_MODE,
        NATIVE_LISTEN_MODE_WAIT_ACK,
        NATIVE_LISTEN_MODE_WAIT_DATA,
        NATIVE_RETRANS_MODE,
        NATIVE_FAILED_TRANSACTION
    } native_aux_fsm_state_e;

    native_aux_fsm_state_e current_state, next_state;

    bit [3:0] command;
    bit [19:0] address;
    bit [7:0] length;
    bit [7:0] data[$];
    int defer_counter = 0;
    bit [7:0] success_counter = 8'b00000000 // Counter for successful number of bytes written

    // Initialize the FSM
    current_state = IDLE_MODE;

    forever begin
        case (current_state)
            IDLE_MODE: begin
                // Wait for the next transaction
                ref_model_in_port.get(tl_item);

                if (tl_item.LPM_Transaction_VLD) begin
                    command = (override_command != 4'b0000) ? override_command : tl_item.LPM_CMD;
                    address = (override_address != 20'h00000) ? override_address : tl_item.LPM_Address;
                    length = (override_length != 8'h00) ? override_length : tl_item.LPM_LEN;
                    data = (override_data.size() > 0) ? override_data : {tl_item.LPM_Data};

                    if (command == AUX_NATIVE_WRITE) begin
                        `uvm_info(get_type_name(), "Starting Native AUX Write Transaction", UVM_LOW);
                        next_state = NATIVE_TALK_MODE;
                    end else begin
                        `uvm_error(get_type_name(), "Invalid LPM_CMD for Native AUX Write Transaction");
                        next_state = IDLE_MODE;
                    end
                end else begin
                    next_state = IDLE_MODE;
                end
            end

            NATIVE_TALK_MODE: begin

                // Assign the encoded value to aux_in_out
                // Encoded value: 1000|LPM_Address -> LPM_Address -> LPM_Address -> LPM_LEN -> LPM_Data

                // Transmit the write request
                expected_transaction.aux_in_out = {4'b1000, address[19:16]}; // Byte 1
                // Raise the PHY_START_STOP signal
                expected_transaction.PHY_START_STOP = 1'b1
                ref_model_out_port.write(expected_transaction);

                expected_transaction.aux_in_out = address[15:8]; // Byte 2
                // Raise the PHY_START_STOP signal
                expected_transaction.PHY_START_STOP = 1'b1
                ref_model_out_port.write(expected_transaction);

                expected_transaction.aux_in_out = address[7:0]; // Byte 3
                // Raise the PHY_START_STOP signal
                expected_transaction.PHY_START_STOP = 1'b1
                ref_model_out_port.write(expected_transaction);

                expected_transaction.aux_in_out = length; // Byte 4
                // Raise the PHY_START_STOP signal
                expected_transaction.PHY_START_STOP = 1'b1
                ref_model_out_port.write(expected_transaction);

                // Transmit data bytes
                for (int i = 0; i < length; i++) begin
                    expected_transaction.aux_in_out = data[i];
                    ref_model_out_port.write(expected_transaction);
                    // Raise the PHY_START_STOP signal
                    expected_transaction.PHY_START_STOP = 1'b1
                end

                // // Lower the PHY_START_STOP signal
                // expected_transaction.PHY_START_STOP = 1'b0; 
                
                // // Send the expected transaction to the scoreboard
                // ref_model_out_port.write(expected_transaction);

                next_state = NATIVE_LISTEN_MODE_WAIT_ACK; // Wait for ACK/NACK/DEFER

            end

            NATIVE_LISTEN_MODE_WAIT_ACK: begin
                // Wait for the next transaction
                ref_model_in_port.get(sink_item);

                // Extract the command
                command = sink_item.aux_in_out[3:0]; // Second 4 bits

                case (command)
                    AUX_ACK: begin // ACK
                        `uvm_info(get_type_name(), "Received AUX_ACK Command", UVM_LOW);

                        // Populate the expected transaction
                        expected_transaction.LPM_Reply_ACK = AUX_ACK[1:0];
                        expected_transaction.LPM_Reply_ACK_VLD = 1'b1;
                        expected_transaction.LPM_Reply_Data = 8'h00; // No data for ACK
                        expected_transaction.LPM_Reply_Data_VLD = 1'b0;

                        // Send the expected transaction to the scoreboard
                        ref_model_out_port.write(expected_transaction);

                        next_state = IDLE_MODE; // Transaction successful, move to IDLE
                    end

                    AUX_NACK: begin // NACK
                        `uvm_info(get_type_name(), "Received AUX_NACK Command", UVM_LOW);

                        // Simulate acknowledgment for NACK
                        expected_transaction.LPM_Reply_ACK = AUX_NACK[1:0];
                        expected_transaction.LPM_Reply_ACK_VLD = 1'b1;
                        expected_transaction.LPM_Reply_Data = 8'h00; // No data for NACK
                        expected_transaction.LPM_Reply_Data_VLD = 1'b0;

                        // Send the expected transaction to the scoreboard
                        ref_model_out_port.write(expected_transaction);

                        next_state = NATIVE_RETRANS_MODE; // Retransmit missing bytes
                    end

                    AUX_DEFER: begin // DEFER
                        `uvm_info(get_type_name(), "Received AUX_DEFER Command", UVM_LOW);

                        // Simulate acknowledgment for DEFER
                        expected_transaction.LPM_Reply_ACK = AUX_DEFER[1:0];
                        expected_transaction.LPM_Reply_ACK_VLD = 1'b1;
                        expected_transaction.LPM_Reply_Data = 8'h00; // No data for DEFER
                        expected_transaction.LPM_Reply_Data_VLD = 1'b0;

                        // Send the expected transaction to the scoreboard
                        ref_model_out_port.write(expected_transaction);

                        defer_counter = defer_counter + 1;
                        if (defer_counter == 8) begin
                            next_state = NATIVE_FAILED_TRANSACTION; // Too many defers, fail the transaction
                        end else begin
                            next_state = NATIVE_TALK_MODE; // Retry the transaction
                        end
                    end

                    AUX_RESERVED: begin // RESERVED
                        `uvm_info(get_type_name(), "Received AUX_RESERVED Command", UVM_LOW);

                        // Simulate acknowledgment for RESERVED
                        expected_transaction.LPM_Reply_ACK = AUX_RESERVED[1:0];
                        expected_transaction.LPM_Reply_ACK_VLD = 1'b1;
                        expected_transaction.LPM_Reply_Data = 8'h00; // No data for RESERVED
                        expected_transaction.LPM_Reply_Data_VLD = 1'b0;

                        // Send the expected transaction to the scoreboard
                        ref_model_out_port.write(expected_transaction);

                        next_state = NATIVE_TALK_MODE; // Retry the transaction
                    end

                    default: begin // Invalid or unsupported command
                        `uvm_error(get_type_name(), $sformatf("Invalid or unsupported command: 0x%h", command));
                        next_state = IDLE_MODE;
                    end
                endcase
            end

            NATIVE_RETRANS_MODE: begin
                // Retry the write transaction
                `uvm_info(get_type_name(), "Retrying Native AUX Write Transaction", UVM_LOW);

                // Wait for the next transaction
                ref_model_in_port.get(tl_item);

                success_counter = tl_item.aux_in_out [7:0]; // Extract the number of successful bytes written
                
                // Assign the encoded value to aux_in_out
                // Encoded value: 1000|LPM_Address -> LPM_Address -> LPM_Address -> (length - success_counter) -> Remaining Data

                // Transmit the write request
                expected_transaction.aux_in_out = {4'b1000, address[19:16]}; // Byte 1
                // Raise the PHY_START_STOP signal
                expected_transaction.PHY_START_STOP = 1'b1
                ref_model_out_port.write(expected_transaction);

                expected_transaction.aux_in_out = address[15:8]; // Byte 2
                // Raise the PHY_START_STOP signal
                expected_transaction.PHY_START_STOP = 1'b1
                ref_model_out_port.write(expected_transaction);

                expected_transaction.aux_in_out = address[7:0]; // Byte 3
                // Raise the PHY_START_STOP signal
                expected_transaction.PHY_START_STOP = 1'b1
                ref_model_out_port.write(expected_transaction);

                expected_transaction.aux_in_out = (length - success_counter); // Byte 4
                // Raise the PHY_START_STOP signal
                expected_transaction.PHY_START_STOP = 1'b1
                ref_model_out_port.write(expected_transaction);

                // Transmit data bytes
                for (int i = success_counter; i <= length; i++) begin
                    expected_transaction.aux_in_out = data[i];
                    // Raise the PHY_START_STOP signal
                    expected_transaction.PHY_START_STOP = 1'b1
                    ref_model_out_port.write(expected_transaction);
                end

                // // Lower the PHY_START_STOP signal
                // expected_transaction.PHY_START_STOP = 1'b0; 
                
                // // Send the expected transaction to the scoreboard
                // ref_model_out_port.write(expected_transaction);

                next_state = NATIVE_LISTEN_MODE_WAIT_ACK; // Wait for ACK/NACK/DEFER
            end

            NATIVE_FAILED_TRANSACTION: begin
                // Transaction failed
                `uvm_error(get_type_name(), "Native AUX Write Transaction Failed", UVM_LOW);
                expected_transaction.CTRL_Native_Failed = 1'b1;
                ref_model_out_port.write(expected_transaction);
                next_state = IDLE_MODE;
            end

            default: begin
                next_state = IDLE_MODE;
            end
        endcase

        // Update the current state
        current_state = next_state;

    end
endtask