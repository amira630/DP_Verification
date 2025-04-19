typedef enum logic [2:0] {
    IDLE,
    ADDRESS_ONLY,
    READ_EDID,
    STOP_CONDITION,
    ERROR
} fsm_state_e;

fsm_state_e current_state, next_state;

task generate_i2c_over_aux_transaction_fsm(
    input dp_transaction received_transaction,
    output dp_transaction expected_transaction
);
    bit [3:0] command;       // First 4 bits: Command
    bit [7:0] address;       // Last 8 bits of address
    bit [7:0] length;        // Next 8 bits: Length
    bit [7:0] data[$];       // Remaining bits: Data
    bit ack_count = 0;       // Acknowledgment counter

    current_state = IDLE; // Start in the IDLE state

    forever begin
        case (current_state)
            IDLE: begin
                // Wait for a valid transaction
                if (ref_model_in_port.try_get(received_transaction)) begin
                    if (received_transaction.SPM_Transaction_VLD) begin
                        next_state = ADDRESS_ONLY;
                    end else begin
                        `uvm_warning(get_type_name(), "SPM_Transaction_VLD is not asserted");
                        next_state = ERROR;
                    end
                end
            end

            ADDRESS_ONLY: begin
                // Step 1: Address-only transaction
                if (received_transaction.SPM_CMD == AUX_I2C_READ && received_transaction.SPM_LEN == 0) begin
                address = received_transaction.SPM_Address; // Extract the address from the received transaction

                // Assign the encoded value to aux_in_out
                // Encoded value: 0101|0000 -> 00000000 -> SPM_Address

                // Byte 1
                expected_transaction.aux_in_out = 8'b0101_0000;
                // Raise the start_stop signal
                expected_transaction.start_stop = 1'b1;

                // Send the expected transaction to the scoreboard
                ref_model_out_port.write(expected_transaction);
                
                // Byte 2
                expected_transaction.aux_in_out = 8'b0000_0000;

                // Send the expected transaction to the scoreboard
                ref_model_out_port.write(expected_transaction);
                
                // Byte 3
                expected_transaction.aux_in_out = address; 
                
                // Send the expected transaction to the scoreboard
                ref_model_out_port.write(expected_transaction);

                // // Simulate the encoded Address-only I2C-over-AUX transaction
                // `uvm_info(get_type_name(), "Transmitting Address-only I2C-over-AUX transaction", UVM_LOW);
                // `uvm_info(get_type_name(), $sformatf("AUX_IN_OUT: 0101|0000 -> 00000000 -> 00000000 (START_STOP=1, MOT=1, I2C Address=0000000)"), UVM_LOW);

                // Wait for the next transaction
                ref_model_in_port.get(received_transaction);
                
                    // Extract the command
                    command = received_transaction.aux_in_out[7:4]; // First 4 bits
                
                    // Take action based on the command
                    case (command)
                        I2C_ACK: begin // ACK
                            `uvm_info(get_type_name(), "Processing I2C_ACK Command", UVM_LOW);
                
                            // Populate the expected transaction
                            expected_transaction.SPM_Reply_ACK = I2C_ACK[3:2];
                            expected_transaction.SPM_Reply_ACK_VLD = 1'b1;
                            expected_transaction.SPM_Reply_Data = 8'h00;
                            expected_transaction.SPM_Reply_Data_VLD = 1'b0;
                            ack_count = 1; // Increment the ack_count to exit the loop
                
                            // Log the data being sent
                            `uvm_info(get_type_name(), $sformatf("Sending I2C_ACK Response: data_size=%0d", data.size()), UVM_LOW);
                        end
                
                        I2C_NACK: begin // NACK
                            `uvm_info(get_type_name(), "Processing I2C_NACK Command", UVM_LOW);
                
                            // Simulate acknowledgment for NACK
                            expected_transaction.SPM_Reply_ACK = I2C_NACK[3:2];
                            expected_transaction.SPM_Reply_ACK_VLD = 1'b1;
                            expected_transaction.SPM_Reply_Data = 8'h00; // No data for NACK
                            expected_transaction.SPM_Reply_Data_VLD = 1'b0;
                
                            // Log the acknowledgment
                            `uvm_info(get_type_name(), "I2C_NACK Command Acknowledged", UVM_LOW);
                        end
                
                        I2C_DEFER: begin // DEFER
                            `uvm_info(get_type_name(), "Processing I2C_DEFER Command", UVM_LOW);
                
                            // Simulate acknowledgment for DEFER
                            expected_transaction.SPM_Reply_ACK = I2C_DEFER[3:2];
                            expected_transaction.SPM_Reply_ACK_VLD = 1'b1;
                            expected_transaction.SPM_Reply_Data = 8'h00; // No data for DEFER
                            expected_transaction.SPM_Reply_Data_VLD = 1'b0;
                
                            // Log the acknowledgment
                            `uvm_info(get_type_name(), "I2C_DEFER Command Acknowledged", UVM_LOW);
                        end
                
                        I2C_RESERVED: begin // RESERVED
                            `uvm_info(get_type_name(), "Processing I2C_RESERVED Command", UVM_LOW);
                
                            // Simulate acknowledgment for RESERVED
                            expected_transaction.SPM_Reply_ACK = I2C_RESERVED[3:2];
                            expected_transaction.SPM_Reply_ACK_VLD = 1'b1;
                            expected_transaction.SPM_Reply_Data = 8'h00; // No data for RESERVED
                            expected_transaction.SPM_Reply_Data_VLD = 1'b0;
                
                            // Log the acknowledgment
                            `uvm_info(get_type_name(), "I2C_RESERVED Command Acknowledged", UVM_LOW);
                        end
                
                        default: begin // Invalid or unsupported command
                            `uvm_error(get_type_name(), $sformatf("Invalid or unsupported command: 0x%h", command));
                        end
                    endcase
                
                    // Send the expected transaction to the scoreboard
                    ref_model_out_port.write(expected_transaction);

                    next_state = READ_EDID;
                end else begin
                    `uvm_error(get_type_name(), "Invalid SPM_CMD or SPM_LEN for I2C-over-AUX transaction");
                    next_state = ERROR;
                end
            end

            READ_EDID: begin
                // Step 2: Read EDID data (128 bytes)
                ack_count = 0;
                while (ack_count < 128) begin
                    // Wait for the next transaction
                    ref_model_in_port.get(received_transaction);

                    if (received_transaction.SPM_Transaction_VLD) begin
                        command = received_transaction.aux_in_out[7:4]; // Extract the command
                        data = received_transaction.aux_in_out[7:0];   // Extract the data

                        case (command)
                            I2C_ACK: begin
                                `uvm_info(get_type_name(), "Processing I2C_ACK Command", UVM_LOW);

                                // Populate the expected transaction
                                expected_transaction.SPM_Reply_ACK = I2C_ACK[3:2];
                                expected_transaction.SPM_Reply_ACK_VLD = 1'b1;
                                expected_transaction.SPM_Reply_Data = data;
                                expected_transaction.SPM_Reply_Data_VLD = 1'b1;

                                // Send the expected transaction to the scoreboard
                                ref_model_out_port.write(expected_transaction);

                                ack_count++;
                            end

                            I2C_NACK: begin
                                `uvm_info(get_type_name(), "Processing I2C_NACK Command", UVM_LOW);

                                // Simulate acknowledgment for NACK
                                expected_transaction.SPM_Reply_ACK = I2C_NACK[3:2];
                                expected_transaction.SPM_Reply_ACK_VLD = 1'b1;
                                expected_transaction.SPM_Reply_Data = 8'h00; // No data for NACK
                                expected_transaction.SPM_Reply_Data_VLD = 1'b0;

                                // Send the expected transaction to the scoreboard
                                ref_model_out_port.write(expected_transaction);
                            end

                            default: begin
                                `uvm_error(get_type_name(), $sformatf("Invalid or unsupported command: 0x%h", command));
                                next_state = ERROR;
                            end
                        endcase
                    end else begin
                        `uvm_warning(get_type_name(), "SPM_Transaction_VLD is not asserted");
                        next_state = ERROR;
                    end
                end

                next_state = STOP_CONDITION;
            end

            STOP_CONDITION: begin
                // Step 3: Address-only transaction with MOT=0 (STOP condition)
                if (received_transaction.SPM_CMD == AUX_I2C_READ && received_transaction.SPM_LEN == 0) begin
                    // Byte 1
                    expected_transaction.aux_in_out = 8'b0001_0000;
                    expected_transaction.start_stop = 1'b1; // Raise the start_stop signal
                    ref_model_out_port.write(expected_transaction);

                    // Byte 2
                    expected_transaction.aux_in_out = 8'b0000_0000;
                    ref_model_out_port.write(expected_transaction);

                    // Byte 3
                    expected_transaction.aux_in_out = address;
                    ref_model_out_port.write(expected_transaction);

                    // Log the transaction
                    `uvm_info(get_type_name(), "STOP condition transaction sent", UVM_LOW);

                    next_state = IDLE; // Return to IDLE after completing the transaction
                end else begin
                    `uvm_error(get_type_name(), "Invalid SPM_CMD or SPM_LEN for STOP condition");
                    next_state = ERROR;
                end
            end

            ERROR: begin
                // Handle errors
                `uvm_error(get_type_name(), "Error occurred in FSM");
                next_state = IDLE; // Return to IDLE after handling the error
            end

            default: begin
                next_state = IDLE; // Default state
            end
        endcase

        // Update the current state
        current_state = next_state;
    end
endtask


function void generate_native_aux_write_transaction(
    input dp_transaction received_transaction,
    output dp_transaction expected_transaction,
    input bit [3:0] override_command = 4'b0000,  // Default: Use received_transaction.LPM_CMD
    input bit [19:0] override_address = 20'h00000, // Default: Use received_transaction.LPM_Address
    input bit [7:0] override_length = 8'h00,      // Default: Use received_transaction.LPM_LEN
    input bit [7:0] override_data[$] = {}         // Default: Use received_transaction.LPM_Data
);
    // Decode the aux_in_out signal
    bit [3:0] command;       // First 4 bits: Command
    bit [19:0] address;      // Address
    bit [7:0] length;        // Length
    bit [7:0] data[$];       // Data
    bit ack_count = 0;       // Ack counter

    // Use overrides if provided, otherwise use defaults from received_transaction
    command = (override_command != 4'b0000) ? override_command : received_transaction.LPM_CMD;
    address = (override_address != 20'h00000) ? override_address : received_transaction.LPM_Address;
    length = (override_length != 8'h00) ? override_length : received_transaction.LPM_LEN;
    data = (override_data.size() > 0) ? override_data : {received_transaction.LPM_Data};

    while (ack_count < 1) begin
        // Wait for the next transaction
        ref_model_in_port.get(received_transaction);

        // Copy the received transaction
        expected_transaction.copy(received_transaction);

        // Initialize outputs
        expected_transaction.LPM_Reply_ACK = 1'b0;
        expected_transaction.LPM_Reply_ACK_VLD = 1'b0;
        expected_transaction.LPM_Reply_DATA = 8'h00;
        expected_transaction.LPM_Reply_DATA_VLD = 1'b0;
        expected_transaction.LPM_Native_I2C = 1'b0;

        // Check if the transaction is valid
        if (received_transaction.LPM_Transaction_VLD) begin
            // Handle Write Request Transaction
            if (command == AUX_NATIVE_WRITE) begin
                // Simulate transmitting the request
                `uvm_info(get_type_name(), $sformatf("Transmitting Write Request: CMD=0x%0b, Addr=0x%0h, LEN=%0d, DATA=0x%0h",
                                                     command, address, length, data), UVM_LOW);

                // Assign the encoded value to aux_in_out
                // Encoded value: 1000|LPM_Address -> LPM_Address -> LPM_Address -> LPM_LEN -> LPM_Data

                // Byte 1: 1000 followed by the first 4 bits of address
                expected_transaction.aux_in_out = {4'b1000, address[19:16]}; // 1000 + first 4 bits of address
                expected_transaction.start_stop = 1'b1; // Raise the start_stop signal
                ref_model_out_port.write(expected_transaction); // Send the expected transaction to the scoreboard

                // Byte 2: Next 8 bits of address
                expected_transaction.aux_in_out = address[15:8]; // Next 8 bits of address
                ref_model_out_port.write(expected_transaction); // Send the expected transaction to the scoreboard

                // Byte 3: Last 8 bits of address
                expected_transaction.aux_in_out = address[7:0]; // Last 8 bits of address
                ref_model_out_port.write(expected_transaction); // Send the expected transaction to the scoreboard

                // Byte 4: Length
                expected_transaction.aux_in_out = length; // Length
                ref_model_out_port.write(expected_transaction); // Send the expected transaction to the scoreboard

                // Loop to send data bytes
                for (int i = 0; i < length; i++) begin
                    expected_transaction.aux_in_out = data[i];
                    ref_model_out_port.write(expected_transaction); // Send the expected transaction to the scoreboard
                end

                // Wait for the next transaction
                ref_model_in_port.get(received_transaction);

                // Extract the command
                command = received_transaction.aux_in_out[3:0]; // Second 4 bits

                // Take action based on the command
                case (command)
                    AUX_ACK: begin // ACK
                        `uvm_info(get_type_name(), "Processing AUX_ACK Command", UVM_LOW);

                        // Populate the expected transaction
                        expected_transaction.LPM_Reply_ACK = AUX_ACK[1:0];
                        expected_transaction.LPM_Reply_ACK_VLD = 1'b1;
                        expected_transaction.LPM_Reply_Data = 8'h00; // No data for ACK
                        expected_transaction.LPM_Reply_Data_VLD = 1'b0;

                        // Send the expected transaction to the scoreboard
                        ref_model_out_port.write(expected_transaction);

                        ack_count = 1; // Increment the ack_count to exit the loop

                        // Log the data being sent
                        `uvm_info(get_type_name(), $sformatf("Sending AUX_ACK Response: data_size=%0d", data.size()), UVM_LOW);
                    end

                    AUX_NACK: begin // NACK
                        `uvm_info(get_type_name(), "Processing AUX_NACK Command", UVM_LOW);

                        // Simulate acknowledgment for NACK
                        expected_transaction.LPM_Reply_ACK = AUX_NACK[1:0];
                        expected_transaction.LPM_Reply_ACK_VLD = 1'b1;
                        expected_transaction.LPM_Reply_Data = 8'h00; // No data for NACK
                        expected_transaction.LPM_Reply_Data_VLD = 1'b0;

                        // Send the expected transaction to the scoreboard
                        ref_model_out_port.write(expected_transaction);

                        // Log the acknowledgment
                        `uvm_info(get_type_name(), "AUX_NACK Command Acknowledged", UVM_LOW);
                    end

                    AUX_DEFER: begin // DEFER
                        `uvm_info(get_type_name(), "Processing AUX_DEFER Command", UVM_LOW);

                        // Simulate acknowledgment for DEFER
                        expected_transaction.LPM_Reply_ACK = AUX_DEFER[1:0];
                        expected_transaction.LPM_Reply_ACK_VLD = 1'b1;
                        expected_transaction.LPM_Reply_Data = 8'h00; // No data for DEFER
                        expected_transaction.LPM_Reply_Data_VLD = 1'b0;

                        // Send the expected transaction to the scoreboard
                        ref_model_out_port.write(expected_transaction);

                        // Log the acknowledgment
                        `uvm_info(get_type_name(), "AUX_DEFER Command Acknowledged", UVM_LOW);
                    end

                    AUX_RESERVED: begin // RESERVED
                        `uvm_info(get_type_name(), "Processing AUX_RESERVED Command", UVM_LOW);

                        // Simulate acknowledgment for RESERVED
                        expected_transaction.LPM_Reply_ACK = AUX_RESERVED[1:0];
                        expected_transaction.LPM_Reply_ACK_VLD = 1'b1;
                        expected_transaction.LPM_Reply_Data = 8'h00; // No data for RESERVED
                        expected_transaction.LPM_Reply_Data_VLD = 1'b0;

                        // Send the expected transaction to the scoreboard
                        ref_model_out_port.write(expected_transaction);

                        // Log the acknowledgment
                        `uvm_info(get_type_name(), "AUX_RESERVED Command Acknowledged", UVM_LOW);
                    end

                    default: begin // Invalid or unsupported command
                        `uvm_error(get_type_name(), $sformatf("Invalid or unsupported command: 0x%h", command));
                    end
                endcase
            end else begin
                `uvm_error(get_type_name(), $sformatf("Invalid LPM_CMD: %0b", command));
            end
        end else begin
            // Transaction not valid
            `uvm_warning(get_type_name(), "LPM_Transaction_VLD is not asserted");
        end
    end

    // Log the generated expected transaction
    `uvm_info(get_type_name(), $sformatf("Generated expected transaction: %s", expected_transaction.convert2string()), UVM_LOW);
endfunction

    // // Function to generate the expected transaction for Native AUX Write Transaction
    // function void generate_native_aux_write_transaction(
    //     input dp_transaction received_transaction,
    //     output dp_transaction expected_transaction
    // );
    //     // Decode the aux_in_out signal
    //     bit [3:0] command;       // First 4 bits: Command
    //     bit [7:0] address;       // last 8 bits of address Address
    //     bit [7:0] length;        // Next 8 bits: Length
    //     bit [7:0] data[$];       // Remaining bits: Data
    //     bit ack_count = 0;  //Ack counter

    //     while (ack_count < 1) begin

    //     // Wait for the next transaction
    //     ref_model_in_port.get(received_transaction);
        
    //     // Copy the received transaction
    //     expected_transaction.copy(received_transaction);
    
    //     // Initialize outputs
    //     expected_transaction.LPM_Reply_ACK = 1'b0;
    //     expected_transaction.LPM_Reply_ACK_VLD = 1'b0;
    //     expected_transaction.LPM_Reply_DATA = 8'h00;
    //     expected_transaction.LPM_Reply_DATA_VLD = 1'b0;
    //     expected_transaction.LPM_Native_I2C = 1'b0;

    //     // Check if the transaction is valid
    //     if (received_transaction.LPM_Transaction_VLD) begin

    //         // Handle Write Request Transaction
    //         if (received_transaction.LPM_CMD == AUX_NATIVE_WRITE) begin
    //             // Simulate transmitting the request
    //             `uvm_info(get_type_name(), $sformatf("Transmitting Write Request: CMD=0x%0b, Addr=0x%0h, LEN=%0d, DATA=0x%0h",
    //                                                  received_transaction.LPM_CMD,
    //                                                  received_transaction.LPM_Address,
    //                                                  received_transaction.LPM_LEN,
    //                                                  received_transaction.LPM_Data), UVM_LOW);
    
    //             // Assign the encoded value to aux_in_out
    //             // Encoded value: 1000|LPM_Address -> LPM_Address -> LPM_Address -> LPM_LEN -> LPM_Data 

    //             // Byte 1: 1001 followed by the first 4 bits of LPM_Address
    //             expected_transaction.aux_in_out = {4'b1000, received_transaction.LPM_Address[19:16]}; // 1000 + first 4 bits of LPM_Address
    //             expected_transaction.start_stop = 1'b1; // Raise the start_stop signal
    //             ref_model_out_port.write(expected_transaction); // Send the expected transaction to the scoreboard
                
    //             // Byte 2: Next 8 bits of LPM_Address
    //             expected_transaction.aux_in_out = received_transaction.LPM_Address[15:8]; // Next 8 bits of LPM_Address
    //             ref_model_out_port.write(expected_transaction); // Send the expected transaction to the scoreboard
                
    //             // Byte 3: Last 8 bits of LPM_Address
    //             expected_transaction.aux_in_out = received_transaction.LPM_Address[7:0]; // Last 8 bits of LPM_Address
    //             ref_model_out_port.write(expected_transaction); // Send the expected transaction to the scoreboard
                
    //             // Byte 4: LPM_LEN
    //             expected_transaction.aux_in_out = received_transaction.LPM_LEN; // LPM_LEN
    //             ref_model_out_port.write(expected_transaction); // Send the expected transaction to the scoreboard

    //             length = received_transaction.LPM_LEN;   // Store the length for later use

    //             // Loop to send data bytes from LPM
    //                 for (int i = 0; i < length + 1; i++) begin

    //                     // Wait for the next transaction for each byte
    //                     ref_model_in_port.get(received_transaction);
                    
    //                     expected_transaction.aux_in_out = received_transaction.LPM_Data;
    //                     ref_model_out_port.write(expected_transaction); // Send the expected transaction to the scoreboard

    //                 end

    //             // Allocate the dynamic array based on the length
    //             data = new[length];

    //             // Wait for the next transaction
    //             ref_model_in_port.get(received_transaction);
                
    //                 // Extract the command
    //                 command = received_transaction.aux_in_out[3:0]; // Second 4 bits
                    
    //                 // Take action based on the command
    //                 case (command)
    //                     AUX_ACK: begin // ACK
    //                         `uvm_info(get_type_name(), "Processing AUX_ACK Command", UVM_LOW);
                    
    //                             // Populate the expected transaction
    //                             expected_transaction.LPM_Reply_ACK = AUX_ACK[1:0];
    //                             expected_transaction.LPM_Reply_ACK_VLD = 1'b1;
    //                             expected_transaction.LPM_Reply_Data = 8'h00; // No data for ACK
    //                             expected_transaction.LPM_Reply_Data_VLD = 1'b0;

    //                         // Send the expected transaction to the scoreboard
    //                         ref_model_out_port.write(expected_transaction);
                    
    //                         ack_count = 1; // Increment the ack_count to exit the loop
                    
    //                         // Log the data being sent
    //                         `uvm_info(get_type_name(), $sformatf("Sending AUX_ACK Response: data_size=%0d", data.size()), UVM_LOW);
    //                     end
                    
    //                     AUX_NACK: begin // NACK
    //                         `uvm_info(get_type_name(), "Processing AUX_NACK Command", UVM_LOW);
                    
    //                         // Simulate acknowledgment for NACK
    //                         expected_transaction.LPM_Reply_ACK = AUX_NACK[1:0];
    //                         expected_transaction.LPM_Reply_ACK_VLD = 1'b1;
    //                         expected_transaction.LPM_Reply_Data = 8'h00; // No data for NACK
    //                         expected_transaction.LPM_Reply_Data_VLD = 1'b0;
                    
    //                         // Send the expected transaction to the scoreboard
    //                         ref_model_out_port.write(expected_transaction);
                    
    //                         // Log the acknowledgment
    //                         `uvm_info(get_type_name(), "AUX_NACK Command Acknowledged", UVM_LOW);
    //                     end
                    
    //                     AUX_DEFER: begin // DEFER
    //                         `uvm_info(get_type_name(), "Processing AUX_DEFER Command", UVM_LOW);
                    
    //                         // Simulate acknowledgment for DEFER
    //                         expected_transaction.LPM_Reply_ACK = AUX_DEFER[1:0];
    //                         expected_transaction.LPM_Reply_ACK_VLD = 1'b1;
    //                         expected_transaction.LPM_Reply_Data = 8'h00; // No data for DEFER
    //                         expected_transaction.LPM_Reply_Data_VLD = 1'b0;
                    
    //                         // Send the expected transaction to the scoreboard
    //                         ref_model_out_port.write(expected_transaction);
                    
    //                         // Log the acknowledgment
    //                         `uvm_info(get_type_name(), "AUX_DEFER Command Acknowledged", UVM_LOW);
    //                     end
                    
    //                     AUX_RESERVED: begin // RESERVED
    //                         `uvm_info(get_type_name(), "Processing AUX_RESERVED Command", UVM_LOW);
                    
    //                         // Simulate acknowledgment for RESERVED
    //                         expected_transaction.LPM_Reply_ACK = AUX_RESERVED[1:0];
    //                         expected_transaction.LPM_Reply_ACK_VLD = 1'b1;
    //                         expected_transaction.LPM_Reply_Data = 8'h00; // No data for RESERVED
    //                         expected_transaction.LPM_Reply_Data_VLD = 1'b0;
                    
    //                         // Send the expected transaction to the scoreboard
    //                         ref_model_out_port.write(expected_transaction);
                    
    //                         // Log the acknowledgment
    //                         `uvm_info(get_type_name(), "AUX_RESERVED Command Acknowledged", UVM_LOW);
    //                     end
                    
    //                     default: begin // Invalid or unsupported command
    //                         `uvm_error(get_type_name(), $sformatf("Invalid or unsupported command: 0x%h", command));
    //                     end
    //                 endcase
    
    //         // Handle Invalid Command
    //         end else begin
    //             `uvm_error(get_type_name(), $sformatf("Invalid LPM_CMD: %0b", received_transaction.LPM_CMD));
    //         end
    //     end else begin
    //         // Transaction not valid
    //         `uvm_warning(get_type_name(), "LPM_Transaction_VLD is not asserted");
    //     end
    //     end

    //     // Log the generated expected transaction
    //     `uvm_info(get_type_name(), $sformatf("Generated expected transaction: %s", expected_transaction.convert2string()), UVM_LOW);
    // endfunction

    class dp_reference_model extends uvm_component;
    `uvm_component_utils(dp_reference_model)

    // Input and output analysis ports for connecting to the scoreboard
    uvm_analysis_imp #(dp_transaction) ref_model_in_port;  // Receives transactions from the monitor
    uvm_analysis_port #(dp_transaction) ref_model_out_port; // Sends expected transactions to the scoreboard

    // Internal variables
    dp_transaction expected_transaction;

    // Variables for connection detection scenario
    bit HPD_Signal_prev = 0; // Previous state of HPD_Signal
    time HPD_high_start; // Time when HPD_Signal went high
    time HPD_low_start;  // Time when HPD_Signal went low

// typedef enum logic [2:0] {
//     IDLE,
//     CONNECTION_DETECTION,
//     LINK_TRAINING,
//     I2C_OVER_AUX,
//     NATIVE_AUX,
//     ERROR
// } fsm_state_e;

// fsm_state_e current_state, next_state;

    // Constructor
    function new(string name, uvm_component parent);
        super.new(name, parent);
        ref_model_in_port = new("ref_model_in_port", this);
        ref_model_out_port = new("ref_model_out_port", this);
    endfunction

    // Build phase
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info(get_type_name(), "Reference model build_phase completed", UVM_LOW)
    endfunction

    // Main task to process transactions
    task run_phase(uvm_phase phase);
        dp_transaction received_transaction;

        phase.raise_objection(this); // Raise objection to keep the simulation running

        current_state = IDLE; // Start in the IDLE state

        forever begin
            // Generate the expected transaction based on the received transaction
            expected_transaction = new();
            generate_expected_transaction(received_transaction, expected_transaction);
        end

        phase.drop_objection(this); // Drop objection when done
    endtask

    // // Main task to process transactions
    // task run_phase(uvm_phase phase);
    //     dp_transaction received_transaction;
    //     dp_transaction expected_transaction;
    
    //     phase.raise_objection(this); // Raise objection to keep the simulation running
    
    //     current_state = IDLE; // Start in the IDLE state
    
    //     forever begin
    //         case (current_state)
    //             IDLE: begin
    //                 // Wait for a transaction
    //                 if (ref_model_in_port.try_get(received_transaction)) begin
    //                     // Determine the next state based on the transaction type
    //                     if (received_transaction.HPD_Signal) begin
    //                         next_state = CONNECTION_DETECTION;
    //                     end else if (received_transaction.LPM_CMD == AUX_NATIVE_READ || received_transaction.LPM_CMD == AUX_NATIVE_WRITE) begin
    //                         next_state = NATIVE_AUX;
    //                     end else if (received_transaction.SPM_CMD == AUX_I2C_READ) begin
    //                         next_state = I2C_OVER_AUX;
    //                     end else begin
    //                         next_state = LINK_TRAINING;
    //                     end
    //                 end else begin
    //                     next_state = IDLE; // Stay in IDLE if no transaction is available
    //                 end
    //             end
    
    //             CONNECTION_DETECTION: begin
    //                 // Call the connection detection function
    //                 generate_connection_detection(received_transaction, expected_transaction);
    //                 next_state = IDLE; // Return to IDLE after processing
    //             end
    
    //             LINK_TRAINING: begin
    //                 // Call the link training flow function
    //                 generate_link_training_flow(received_transaction, expected_transaction);
    //                 next_state = IDLE; // Return to IDLE after processing
    //             end
    
    //             I2C_OVER_AUX: begin
    //                 // Call the I2C-over-AUX transaction function
    //                 generate_i2c_over_aux_transaction(received_transaction, expected_transaction);
    //                 next_state = IDLE; // Return to IDLE after processing
    //             end
    
    //             NATIVE_AUX: begin
    //                 // Call the native AUX transaction function
    //                 generate_native_aux_transaction(received_transaction, expected_transaction);
    //                 next_state = IDLE; // Return to IDLE after processing
    //             end
    
    //             ERROR: begin
    //                 // Handle invalid or unsupported scenarios
    //                 `uvm_error(get_type_name(), "Invalid or unsupported transaction");
    //                 next_state = IDLE; // Return to IDLE after handling the error
    //             end
    
    //             default: begin
    //                 next_state = IDLE; // Default state
    //             end
    //         endcase
    
    //         // Update the current state
    //         current_state = next_state;
    //     end
    
    //     phase.drop_objection(this); // Drop objection when done
    // endtask


    // Function to generate the expected transaction
    function void generate_expected_transaction(
        input dp_transaction received_transaction,
        output dp_transaction expected_transaction
    );

        // Connection Detection Scenario
        generate_connection_detection(received_transaction, expected_transaction);

        // // Link Training Scenario //

        // // I2C-over-AUX Transaction Scenario (EDID Read)
        // generate_i2c_over_aux_transaction(received_transaction, expected_transaction);

        // // Native AUX Transaction Scenario
        // generate_native_aux_transaction(received_transaction, expected_transaction);

        // // Link Training Flow
        // generate_link_training_flow(received_transaction, expected_transaction);
        
        // // End of link training flow

        // Log the generated expected transaction
        `uvm_info(get_type_name(), $sformatf("Generated expected transaction: %s", expected_transaction.convert2string()), UVM_LOW)
    endfunction
    


    // Function to handle the Connection Detection Scenario
    function void generate_connection_detection(
        input dp_transaction received_transaction,
        output dp_transaction expected_transaction
    );
        // Wait for the next transaction
        ref_model_in_port.get(received_transaction);

        // Copy the received transaction
        expected_transaction.copy(received_transaction);

        // Check if HPD_Signal just went high
        if (received_transaction.HPD_Signal && !HPD_Signal_prev) begin
            HPD_high_start = $time;
        end else if (!received_transaction.HPD_Signal && HPD_Signal_prev) begin
            // Check if HPD_Signal just went low
            HPD_low_start = $time;
        end
    
        // Check if HPD_Signal has been high for ≥2 ms
        if (received_transaction.HPD_Signal && ($time - HPD_high_start) >= 2_000_000) begin
            expected_transaction.HPD_Detect = 1'b1; // Assert HPD_Detect

            // Start Link Training Flow
            generate_link_training_flow(received_transaction, expected_transaction);

        end else begin
            expected_transaction.HPD_Detect = 1'b0; // Deassert HPD_Detect
        end
    
        // Check if HPD_Signal went low for 0.5–1 ms and then returned high
        if (!received_transaction.HPD_Signal && ($time - HPD_low_start) >= 500_000 && ($time - HPD_low_start) <= 1_000_000) begin
            if (HPD_Signal_prev) begin
                expected_transaction.HPD_IRQ = 1'b1; // Pulse HPD_IRQ for 1 clock cycle
            end
        end else begin
            expected_transaction.HPD_IRQ = 1'b0; // Deassert HPD_IRQ
        end
                
        // Update the previous state of HPD_Signal
        HPD_Signal_prev = received_transaction.HPD_Signal;
    
        // Log the connection detection results
        `uvm_info(get_type_name(), $sformatf("Connection Detection: HPD_Detect=%0b, HPD_IRQ=%0b",
                                             expected_transaction.HPD_Detect,
                                             expected_transaction.HPD_IRQ), UVM_LOW);

        // Send the expected transaction to the scoreboard
        ref_model_out_port.write(expected_transaction);

        //Note to self: need to make this function run continuously

    endfunction

















    //to be added: nack and defer correct conditions, correct aux_in_out, ctrl_i2c_failed maybe??

    // Function to generate the expected transaction for I2C-over-AUX (EDID Read)
    function void generate_i2c_over_aux_transaction(
        input dp_transaction received_transaction,
        output dp_transaction expected_transaction
    );
        // Decode the aux_in_out signal
        bit [3:0] command;       // First 4 bits: Command
        bit [7:0] address;       // last 8 bits of address Address
        bit [7:0] length;        // Next 8 bits: Length
        bit [7:0] data[$];       // Remaining bits: Data
        bit ack_count = 0;  //Ack counter
        
        while (ack_count < 1) begin

        // Wait for the next transaction
        ref_model_in_port.get(received_transaction);

        // Copy the received transaction
        expected_transaction.copy(received_transaction);
    
        // Initialize outputs
        // note to self: need to turn off hpd detect / IRQ maybe?
        expected_transaction.SPM_Reply_ACK = I2C_ACK[3:2];
        expected_transaction.SPM_Reply_ACK_VLD = 1'b0;
        expected_transaction.SPM_Reply_Data = 8'h00;
        expected_transaction.SPM_Reply_Data_VLD = 1'b0;
        expected_transaction.I2C_Complete = 1'b0;
    
        // Check if the transaction is valid
        if (received_transaction.SPM_Transaction_VLD) begin
            // Step 1: Address-only transaction
            if (received_transaction.SPM_CMD == AUX_I2C_READ && received_transaction.SPM_LEN == 0) begin

                address = received_transaction.SPM_Address; // Extract the address from the received transaction

                // Assign the encoded value to aux_in_out
                // Encoded value: 0101|0000 -> 00000000 -> SPM_Address

                // Byte 1
                expected_transaction.aux_in_out = 8'b0101_0000;
                // Raise the start_stop signal
                expected_transaction.start_stop = 1'b1;

                // Send the expected transaction to the scoreboard
                ref_model_out_port.write(expected_transaction);
                
                // Byte 2
                expected_transaction.aux_in_out = 8'b0000_0000;

                // Send the expected transaction to the scoreboard
                ref_model_out_port.write(expected_transaction);
                
                // Byte 3
                expected_transaction.aux_in_out = address; 
                
                // Send the expected transaction to the scoreboard
                ref_model_out_port.write(expected_transaction);

                // // Simulate the encoded Address-only I2C-over-AUX transaction
                // `uvm_info(get_type_name(), "Transmitting Address-only I2C-over-AUX transaction", UVM_LOW);
                // `uvm_info(get_type_name(), $sformatf("AUX_IN_OUT: 0101|0000 -> 00000000 -> 00000000 (START_STOP=1, MOT=1, I2C Address=0000000)"), UVM_LOW);

                // Wait for the next transaction
                ref_model_in_port.get(received_transaction);
                
                    // Extract the command
                    command = received_transaction.aux_in_out[7:4]; // First 4 bits
                
                    // Take action based on the command
                    case (command)
                        I2C_ACK: begin // ACK
                            `uvm_info(get_type_name(), "Processing I2C_ACK Command", UVM_LOW);
                
                            // Populate the expected transaction
                            expected_transaction.SPM_Reply_ACK = I2C_ACK[3:2];
                            expected_transaction.SPM_Reply_ACK_VLD = 1'b1;
                            expected_transaction.SPM_Reply_Data = 8'h00;
                            expected_transaction.SPM_Reply_Data_VLD = 1'b0;
                            ack_count = 1; // Increment the ack_count to exit the loop
                
                            // Log the data being sent
                            `uvm_info(get_type_name(), $sformatf("Sending I2C_ACK Response: data_size=%0d", data.size()), UVM_LOW);
                        end
                
                        I2C_NACK: begin // NACK
                            `uvm_info(get_type_name(), "Processing I2C_NACK Command", UVM_LOW);
                
                            // Simulate acknowledgment for NACK
                            expected_transaction.SPM_Reply_ACK = I2C_NACK[3:2];
                            expected_transaction.SPM_Reply_ACK_VLD = 1'b1;
                            expected_transaction.SPM_Reply_Data = 8'h00; // No data for NACK
                            expected_transaction.SPM_Reply_Data_VLD = 1'b0;
                
                            // Log the acknowledgment
                            `uvm_info(get_type_name(), "I2C_NACK Command Acknowledged", UVM_LOW);
                        end
                
                        I2C_DEFER: begin // DEFER
                            `uvm_info(get_type_name(), "Processing I2C_DEFER Command", UVM_LOW);
                
                            // Simulate acknowledgment for DEFER
                            expected_transaction.SPM_Reply_ACK = I2C_DEFER[3:2];
                            expected_transaction.SPM_Reply_ACK_VLD = 1'b1;
                            expected_transaction.SPM_Reply_Data = 8'h00; // No data for DEFER
                            expected_transaction.SPM_Reply_Data_VLD = 1'b0;
                
                            // Log the acknowledgment
                            `uvm_info(get_type_name(), "I2C_DEFER Command Acknowledged", UVM_LOW);
                        end
                
                        I2C_RESERVED: begin // RESERVED
                            `uvm_info(get_type_name(), "Processing I2C_RESERVED Command", UVM_LOW);
                
                            // Simulate acknowledgment for RESERVED
                            expected_transaction.SPM_Reply_ACK = I2C_RESERVED[3:2];
                            expected_transaction.SPM_Reply_ACK_VLD = 1'b1;
                            expected_transaction.SPM_Reply_Data = 8'h00; // No data for RESERVED
                            expected_transaction.SPM_Reply_Data_VLD = 1'b0;
                
                            // Log the acknowledgment
                            `uvm_info(get_type_name(), "I2C_RESERVED Command Acknowledged", UVM_LOW);
                        end
                
                        default: begin // Invalid or unsupported command
                            `uvm_error(get_type_name(), $sformatf("Invalid or unsupported command: 0x%h", command));
                        end
                    endcase
                
                    // Send the expected transaction to the scoreboard
                    ref_model_out_port.write(expected_transaction);
                
                    // Log the processed transaction
                    `uvm_info(get_type_name(), $sformatf("Processed transaction: cmd=0x%h, addr=0x%h, len=0x%h", command, address, length), UVM_LOW);
            end else begin
                // Invalid command
                `uvm_error(get_type_name(), "Invalid SPM_CMD or SPM_LEN for I2C-over-AUX transaction");
            end

        end else begin
            // Transaction not valid
            `uvm_warning(get_type_name(), "SPM_Transaction_VLD is not asserted");
        end

        end
        
        ack_count = 0; //Reset ack counter

        // Step 2: Read EDID data (128 bytes)
        while (ack_count < 128) begin // Read 128 bytes of EDID data

        // Wait for the next transaction
        ref_model_in_port.get(received_transaction);
    
        // Check if the transaction is valid
        if (received_transaction.SPM_Transaction_VLD) begin
            // Step 1: Address-only transaction
            if (received_transaction.SPM_CMD == AUX_I2C_READ && received_transaction.SPM_LEN == 0) begin

                // Assign the encoded value to aux_in_out
                // Encoded value: 0101|0000 -> 00000000 -> SPM_Address -> 00000000

                // Byte 1
                expected_transaction.aux_in_out = 8'b0101_0000;
                // Raise the start_stop signal
                expected_transaction.start_stop = 1'b1;

                // Send the expected transaction to the scoreboard
                ref_model_out_port.write(expected_transaction);
                
                // Byte 2
                expected_transaction.aux_in_out = 8'b0000_0000;

                // Send the expected transaction to the scoreboard
                ref_model_out_port.write(expected_transaction);
                
                // Byte 3
                expected_transaction.aux_in_out = address; 
                
                // Send the expected transaction to the scoreboard
                ref_model_out_port.write(expected_transaction);

                // Byte 4
                expected_transaction.aux_in_out = 8'b0000_0000;
                
                // Send the expected transaction to the scoreboard
                ref_model_out_port.write(expected_transaction);

                // // Simulate sending the read request
                // `uvm_info(get_type_name(), $sformatf("AUX_IN_OUT: 0101|0000 -> 00000000 -> 00000000 -> 0000|0000 (START_STOP=1, MOT=1, I2C Address=0000000, Read Length=1)"), UVM_LOW);

                // Wait for the next transaction
                ref_model_in_port.get(received_transaction);
                
                    // Extract the command
                    command = received_transaction.aux_in_out[7:4]; // First 4 bits

                    // Wait for the next transaction
                    ref_model_in_port.get(received_transaction);  
                    
                    // Extract the data
                    data = received_transaction.aux_in_out[7:0]; // Second 8 bits  
                
                    // Take action based on the command
                    case (command)
                        I2C_ACK: begin // ACK
                            `uvm_info(get_type_name(), "Processing I2C_ACK Command", UVM_LOW);
                
                            // Populate the expected transaction
                            expected_transaction.SPM_Reply_ACK = I2C_ACK[3:2];
                            expected_transaction.SPM_Reply_ACK_VLD = 1'b1;
                            expected_transaction.SPM_Reply_Data = data;;
                            expected_transaction.SPM_Reply_Data_VLD = 1'b0;
                            ack_count = ack_count + 1; // Increment the ack_count to exit the loop
                
                            // Log the data being sent
                            `uvm_info(get_type_name(), $sformatf("Sending I2C_ACK Response: data_size=%0d", data.size()), UVM_LOW);
                        end
                
                        I2C_NACK: begin // NACK
                            `uvm_info(get_type_name(), "Processing I2C_NACK Command", UVM_LOW);
                
                            // Simulate acknowledgment for NACK
                            expected_transaction.SPM_Reply_ACK = I2C_NACK[3:2];
                            expected_transaction.SPM_Reply_ACK_VLD = 1'b1;
                            expected_transaction.SPM_Reply_Data = 8'h00; // No data for NACK
                            expected_transaction.SPM_Reply_Data_VLD = 1'b0;
                
                            // Log the acknowledgment
                            `uvm_info(get_type_name(), "I2C_NACK Command Acknowledged", UVM_LOW);
                        end
                
                        I2C_DEFER: begin // DEFER
                            `uvm_info(get_type_name(), "Processing I2C_DEFER Command", UVM_LOW);
                
                            // Simulate acknowledgment for DEFER
                            expected_transaction.SPM_Reply_ACK = I2C_DEFER[3:2];
                            expected_transaction.SPM_Reply_ACK_VLD = 1'b1;
                            expected_transaction.SPM_Reply_Data = 8'h00; // No data for DEFER
                            expected_transaction.SPM_Reply_Data_VLD = 1'b0;
                
                            // Log the acknowledgment
                            `uvm_info(get_type_name(), "I2C_DEFER Command Acknowledged", UVM_LOW);
                        end
                
                        I2C_RESERVED: begin // RESERVED
                            `uvm_info(get_type_name(), "Processing I2C_RESERVED Command", UVM_LOW);
                
                            // Simulate acknowledgment for RESERVED
                            expected_transaction.SPM_Reply_ACK = I2C_RESERVED[3:2];
                            expected_transaction.SPM_Reply_ACK_VLD = 1'b1;
                            expected_transaction.SPM_Reply_Data = 8'h00; // No data for RESERVED
                            expected_transaction.SPM_Reply_Data_VLD = 1'b0;
                
                            // Log the acknowledgment
                            `uvm_info(get_type_name(), "I2C_RESERVED Command Acknowledged", UVM_LOW);
                        end
                
                        default: begin // Invalid or unsupported command
                            `uvm_error(get_type_name(), $sformatf("Invalid or unsupported command: 0x%h", command));
                        end
                    endcase
                
                    // Send the expected transaction to the scoreboard
                    ref_model_out_port.write(expected_transaction);
                
                    // Log the processed transaction
                    `uvm_info(get_type_name(), $sformatf("Processed transaction: cmd=0x%h, addr=0x%h, len=0x%h", command, address, length), UVM_LOW);
            end else begin
                // Invalid command
                `uvm_error(get_type_name(), "Invalid SPM_CMD or SPM_LEN for I2C-over-AUX transaction");
            end

        end else begin
            // Transaction not valid
            `uvm_warning(get_type_name(), "SPM_Transaction_VLD is not asserted");
        end

        end

        ack_count = 0; //Reset ack counter

        // Step 3: Address-only transaction with MOT=0 (STOP condition)
        while (ack_count < 1) begin

        // Wait for the next transaction
        ref_model_in_port.get(received_transaction);
    
        // Check if the transaction is valid
        if (received_transaction.SPM_Transaction_VLD) begin
            // Step 1: Address-only transaction
            if (received_transaction.SPM_CMD == AUX_I2C_READ && received_transaction.SPM_LEN == 0) begin
                
                // Assign the encoded value to aux_in_out
                // Encoded value: 0001|0000 -> 00000000 -> SPM_Address -> 00000000

                // Byte 1
                expected_transaction.aux_in_out = 8'b0001_0000;
                // Raise the start_stop signal
                expected_transaction.start_stop = 1'b1;

                // Send the expected transaction to the scoreboard
                ref_model_out_port.write(expected_transaction);
                
                // Byte 2
                expected_transaction.aux_in_out = 8'b0000_0000;

                // Send the expected transaction to the scoreboard
                ref_model_out_port.write(expected_transaction);
                
                // Byte 3
                expected_transaction.aux_in_out = address; 
                
                // Send the expected transaction to the scoreboard
                ref_model_out_port.write(expected_transaction);

                // // Simulate the encoded Address-only I2C-over-AUX transaction
                // `uvm_info(get_type_name(), "Transmitting Address-only I2C-over-AUX transaction", UVM_LOW);
                // `uvm_info(get_type_name(), $sformatf("AUX_IN_OUT: 0001|0000 -> 00000000 -> 00000000 (START_STOP=1, MOT=1, I2C Address=0000000)"), UVM_LOW);

                // Wait for the next transaction
                ref_model_in_port.get(received_transaction);
                
                    // Extract the command
                    command = received_transaction.aux_in_out[7:4]; // First 4 bits
                
                    // Take action based on the command
                    case (command)
                        I2C_ACK: begin // ACK
                            `uvm_info(get_type_name(), "Processing I2C_ACK Command", UVM_LOW);
                
                            // Populate the expected transaction
                            expected_transaction.SPM_Reply_ACK = I2C_ACK[3:2];
                            expected_transaction.SPM_Reply_ACK_VLD = 1'b1;
                            expected_transaction.SPM_Reply_Data = 8'h00;
                            expected_transaction.SPM_Reply_Data_VLD = 1'b0;
                            ack_count = 1; // Increment the ack_count to exit the loop
                
                            // Log the data being sent
                            `uvm_info(get_type_name(), $sformatf("Sending I2C_ACK Response: data_size=%0d", data.size()), UVM_LOW);
                        end
                
                        I2C_NACK: begin // NACK
                            `uvm_info(get_type_name(), "Processing I2C_NACK Command", UVM_LOW);
                
                            // Simulate acknowledgment for NACK
                            expected_transaction.SPM_Reply_ACK = I2C_NACK[3:2];
                            expected_transaction.SPM_Reply_ACK_VLD = 1'b1;
                            expected_transaction.SPM_Reply_Data = 8'h00; // No data for NACK
                            expected_transaction.SPM_Reply_Data_VLD = 1'b0;
                
                            // Log the acknowledgment
                            `uvm_info(get_type_name(), "I2C_NACK Command Acknowledged", UVM_LOW);
                        end
                
                        I2C_DEFER: begin // DEFER
                            `uvm_info(get_type_name(), "Processing I2C_DEFER Command", UVM_LOW);
                
                            // Simulate acknowledgment for DEFER
                            expected_transaction.SPM_Reply_ACK = I2C_DEFER[3:2];
                            expected_transaction.SPM_Reply_ACK_VLD = 1'b1;
                            expected_transaction.SPM_Reply_Data = 8'h00; // No data for DEFER
                            expected_transaction.SPM_Reply_Data_VLD = 1'b0;
                
                            // Log the acknowledgment
                            `uvm_info(get_type_name(), "I2C_DEFER Command Acknowledged", UVM_LOW);
                        end
                
                        I2C_RESERVED: begin // RESERVED
                            `uvm_info(get_type_name(), "Processing I2C_RESERVED Command", UVM_LOW);
                
                            // Simulate acknowledgment for RESERVED
                            expected_transaction.SPM_Reply_ACK = I2C_RESERVED[3:2];
                            expected_transaction.SPM_Reply_ACK_VLD = 1'b1;
                            expected_transaction.SPM_Reply_Data = 8'h00; // No data for RESERVED
                            expected_transaction.SPM_Reply_Data_VLD = 1'b0;
                
                            // Log the acknowledgment
                            `uvm_info(get_type_name(), "I2C_RESERVED Command Acknowledged", UVM_LOW);
                        end
                
                        default: begin // Invalid or unsupported command
                            `uvm_error(get_type_name(), $sformatf("Invalid or unsupported command: 0x%h", command));
                        end
                    endcase
                
                    // Send the expected transaction to the scoreboard
                    ref_model_out_port.write(expected_transaction);
                
                    // Log the processed transaction
                    `uvm_info(get_type_name(), $sformatf("Processed transaction: cmd=0x%h, addr=0x%h, len=0x%h", command, address, length), UVM_LOW);
            end else begin
                // Invalid command
                `uvm_error(get_type_name(), "Invalid SPM_CMD or SPM_LEN for I2C-over-AUX transaction");
            end

        end else begin
            // Transaction not valid
            `uvm_warning(get_type_name(), "SPM_Transaction_VLD is not asserted");
        end

        end

        // Log the generated expected transaction
        `uvm_info(get_type_name(), $sformatf("Generated expected transaction: %s", expected_transaction.convert2string()), UVM_LOW);
    endfunction

   
    //to be added: nack and defer conditions
   
    // Function to generate the expected transaction for Native AUX Read Transaction
    function void generate_native_aux_read_transaction(
        input dp_transaction received_transaction,
        output dp_transaction expected_transaction
    );
        // Decode the aux_in_out signal
        bit [3:0] command;       // First 4 bits: Command
        bit [7:0] address;       // last 8 bits of address Address
        bit [7:0] length;        // Next 8 bits: Length
        bit [7:0] data[$];       // Remaining bits: Data
        bit ack_count = 0;  //Ack counter

        while (ack_count < 1) begin

         // Wait for the next transaction
        ref_model_in_port.get(received_transaction);
        
        // Copy the received transaction
        expected_transaction.copy(received_transaction);
    
        // Initialize outputs
        expected_transaction.LPM_Reply_ACK = 1'b0;
        expected_transaction.LPM_Reply_ACK_VLD = 1'b0;
        expected_transaction.LPM_Reply_DATA = 8'h00;
        expected_transaction.LPM_Reply_DATA_VLD = 1'b0;
        expected_transaction.LPM_Native_I2C = 1'b0;

        // Check if the transaction is valid
        if (received_transaction.LPM_Transaction_VLD) begin

            // Handle Read Request Transaction
            if (received_transaction.LPM_CMD == AUX_NATIVE_READ) begin
                // Log the read request transaction
                `uvm_info(get_type_name(), $sformatf("Transmitting Read Request: CMD=0x%0b, Addr=0x%0h, LEN=%0d",
                                                     received_transaction.LPM_CMD,
                                                     received_transaction.LPM_Address,
                                                     received_transaction.LPM_LEN), UVM_LOW);
    
                // Assign the encoded value to aux_in_out
                // Encoded value: 1001|LPM_Address -> LPM_Address -> LPM_Address -> LPM_LEN

                // Byte 1: 1001 followed by the first 4 bits of LPM_Address
                expected_transaction.aux_in_out = {4'b1001, received_transaction.LPM_Address[19:16]}; // 1001 + first 4 bits of LPM_Address
                expected_transaction.start_stop = 1'b1; // Raise the start_stop signal
                ref_model_out_port.write(expected_transaction); // Send the expected transaction to the scoreboard
                
                // Byte 2: Next 8 bits of LPM_Address
                expected_transaction.aux_in_out = received_transaction.LPM_Address[15:8]; // Next 8 bits of LPM_Address
                ref_model_out_port.write(expected_transaction); // Send the expected transaction to the scoreboard
                
                // Byte 3: Last 8 bits of LPM_Address
                expected_transaction.aux_in_out = received_transaction.LPM_Address[7:0]; // Last 8 bits of LPM_Address
                ref_model_out_port.write(expected_transaction); // Send the expected transaction to the scoreboard
                
                // Byte 4: LPM_LEN
                expected_transaction.aux_in_out = received_transaction.LPM_LEN; // LPM_LEN
                ref_model_out_port.write(expected_transaction); // Send the expected transaction to the scoreboard

                length = received_transaction.LPM_LEN;   // Store the length for later use

                // Allocate the dynamic array based on the length
                data = new[length];

                // Wait for the next transaction
                ref_model_in_port.get(received_transaction);
                
                    // Extract the command
                    command = received_transaction.aux_in_out[3:0]; // Second 4 bits
                    
                    // Loop to extract data bytes based on the length
                    for (int i = 0; i < length + 1; i++) begin
                        // Wait for the next transaction for each byte
                        ref_model_in_port.get(received_transaction);
                    
                        // Extract the data byte(s) from aux_in_out
                        data[i] = received_transaction.aux_in_out[7:0];
                    
                        // Log the extracted data byte
                        `uvm_info(get_type_name(), $sformatf("Extracted Data Byte %0d: 0x%0h", i, data[i]), UVM_LOW);
                    end
                    
                    // Take action based on the command
                    case (command)
                        AUX_ACK: begin // ACK
                            `uvm_info(get_type_name(), "Processing AUX_ACK Command", UVM_LOW);
                    
                            for (int i = 0; i < length + 1; i++) begin
                                // Populate the expected transaction
                                expected_transaction.LPM_Reply_ACK = AUX_ACK[1:0];
                                expected_transaction.LPM_Reply_ACK_VLD = 1'b1;
                                expected_transaction.LPM_Reply_Data = data[i];
                                expected_transaction.LPM_Reply_Data_VLD = 1'b1;
                    
                                // Send the expected transaction to the scoreboard
                                ref_model_out_port.write(expected_transaction);
                            end
                    
                            ack_count = 1; // Increment the ack_count to exit the loop
                    
                            // Log the data being sent
                            `uvm_info(get_type_name(), $sformatf("Sending AUX_ACK Response: data_size=%0d", data.size()), UVM_LOW);
                        end
                    
                        AUX_NACK: begin // NACK
                            `uvm_info(get_type_name(), "Processing AUX_NACK Command", UVM_LOW);
                    
                            // Simulate acknowledgment for NACK
                            expected_transaction.LPM_Reply_ACK = AUX_NACK[1:0];
                            expected_transaction.LPM_Reply_ACK_VLD = 1'b1;
                            expected_transaction.LPM_Reply_Data = 8'h00; // No data for NACK
                            expected_transaction.LPM_Reply_Data_VLD = 1'b0;
                    
                            // Send the expected transaction to the scoreboard
                            ref_model_out_port.write(expected_transaction);
                    
                            // Log the acknowledgment
                            `uvm_info(get_type_name(), "AUX_NACK Command Acknowledged", UVM_LOW);
                        end
                    
                        AUX_DEFER: begin // DEFER
                            `uvm_info(get_type_name(), "Processing AUX_DEFER Command", UVM_LOW);
                    
                            // Simulate acknowledgment for DEFER
                            expected_transaction.LPM_Reply_ACK = AUX_DEFER[1:0];
                            expected_transaction.LPM_Reply_ACK_VLD = 1'b1;
                            expected_transaction.LPM_Reply_Data = 8'h00; // No data for DEFER
                            expected_transaction.LPM_Reply_Data_VLD = 1'b0;
                    
                            // Send the expected transaction to the scoreboard
                            ref_model_out_port.write(expected_transaction);
                    
                            // Log the acknowledgment
                            `uvm_info(get_type_name(), "AUX_DEFER Command Acknowledged", UVM_LOW);
                        end
                    
                        AUX_RESERVED: begin // RESERVED
                            `uvm_info(get_type_name(), "Processing AUX_RESERVED Command", UVM_LOW);
                    
                            // Simulate acknowledgment for RESERVED
                            expected_transaction.LPM_Reply_ACK = AUX_RESERVED[1:0];
                            expected_transaction.LPM_Reply_ACK_VLD = 1'b1;
                            expected_transaction.LPM_Reply_Data = 8'h00; // No data for RESERVED
                            expected_transaction.LPM_Reply_Data_VLD = 1'b0;
                    
                            // Send the expected transaction to the scoreboard
                            ref_model_out_port.write(expected_transaction);
                    
                            // Log the acknowledgment
                            `uvm_info(get_type_name(), "AUX_RESERVED Command Acknowledged", UVM_LOW);
                        end
                    
                        default: begin // Invalid or unsupported command
                            `uvm_error(get_type_name(), $sformatf("Invalid or unsupported command: 0x%h", command));
                        end
                    endcase


    
            // Handle Invalid Command
            end else begin
                `uvm_error(get_type_name(), $sformatf("Invalid LPM_CMD: %0b", received_transaction.LPM_CMD));
            end
        end else begin
            // Transaction not valid
            `uvm_warning(get_type_name(), "LPM_Transaction_VLD is not asserted");
        end
        end

        // Log the generated expected transaction
        `uvm_info(get_type_name(), $sformatf("Generated expected transaction: %s", expected_transaction.convert2string()), UVM_LOW);
    endfunction

    // Function to generate the expected transaction for Native AUX Write Transaction
    function void generate_native_aux_write_transaction(
    input dp_transaction received_transaction,
    output dp_transaction expected_transaction,
    input bit [3:0] override_command = 4'b0000,  // Default: Use received_transaction.LPM_CMD
    input bit [19:0] override_address = 20'h00000, // Default: Use received_transaction.LPM_Address
    input bit [7:0] override_length = 8'h00,      // Default: Use received_transaction.LPM_LEN
    input bit [7:0] override_data[$] = {}         // Default: Use received_transaction.LPM_Data
);
    // Decode the aux_in_out signal
    bit [3:0] command;       // First 4 bits: Command
    bit [19:0] address;      // Address
    bit [7:0] length;        // Length
    bit [7:0] data[$];       // Data
    bit ack_count = 0;       // Ack counter

    // Use overrides if provided, otherwise use defaults from received_transaction
    command = (override_command != 4'b0000) ? override_command : received_transaction.LPM_CMD;
    address = (override_address != 20'h00000) ? override_address : received_transaction.LPM_Address;
    length = (override_length != 8'h00) ? override_length : received_transaction.LPM_LEN;
    data = (override_data.size() > 0) ? override_data : {received_transaction.LPM_Data};

    while (ack_count < 1) begin
        // Wait for the next transaction
        ref_model_in_port.get(received_transaction);

        // Copy the received transaction
        expected_transaction.copy(received_transaction);

        // Initialize outputs
        expected_transaction.LPM_Reply_ACK = 1'b0;
        expected_transaction.LPM_Reply_ACK_VLD = 1'b0;
        expected_transaction.LPM_Reply_DATA = 8'h00;
        expected_transaction.LPM_Reply_DATA_VLD = 1'b0;
        expected_transaction.LPM_Native_I2C = 1'b0;

        // Check if the transaction is valid
        if (received_transaction.LPM_Transaction_VLD) begin
            // Handle Write Request Transaction
            if (command == AUX_NATIVE_WRITE) begin
                // Simulate transmitting the request
                `uvm_info(get_type_name(), $sformatf("Transmitting Write Request: CMD=0x%0b, Addr=0x%0h, LEN=%0d, DATA=0x%0h",
                                                     command, address, length, data), UVM_LOW);

                // Assign the encoded value to aux_in_out
                // Encoded value: 1000|LPM_Address -> LPM_Address -> LPM_Address -> LPM_LEN -> LPM_Data

                // Byte 1: 1000 followed by the first 4 bits of address
                expected_transaction.aux_in_out = {4'b1000, address[19:16]}; // 1000 + first 4 bits of address
                expected_transaction.start_stop = 1'b1; // Raise the start_stop signal
                ref_model_out_port.write(expected_transaction); // Send the expected transaction to the scoreboard

                // Byte 2: Next 8 bits of address
                expected_transaction.aux_in_out = address[15:8]; // Next 8 bits of address
                ref_model_out_port.write(expected_transaction); // Send the expected transaction to the scoreboard

                // Byte 3: Last 8 bits of address
                expected_transaction.aux_in_out = address[7:0]; // Last 8 bits of address
                ref_model_out_port.write(expected_transaction); // Send the expected transaction to the scoreboard

                // Byte 4: Length
                expected_transaction.aux_in_out = length; // Length
                ref_model_out_port.write(expected_transaction); // Send the expected transaction to the scoreboard

                // Loop to send data bytes
                for (int i = 0; i < length; i++) begin
                    expected_transaction.aux_in_out = data[i];
                    ref_model_out_port.write(expected_transaction); // Send the expected transaction to the scoreboard
                end

                // Wait for the next transaction
                ref_model_in_port.get(received_transaction);

                // Extract the command
                command = received_transaction.aux_in_out[3:0]; // Second 4 bits

                // Take action based on the command
                case (command)
                    AUX_ACK: begin // ACK
                        `uvm_info(get_type_name(), "Processing AUX_ACK Command", UVM_LOW);

                        // Populate the expected transaction
                        expected_transaction.LPM_Reply_ACK = AUX_ACK[1:0];
                        expected_transaction.LPM_Reply_ACK_VLD = 1'b1;
                        expected_transaction.LPM_Reply_Data = 8'h00; // No data for ACK
                        expected_transaction.LPM_Reply_Data_VLD = 1'b0;

                        // Send the expected transaction to the scoreboard
                        ref_model_out_port.write(expected_transaction);

                        ack_count = 1; // Increment the ack_count to exit the loop

                        // Log the data being sent
                        `uvm_info(get_type_name(), $sformatf("Sending AUX_ACK Response: data_size=%0d", data.size()), UVM_LOW);
                    end

                    AUX_NACK: begin // NACK
                        `uvm_info(get_type_name(), "Processing AUX_NACK Command", UVM_LOW);

                        // Simulate acknowledgment for NACK
                        expected_transaction.LPM_Reply_ACK = AUX_NACK[1:0];
                        expected_transaction.LPM_Reply_ACK_VLD = 1'b1;
                        expected_transaction.LPM_Reply_Data = 8'h00; // No data for NACK
                        expected_transaction.LPM_Reply_Data_VLD = 1'b0;

                        // Send the expected transaction to the scoreboard
                        ref_model_out_port.write(expected_transaction);

                        // Log the acknowledgment
                        `uvm_info(get_type_name(), "AUX_NACK Command Acknowledged", UVM_LOW);
                    end

                    AUX_DEFER: begin // DEFER
                        `uvm_info(get_type_name(), "Processing AUX_DEFER Command", UVM_LOW);

                        // Simulate acknowledgment for DEFER
                        expected_transaction.LPM_Reply_ACK = AUX_DEFER[1:0];
                        expected_transaction.LPM_Reply_ACK_VLD = 1'b1;
                        expected_transaction.LPM_Reply_Data = 8'h00; // No data for DEFER
                        expected_transaction.LPM_Reply_Data_VLD = 1'b0;

                        // Send the expected transaction to the scoreboard
                        ref_model_out_port.write(expected_transaction);

                        // Log the acknowledgment
                        `uvm_info(get_type_name(), "AUX_DEFER Command Acknowledged", UVM_LOW);
                    end

                    AUX_RESERVED: begin // RESERVED
                        `uvm_info(get_type_name(), "Processing AUX_RESERVED Command", UVM_LOW);

                        // Simulate acknowledgment for RESERVED
                        expected_transaction.LPM_Reply_ACK = AUX_RESERVED[1:0];
                        expected_transaction.LPM_Reply_ACK_VLD = 1'b1;
                        expected_transaction.LPM_Reply_Data = 8'h00; // No data for RESERVED
                        expected_transaction.LPM_Reply_Data_VLD = 1'b0;

                        // Send the expected transaction to the scoreboard
                        ref_model_out_port.write(expected_transaction);

                        // Log the acknowledgment
                        `uvm_info(get_type_name(), "AUX_RESERVED Command Acknowledged", UVM_LOW);
                    end

                    default: begin // Invalid or unsupported command
                        `uvm_error(get_type_name(), $sformatf("Invalid or unsupported command: 0x%h", command));
                    end
                endcase
            end else begin
                `uvm_error(get_type_name(), $sformatf("Invalid LPM_CMD: %0b", command));
            end
        end else begin
            // Transaction not valid
            `uvm_warning(get_type_name(), "LPM_Transaction_VLD is not asserted");
        end
    end

    // Log the generated expected transaction
    `uvm_info(get_type_name(), $sformatf("Generated expected transaction: %s", expected_transaction.convert2string()), UVM_LOW);
endfunction


    // Function to generate the expected transaction for Clock Recovery Phase
    function bit generate_clock_recovery_phase(
        input dp_transaction received_transaction,
        output dp_transaction expected_transaction
    );
        bit CR_DONE = 0;
        bit [3:0] command;       // First 4 bits: Command
        bit [7:0] length;        // Next 8 bits: Length
        bit [7:0] data[$];       // Remaining bits: Data
        bit ack_count = 0;  //Ack counter
        
        // to be added: add PHY_Instruct && PHY_ADJ_BW && PHY_ADJ_LC?
        // Step 1: Enable Training Pattern 1 and disable scrambling
        `uvm_info(get_type_name(), "Enabling Training Pattern 1 for Clock Recovery and Disabling Scrambling", UVM_LOW);

        while (ack_count < 1) begin

        // Wait for the next transaction
        ref_model_in_port.get(received_transaction);

        // Check if the transaction is valid
        if (received_transaction.LPM_Transaction_VLD) begin

            // Handle Write Request Transaction
            if (received_transaction.LPM_CMD == AUX_NATIVE_WRITE) begin

                // Assign the encoded value to aux_in_out
                // Encoded value: 1000|0000 -> 00000001 -> 00000010 -> 00000000 -> 00000000(don't know what for now)

                // Byte 1:
                expected_transaction.aux_in_out = 8'b10000000
                expected_transaction.start_stop = 1'b1; // Raise the start_stop signal
                ref_model_out_port.write(expected_transaction); // Send the expected transaction to the scoreboard
                
                // Byte 2:
                expected_transaction.aux_in_out = 8'b00000001;
                ref_model_out_port.write(expected_transaction); // Send the expected transaction to the scoreboard
                
                // Byte 3:
                expected_transaction.aux_in_out = 8'b00000010; // address 0x00102
                ref_model_out_port.write(expected_transaction); // Send the expected transaction to the scoreboard
                
                // Byte 4:
                expected_transaction.aux_in_out = 8'b00000000; // length = 0
                ref_model_out_port.write(expected_transaction); // Send the expected transaction to the scoreboard

                // Byte 5:
                expected_transaction.aux_in_out = 8'b00000000; // don't know what for now
                ref_model_out_port.write(expected_transaction); // Send the expected transaction to the scoreboard

                // Wait for the next transaction
                ref_model_in_port.get(received_transaction);
                
                    // Extract the command
                    command = received_transaction.aux_in_out[3:0]; // Second 4 bits
                    
                    // Take action based on the command
                    case (command)
                        AUX_ACK: begin // ACK
                            `uvm_info(get_type_name(), "Processing AUX_ACK Command", UVM_LOW);
                    
                                // Populate the expected transaction
                                expected_transaction.LPM_Reply_ACK = AUX_ACK[1:0];
                                expected_transaction.LPM_Reply_ACK_VLD = 1'b1;
                                expected_transaction.LPM_Reply_Data = 8'h00; // No data for ACK
                                expected_transaction.LPM_Reply_Data_VLD = 1'b0;

                            // Send the expected transaction to the scoreboard
                            ref_model_out_port.write(expected_transaction);
                    
                            ack_count = 1; // Increment the ack_count to exit the loop
                    
                            // Log the data being sent
                            `uvm_info(get_type_name(), $sformatf("Sending AUX_ACK Response: data_size=%0d", data.size()), UVM_LOW);
                        end
                    
                        AUX_NACK: begin // NACK
                            `uvm_info(get_type_name(), "Processing AUX_NACK Command", UVM_LOW);
                    
                            // Simulate acknowledgment for NACK
                            expected_transaction.LPM_Reply_ACK = AUX_NACK[1:0];
                            expected_transaction.LPM_Reply_ACK_VLD = 1'b1;
                            expected_transaction.LPM_Reply_Data = 8'h00; // No data for NACK
                            expected_transaction.LPM_Reply_Data_VLD = 1'b0;
                    
                            // Send the expected transaction to the scoreboard
                            ref_model_out_port.write(expected_transaction);
                    
                            // Log the acknowledgment
                            `uvm_info(get_type_name(), "AUX_NACK Command Acknowledged", UVM_LOW);
                        end
                    
                        AUX_DEFER: begin // DEFER
                            `uvm_info(get_type_name(), "Processing AUX_DEFER Command", UVM_LOW);
                    
                            // Simulate acknowledgment for DEFER
                            expected_transaction.LPM_Reply_ACK = AUX_DEFER[1:0];
                            expected_transaction.LPM_Reply_ACK_VLD = 1'b1;
                            expected_transaction.LPM_Reply_Data = 8'h00; // No data for DEFER
                            expected_transaction.LPM_Reply_Data_VLD = 1'b0;
                    
                            // Send the expected transaction to the scoreboard
                            ref_model_out_port.write(expected_transaction);
                    
                            // Log the acknowledgment
                            `uvm_info(get_type_name(), "AUX_DEFER Command Acknowledged", UVM_LOW);
                        end
                    
                        AUX_RESERVED: begin // RESERVED
                            `uvm_info(get_type_name(), "Processing AUX_RESERVED Command", UVM_LOW);
                    
                            // Simulate acknowledgment for RESERVED
                            expected_transaction.LPM_Reply_ACK = AUX_RESERVED[1:0];
                            expected_transaction.LPM_Reply_ACK_VLD = 1'b1;
                            expected_transaction.LPM_Reply_Data = 8'h00; // No data for RESERVED
                            expected_transaction.LPM_Reply_Data_VLD = 1'b0;
                    
                            // Send the expected transaction to the scoreboard
                            ref_model_out_port.write(expected_transaction);
                    
                            // Log the acknowledgment
                            `uvm_info(get_type_name(), "AUX_RESERVED Command Acknowledged", UVM_LOW);
                        end
                    
                        default: begin // Invalid or unsupported command
                            `uvm_error(get_type_name(), $sformatf("Invalid or unsupported command: 0x%h", command));
                        end
                    endcase
    
            // Handle Invalid Command
            end else begin
                `uvm_error(get_type_name(), $sformatf("Invalid LPM_CMD: %0b", received_transaction.LPM_CMD));
            end
        end else begin
            // Transaction not valid
            `uvm_warning(get_type_name(), "LPM_Transaction_VLD is not asserted");
        end
        end
    
        // Step 2: Configure initial driving settings (minimum voltage and 0 dB pre-emphasis) from 0x00103 to 0x00106
        `uvm_info(get_type_name(), "Configuring initial driving settings for Clock Recovery", UVM_LOW);
        ack_count = 0;  //reset Ack counter

        while (ack_count < 1) begin

        // Wait for the next transaction
        ref_model_in_port.get(received_transaction);

        // Check if the transaction is valid
        if (received_transaction.LPM_Transaction_VLD) begin

            // Handle Write Request Transaction
            if (received_transaction.LPM_CMD == AUX_NATIVE_WRITE) begin

                // Assign the encoded value to aux_in_out
                // Encoded value: 1000|0000 -> 00000001 -> 00000011 -> 00000000 -> 00000000 x4 times (don't know what for now)

                // Byte 1:
                expected_transaction.aux_in_out = 8'b10000000
                expected_transaction.start_stop = 1'b1; // Raise the start_stop signal
                ref_model_out_port.write(expected_transaction); // Send the expected transaction to the scoreboard
                
                // Byte 2:
                expected_transaction.aux_in_out = 8'b00000001;
                ref_model_out_port.write(expected_transaction); // Send the expected transaction to the scoreboard
                
                // Byte 3: 
                expected_transaction.aux_in_out = 8'b00000011; // address 0x00103
                ref_model_out_port.write(expected_transaction); // Send the expected transaction to the scoreboard
                
                // Byte 4: 
                expected_transaction.aux_in_out = 8'b00000011; // length = 4
                ref_model_out_port.write(expected_transaction); // Send the expected transaction to the scoreboard

                // Byte 5: 
                expected_transaction.aux_in_out = 8'b00000000; // don't know what for now
                ref_model_out_port.write(expected_transaction); // Send the expected transaction to the scoreboard
                
                // Byte 6: 
                expected_transaction.aux_in_out = 8'b00000000; // don't know what for now
                ref_model_out_port.write(expected_transaction); // Send the expected transaction to the scoreboard

                // Byte 7: 
                expected_transaction.aux_in_out = 8'b00000000; // don't know what for now
                ref_model_out_port.write(expected_transaction); // Send the expected transaction to the scoreboard

                // Byte 8: 
                expected_transaction.aux_in_out = 8'b00000000; // don't know what for now
                ref_model_out_port.write(expected_transaction); // Send the expected transaction to the scoreboard

                // Wait for the next transaction
                ref_model_in_port.get(received_transaction);
                
                    // Extract the command
                    command = received_transaction.aux_in_out[3:0]; // Second 4 bits
                    
                    // Take action based on the command
                    case (command)
                        AUX_ACK: begin // ACK
                            `uvm_info(get_type_name(), "Processing AUX_ACK Command", UVM_LOW);
                    
                                // Populate the expected transaction
                                expected_transaction.LPM_Reply_ACK = AUX_ACK[1:0];
                                expected_transaction.LPM_Reply_ACK_VLD = 1'b1;
                                expected_transaction.LPM_Reply_Data = 8'h00; // No data for ACK
                                expected_transaction.LPM_Reply_Data_VLD = 1'b0;

                            // Send the expected transaction to the scoreboard
                            ref_model_out_port.write(expected_transaction);
                    
                            ack_count = 1; // Increment the ack_count to exit the loop
                    
                            // Log the data being sent
                            `uvm_info(get_type_name(), $sformatf("Sending AUX_ACK Response: data_size=%0d", data.size()), UVM_LOW);
                        end
                    
                        AUX_NACK: begin // NACK
                            `uvm_info(get_type_name(), "Processing AUX_NACK Command", UVM_LOW);
                    
                            // Simulate acknowledgment for NACK
                            expected_transaction.LPM_Reply_ACK = AUX_NACK[1:0];
                            expected_transaction.LPM_Reply_ACK_VLD = 1'b1;
                            expected_transaction.LPM_Reply_Data = 8'h00; // No data for NACK
                            expected_transaction.LPM_Reply_Data_VLD = 1'b0;
                    
                            // Send the expected transaction to the scoreboard
                            ref_model_out_port.write(expected_transaction);
                    
                            // Log the acknowledgment
                            `uvm_info(get_type_name(), "AUX_NACK Command Acknowledged", UVM_LOW);
                        end
                    
                        AUX_DEFER: begin // DEFER
                            `uvm_info(get_type_name(), "Processing AUX_DEFER Command", UVM_LOW);
                    
                            // Simulate acknowledgment for DEFER
                            expected_transaction.LPM_Reply_ACK = AUX_DEFER[1:0];
                            expected_transaction.LPM_Reply_ACK_VLD = 1'b1;
                            expected_transaction.LPM_Reply_Data = 8'h00; // No data for DEFER
                            expected_transaction.LPM_Reply_Data_VLD = 1'b0;
                    
                            // Send the expected transaction to the scoreboard
                            ref_model_out_port.write(expected_transaction);
                    
                            // Log the acknowledgment
                            `uvm_info(get_type_name(), "AUX_DEFER Command Acknowledged", UVM_LOW);
                        end
                    
                        AUX_RESERVED: begin // RESERVED
                            `uvm_info(get_type_name(), "Processing AUX_RESERVED Command", UVM_LOW);
                    
                            // Simulate acknowledgment for RESERVED
                            expected_transaction.LPM_Reply_ACK = AUX_RESERVED[1:0];
                            expected_transaction.LPM_Reply_ACK_VLD = 1'b1;
                            expected_transaction.LPM_Reply_Data = 8'h00; // No data for RESERVED
                            expected_transaction.LPM_Reply_Data_VLD = 1'b0;
                    
                            // Send the expected transaction to the scoreboard
                            ref_model_out_port.write(expected_transaction);
                    
                            // Log the acknowledgment
                            `uvm_info(get_type_name(), "AUX_RESERVED Command Acknowledged", UVM_LOW);
                        end
                    
                        default: begin // Invalid or unsupported command
                            `uvm_error(get_type_name(), $sformatf("Invalid or unsupported command: 0x%h", command));
                        end
                    endcase
    
            // Handle Invalid Command
            end else begin
                `uvm_error(get_type_name(), $sformatf("Invalid LPM_CMD: %0b", received_transaction.LPM_CMD));
            end
        end else begin
            // Transaction not valid
            `uvm_warning(get_type_name(), "LPM_Transaction_VLD is not asserted");
        end
        end

        // Step 3: Read TRAINING_AUX_RD_INTERVAL (Address 0x0000E)
        `uvm_info(get_type_name(), "Reading TRAINING_AUX_RD_INTERVAL", UVM_LOW);
        
        ack_count = 0;  //Reset Ack counter

        while (ack_count < 1) begin

        // Wait for the next transaction
        ref_model_in_port.get(received_transaction);

        // Check if the transaction is valid
        if (received_transaction.LPM_Transaction_VLD) begin

            // Handle Read Request Transaction
            if (received_transaction.LPM_CMD == AUX_NATIVE_READ) begin
    
                // Assign the encoded value to aux_in_out
                // Encoded value: 1001|0000 -> 00000001 -> 00000011 -> 00000000 -> 00000000 x4 times (don't know what for now)

                // Byte 1:
                expected_transaction.aux_in_out = 8'b10010000
                expected_transaction.start_stop = 1'b1; // Raise the start_stop signal
                ref_model_out_port.write(expected_transaction); // Send the expected transaction to the scoreboard
                
                // Byte 2:
                expected_transaction.aux_in_out = 8'b00000000;
                ref_model_out_port.write(expected_transaction); // Send the expected transaction to the scoreboard
                
                // Byte 3: 
                expected_transaction.aux_in_out = 8'b00001110; // address 0x0000E
                ref_model_out_port.write(expected_transaction); // Send the expected transaction to the scoreboard
                
                // Byte 4: 
                expected_transaction.aux_in_out = 8'b00000000; // length = 1
                ref_model_out_port.write(expected_transaction); // Send the expected transaction to the scoreboard

                length = 8'b00000000;   // Store the length for later use

                // Allocate the dynamic array based on the length
                data = new[length];

                // Wait for the next transaction
                ref_model_in_port.get(received_transaction);
                
                    // Extract the command
                    command = received_transaction.aux_in_out[3:0]; // Second 4 bits
                    
                    // Loop to extract data bytes based on the length
                    for (int i = 0; i < length + 1; i++) begin
                        // Wait for the next transaction for each byte
                        ref_model_in_port.get(received_transaction);
                    
                        // Extract the data byte(s) from aux_in_out
                        data[i] = received_transaction.aux_in_out[7:0];
                    
                        // Log the extracted data byte
                        `uvm_info(get_type_name(), $sformatf("Extracted Data Byte %0d: 0x%0h", i, data[i]), UVM_LOW);
                    end
                    
                    // Take action based on the command
                    case (command)
                        AUX_ACK: begin // ACK
                            `uvm_info(get_type_name(), "Processing AUX_ACK Command", UVM_LOW);
                    
                            for (int i = 0; i < length + 1; i++) begin
                                // Populate the expected transaction
                                expected_transaction.LPM_Reply_ACK = AUX_ACK[1:0];
                                expected_transaction.LPM_Reply_ACK_VLD = 1'b1;
                                expected_transaction.LPM_Reply_Data = data[i];
                                expected_transaction.LPM_Reply_Data_VLD = 1'b1;
                    
                                // Send the expected transaction to the scoreboard
                                ref_model_out_port.write(expected_transaction);
                            end
                    
                            ack_count = 1; // Increment the ack_count to exit the loop
                    
                            // Log the data being sent
                            `uvm_info(get_type_name(), $sformatf("Sending AUX_ACK Response: data_size=%0d", data.size()), UVM_LOW);
                        end
                    
                        AUX_NACK: begin // NACK
                            `uvm_info(get_type_name(), "Processing AUX_NACK Command", UVM_LOW);
                    
                            // Simulate acknowledgment for NACK
                            expected_transaction.LPM_Reply_ACK = AUX_NACK[1:0];
                            expected_transaction.LPM_Reply_ACK_VLD = 1'b1;
                            expected_transaction.LPM_Reply_Data = 8'h00; // No data for NACK
                            expected_transaction.LPM_Reply_Data_VLD = 1'b0;
                    
                            // Send the expected transaction to the scoreboard
                            ref_model_out_port.write(expected_transaction);
                    
                            // Log the acknowledgment
                            `uvm_info(get_type_name(), "AUX_NACK Command Acknowledged", UVM_LOW);
                        end
                    
                        AUX_DEFER: begin // DEFER
                            `uvm_info(get_type_name(), "Processing AUX_DEFER Command", UVM_LOW);
                    
                            // Simulate acknowledgment for DEFER
                            expected_transaction.LPM_Reply_ACK = AUX_DEFER[1:0];
                            expected_transaction.LPM_Reply_ACK_VLD = 1'b1;
                            expected_transaction.LPM_Reply_Data = 8'h00; // No data for DEFER
                            expected_transaction.LPM_Reply_Data_VLD = 1'b0;
                    
                            // Send the expected transaction to the scoreboard
                            ref_model_out_port.write(expected_transaction);
                    
                            // Log the acknowledgment
                            `uvm_info(get_type_name(), "AUX_DEFER Command Acknowledged", UVM_LOW);
                        end
                    
                        AUX_RESERVED: begin // RESERVED
                            `uvm_info(get_type_name(), "Processing AUX_RESERVED Command", UVM_LOW);
                    
                            // Simulate acknowledgment for RESERVED
                            expected_transaction.LPM_Reply_ACK = AUX_RESERVED[1:0];
                            expected_transaction.LPM_Reply_ACK_VLD = 1'b1;
                            expected_transaction.LPM_Reply_Data = 8'h00; // No data for RESERVED
                            expected_transaction.LPM_Reply_Data_VLD = 1'b0;
                    
                            // Send the expected transaction to the scoreboard
                            ref_model_out_port.write(expected_transaction);
                    
                            // Log the acknowledgment
                            `uvm_info(get_type_name(), "AUX_RESERVED Command Acknowledged", UVM_LOW);
                        end
                    
                        default: begin // Invalid or unsupported command
                            `uvm_error(get_type_name(), $sformatf("Invalid or unsupported command: 0x%h", command));
                        end
                    endcase
    
        // Handle Invalid Command
            end else begin
                `uvm_error(get_type_name(), $sformatf("Invalid LPM_CMD: %0b", received_transaction.LPM_CMD));
            end
        end else begin
            // Transaction not valid
            `uvm_warning(get_type_name(), "LPM_Transaction_VLD is not asserted");
        end
        end

        // haven't figured out how to wait
        // Step 4: Wait for the interval and read Link Status registers (0x00202 : 0x00207)
        ack_count = 0;  //Reset Ack counter

        while (ack_count < 1) begin

        // Wait for the next transaction
        ref_model_in_port.get(received_transaction);

        // Check if the transaction is valid
        if (received_transaction.LPM_Transaction_VLD) begin

            // Handle Read Request Transaction
            if (received_transaction.LPM_CMD == AUX_NATIVE_READ) begin
    
                // Assign the encoded value to aux_in_out
                // Encoded value: 1001|0000 -> 00000001 -> 00000011 -> 00000000 -> 00000000 x4 times (don't know what for now)

                // Byte 1:
                expected_transaction.aux_in_out = 8'b10010000
                expected_transaction.start_stop = 1'b1; // Raise the start_stop signal
                ref_model_out_port.write(expected_transaction); // Send the expected transaction to the scoreboard
                
                // Byte 2:
                expected_transaction.aux_in_out = 8'b00000010;
                ref_model_out_port.write(expected_transaction); // Send the expected transaction to the scoreboard
                
                // Byte 3: 
                expected_transaction.aux_in_out = 8'b00000010; // address 0x00202
                ref_model_out_port.write(expected_transaction); // Send the expected transaction to the scoreboard
                
                // Byte 4: 
                expected_transaction.aux_in_out = 8'b00000101; // length = 6
                ref_model_out_port.write(expected_transaction); // Send the expected transaction to the scoreboard

                length = 8'b00000101;   // Store the length for later use

                // Allocate the dynamic array based on the length
                data = new[length];

                // Wait for the next transaction
                ref_model_in_port.get(received_transaction);
                
                    // Extract the command
                    command = received_transaction.aux_in_out[3:0]; // Second 4 bits
                    
                    // Loop to extract data bytes based on the length
                    for (int i = 0; i < length + 1; i++) begin
                        // Wait for the next transaction for each byte
                        ref_model_in_port.get(received_transaction);
                    
                        // Extract the data byte(s) from aux_in_out
                        data[i] = received_transaction.aux_in_out[7:0];
                    
                        // Log the extracted data byte
                        `uvm_info(get_type_name(), $sformatf("Extracted Data Byte %0d: 0x%0h", i, data[i]), UVM_LOW);
                    end
                    
                    // Take action based on the command
                    case (command)
                        AUX_ACK: begin // ACK
                            `uvm_info(get_type_name(), "Processing AUX_ACK Command", UVM_LOW);
                    
                            for (int i = 0; i < length + 1; i++) begin
                                // Populate the expected transaction
                                expected_transaction.LPM_Reply_ACK = AUX_ACK[1:0];
                                expected_transaction.LPM_Reply_ACK_VLD = 1'b1;
                                expected_transaction.LPM_Reply_Data = data[i];
                                expected_transaction.LPM_Reply_Data_VLD = 1'b1;
                    
                                // Send the expected transaction to the scoreboard
                                ref_model_out_port.write(expected_transaction);
                            end
                    
                            ack_count = 1; // Increment the ack_count to exit the loop
                    
                            // Log the data being sent
                            `uvm_info(get_type_name(), $sformatf("Sending AUX_ACK Response: data_size=%0d", data.size()), UVM_LOW);
                        end
                    
                        AUX_NACK: begin // NACK
                            `uvm_info(get_type_name(), "Processing AUX_NACK Command", UVM_LOW);
                    
                            // Simulate acknowledgment for NACK
                            expected_transaction.LPM_Reply_ACK = AUX_NACK[1:0];
                            expected_transaction.LPM_Reply_ACK_VLD = 1'b1;
                            expected_transaction.LPM_Reply_Data = 8'h00; // No data for NACK
                            expected_transaction.LPM_Reply_Data_VLD = 1'b0;
                    
                            // Send the expected transaction to the scoreboard
                            ref_model_out_port.write(expected_transaction);
                    
                            // Log the acknowledgment
                            `uvm_info(get_type_name(), "AUX_NACK Command Acknowledged", UVM_LOW);
                        end
                    
                        AUX_DEFER: begin // DEFER
                            `uvm_info(get_type_name(), "Processing AUX_DEFER Command", UVM_LOW);
                    
                            // Simulate acknowledgment for DEFER
                            expected_transaction.LPM_Reply_ACK = AUX_DEFER[1:0];
                            expected_transaction.LPM_Reply_ACK_VLD = 1'b1;
                            expected_transaction.LPM_Reply_Data = 8'h00; // No data for DEFER
                            expected_transaction.LPM_Reply_Data_VLD = 1'b0;
                    
                            // Send the expected transaction to the scoreboard
                            ref_model_out_port.write(expected_transaction);
                    
                            // Log the acknowledgment
                            `uvm_info(get_type_name(), "AUX_DEFER Command Acknowledged", UVM_LOW);
                        end
                    
                        AUX_RESERVED: begin // RESERVED
                            `uvm_info(get_type_name(), "Processing AUX_RESERVED Command", UVM_LOW);
                    
                            // Simulate acknowledgment for RESERVED
                            expected_transaction.LPM_Reply_ACK = AUX_RESERVED[1:0];
                            expected_transaction.LPM_Reply_ACK_VLD = 1'b1;
                            expected_transaction.LPM_Reply_Data = 8'h00; // No data for RESERVED
                            expected_transaction.LPM_Reply_Data_VLD = 1'b0;
                    
                            // Send the expected transaction to the scoreboard
                            ref_model_out_port.write(expected_transaction);
                    
                            // Log the acknowledgment
                            `uvm_info(get_type_name(), "AUX_RESERVED Command Acknowledged", UVM_LOW);
                        end
                    
                        default: begin // Invalid or unsupported command
                            `uvm_error(get_type_name(), $sformatf("Invalid or unsupported command: 0x%h", command));
                        end
                    endcase
    
        // Handle Invalid Command
            end else begin
                `uvm_error(get_type_name(), $sformatf("Invalid LPM_CMD: %0b", received_transaction.LPM_CMD));
            end
        end else begin
            // Transaction not valid
            `uvm_warning(get_type_name(), "LPM_Transaction_VLD is not asserted");
        end
        end
    
        // Step 5: Handle failure
        if (!CR_DONE) begin
            `uvm_error(get_type_name(), "Clock Recovery failed after retries");
        end
    
        return CR_DONE;
    endfunction
    



    // Function to generate the expected transaction for Channel Equalization Phase
    function bit generate_channel_equalization_phase(
        input dp_transaction received_transaction,
        output dp_transaction expected_transaction
    );
        bit EQ_DONE = 0;
    
        // Step 1: Enable Training Pattern 2 and disable scrambling
        `uvm_info(get_type_name(), "Enabling Training Pattern 2 for Channel Equalization", UVM_LOW);
        expected_transaction.LPM_Reply_ACK = 1'b1;
        expected_transaction.LPM_Reply_ACK_VLD = 1'b1;
    
        // Step 2: Read TRAINING_AUX_RD_INTERVAL
        expected_transaction.SPM_Reply_Data = $urandom_range(1, 10); // Simulate interval value
        `uvm_info(get_type_name(), $sformatf("TRAINING_AUX_RD_INTERVAL: %0d", expected_transaction.SPM_Reply_Data), UVM_LOW);
    
        // Step 3: Wait for the interval and read Link Status registers
        for (int retry = 0; retry < 5; retry++) begin
            `uvm_info(get_type_name(), "Reading Link Status registers for Channel Equalization", UVM_LOW);
            bit [7:0] EQ_status = $urandom_range(0, 1); // Randomly simulate success/failure
    
            if (EQ_status) begin
                EQ_DONE = 1;
                `uvm_info(get_type_name(), "Channel Equalization successful", UVM_LOW);
                break;
            end else begin
                `uvm_warning(get_type_name(), "Channel Equalization failed, retrying...");
            end
        end
    
        // Step 4: Handle failure
        if (!EQ_DONE) begin
            `uvm_error(get_type_name(), "Channel Equalization failed after retries");
        end
    
        return EQ_DONE;
    endfunction




    // Function to generate the expected transaction for Link Training Flow
    function void generate_link_training_flow(
        input dp_transaction received_transaction,
        output dp_transaction expected_transaction
    );
        bit [3:0] command;       // First 4 bits: Command

        // Initialize internal flags
        bit CR_DONE = 0;
        bit EQ_DONE = 0;
    
        // Step 1: Read DPCD capabilities (0x00000–0x000FF)
        `uvm_info(get_type_name(), "Reading DPCD capabilities", UVM_LOW);

        for (int i = 0; i < 16; i++) begin
        // Native AUX Transaction Scenario
        generate_native_aux_read_transaction(received_transaction, expected_transaction);
        end
        
        // need to understand better
        // Step 2: Writing to the Link Configuration field (offsets 0x00100–0x00101) to set the Link Bandwidth and Lane Count  clears register 0x00102 to 00h in the same write 
        //transaction.
        
        bit ack_count = 0;  //Ack counter

         // Wait for the next transaction

        while (ack_count < 1) begin

        ref_model_in_port.get(received_transaction);

        // Check if the transaction is valid
        if (received_transaction.LPM_Transaction_VLD) begin

            // Handle Write Request Transaction
            if (received_transaction.LPM_CMD == AUX_NATIVE_WRITE) begin

                // Assign the encoded value to aux_in_out
                // Encoded value: 1000|0000 -> 00000001 -> 00000000 -> 00000010 -> Link_BW_CR -> Link_LC_CR -> 00000000

                // Byte 1:
                expected_transaction.aux_in_out = 8'b10000000
                expected_transaction.start_stop = 1'b1; // Raise the start_stop signal
                ref_model_out_port.write(expected_transaction); // Send the expected transaction to the scoreboard
                
                // Byte 2:
                expected_transaction.aux_in_out = 8'b00000001;
                ref_model_out_port.write(expected_transaction); // Send the expected transaction to the scoreboard
                
                // Byte 3:
                expected_transaction.aux_in_out = 8'b00000000; // address 0x00100
                ref_model_out_port.write(expected_transaction); // Send the expected transaction to the scoreboard
                
                // Byte 4:
                expected_transaction.aux_in_out = 8'b00000010; // length = 3
                ref_model_out_port.write(expected_transaction); // Send the expected transaction to the scoreboard

                length = received_transaction.LPM_LEN;   // Store the length for later use

                // Byte 5: Link_BW_CR
                expected_transaction.aux_in_out = received_transaction.Link_BW_CR; // Link_BW_CR
                ref_model_out_port.write(expected_transaction); // Send the expected transaction to the scoreboard

                length = received_transaction.LPM_LEN;   // Store the length for later use

                // Byte 6: Link_LC_CR
                expected_transaction.aux_in_out = received_transaction.Link_LC_CR; // Link_LC_CR
                ref_model_out_port.write(expected_transaction); // Send the expected transaction to the scoreboard

                length = received_transaction.LPM_LEN;   // Store the length for later use

                // Byte 7: 00000000
                expected_transaction.aux_in_out = 8'h00;
                ref_model_out_port.write(expected_transaction); // Send the expected transaction to the scoreboard

                // Wait for the next transaction
                ref_model_in_port.get(received_transaction);
                
                    // Extract the command
                    command = received_transaction.aux_in_out[3:0]; // Second 4 bits
                    
                    // Take action based on the command
                    case (command)
                        AUX_ACK: begin // ACK
                            `uvm_info(get_type_name(), "Processing AUX_ACK Command", UVM_LOW);
                    
                                // Populate the expected transaction
                                expected_transaction.LPM_Reply_ACK = AUX_ACK[1:0];
                                expected_transaction.LPM_Reply_ACK_VLD = 1'b1;
                                expected_transaction.LPM_Reply_Data = 8'h00; // No data for ACK
                                expected_transaction.LPM_Reply_Data_VLD = 1'b0;

                            // Send the expected transaction to the scoreboard
                            ref_model_out_port.write(expected_transaction);
                    
                            ack_count = 1; // Increment the ack_count to exit the loop
                    
                            // Log the data being sent
                            `uvm_info(get_type_name(), $sformatf("Sending AUX_ACK Response: data_size=%0d", data.size()), UVM_LOW);
                        end
                    
                        AUX_NACK: begin // NACK
                            `uvm_info(get_type_name(), "Processing AUX_NACK Command", UVM_LOW);
                    
                            // Simulate acknowledgment for NACK
                            expected_transaction.LPM_Reply_ACK = AUX_NACK[1:0];
                            expected_transaction.LPM_Reply_ACK_VLD = 1'b1;
                            expected_transaction.LPM_Reply_Data = 8'h00; // No data for NACK
                            expected_transaction.LPM_Reply_Data_VLD = 1'b0;
                    
                            // Send the expected transaction to the scoreboard
                            ref_model_out_port.write(expected_transaction);
                    
                            // Log the acknowledgment
                            `uvm_info(get_type_name(), "AUX_NACK Command Acknowledged", UVM_LOW);
                        end
                    
                        AUX_DEFER: begin // DEFER
                            `uvm_info(get_type_name(), "Processing AUX_DEFER Command", UVM_LOW);
                    
                            // Simulate acknowledgment for DEFER
                            expected_transaction.LPM_Reply_ACK = AUX_DEFER[1:0];
                            expected_transaction.LPM_Reply_ACK_VLD = 1'b1;
                            expected_transaction.LPM_Reply_Data = 8'h00; // No data for DEFER
                            expected_transaction.LPM_Reply_Data_VLD = 1'b0;
                    
                            // Send the expected transaction to the scoreboard
                            ref_model_out_port.write(expected_transaction);
                    
                            // Log the acknowledgment
                            `uvm_info(get_type_name(), "AUX_DEFER Command Acknowledged", UVM_LOW);
                        end
                    
                        AUX_RESERVED: begin // RESERVED
                            `uvm_info(get_type_name(), "Processing AUX_RESERVED Command", UVM_LOW);
                    
                            // Simulate acknowledgment for RESERVED
                            expected_transaction.LPM_Reply_ACK = AUX_RESERVED[1:0];
                            expected_transaction.LPM_Reply_ACK_VLD = 1'b1;
                            expected_transaction.LPM_Reply_Data = 8'h00; // No data for RESERVED
                            expected_transaction.LPM_Reply_Data_VLD = 1'b0;
                    
                            // Send the expected transaction to the scoreboard
                            ref_model_out_port.write(expected_transaction);
                    
                            // Log the acknowledgment
                            `uvm_info(get_type_name(), "AUX_RESERVED Command Acknowledged", UVM_LOW);
                        end
                    
                        default: begin // Invalid or unsupported command
                            `uvm_error(get_type_name(), $sformatf("Invalid or unsupported command: 0x%h", command));
                        end
                    endcase
    
            // Handle Invalid Command
            end else begin
                `uvm_error(get_type_name(), $sformatf("Invalid LPM_CMD: %0b", received_transaction.LPM_CMD));
            end
        end else begin
            // Transaction not valid
            `uvm_warning(get_type_name(), "LPM_Transaction_VLD is not asserted");
        end
        end

    
        // Step 3: Begin Clock Recovery Phase
        CR_DONE = generate_clock_recovery_phase(received_transaction, expected_transaction);
    
        // Step 5: Begin Channel Equalization Phase if CR is successful
        if (CR_DONE) begin
            EQ_DONE = generate_channel_equalization_phase(received_transaction, expected_transaction);
        end
    
        // Step 6: Finalize Link Training
        if (EQ_DONE) begin
            expected_transaction.EQ_LT_Pass = 1'b1;
            expected_transaction.final_bw = $urandom_range(1, 4); // Simulate final bandwidth
            expected_transaction.final_lane_count = $urandom_range(1, 4); // Simulate final lane count
            `uvm_info(get_type_name(), $sformatf("Link Training successful: BW=%0d, Lanes=%0d",
                                                 expected_transaction.final_bw,
                                                 expected_transaction.final_lane_count), UVM_LOW);
        end else begin
            expected_transaction.EQ_Failed = 1'b1;
            `uvm_error(get_type_name(), "Link Training failed");
        end
    endfunction

endclass









   '{8'hAA, 8'hBB, 8'hCC}      // Override data (custom data array)