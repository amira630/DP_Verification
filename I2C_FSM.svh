    //to be added: nack and defer correct conditions, correct aux_in_out, ctrl_i2c_failed maybe??

    // Function to generate the expected transaction for I2C-over-AUX (EDID Read)
    function void generate_i2c_over_aux_transaction(
    input dp_sink_sequence_item sink_item,  // Transaction from dp_sink_monitor
    input dp_tl_sequence_item tl_item,      // Transaction from dp_tl_monitor
    output dp_transaction expected_transaction // Generated expected transaction
    );
        // Decode the aux_in_out signal
        bit [3:0] command;       // First 4 bits: Command
        bit [7:0] address;       // last 8 bits of address Address
        bit [7:0] length;        // Next 8 bits: Length
        bit [7:0] data[$];       // Remaining bits: Data
        int ack_count = 0;  //Ack counter
        
        while (ack_count < 1) begin

        // Wait for the next transaction
        ref_model_in_port.get(tl_item);
    
        // Initialize outputs
        // note to self: need to turn off hpd detect / IRQ maybe?
        expected_transaction.SPM_Reply_ACK = I2C_ACK[3:2];
        expected_transaction.SPM_Reply_ACK_VLD = 1'b0;
        expected_transaction.SPM_Reply_Data = 8'h00;
        expected_transaction.SPM_Reply_Data_VLD = 1'b0;
        expected_transaction.I2C_Complete = 1'b0;
    
        // Check if the transaction is valid
        if (tl_item.SPM_Transaction_VLD) begin
            // Step 1: Address-only transaction
            if (tl_item.SPM_CMD == AUX_I2C_READ && tl_item.SPM_LEN == 0) begin

                address = tl_item.SPM_Address; // Extract the address from the received transaction

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
                ref_model_in_port.get(sink_item);
                
                    // Extract the command
                    command = sink_item.aux_in_out[7:4]; // First 4 bits
                
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
                            expected_transaction.CTRL_I2C_Failed = 1'b1; // Set CTRL_I2C_Failed to indicate failure
                
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
        ref_model_in_port.get(tl_item);
    
        // Check if the transaction is valid
        if (tl_item.SPM_Transaction_VLD) begin
            // Step 1: Address-only transaction
            if (tl_item.SPM_CMD == AUX_I2C_READ && tl_item.SPM_LEN == 0) begin

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
                ref_model_in_port.get(sink_item);
                
                    // Extract the command
                    command = sink_item.aux_in_out[7:4]; // First 4 bits

                    // Wait for the next transaction
                    ref_model_in_port.get(sink_item);  
                    
                    // Extract the data
                    data = sink_item.aux_in_out[7:0]; // Second 8 bits  
                
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
                            expected_transaction.CTRL_I2C_Failed = 1'b1; // Set CTRL_I2C_Failed to indicate failure

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
        ref_model_in_port.get(tl_item);
    
        // Check if the transaction is valid
        if (tl_item.SPM_Transaction_VLD) begin
            // Step 1: Address-only transaction
            if (tl_item.SPM_CMD == AUX_I2C_READ && tl_item.SPM_LEN == 0) begin
                
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
                ref_model_in_port.get(sink_item);
                
                    // Extract the command
                    command = sink_item.aux_in_out[7:4]; // First 4 bits
                
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
                            expected_transaction.CTRL_I2C_Failed = 1'b1; // Set CTRL_I2C_Failed to indicate failure
                
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














































