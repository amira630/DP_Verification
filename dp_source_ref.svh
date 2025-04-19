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
        output dp_transaction expected_transaction,
        input bit [3:0] override_command = 4'b0000,  // Default: Use received_transaction.LPM_CMD
        input bit [19:0] override_address = 20'h00000, // Default: Use received_transaction.LPM_Address
        input bit [7:0] override_length = 8'h00       // Default: Use received_transaction.LPM_LEN
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
    
        // while (ack_count < 1) begin
            // Wait for the next transaction
            // ref_model_in_port.get(received_transaction);
    
            // // Copy the received transaction
            // expected_transaction.copy(received_transaction);
    
            // // Initialize outputs
            // expected_transaction.LPM_Reply_ACK = 1'b0;
            // expected_transaction.LPM_Reply_ACK_VLD = 1'b0;
            // expected_transaction.LPM_Reply_DATA = 8'h00;
            // expected_transaction.LPM_Reply_DATA_VLD = 1'b0;
            // expected_transaction.LPM_Native_I2C = 1'b0;
    
            // Check if the transaction is valid
            if (received_transaction.LPM_Transaction_VLD) begin
                // Handle Read Request Transaction
                if (command == AUX_NATIVE_READ) begin
                    // Log the read request transaction
                    `uvm_info(get_type_name(), $sformatf("Transmitting Read Request: CMD=0x%0b, Addr=0x%0h, LEN=%0d",
                                                         command, address, length), UVM_LOW);
    
                    // Assign the encoded value to aux_in_out
                    // Encoded value: 1001|Address -> Address -> Address -> Length
    
                    // Byte 1: 1001 followed by the first 4 bits of address
                    expected_transaction.aux_in_out = {4'b1001, address[19:16]}; // 1001 + first 4 bits of address
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
    
                            // ack_count = 1; // Increment the ack_count to exit the loop
    
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
        // end
    
        // Log the generated expected transaction
        `uvm_info(get_type_name(), $sformatf("Generated expected transaction: %s", expected_transaction.convert2string()), UVM_LOW);
    endfunction

    //to be added: nack and defer conditions

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

    // while (ack_count < 1) begin
    // //     // Wait for the next transaction
    //     ref_model_in_port.get(received_transaction); //Lpm_seq_item

        // // Copy the received transaction
        // expected_transaction.copy(received_transaction);

        // // Initialize outputs
        // expected_transaction.LPM_Reply_ACK = 1'b0;
        // expected_transaction.LPM_Reply_ACK_VLD = 1'b0;
        // expected_transaction.LPM_Reply_DATA = 8'h00;
        // expected_transaction.LPM_Reply_DATA_VLD = 1'b0;
        // expected_transaction.LPM_Native_I2C = 1'b0;

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
                ref_model_in_port.get(received_transaction); //Sink_seq_item

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

                        // ack_count = 1; // Increment the ack_count to exit the loop

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
    // end

    // Log the generated expected transaction
    `uvm_info(get_type_name(), $sformatf("Generated expected transaction: %s", expected_transaction.convert2string()), UVM_LOW);
endfunction


function bit generate_clock_recovery_phase(
    input dp_transaction received_transaction,
    output dp_transaction expected_transaction
);

    typedef enum logic [2:0] {
       IDLE,
       WRITE_LINK_CONFIG,
       ENABLE_TRAINING_PATTERN,
       CONFIGURE_DRIVING_SETTINGS,
       READ_TRAINING_INTERVAL,
       WAIT_AND_READ_LINK_STATUS,
       FAILURE,
       SUCCESS
    } fsm_state_e;

    bit CR_DONE = 0;
    fsm_state_e current_state, next_state;
    bit ack_count = 0;  //Ack counter
    bit [1:0]  MAX_VTG_temp, MAX_PRE_temp; // Temporary variables for max values
    bit [3:0]  full_loop_counter = 4'b0000;
    bit [3:0]  same_parameters_repeated_counter = 4'b0000;
    bit [3:0]  CURRENT_LANE_COUNT = 2'b00; // Current lane count
    bit [7:0]  CURRENT_LINK_RATE = 8'h00; // Current link rate

    // Initialize the FSM
    current_state = IDLE;

    forever begin
        case (current_state)
            IDLE: begin
                // Wait for the next transaction
                ref_model_in_port.get(received_transaction); //Lpm_seq_item

                // Store the important values
                MAX_VTG_temp = received_transaction.MAX_VTG;
                MAX_PRE_temp = received_transaction.MAX_PRE;
                CURRENT_LANE_COUNT = received_transaction.Link_LC_CR;
                CURRENT_LINK_RATE = received_transaction.Link_BW_CR;

                if (received_transaction.LPM_Start_CR && received_transaction.Driving_Param_VLD && received_transaction.Config_Param_VLD)
                // Start the clock recovery process
                `uvm_info(get_type_name(), "Starting Clock Recovery Phase", UVM_LOW);
                next_state = WRITE_LINK_CONFIG;
                else begin
                    next_state = IDLE; // Stay in IDLE if not valid
                end
            end

            IDLE_WITH_UPDATED_BW_OR_LC: begin
                // Wait for the next transaction
                ref_model_in_port.get(received_transaction); //Lpm_seq_item

                // Store the important values
                CURRENT_LANE_COUNT = received_transaction.Link_LC_CR;
                CURRENT_LINK_RATE = received_transaction.Link_BW_CR;

                if (received_transaction.LPM_Start_CR && received_transaction.Driving_Param_VLD && received_transaction.Config_Param_VLD)
                // Start the clock recovery process
                `uvm_info(get_type_name(), "Repeatinf Clock Recovery Phase with Updated Parameters", UVM_LOW);
                next_state = WRITE_LINK_CONFIG;
                else begin
                    next_state = IDLE_WITH_UPDATED_BW_OR_LC; // Stay in IDLE if not valid
                end
            end

            WRITE_LINK_CONFIG: begin
                // Step 1: Write to the Link Configuration field
                `uvm_info(get_type_name(), "Writing to Link Configuration field", UVM_LOW);
                
                generate_native_aux_write_transaction(
                    received_transaction,       // Input transaction
                    expected_transaction,       // Output transaction
                    4'b1000,                    // Override command (AUX_NATIVE_WRITE)
                    20'h00100,                  // Override address (0x00100)
                    8'h03,                      // Override length (3 byte(s))
                    '{received_transaction.CURRENT_LINK_RATE, {3'b100, 5'(received_transaction.CURRENT_LANE_COUNT + 5'b01)}, 8'h00} // Override data
                );
                
                next_state = ENABLE_TRAINING_PATTERN;
            end
            
            // need manual implementation of the function to generate the expected transaction for training pattern
            ENABLE_TRAINING_PATTERN: begin
                // Step 2: Enable Training Pattern 1 and disable scrambling
                `uvm_info(get_type_name(), "Enabling Training Pattern 1 and disabling scrambling", UVM_LOW);

                expected_transaction.PHY_Instruct = 2'b00; // Training pattern 1
                expected_transaction.PHY_Instruct_VLD = 1'b1; // Set PHY_Instruct_VLD to 1
                // expected_transaction.PHY_ADJ_BW = received_transaction.Link_BW_CR
                // expected_transaction.PHY_ADJ_LC = received_transaction.Link_LC_CR

                generate_native_aux_write_transaction(
                    received_transaction,       // Input transaction
                    expected_transaction,       // Output transaction
                    4'b1000,                    // Override command (AUX_NATIVE_WRITE)
                    20'h00102,                  // Override address (0x00102)
                    8'h00,                      // Override length (1 byte)
                    8'h21                      // Override data
                );

                expected_transaction.PHY_Instruct_VLD = 1'b1; // Set PHY_Instruct_VLD to 1

                next_state = CONFIGURE_DRIVING_SETTINGS;
            end

            // add if conditions
                 CONFIGURE_DRIVING_SETTINGS: begin
                // Step 3: Configure initial driving settings
                `uvm_info(get_type_name(), "Configuring initial driving settings", UVM_LOW);
            
                if (received_transaction.Link_LC_CR == 2'b00) begin
                    // Configure Lane 0
                    generate_native_aux_write_transaction(
                        received_transaction,       // Input transaction
                        expected_transaction,       // Output transaction
                        4'b1000,                    // Override command (AUX_NATIVE_WRITE)
                        20'h00103,                  // Override address (0x00103)
                        8'h00,                      // Override length (1 byte)
                        '{(received_transaction.VTG[1:0] == received_transaction.MAX_VTG && received_transaction.PRE[1:0] == received_transaction.MAX_PRE) ? {2'b00, 1'b1, received_transaction.PRE[1:0], 1'b1, received_transaction.VTG[1:0]} :
                          (received_transaction.VTG[1:0] == received_transaction.MAX_VTG) ? {2'b00, 1'b0, received_transaction.PRE[1:0], 1'b1, received_transaction.VTG[1:0]} :
                          (received_transaction.PRE[1:0] == received_transaction.MAX_PRE) ? {2'b00, 1'b1, received_transaction.PRE[1:0], 1'b0, received_transaction.VTG[1:0]} :
                          {2'b00, 1'b0, received_transaction.PRE[1:0], 1'b0, received_transaction.VTG[1:0]}} // Override data
                    );
                end else if (received_transaction.Link_LC_CR == 2'b01) begin
                    // Configure Lanes 0 and 1
                    generate_native_aux_write_transaction(
                        received_transaction,       // Input transaction
                        expected_transaction,       // Output transaction
                        4'b1000,                    // Override command (AUX_NATIVE_WRITE)
                        20'h00103,                  // Override address (0x00103)
                        8'h01,                      // Override length (2 bytes)
                        '{(received_transaction.VTG[1:0] == received_transaction.MAX_VTG && received_transaction.PRE[1:0] == received_transaction.MAX_PRE) ? {2'b00, 1'b1, received_transaction.PRE[1:0], 1'b1, received_transaction.VTG[1:0]} :
                          (received_transaction.VTG[1:0] == received_transaction.MAX_VTG) ? {2'b00, 1'b0, received_transaction.PRE[1:0], 1'b1, received_transaction.VTG[1:0]} :
                          (received_transaction.PRE[1:0] == received_transaction.MAX_PRE) ? {2'b00, 1'b1, received_transaction.PRE[1:0], 1'b0, received_transaction.VTG[1:0]} :
                          {2'b00, 1'b0, received_transaction.PRE[1:0], 1'b0, received_transaction.VTG[1:0]},
                          (received_transaction.VTG[3:2] == received_transaction.MAX_VTG && received_transaction.PRE[3:2] == received_transaction.MAX_PRE) ? {2'b00, 1'b1, received_transaction.PRE[3:2], 1'b1, received_transaction.VTG[3:2]} :
                          (received_transaction.VTG[3:2] == received_transaction.MAX_VTG) ? {2'b00, 1'b0, received_transaction.PRE[3:2], 1'b1, received_transaction.VTG[3:2]} :
                          (received_transaction.PRE[3:2] == received_transaction.MAX_PRE) ? {2'b00, 1'b1, received_transaction.PRE[3:2], 1'b0, received_transaction.VTG[3:2]} :
                          {2'b00, 1'b0, received_transaction.PRE[3:2], 1'b0, received_transaction.VTG[3:2]}} // Override data
                    );
                end else begin
                    // Configure Lanes 0, 1, 2, and 3
                    generate_native_aux_write_transaction(
                        received_transaction,       // Input transaction
                        expected_transaction,       // Output transaction
                        4'b1000,                    // Override command (AUX_NATIVE_WRITE)
                        20'h00103,                  // Override address (0x00103)
                        8'h03,                      // Override length (4 bytes)
                        '{(received_transaction.VTG[1:0] == received_transaction.MAX_VTG && received_transaction.PRE[1:0] == received_transaction.MAX_PRE) ? {2'b00, 1'b1, received_transaction.PRE[1:0], 1'b1, received_transaction.VTG[1:0]} :
                          (received_transaction.VTG[1:0] == received_transaction.MAX_VTG) ? {2'b00, 1'b0, received_transaction.PRE[1:0], 1'b1, received_transaction.VTG[1:0]} :
                          (received_transaction.PRE[1:0] == received_transaction.MAX_PRE) ? {2'b00, 1'b1, received_transaction.PRE[1:0], 1'b0, received_transaction.VTG[1:0]} :
                          {2'b00, 1'b0, received_transaction.PRE[1:0], 1'b0, received_transaction.VTG[1:0]},
                          (received_transaction.VTG[3:2] == received_transaction.MAX_VTG && received_transaction.PRE[3:2] == received_transaction.MAX_PRE) ? {2'b00, 1'b1, received_transaction.PRE[3:2], 1'b1, received_transaction.VTG[3:2]} :
                          (received_transaction.VTG[3:2] == received_transaction.MAX_VTG) ? {2'b00, 1'b0, received_transaction.PRE[3:2], 1'b1, received_transaction.VTG[3:2]} :
                          (received_transaction.PRE[3:2] == received_transaction.MAX_PRE) ? {2'b00, 1'b1, received_transaction.PRE[3:2], 1'b0, received_transaction.VTG[3:2]} :
                          {2'b00, 1'b0, received_transaction.PRE[3:2], 1'b0, received_transaction.VTG[3:2]},
                          (received_transaction.VTG[5:4] == received_transaction.MAX_VTG && received_transaction.PRE[5:4] == received_transaction.MAX_PRE) ? {2'b00, 1'b1, received_transaction.PRE[5:4], 1'b1, received_transaction.VTG[5:4]} :
                          (received_transaction.VTG[5:4] == received_transaction.MAX_VTG) ? {2'b00, 1'b0, received_transaction.PRE[5:4], 1'b1, received_transaction.VTG[5:4]} :
                          (received_transaction.PRE[5:4] == received_transaction.MAX_PRE) ? {2'b00, 1'b1, received_transaction.PRE[5:4], 1'b0, received_transaction.VTG[5:4]} :
                          {2'b00, 1'b0, received_transaction.PRE[5:4], 1'b0, received_transaction.VTG[5:4]},
                          (received_transaction.VTG[7:6] == received_transaction.MAX_VTG && received_transaction.PRE[7:6] == received_transaction.MAX_PRE) ? {2'b00, 1'b1, received_transaction.PRE[7:6], 1'b1, received_transaction.VTG[7:6]} :
                          (received_transaction.VTG[7:6] == received_transaction.MAX_VTG) ? {2'b00, 1'b0, received_transaction.PRE[7:6], 1'b1, received_transaction.VTG[7:6]} :
                          (received_transaction.PRE[7:6] == received_transaction.MAX_PRE) ? {2'b00, 1'b1, received_transaction.PRE[7:6], 1'b0, received_transaction.VTG[7:6]} :
                          {2'b00, 1'b0, received_transaction.PRE[7:6], 1'b0, received_transaction.VTG[7:6]}} // Override data
                    );
                end

                next_state = READ_TRAINING_INTERVAL;
            end

            READ_TRAINING_INTERVAL: begin
                // Step 4: Read TRAINING_AUX_RD_INTERVAL
                `uvm_info(get_type_name(), "Reading TRAINING_AUX_RD_INTERVAL", UVM_LOW);
                generate_native_aux_read_transaction(
                    received_transaction,       // Input transaction
                    expected_transaction,       // Output transaction
                    4'b1001,                    // Override command (AUX_NATIVE_READ)
                    20'h0000E,                  // Override address (0x0000E)
                    8'h01                       // Override length (1 byte)
                );
                next_state = WAIT_AND_READ_LINK_STATUS;
            end

            WAIT_AND_READ_LINK_STATUS: begin
       
    //     constraint eq_rd_value_constraint {
    //     EQ_RD_Value[7] == 1'b1; // Ensure the MSB is always 1
    //     EQ_RD_Value[6:0] inside {7'h00, 7'h01, 7'h02, 7'h03, 7'h04}; // Allowed values for the lower 7 bits

                // Step 5: Wait for the interval and read Link Status registers
                ref_model_in_port.get(received_transaction); //Lpm_seq_item
                // Wait EQ_RD_Value
                `uvm_info(get_type_name(), "Waiting for TRAINING_AUX_RD_INTERVAL and reading Link Status registers", UVM_LOW);
                generate_native_aux_read_transaction(
                    received_transaction,       // Input transaction
                    expected_transaction,       // Output transaction
                    4'b1001,                    // Override command (AUX_NATIVE_READ)
                    20'h00202,                  // Override address (0x00202)
                    8'h05                       // Override length (6 byte(s))
                );

            end
            
            // Need to maybe store Link_LC_CR in a temp variable
            // Step 6: Check for CR_DONE and CR_DONE_VLD
            CR_DONE_CHECK: begin
            
            same_parameters_repeated_counter = same_parameters_repeated_counter + 1;

            // Wait for the next transaction
            ref_model_in_port.get(received_transaction); //Lpm_seq_item

		    if((received_transaction.Link_LC_CR == 'b11) && (&received_transaction.CR_DONE))
             begin
              next_state = SUCCESS;			
             end
            else if((received_transaction.Link_LC_CR == 'b01) && (&received_transaction.CR_DONE[1:0]))
             begin
              next_state = SUCCESS;			
             end
            else if((received_transaction.Link_LC_CR == 'b00) && (received_transaction.CR_DONE[0]))
             begin
              next_state = SUCCESS;			
             end
            else if(received_transaction.Link_LC_CR == 'b10)   // Error Value of LC so it goes to the IDLE STATE 
             begin
              next_state = IDLE_STATE;			
             end
			     else
			      begin
              next_state = READ_ADJUSTED_DRIVING_PARAMETERS; 	
            end	
            end

            // Read Adjusted Training Parameters
            READ_ADJUSTED_DRIVING_PARAMETERS: begin

            `uvm_info(get_type_name(), "Reading Adjusted Training Parameters", UVM_LOW);

                generate_native_aux_read_transaction(
                    received_transaction,       // Input transaction
                    expected_transaction,       // Output transaction
                    4'b1001,                    // Override command (AUX_NATIVE_READ)
                    20'h00206,                  // Override address (0x00202)
                    8'h01                       // Override length (2 byte(s))
                );

                next_state = CHECK_NEW_CONDITIONS; 

            end
        // Conditions: 1. MAX_VTG = VTG 2. full_loop_counter > 10 3. same_parameters_repeated_counter > 5
        // Note: Should be 3 conditions but don't know
            CHECK_NEW_CONDITIONS: begin
          ref_model_in_port.get(received_transaction); //Lpm_seq_item

           if ((full_loop_counter == 'd11) || (same_parameters_repeated_counter == 'd6) || (received_transaction.VTG == MAX_VTG_temp))
            begin
             next_state = CHECK_IF_RBR;
            end
           else
            begin
             next_state = CONFIGURE_DRIVING_SETTINGS; // Repeat from step 3
            end
          end

            // Check if RBR is used
            CHECK_IF_RBR: begin

           if (CURRENT_LINK_RATE == == 8'h06) // is Bandwidth used is RBR?
            begin
             next_state = CHECK_IF_ONE_LANE_USED;
            end
           else
            begin
             next_state = REDUCE_LINK_RATE;
            end

            end

            // Check if one lane is used
            CHECK_IF_ONE_LANE_USED: begin
              if (CURRENT_LANE_COUNT == 2'b00) // is one lane used?
            begin
             next_state = FAILURE;
            end
              else
            begin
             next_state = REDUCE_LANE_COUNT;
            end
            end
            
            // Reduce Lane Count
            REDUCE_LANE_COUNT: begin
            if (CURRENT_LANE_COUNT == 2'b11)
            begin
             CURRENT_LANE_COUNT = 2'b01;
            end
            else
            begin
             CURRENT_LANE_COUNT = 2'b01;
            end  
            next_state = IDLE_WITH_UPDATED_BW_OR_LC; // Reset to IDLE for the next phase  
            end

            // Reduce Link Count
            REDUCE_LINK_RATE: begin
          if (CURRENT_LINK_RATE == 8'h1E)               // HBR3
           begin
             CURRENT_LINK_RATE = 8'h14;          // HBR2
           end
          else if (CURRENT_LINK_RATE == 8'h14)          // HBR2
           begin
             CURRENT_LINK_RATE = 8'h0A;          // HBR
           end
          else if (CURRENT_LINK_RATE == 8'h0A)          // HBR
           begin
              CURRENT_LINK_RATE = 8'h06;          // RBR
           end
          else                                       // Default
           begin
              CURRENT_LINK_RATE = 8'h06;          // RBR
           end 
            next_state = IDLE_WITH_UPDATED_BW_OR_LC; // Reset to IDLE for the next phase 
            end

            SUCCESS: begin
                // Clock Recovery successful
                `uvm_info(get_type_name(), "Clock Recovery successful", UVM_LOW);
                expected_transaction.CR_Completed = 1'b1;
                 ref_model_out_port.write(expected_transaction); // Send the expected transaction to the scoreboard
                CR_DONE = 1;
                next_state = IDLE; // Reset to IDLE for the next phase
                break;
            end
               FSM_CR_Failed,           // A Signal indicating the failure of the Clock Recovery phase during link training, meaning the sink failed to acquire the clock frequency during the training process
            FAILURE: begin
                // Clock Recovery failed
                `uvm_error(get_type_name(), "Clock Recovery failed", UVM_LOW);
                expected_transaction.FSM_CR_Failed = 1'b1;
                ref_model_out_port.write(expected_transaction); // Send the expected transaction to the scoreboard
                // CR_DONE = 0;
                next_state = IDLE; // Reset to IDLE for the next phase
                break;      
            end

            default: begin
                // Default state
                next_state = IDLE;
            end
        endcase

        // Update the current state
        current_state = next_state;

        // Exit the loop if the process is complete
        if (current_state == IDLE && (CR_DONE || next_state == FAILURE)) begin
            break;
        end
    end

    return CR_DONE;
endfunction


    // Function to generate the expected transaction for Channel Equalization Phase
    function bit generate_channel_equalization_phase(
        input dp_transaction received_transaction,
        output dp_transaction expected_transaction
    );
        // bit EQ_DONE = 0;
    
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
        generate_native_aux_read_transaction(
            received_transaction,       // Input transaction
            expected_transaction        // Output transaction
        );
        end
        
        // need to understand better
        // need to handle how to get Link_BW_CR and Link_LC_CR
        // Step 2: Writing to the Link Configuration field (offsets 0x00100–0x00101) to set the Link Bandwidth and Lane Count  clears register 0x00102 to 00h in the same write 
        //transaction.

                // Assign the encoded value to aux_in_out
                // Encoded value: 1000|0000 -> 00000001 -> 00000000 -> 00000010 -> Link_BW_CR -> Link_LC_CR -> 00000000
                
                // Call the Native aux write function to handle the transaction
                generate_native_aux_write_transaction(
                    received_transaction,       // Input transaction
                    expected_transaction,       // Output transaction
                    4'b1000,                    // Override command (AUX_NATIVE_WRITE)
                    20'h00100,                  // Override address (0x00100)
                    8'h03,                      // Override length (3 byte(s)) (length + 1)
                    '{8'Link_BW_CR, 8'Link_LC_CR, 8'h00}      // Override data
                );

    
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