// Function to generate the expected transaction for I2C-over-AUX (EDID Read)
// ADD the timeout timer
    
    task generate_i2c_over_aux_transaction_fsm(
        input dp_sink_sequence_item sink_item,  // Transaction from dp_sink_monitor
        input dp_tl_sequence_item tl_item,      // Transaction from dp_tl_monitor
        output dp_transaction expected_transaction // Generated expected transaction
    );

        typedef enum logic [1:0] {
        IDLE,
        ADDRESS_ONLY_START,
        DATA,
        ADDRESS_ONLY_END
       } i2c_fsm_state_e;

        i2c_fsm_state_e current_state, next_state;
        bit [3:0] command;       // First 4 bits: Command
        bit [7:0] address;       // Address
        bit [7:0] data;          // Data
        int ACK_COUNTER = 0;     // Ack counter
        int DEFER_COUNTER = 0;   // DEFER counter
    
        // Initialize the FSM
        current_state = IDLE;
    
        forever begin
            case (current_state)
                IDLE: begin
                    // Wait for the next transaction
                    ref_model_in_port.get(tl_item);
    
                    // Initialize outputs
                    expected_transaction.SPM_Reply_ACK = 2'b00;
                    expected_transaction.SPM_Reply_ACK_VLD = 1'b0;
                    expected_transaction.SPM_Reply_Data = 8'h00;
                    expected_transaction.SPM_Reply_Data_VLD = 1'b0;
                    expected_transaction.CTRL_I2C_Failed = 1'b0;
                    expected_transaction.SPM_NATIVE_I2C = 1'b1;

                    // Initialize the DEFER counter
                    DEFER_COUNTER = 0;

                    // Initialize the ACK counter
                    ACK_COUNTER = 0;
    
                    // Check if the transaction is valid
                    if (tl_item.SPM_Transaction_VLD) begin
                        if (tl_item.SPM_CMD == AUX_I2C_READ && tl_item.SPM_LEN == 0) begin
                            address = tl_item.SPM_Address; // Extract the address
                            next_state = ADDRESS_ONLY_START;
                        end else begin
                            `uvm_error(get_type_name(), "Invalid SPM_CMD or SPM_LEN for I2C-over-AUX transaction");
                            next_state = IDLE;
                        end
                    end else begin
                        `uvm_warning(get_type_name(), "SPM_Transaction_VLD is not asserted");
                        next_state = IDLE;
                    end
                end
    
                ADDRESS_ONLY_START: begin

                address = tl_item.SPM_Address; // Extract the address from the received transaction

                // Assign the encoded value to aux_in_out
                // Encoded value: 0101|0000 -> 00000000 -> SPM_Address

                // Byte 1
                expected_transaction.aux_in_out = 8'b0101_0000;
                // Raise the PHY_START_STOP signal
                expected_transaction.PHY_START_STOP = 1'b1;

                // Send the expected transaction to the scoreboard
                ref_model_out_port.write(expected_transaction);
                
                // Byte 2
                expected_transaction.aux_in_out = 8'b0000_0000;
                // Raise the PHY_START_STOP signal
                expected_transaction.PHY_START_STOP = 1'b1;

                // Send the expected transaction to the scoreboard
                ref_model_out_port.write(expected_transaction);
                
                // Byte 3
                expected_transaction.aux_in_out = address;
                // Raise the PHY_START_STOP signal
                expected_transaction.PHY_START_STOP = 1'b1; 
                
                // Send the expected transaction to the scoreboard
                ref_model_out_port.write(expected_transaction);

                // // Simulate the encoded Address-only I2C-over-AUX transaction
                // `uvm_info(get_type_name(), "Transmitting Address-only I2C-over-AUX transaction", UVM_LOW);
                // `uvm_info(get_type_name(), $sformatf("AUX_IN_OUT: 0101|0000 -> 00000000 -> 00000000 (START_STOP=1, MOT=1, I2C Address=0000000)"), UVM_LOW);

                // Wait for the next transaction
                ref_model_in_port.get(sink_item);
                
                    // Extract the command
                    command = sink_item.aux_in_out[7:4]; // First 4 bits

                    // Take action based on the command
                    case (command)
                        I2C_ACK: begin // ACK
                            `uvm_info(get_type_name(), "Processing I2C_ACK Command", UVM_LOW);
                
                            // Populate the expected transaction
                            expected_transaction.SPM_Reply_ACK = I2C_ACK[3:2];
                            expected_transaction.SPM_Reply_ACK_VLD = 1'b1;
                            expected_transaction.SPM_Reply_Data = 8'h00;
                            expected_transaction.SPM_Reply_Data_VLD = 1'b0;
                
                            // Log the data being sent
                            `uvm_info(get_type_name(), $sformatf("Sending I2C_ACK Response: data_size=%0d", data.size()), UVM_LOW);

                            next_state = DATA; // Move to DATA state
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

                            next_state = ADDRESS_ONLY_START; // Retry ADDRESS_ONLY_START state

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

                            DEFER_COUNTER = DEFER_COUNTER + 1;
                            if (DEFER_COUNTER == 8) 
                            begin
                                next_state = IDLE; // Restart from IDLE state after 8 DEFERs
                                expected_transaction.CTRL_I2C_Failed = 1'b1; // Set CTRL_I2C_Failed to indicate failure
                                `uvm_info(get_type_name(), "Restarting from IDLE state after 8 DEFERs", UVM_LOW);
                            end 
                            else
                            begin
                                next_state = ADDRESS_ONLY_START; // Retry ADDRESS_ONLY_START state
                            end

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

                            next_state = ADDRESS_ONLY_START; // Retry ADDRESS_ONLY_START state
                        end
                
                        default: begin // Invalid or unsupported command
                            `uvm_error(get_type_name(), $sformatf("Invalid or unsupported command: 0x%h", command));
                        end
                    endcase
                
                    // Send the expected transaction to the scoreboard
                    ref_model_out_port.write(expected_transaction);

                end

                GET_NEW_DATA: begin

                    // Wait for the next transaction
                    ref_model_in_port.get(tl_item);

                    next_state = DATA; // Move to DATA state

                end
    
                DATA: begin

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
                expected_transaction.aux_in_out = tl_item.SPM_Address; 
                
                // Send the expected transaction to the scoreboard
                ref_model_out_port.write(expected_transaction);

                // Byte 4
                expected_transaction.aux_in_out = 8'b0000_0000;
                
                // Send the expected transaction to the scoreboard
                ref_model_out_port.write(expected_transaction);

                // // Simulate sending the read request
                // `uvm_info(get_type_name(), $sformatf("AUX_IN_OUT: 0101|0000 -> 00000000 -> 00000000 -> 0000|0000 (START_STOP=1, MOT=1, I2C Address=0000000, Read Length=1)"), UVM_LOW);

                // Wait for the next transaction
                ref_model_in_port.get(sink_item);
                
                    // Extract the command
                    command = sink_item.aux_in_out[7:4]; // First 4 bits

                    // Wait for the next transaction
                    ref_model_in_port.get(sink_item);  
                    
                    // Extract the data
                    data = sink_item.aux_in_out[7:0]; // Second 8 bits  
                
                    // Take action based on the command
                    case (command)
                        I2C_ACK: begin // ACK
                            `uvm_info(get_type_name(), "Processing I2C_ACK Command", UVM_LOW);
                
                            // Populate the expected transaction
                            expected_transaction.SPM_Reply_ACK = I2C_ACK[3:2];
                            expected_transaction.SPM_Reply_ACK_VLD = 1'b1;
                            expected_transaction.SPM_Reply_Data = data;
                            expected_transaction.SPM_Reply_Data_VLD = 1'b1;
                
                            // Log the data being sent
                            `uvm_info(get_type_name(), $sformatf("Sending I2C_ACK Response: data_size=%0d", data.size()), UVM_LOW);

                            ACK_COUNTER = ACK_COUNTER + 1; // Increment the ACK_COUNTER to exit the loop

                            if (ACK_COUNTER == 128) begin
                                next_state = ADDRESS_ONLY_END; // Move to ADDRESS_ONLY_END state
                            end else begin
                                next_state = GET_NEW_DATA; // Go to GET_NEW_DATA state
                            end

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

                            next_state = DATA; // Retry DATA state

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

                            DEFER_COUNTER = DEFER_COUNTER + 1;
                            if (DEFER_COUNTER == 8) 
                            begin
                                next_state = IDLE; // Restart from IDLE state after 8 DEFERs
                                expected_transaction.CTRL_I2C_Failed = 1'b1; // Set CTRL_I2C_Failed to indicate failure
                                `uvm_info(get_type_name(), "Restarting from IDLE state after 8 DEFERs", UVM_LOW);
                            end 
                            else
                            begin
                                next_state = DATA; // Retry DATA state
                            end

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

                            next_state = DATA; // Retry DATA state
                        end
                
                        default: begin // Invalid or unsupported command
                            `uvm_error(get_type_name(), $sformatf("Invalid or unsupported command: 0x%h", command));
                        end
                    endcase
                
                    // Send the expected transaction to the scoreboard
                    ref_model_out_port.write(expected_transaction);

                end
    
                ADDRESS_ONLY_END: begin

                // NOT SURE IF I NEED TO GET A NEW TL_ITEM HERE OR NOT

                // // Wait for the next transaction
                // ref_model_in_port.get(tl_item);

                
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
                ref_model_in_port.get(sink_item);
                
                    // Extract the command
                    command = sink_item.aux_in_out[7:4]; // First 4 bits
                
                    // Take action based on the command
                    case (command)
                        I2C_ACK: begin // ACK
                            `uvm_info(get_type_name(), "Processing I2C_ACK Command", UVM_LOW);
                
                            // Populate the expected transaction
                            expected_transaction.SPM_Reply_ACK = I2C_ACK[3:2];
                            expected_transaction.SPM_Reply_ACK_VLD = 1'b1;
                            expected_transaction.SPM_Reply_Data = 8'h00;
                            expected_transaction.SPM_Reply_Data_VLD = 1'b0;
                
                            // Log the data being sent
                            `uvm_info(get_type_name(), $sformatf("Sending I2C_ACK Response: data_size=%0d", data.size()), UVM_LOW);

                            // Send the expected transaction to the scoreboard
                            ref_model_out_port.write(expected_transaction);

                            next_state = IDLE; // Move to IDLE state

                            break; // Exit the loop
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

                            // Send the expected transaction to the scoreboard
                            ref_model_out_port.write(expected_transaction)

                            next_state = ADDRESS_ONLY_END; // Retry ADDRESS_ONLY_END state

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

                            // Send the expected transaction to the scoreboard
                            ref_model_out_port.write(expected_transaction)

                            DEFER_COUNTER = DEFER_COUNTER + 1;
                            if (DEFER_COUNTER == 8) 
                            begin
                                next_state = IDLE; // Restart from IDLE state after 8 DEFERs
                                expected_transaction.CTRL_I2C_Failed = 1'b1; // Set CTRL_I2C_Failed to indicate failure
                                `uvm_info(get_type_name(), "Restarting from IDLE state after 8 DEFERs", UVM_LOW);
                            end 
                            else
                            begin
                                next_state = ADDRESS_ONLY_END; // Retry ADDRESS_ONLY_END state
                            end

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

                            // Send the expected transaction to the scoreboard
                            ref_model_out_port.write(expected_transaction)

                            next_state = ADDRESS_ONLY_END; // Retry ADDRESS_ONLY_END state
                        end
                
                        default: begin // Invalid or unsupported command
                            `uvm_error(get_type_name(), $sformatf("Invalid or unsupported command: 0x%h", command));
                        end
                    endcase
                
                end
    
                default: begin
                    `uvm_error(get_type_name(), "Invalid FSM state");
                    next_state = IDLE;
                end
            endcase
    
            // Update the current state
            current_state = next_state;
        end
    endtask