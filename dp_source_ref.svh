class dp_reference_model extends uvm_component;
    `uvm_component_utils(dp_reference_model)

    // Input and output analysis ports for connecting to the scoreboard
    uvm_analysis_imp #(dp_sink_sequence_item) sink_in_port;  // Receives transactions from dp_sink_monitor
    uvm_analysis_imp #(dp_tl_sequence_item) tl_in_port;      // Receives transactions from dp_tl_monitor
    uvm_analysis_port #(dp_transaction) ref_model_out_port; // Sends expected transactions to the scoreboard

    // Transaction variables for output of Reference model
    dp_transaction expected_transaction;

    // Variables for connection detection scenario
    bit HPD_Signal_prev = 0; // Previous state of HPD_Signal
    time HPD_high_start; // Time when HPD_Signal went high
    time HPD_low_start;  // Time when HPD_Signal went low

    // Constructor
    function new(string name, uvm_component parent);
        super.new(name, parent);
        sink_in_port = new("sink_in_port", this);
        tl_in_port = new("tl_in_port", this);
        ref_model_out_port = new("ref_model_out_port", this);
    endfunction

    // Build phase
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        `uvm_info(get_type_name(), "Reference model build_phase completed", UVM_LOW)
    endfunction

    // Main task to process transactions
    task run_phase(uvm_phase phase);
    dp_sink_sequence_item sink_item;
    dp_tl_sequence_item tl_item;

        phase.raise_objection(this); // Raise objection to keep the simulation running

        // current_state = IDLE; // Start in the IDLE state

        forever begin
            // Generate the expected transaction based on the received transaction
            expected_transaction = new();
            generate_expected_transaction(sink_item, tl_item, expected_transaction);
        end

        phase.drop_objection(this); // Drop objection when done
    endtask

    // Function to generate the expected transaction
    function void generate_expected_transaction(
    input dp_sink_sequence_item sink_item,  // Transaction from dp_sink_monitor
    input dp_tl_sequence_item tl_item,      // Transaction from dp_tl_monitor
    output dp_transaction expected_transaction // Generated expected transaction
    );

        // Connection Detection Scenario
        generate_connection_detection(sink_item, tl_item, expected_transaction);

        // // Link Training Scenario //

        // // I2C-over-AUX Transaction Scenario (EDID Read)
        // generate_i2c_over_aux_transaction(sink_item, tl_item, expected_transaction);

        // // Native AUX Transaction Scenario
        // generate_native_aux_transaction(sink_item, tl_item, expected_transaction);

        // // Link Training Flow
        // generate_link_training_flow(sink_item, tl_item, expected_transaction);
        
        // // End of link training flow

        // Log the generated expected transaction
        `uvm_info(get_type_name(), $sformatf("Generated expected transaction: %s", expected_transaction.convert2string()), UVM_LOW)
    endfunction
    

    // need to modify a bit
    // Function to handle the Connection Detection Scenario
    function void generate_connection_detection(
    input dp_sink_sequence_item sink_item,  // Transaction from dp_sink_monitor
    input dp_tl_sequence_item tl_item,      // Transaction from dp_tl_monitor
    output dp_transaction expected_transaction // Generated expected transaction
    );
        // Wait for the next transaction
        ref_model_in_port.get(sink_item);

        // Check if HPD_Signal just went high
        if (sink_item.HPD_Signal && !HPD_Signal_prev) begin
            HPD_high_start = $time;
        end else if (!sink_item.HPD_Signal && HPD_Signal_prev) begin
            // Check if HPD_Signal just went low
            HPD_low_start = $time;
        end
    
        // Check if HPD_Signal has been high for ≥2 ms
        if (sink_item.HPD_Signal && ($time - HPD_high_start) >= 2_000_000) begin
            expected_transaction.HPD_Detect = 1'b1; // Assert HPD_Detect

            // Start Link Training Flow
            generate_link_training_flow(sink_item, tl_item, expected_transaction);

        end else begin
            expected_transaction.HPD_Detect = 1'b0; // Deassert HPD_Detect
        end
    
        // Check if HPD_Signal went low for 0.5–1 ms and then returned high
        if (!sink_item.HPD_Signal && ($time - HPD_low_start) >= 500_000 && ($time - HPD_low_start) <= 1_000_000) begin
            if (HPD_Signal_prev) begin
                expected_transaction.HPD_IRQ = 1'b1; // Pulse HPD_IRQ for 1 clock cycle
            end
        end else begin
            expected_transaction.HPD_IRQ = 1'b0; // Deassert HPD_IRQ
        end
                
        // Update the previous state of HPD_Signal
        HPD_Signal_prev = sink_item.HPD_Signal;
    
        // Log the connection detection results
        `uvm_info(get_type_name(), $sformatf("Connection Detection: HPD_Detect=%0b, HPD_IRQ=%0b",
                                             expected_transaction.HPD_Detect,
                                             expected_transaction.HPD_IRQ), UVM_LOW);

        // Send the expected transaction to the scoreboard
        ref_model_out_port.write(expected_transaction);

        //Note to self: need to make this function run continuously

    endfunction



// Function to generate the expected transaction for I2C-over-AUX (EDID Read)
// ADD the timeout timer
    
    task generate_i2c_over_aux_transaction(
        input dp_sink_sequence_item sink_item,  // Transaction from dp_sink_monitor
        input dp_tl_sequence_item tl_item,      // Transaction from dp_tl_monitor
        output dp_transaction expected_transaction // Generated expected transaction
    );

        typedef enum logic [1:0] {
        IDLE,
        ADDRESS_ONLY_START,
        GET_NEW_DATA,
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
                // Raise the AUX_START_STOP signal
                expected_transaction.AUX_START_STOP = 1'b1;

                // Send the expected transaction to the scoreboard
                ref_model_out_port.write(expected_transaction);
                
                // Byte 2
                expected_transaction.aux_in_out = 8'b0000_0000;
                // Raise the AUX_START_STOP signal
                expected_transaction.AUX_START_STOP = 1'b1;

                // Send the expected transaction to the scoreboard
                ref_model_out_port.write(expected_transaction);
                
                // Byte 3
                expected_transaction.aux_in_out = address;
                // Raise the AUX_START_STOP signal
                expected_transaction.AUX_START_STOP = 1'b1; 
                
                // Send the expected transaction to the scoreboard
                ref_model_out_port.write(expected_transaction);

                // // Lower the AUX_START_STOP signal
                // expected_transaction.AUX_START_STOP = 1'b0; 
                
                // // Send the expected transaction to the scoreboard
                // ref_model_out_port.write(expected_transaction);

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

                    // // Wait for the next transaction
                    // ref_model_in_port.get(tl_item);

                    next_state = DATA; // Move to DATA state

                end
    
                DATA: begin

                // Assign the encoded value to aux_in_out
                // Encoded value: 0101|0000 -> 00000000 -> SPM_Address -> 00000000

                // Byte 1
                expected_transaction.aux_in_out = 8'b0101_0000;
                // Raise the AUX_START_STOP signal
                expected_transaction.AUX_START_STOP = 1'b1;

                // Send the expected transaction to the scoreboard
                ref_model_out_port.write(expected_transaction);
                
                // Byte 2
                expected_transaction.aux_in_out = 8'b0000_0000;
                // Raise the AUX_START_STOP signal
                expected_transaction.AUX_START_STOP = 1'b1;

                // Send the expected transaction to the scoreboard
                ref_model_out_port.write(expected_transaction);
                
                // Byte 3
                expected_transaction.aux_in_out = tl_item.SPM_Address;
                // Raise the AUX_START_STOP signal
                expected_transaction.AUX_START_STOP = 1'b1;
                
                // Send the expected transaction to the scoreboard
                ref_model_out_port.write(expected_transaction);

                // Byte 4
                expected_transaction.aux_in_out = 8'b0000_0000;
                // Raise the AUX_START_STOP signal
                expected_transaction.AUX_START_STOP = 1'b1;
                
                // Send the expected transaction to the scoreboard
                ref_model_out_port.write(expected_transaction);

                // // Lower the AUX_START_STOP signal
                // expected_transaction.AUX_START_STOP = 1'b0; 
                
                // // Send the expected transaction to the scoreboard
                // ref_model_out_port.write(expected_transaction);

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
                // Raise the AUX_START_STOP signal
                expected_transaction.AUX_START_STOP = 1'b1;

                // Send the expected transaction to the scoreboard
                ref_model_out_port.write(expected_transaction);
                
                // Byte 2
                expected_transaction.aux_in_out = 8'b0000_0000;
                // Raise the AUX_START_STOP signal
                expected_transaction.AUX_START_STOP = 1'b1;

                // Send the expected transaction to the scoreboard
                ref_model_out_port.write(expected_transaction);
                
                // Byte 3
                expected_transaction.aux_in_out = address;
                // Raise the AUX_START_STOP signal
                expected_transaction.AUX_START_STOP = 1'b1; 
                
                // Send the expected transaction to the scoreboard
                ref_model_out_port.write(expected_transaction);

                // // Lower the AUX_START_STOP signal
                // expected_transaction.AUX_START_STOP = 1'b0; 
                
                // // Send the expected transaction to the scoreboard
                // ref_model_out_port.write(expected_transaction);

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
                // // Wait for the next transaction
                // ref_model_in_port.get(tl_item);

                if (tl_item.LPM_Transaction_VLD) begin
                    command = (override_command != 4'b0000) ? override_command : tl_item.LPM_CMD;
                    address = (override_address != 20'h00000) ? override_address : tl_item.LPM_Address;
                    length = (override_length != 8'h00) ? override_length : tl_item.LPM_LEN;

                    expected_transaction.SPM_NATIVE_I2C = 1'b0; // Set SPM_NATIVE_I2C to 0 for Native AUX Transaction
                    expected_transaction.CTRL_Native_Failed = 1'b0; // Reset the failure flag

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
                // Raise the AUX_START_STOP signal
                expected_transaction.AUX_START_STOP = 1'b1;
                ;
                ref_model_out_port.write(expected_transaction);

                // Transmit the next two bytes of the address
                expected_transaction.aux_in_out = address[15:8];
                // Raise the AUX_START_STOP signal
                expected_transaction.AUX_START_STOP = 1'b1;

                ref_model_out_port.write(expected_transaction);

                expected_transaction.aux_in_out = address[7:0];
                // Raise the AUX_START_STOP signal
                expected_transaction.AUX_START_STOP = 1'b1;

                ref_model_out_port.write(expected_transaction);

                // Transmit the length byte
                expected_transaction.aux_in_out = length;
                // Raise the AUX_START_STOP signal
                expected_transaction.AUX_START_STOP = 1'b1;
                
                ref_model_out_port.write(expected_transaction);

                // // Lower the AUX_START_STOP signal
                // expected_transaction.AUX_START_STOP = 1'b0; 
                
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

                                // Send the expected transaction to the scoreboard
                                 ref_model_out_port.write(expected_transaction);

                                 break; // Exit the loop

                                // `uvm_info(get_type_name(), "Restarting from IDLE state after 8 DEFERs", UVM_LOW);
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
                // // Wait for the next transaction
                // ref_model_in_port.get(tl_item);

                if (tl_item.LPM_Transaction_VLD) begin
                    command = (override_command != 4'b0000) ? override_command : tl_item.LPM_CMD;
                    address = (override_address != 20'h00000) ? override_address : tl_item.LPM_Address;
                    length = (override_length != 8'h00) ? override_length : tl_item.LPM_LEN;
                    data = (override_data.size() > 0) ? override_data : {tl_item.LPM_Data};

                    expected_transaction.SPM_NATIVE_I2C = 1'b0; // Set SPM_NATIVE_I2C to 0 for Native AUX Transaction
                    expected_transaction.CTRL_Native_Failed = 1'b0; // Reset the failure flag

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
                // Raise the AUX_START_STOP signal
                expected_transaction.AUX_START_STOP = 1'b1
                ref_model_out_port.write(expected_transaction);

                expected_transaction.aux_in_out = address[15:8]; // Byte 2
                // Raise the AUX_START_STOP signal
                expected_transaction.AUX_START_STOP = 1'b1
                ref_model_out_port.write(expected_transaction);

                expected_transaction.aux_in_out = address[7:0]; // Byte 3
                // Raise the AUX_START_STOP signal
                expected_transaction.AUX_START_STOP = 1'b1
                ref_model_out_port.write(expected_transaction);

                expected_transaction.aux_in_out = length; // Byte 4
                // Raise the AUX_START_STOP signal
                expected_transaction.AUX_START_STOP = 1'b1
                ref_model_out_port.write(expected_transaction);

                // Transmit data bytes
                for (int i = 0; i < length; i++) begin
                    expected_transaction.aux_in_out = data[i];
                    ref_model_out_port.write(expected_transaction);
                    // Raise the AUX_START_STOP signal
                    expected_transaction.AUX_START_STOP = 1'b1
                end

                // // Lower the AUX_START_STOP signal
                // expected_transaction.AUX_START_STOP = 1'b0; 
                
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
                // Raise the AUX_START_STOP signal
                expected_transaction.AUX_START_STOP = 1'b1
                ref_model_out_port.write(expected_transaction);

                expected_transaction.aux_in_out = address[15:8]; // Byte 2
                // Raise the AUX_START_STOP signal
                expected_transaction.AUX_START_STOP = 1'b1
                ref_model_out_port.write(expected_transaction);

                expected_transaction.aux_in_out = address[7:0]; // Byte 3
                // Raise the AUX_START_STOP signal
                expected_transaction.AUX_START_STOP = 1'b1
                ref_model_out_port.write(expected_transaction);

                expected_transaction.aux_in_out = (length - success_counter); // Byte 4
                // Raise the AUX_START_STOP signal
                expected_transaction.AUX_START_STOP = 1'b1
                ref_model_out_port.write(expected_transaction);

                // Transmit data bytes
                for (int i = success_counter; i <= length; i++) begin
                    expected_transaction.aux_in_out = data[i];
                    // Raise the AUX_START_STOP signal
                    expected_transaction.AUX_START_STOP = 1'b1
                    ref_model_out_port.write(expected_transaction);
                end

                // // Lower the AUX_START_STOP signal
                // expected_transaction.AUX_START_STOP = 1'b0; 
                
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
                break; // Exit the loop
            end

            default: begin
                next_state = IDLE_MODE;
            end
        endcase

        // Update the current state
        current_state = next_state;

    end
endtask

function bit generate_clock_recovery_phase(
    input dp_sink_sequence_item sink_item,  // Transaction from dp_sink_monitor
    input dp_tl_sequence_item tl_item,      // Transaction from dp_tl_monitor
    output dp_transaction expected_transaction // Generated expected transaction
);
    
    // State machine for the clock recovery phase
    // Define the states for the FSM
    typedef enum logic [3:0] { // Updated to [3:0] to accommodate more states
        IDLE,
        IDLE_WITH_UPDATED_BW_OR_LC,
        WRITE_LINK_CONFIG,
        ENABLE_TRAINING_PATTERN,
        CONFIGURE_DRIVING_SETTINGS,
        READ_TRAINING_INTERVAL,
        WAIT_AND_READ_LINK_STATUS,
        CR_DONE_CHECK,
        READ_ADJUSTED_DRIVING_PARAMETERS,
        CHECK_NEW_CONDITIONS,
        CHECK_IF_RBR,
        CHECK_IF_ONE_LANE_USED,
        REDUCE_LANE_COUNT,
        REDUCE_LINK_RATE,
        FAILURE,
        SUCCESS
    } fsm_state_e;

    bit CR_DONE = 0;
    fsm_state_e current_state, next_state;
    int ack_count = 0;  //Ack counter
    bit [1:0]  MAX_VTG_temp, MAX_PRE_temp; // Temporary variables for max values
    bit [3:0]  full_loop_counter = 4'b0000;
    bit [3:0]  same_parameters_repeated_counter = 4'b0000;
    bit [3:0]  CURRENT_LANE_COUNT = 2'b00; // Current lane count
    bit [7:0]  CURRENT_LINK_RATE = 8'h00; // Current link rate
    bit [7:0]  CURRENT_PRE;// Temporary variable for current PRE value
    bit [7:0]  CURRENT_VTG; // Temporary variable for current VTG value
    bit [7:0]  PREVIOUS_PRE;// Temporary variable for previous PRE value
    bit [7:0]  PREVIOUS_VTG; // Temporary variable for previous VTG value
    bit [7:0]  MAX_VTG_temp_Concatenated; // Concatenated max values

    // Initialize the FSM
    current_state = IDLE;

    forever begin
        case (current_state)
            IDLE: begin
                // Wait for the next transaction
                ref_model_in_port.get(tl_item); //Lpm_seq_item

                // Store the important values
                MAX_VTG_temp = tl_item.MAX_VTG;
                MAX_PRE_temp = tl_item.MAX_PRE;
                CURRENT_LANE_COUNT = tl_item.Link_LC_CR;
                CURRENT_LINK_RATE = tl_item.Link_BW_CR;
                CURRENT_PRE = tl_item.PRE;
                CURRENT_VTG = tl_item.VTG;

                if (tl_item.LPM_Start_CR && tl_item.Driving_Param_VLD && tl_item.Config_Param_VLD)
                // Start the clock recovery process
                `uvm_info(get_type_name(), "Starting Clock Recovery Phase", UVM_LOW);
                next_state = WRITE_LINK_CONFIG;
                else begin
                    next_state = IDLE; // Stay in IDLE if not valid
                end
            end

            IDLE_WITH_UPDATED_BW_OR_LC: begin
                // // Wait for the next transaction
                // ref_model_in_port.get(tl_item); //Lpm_seq_item

                // // Store the important values
                // MAX_VTG_temp = tl_item.MAX_VTG;
                // MAX_PRE_temp = tl_item.MAX_PRE;
                // CURRENT_LANE_COUNT = tl_item.Link_LC_CR;
                // CURRENT_LINK_RATE = tl_item.Link_BW_CR;
                // CURRENT_PRE = tl_item.PRE;
                // CURRENT_VTG = tl_item.VTG;

                if (tl_item.LPM_Start_CR && tl_item.Driving_Param_VLD && tl_item.Config_Param_VLD)
                // Start the clock recovery process
                `uvm_info(get_type_name(), "Repeating Clock Recovery Phase with Updated Parameters", UVM_LOW);
                next_state = WRITE_LINK_CONFIG;
                else begin
                    next_state = IDLE_WITH_UPDATED_BW_OR_LC; // Stay in IDLE if not valid
                end
            end

            WRITE_LINK_CONFIG: begin
                // Step 1: Write to the Link Configuration field
                `uvm_info(get_type_name(), "Writing to Link Configuration field", UVM_LOW);
                
                generate_native_aux_write_transaction(
                    sink_item,       // Input transaction from sink
                    tl_item,         // Input transaction from tl
                    expected_transaction,       // Output transaction
                    4'b1000,                    // Override command (AUX_NATIVE_WRITE)
                    20'h00100,                  // Override address (0x00100)
                    8'h02,                      // Override length (3 byte(s))
                    '{CURRENT_LINK_RATE, {3'b100, 5'(CURRENT_LANE_COUNT + 5'b01)}, 8'h00} // Override data
                );
                
                if (expected_transaction.CTRL_Native_Failed = 1'b1) begin
                    // If the transaction failed, move to the FAILURE state
                    `uvm_error(get_type_name(), "Failed to write to Link Configuration field", UVM_LOW);
                    next_state = IDLE; // Move to IDLE state
                end else begin
                    // If the transaction was successful, move to the next state
                    next_state = ENABLE_TRAINING_PATTERN;
                end

            end

            
            // need manual implementation of the function to generate the expected transaction for training pattern
            ENABLE_TRAINING_PATTERN: begin
                // Step 2: Enable Training Pattern 1 and disable scrambling
                `uvm_info(get_type_name(), "Enabling Training Pattern 1 and disabling scrambling", UVM_LOW);

                expected_transaction.PHY_Instruct = 2'b00; // Training pattern 1
                expected_transaction.PHY_Instruct_VLD = 1'b1; // Set PHY_Instruct_VLD to 1
                expected_transaction.PHY_ADJ_BW = CURRENT_LINK_RATE; // Set PHY_ADJ_BW to the current link rate
                expected_transaction.PHY_ADJ_LC = CURRENT_LANE_COUNT; // Set PHY_ADJ_LC to the current lane count

                generate_native_aux_write_transaction(
                    sink_item,       // Input transaction from sink
                    tl_item,         // Input transaction from tl
                    expected_transaction,       // Output transaction
                    4'b1000,                    // Override command (AUX_NATIVE_WRITE)
                    20'h00102,                  // Override address (0x00102)
                    8'h00,                      // Override length (1 byte)
                    8'h21                      // Override data
                );

                expected_transaction.PHY_Instruct_VLD = 1'b0; // Set PHY_Instruct_VLD to 0

                if (expected_transaction.CTRL_Native_Failed = 1'b1) begin
                    // If the transaction failed, move to the FAILURE state
                    `uvm_error(get_type_name(), "Failed to enable Training Pattern 1", UVM_LOW);
                    next_state = IDLE; // Move to IDLE state
                end else begin
                    // If the transaction was successful, move to the next state
                    next_state = CONFIGURE_DRIVING_SETTINGS;
                end

            end

            // add if conditions
                 CONFIGURE_DRIVING_SETTINGS: begin
                // Step 3: Configure initial driving settings
                `uvm_info(get_type_name(), "Configuring initial driving settings", UVM_LOW);
            
                if (tl_item.Link_LC_CR == 2'b00) begin
                    // Configure Lane 0
                    generate_native_aux_write_transaction(
                        sink_item,       // Input transaction from sink
                        tl_item,         // Input transaction from tl
                        expected_transaction,       // Output transaction
                        4'b1000,                    // Override command (AUX_NATIVE_WRITE)
                        20'h00103,                  // Override address (0x00103)
                        8'h00,                      // Override length (1 byte)
                        '{(CURRENT_VTG[1:0] == MAX_VTG_temp && CURRENT_PRE[1:0] == MAX_PRE_temp) ? {2'b00, 1'b1, CURRENT_PRE[1:0], 1'b1, CURRENT_VTG[1:0]} :
                          (CURRENT_VTG[1:0] == MAX_VTG_temp) ? {2'b00, 1'b0, CURRENT_PRE[1:0], 1'b1, CURRENT_VTG[1:0]} :
                          (CURRENT_PRE[1:0] == MAX_PRE_temp) ? {2'b00, 1'b1, CURRENT_PRE[1:0], 1'b0, CURRENT_VTG[1:0]} :
                          {2'b00, 1'b0, CURRENT_PRE[1:0], 1'b0, CURRENT_VTG[1:0]}} // Override data
                    );
                end else if (tl_item.Link_LC_CR == 2'b01) begin
                    // Configure Lanes 0 and 1
                    generate_native_aux_write_transaction(
                        sink_item,       // Input transaction from sink
                        tl_item,         // Input transaction from tl
                        expected_transaction,       // Output transaction
                        4'b1000,                    // Override command (AUX_NATIVE_WRITE)
                        20'h00103,                  // Override address (0x00103)
                        8'h01,                      // Override length (2 bytes)
                        '{(CURRENT_VTG[1:0] == MAX_VTG_temp && CURRENT_PRE[1:0] == MAX_PRE_temp) ? {2'b00, 1'b1, CURRENT_PRE[1:0], 1'b1, CURRENT_VTG[1:0]} :
                          (CURRENT_VTG[1:0] == MAX_VTG_temp) ? {2'b00, 1'b0, CURRENT_PRE[1:0], 1'b1, CURRENT_VTG[1:0]} :
                          (CURRENT_PRE[1:0] == MAX_PRE_temp) ? {2'b00, 1'b1, CURRENT_PRE[1:0], 1'b0, CURRENT_VTG[1:0]} :
                          {2'b00, 1'b0, CURRENT_PRE[1:0], 1'b0, CURRENT_VTG[1:0]},
                          (CURRENT_VTG[3:2] == MAX_VTG_temp && CURRENT_PRE[3:2] == MAX_PRE_temp) ? {2'b00, 1'b1, CURRENT_PRE[3:2], 1'b1, CURRENT_VTG[3:2]} :
                          (CURRENT_VTG[3:2] == MAX_VTG_temp) ? {2'b00, 1'b0, CURRENT_PRE[3:2], 1'b1, CURRENT_VTG[3:2]} :
                          (CURRENT_PRE[3:2] == MAX_PRE_temp) ? {2'b00, 1'b1, CURRENT_PRE[3:2], 1'b0, CURRENT_VTG[3:2]} :
                          {2'b00, 1'b0, CURRENT_PRE[3:2], 1'b0, CURRENT_VTG[3:2]}} // Override data
                    );
                end else begin
                    // Configure Lanes 0, 1, 2, and 3
                    generate_native_aux_write_transaction(
                        sink_item,       // Input transaction from sink
                        tl_item,         // Input transaction from tl
                        expected_transaction,       // Output transaction
                        4'b1000,                    // Override command (AUX_NATIVE_WRITE)
                        20'h00103,                  // Override address (0x00103)
                        8'h03,                      // Override length (4 bytes)
                        '{(CURRENT_VTG[1:0] == MAX_VTG_temp && CURRENT_PRE[1:0] == MAX_PRE_temp) ? {2'b00, 1'b1, CURRENT_PRE[1:0], 1'b1, CURRENT_VTG[1:0]} :
                          (CURRENT_VTG[1:0] == MAX_VTG_temp) ? {2'b00, 1'b0, CURRENT_PRE[1:0], 1'b1, CURRENT_VTG[1:0]} :
                          (CURRENT_PRE[1:0] == MAX_PRE_temp) ? {2'b00, 1'b1, CURRENT_PRE[1:0], 1'b0, CURRENT_VTG[1:0]} :
                          {2'b00, 1'b0, CURRENT_PRE[1:0], 1'b0, CURRENT_VTG[1:0]},
                          (CURRENT_VTG[3:2] == MAX_VTG_temp && CURRENT_PRE[3:2] == MAX_PRE_temp) ? {2'b00, 1'b1, CURRENT_PRE[3:2], 1'b1, CURRENT_VTG[3:2]} :
                          (CURRENT_VTG[3:2] == MAX_VTG_temp) ? {2'b00, 1'b0, CURRENT_PRE[3:2], 1'b1, CURRENT_VTG[3:2]} :
                          (CURRENT_PRE[3:2] == MAX_PRE_temp) ? {2'b00, 1'b1, CURRENT_PRE[3:2], 1'b0, CURRENT_VTG[3:2]} :
                          {2'b00, 1'b0, CURRENT_PRE[3:2], 1'b0, CURRENT_VTG[3:2]},
                          (CURRENT_VTG[5:4] == MAX_VTG_temp && CURRENT_PRE[5:4] == MAX_PRE_temp) ? {2'b00, 1'b1, CURRENT_PRE[5:4], 1'b1, CURRENT_VTG[5:4]} :
                          (CURRENT_VTG[5:4] == MAX_VTG_temp) ? {2'b00, 1'b0, CURRENT_PRE[5:4], 1'b1, CURRENT_VTG[5:4]} :
                          (CURRENT_PRE[5:4] == MAX_PRE_temp) ? {2'b00, 1'b1, CURRENT_PRE[5:4], 1'b0, CURRENT_VTG[5:4]} :
                          {2'b00, 1'b0, CURRENT_PRE[5:4], 1'b0, CURRENT_VTG[5:4]},
                          (CURRENT_VTG[7:6] == MAX_VTG_temp && CURRENT_PRE[7:6] == MAX_PRE_temp) ? {2'b00, 1'b1, CURRENT_PRE[7:6], 1'b1, CURRENT_VTG[7:6]} :
                          (CURRENT_VTG[7:6] == MAX_VTG_temp) ? {2'b00, 1'b0, CURRENT_PRE[7:6], 1'b1, CURRENT_VTG[7:6]} :
                          (CURRENT_PRE[7:6] == MAX_PRE_temp) ? {2'b00, 1'b1, CURRENT_PRE[7:6], 1'b0, CURRENT_VTG[7:6]} :
                          {2'b00, 1'b0, CURRENT_PRE[7:6], 1'b0, CURRENT_VTG[7:6]}} // Override data
                    );
                end

                if (expected_transaction.CTRL_Native_Failed = 1'b1) begin
                    // If the transaction failed, move to the FAILURE state
                    `uvm_error(get_type_name(), "Failed to configure initial driving settings", UVM_LOW);
                    next_state = IDLE; // Move to IDLE state
                end else begin
                    // If the transaction was successful, move to the next state
                    next_state = READ_TRAINING_INTERVAL;
                end

            end

            READ_TRAINING_INTERVAL: begin
                // Step 4: Read TRAINING_AUX_RD_INTERVAL
                `uvm_info(get_type_name(), "Reading TRAINING_AUX_RD_INTERVAL", UVM_LOW);
                generate_native_aux_read_transaction(
                    sink_item,       // Input transaction from sink
                    tl_item,         // Input transaction from tl
                    expected_transaction,       // Output transaction
                    4'b1001,                    // Override command (AUX_NATIVE_READ)
                    20'h0000E,                  // Override address (0x0000E)
                    8'h00                       // Override length (1 byte)
                );

                if (expected_transaction.CTRL_Native_Failed = 1'b1) begin
                    // If the transaction failed, move to the FAILURE state
                    `uvm_error(get_type_name(), "Failed to read TRAINING_AUX_RD_INTERVAL", UVM_LOW);
                    next_state = IDLE; // Move to IDLE state
                end else begin
                    // If the transaction was successful, move to the next state
                    next_state = WAIT_AND_READ_LINK_STATUS;
                end

            end

            WAIT_AND_READ_LINK_STATUS: begin
       
    //     constraint eq_rd_value_constraint {
    //     EQ_RD_Value[7] == 1'b1; // Ensure the MSB is always 1
    //     EQ_RD_Value[6:0] inside {7'h00, 7'h01, 7'h02, 7'h03, 7'h04}; // Allowed values for the lower 7 bits
    //     page 629 in reference

                // Step 5: Wait for the interval and read Link Status registers
                ref_model_in_port.get(tl_item); //Lpm_seq_item
                // Wait EQ_RD_Value
                `uvm_info(get_type_name(), "Waiting for TRAINING_AUX_RD_INTERVAL and reading Link Status registers", UVM_LOW);
                generate_native_aux_read_transaction(
                    sink_item,       // Input transaction from sink
                    tl_item,         // Input transaction from tl
                    expected_transaction,       // Output transaction
                    4'b1001,                    // Override command (AUX_NATIVE_READ)
                    20'h00202,                  // Override address (0x00202)
                    8'h05                       // Override length (6 byte(s))
                );

                if (expected_transaction.CTRL_Native_Failed = 1'b1) begin
                    // If the transaction failed, move to the FAILURE state
                    `uvm_error(get_type_name(), "Failed to read Link Status registers", UVM_LOW);
                    next_state = IDLE; // Move to IDLE state
                end else begin
                    // If the transaction was successful, move to the next state
                    next_state = CR_DONE_CHECK;
                end

            end
            
            // Need to maybe store Link_LC_CR in a temp variable
            // Step 6: Check for CR_DONE and CR_DONE_VLD
            CR_DONE_CHECK: begin
            
            // same_parameters_repeated_counter = same_parameters_repeated_counter + 1;

            // Wait for the next transaction
            ref_model_in_port.get(tl_item); //Lpm_seq_item

		    if((CURRENT_LANE_COUNT == 'b11) && (&tl_item.CR_DONE))
             begin
              next_state = SUCCESS;			
             end
            else if((CURRENT_LANE_COUNT == 'b01) && (&tl_item.CR_DONE[1:0]))
             begin
              next_state = SUCCESS;			
             end
            else if((CURRENT_LANE_COUNT == 'b00) && (tl_item.CR_DONE[0]))
             begin
              next_state = SUCCESS;			
             end
            else if(CURRENT_LANE_COUNT == 'b10)   // Error Value of LC so it goes to the IDLE STATE 
             begin
              next_state = IDLE;			
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
                    sink_item,       // Input transaction from sink
                    tl_item,         // Input transaction from tl
                    expected_transaction,       // Output transaction
                    4'b1001,                    // Override command (AUX_NATIVE_READ)
                    20'h00206,                  // Override address (0x00202)
                    8'h01                       // Override length (2 byte(s))
                );
                
                // Update Current_VTG and Current_PRE based on the read values
                PREVIOUS_VTG == CURRENT_VTG
                PREVIOUS_PRE == CURRENT_PRE
                CURRENT_VTG = tl_item.VTG;
                CURRENT_PRE = tl_item.PRE;

                if (expected_transaction.CTRL_Native_Failed = 1'b1) begin
                    // If the transaction failed, move to the FAILURE state
                    `uvm_error(get_type_name(), "Failed to read Adjusted Training Parameters", UVM_LOW);
                    next_state = IDLE; // Move to IDLE state
                end else begin
                    // If the transaction was successful, move to the next state
                    next_state = CHECK_NEW_CONDITIONS;
                end

            end
        // Conditions: 1. MAX_VTG = VTG 2. full_loop_counter > 10 3. same_parameters_repeated_counter > 5
            CHECK_NEW_CONDITIONS: begin
          
          full_loop_counter = full_loop_counter + 1'b1;
          
          if ((CURRENT_VTG == PREVIOUS_VTG) && (CURRENT_PRE == PREVIOUS_PRE)) begin
            same_parameters_repeated_counter = same_parameters_repeated_counter + 1'b1;
          end

           // Concatenate MAX_VTG_temp for 4 lanes

          MAX_VTG_temp_Concatenated = {MAX_VTG_temp, MAX_VTG_temp, MAX_VTG_temp, MAX_VTG_temp};	  // For 4 Lanes
            
           if (CURRENT_LANE_COUNT == 2'b11) begin
           if ((full_loop_counter == 'd11) || (same_parameters_repeated_counter == 'd6) || (CURRENT_VTG == MAX_VTG_temp_Concatenated))
            begin
             next_state = CHECK_IF_RBR;
            end
           else
            begin
             next_state = CONFIGURE_DRIVING_SETTINGS; // Repeat from step 3
            end
            end
            else if (CURRENT_LANE_COUNT == 2'b01) begin
            if ((full_loop_counter == 'd11) || (same_parameters_repeated_counter == 'd6) || (CURRENT_VTG[3:0] == MAX_VTG_temp_Concatenated[3:0]))
            begin
             next_state = CHECK_IF_RBR;
            end
           else
            begin
             next_state = CONFIGURE_DRIVING_SETTINGS; // Repeat from step 3
            end
            end
            else begin
            if ((full_loop_counter == 'd11) || (same_parameters_repeated_counter == 'd6) || (CURRENT_VTG[1:0] == MAX_VTG_temp_Concatenated[1:0]))
            begin
             next_state = CHECK_IF_RBR;
            end
           else
            begin
             next_state = CONFIGURE_DRIVING_SETTINGS; // Repeat from step 3
            end
            end
                
            end

            // Check if RBR is used
            CHECK_IF_RBR: begin

           if (CURRENT_LINK_RATE == == 8'h06) // is Bandwidth used RBR?
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
             CURRENT_LANE_COUNT = 2'b00;
            end  
            next_state = IDLE_WITH_UPDATED_BW_OR_LC; // Reset to IDLE for the next phase  
            end

            // Reduce Link Rate
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
                // break;      
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

        // add a value to retry CR
        // Function to generate the expected transaction for channel equalization phase
        function bit generate_channel_equalization_phase(
        input dp_sink_sequence_item sink_item,  // Transaction from dp_sink_monitor
        input dp_tl_sequence_item tl_item,      // Transaction from dp_tl_monitor
        output dp_transaction expected_transaction,
        input bit [3:0]  NEW_LANE_COUNT = 2'b00; // Current lane count
        input bit [7:0]  NEW_LINK_RATE = 8'h00; // Current link rate
        input bit [7:0]  NEW_VTG = 8'h00;, // Temporary variable for max values
        input bit [7:0]  NEW_PRE = 8'h00 // Temporary variable for max values
        input bit [1:0]  MAX_VTG_temp = 2'b00; // Temporary variable for max values
        input bit [1:0]  MAX_PRE_temp = 2'b00; // Temporary variable for max values
    );
    
        // State machine for the channel equalization phase
        typedef enum logic [4:0] { // Updated to [4:0] to accommodate more states
            IDLE,
            ENABLE_TRAINING_PATTERN_SEQUENCE,
            READ_TRAINING_INTERVAL,
            WAIT_AND_READ_LINK_STATUS,
            CHECK_CR,                        // Added state to check CR_DONE
            CHECK_EQUALIZATION,              // Added state to check equalization parameters
            WRITE_ADJUSTED_DRIVING_PARAMETERS, // Added state to write adjusted driving parameters
            CHECK_IF_RBR,                    // Added state to check if RBR is used
            CHECK_IF_ONE_LANE_USED,          // Added state to check if one lane is used
            REDUCE_LANE_COUNT,
            REDUCE_LINK_RATE,
            FAILURE,
            SUCCESS
        } fsm_state_e;
    
        bit EQ_DONE = 0;
        fsm_state_e current_state, next_state;
        int ack_count = 0;  // Ack counter
        bit [3:0] retry_counter = 4'b0000;  // Retry counter for Sequence 2
        bit [3:0] CURRENT_LANE_COUNT = NEW_LANE_COUNT; // Current lane count
        bit [7:0] CURRENT_LINK_RATE = NEW_LINK_RATE; // Current link rate
        bit [7:0] CURRENT_PRE = NEW_PRE;// Temporary variable for VTG and PRE values
        bit [7:0] CURRENT_VTG = NEW_VTG; // Temporary variable for VTG and PRE values
        bit [1:0] MAX_TPS_SUPPORTED_STORED = 2'b00; // Temporary variable for max values
        int Loop_Counter = 0; // Loop counter for retrying the sequence
        int Max_Loop_Counter = 0; // Maximum loop count for retrying the sequence
    
        // Initialize the FSM
        current_state = IDLE;
    
        forever begin
            case (current_state)
                IDLE: begin
                    // Wait for the next transaction
                    ref_model_in_port.get(tl_item);
    
                    // Store the important values
                    MAX_TPS_SUPPORTED_STORED = tl_item.MAX_TPS_SUPPORTED;
    
                    if (tl_item.LPM_Start_CR && tl_item.Driving_Param_VLD && tl_item.Config_Param_VLD) begin
                        `uvm_info(get_type_name(), "Starting Channel Equalization Phase", UVM_LOW);
                        next_state = ENABLE_TRAINING_PATTERN_SEQUENCE;
                    end else begin
                        next_state = IDLE; // Stay in IDLE if not valid
                    end
                end
    
                ENABLE_TRAINING_PATTERN_SEQUENCE: begin
                    // Step 1: Enable Training Pattern (Depending on MAX TPS supported) and disable scrambling
                    `uvm_info(get_type_name(), "Enabling Training Pattern and disabling scrambling", UVM_LOW);

                    // signals sent to phy layer to transmit TPS
                    if (CURRENT_LANE_COUNT == 2'b00) begin
                        // Configure Lane 0
                        generate_native_aux_write_transaction(
                            sink_item,       // Input transaction from sink
                            tl_item,         // Input transaction from tl
                            expected_transaction,       // Output transaction
                            4'b1000,                    // Override command (AUX_NATIVE_WRITE)
                            20'h00102,                  // Override address (0x00102)
                            8'h01,                      // Override length (2 byte)
                            '{(MAX_TPS_SUPPORTED == 2'b01) ? 8'h22 : 
                              (MAX_TPS_SUPPORTED == 2'b10) ? 8'h23 : 
                              (MAX_TPS_SUPPORTED == 2'b11) ? 8'h07 : 8'h00, // TPS value based on MAX_TPS_SUPPORTED
                              (tl_item.VTG[1:0] == MAX_VTG_temp && tl_item.PRE[1:0] == MAX_PRE_temp) ? {2'b00, 1'b1, tl_item.PRE[1:0], 1'b1, tl_item.VTG[1:0]} :
                              (tl_item.VTG[1:0] == MAX_VTG_temp) ? {2'b00, 1'b0, tl_item.PRE[1:0], 1'b1, tl_item.VTG[1:0]} :
                              (tl_item.PRE[1:0] == MAX_PRE_temp) ? {2'b00, 1'b1, tl_item.PRE[1:0], 1'b0, tl_item.VTG[1:0]} :
                              {2'b00, 1'b0, tl_item.PRE[1:0], 1'b0, tl_item.VTG[1:0]}} // Override data
                        );
                    end else if (CURRENT_LANE_COUNT == 2'b01) begin
                        // Configure Lanes 0 and 1
                        generate_native_aux_write_transaction(
                            sink_item,       // Input transaction from sink
                            tl_item,         // Input transaction from tl
                            expected_transaction,       // Output transaction
                            4'b1000,                    // Override command (AUX_NATIVE_WRITE)
                            20'h00102,                  // Override address (0x00102)
                            8'h02,                      // Override length (3 bytes)
                            '{(MAX_TPS_SUPPORTED == 2'b01) ? 8'h22 : 
                              (MAX_TPS_SUPPORTED == 2'b10) ? 8'h23 : 
                              (MAX_TPS_SUPPORTED == 2'b11) ? 8'h07 : 8'h00, // TPS value based on MAX_TPS_SUPPORTED
                              (tl_item.VTG[1:0] == MAX_VTG_temp && tl_item.PRE[1:0] == MAX_PRE_temp) ? {2'b00, 1'b1, tl_item.PRE[1:0], 1'b1, tl_item.VTG[1:0]} :
                              (tl_item.VTG[1:0] == MAX_VTG_temp) ? {2'b00, 1'b0, tl_item.PRE[1:0], 1'b1, tl_item.VTG[1:0]} :
                              (tl_item.PRE[1:0] == MAX_PRE_temp) ? {2'b00, 1'b1, tl_item.PRE[1:0], 1'b0, tl_item.VTG[1:0]} :
                              {2'b00, 1'b0, tl_item.PRE[1:0], 1'b0, tl_item.VTG[1:0]},
                              (tl_item.VTG[3:2] == MAX_VTG_temp && tl_item.PRE[3:2] == MAX_PRE_temp) ? {2'b00, 1'b1, tl_item.PRE[3:2], 1'b1, tl_item.VTG[3:2]} :
                              (tl_item.VTG[3:2] == MAX_VTG_temp) ? {2'b00, 1'b0, tl_item.PRE[3:2], 1'b1, tl_item.VTG[3:2]} :
                              (tl_item.PRE[3:2] == MAX_PRE_temp) ? {2'b00, 1'b1, tl_item.PRE[3:2], 1'b0, tl_item.VTG[3:2]} :
                              {2'b00, 1'b0, tl_item.PRE[3:2], 1'b0, tl_item.VTG[3:2]}} // Override data
                        );
                    end else begin
                        // Configure Lanes 0, 1, 2, and 3
                        generate_native_aux_write_transaction(
                            sink_item,       // Input transaction from sink
                            tl_item,         // Input transaction from tl
                            expected_transaction,       // Output transaction
                            4'b1000,                    // Override command (AUX_NATIVE_WRITE)
                            20'h00102,                  // Override address (0x00102)
                            8'h04,                      // Override length (5 bytes)
                            '{(MAX_TPS_SUPPORTED == 2'b01) ? 8'h22 : 
                              (MAX_TPS_SUPPORTED == 2'b10) ? 8'h23 : 
                              (MAX_TPS_SUPPORTED == 2'b11) ? 8'h07 : 8'h00, // TPS value based on MAX_TPS_SUPPORTED
                              (tl_item.VTG[1:0] == MAX_VTG_temp && tl_item.PRE[1:0] == MAX_PRE_temp) ? {2'b00, 1'b1, tl_item.PRE[1:0], 1'b1, tl_item.VTG[1:0]} :
                              (tl_item.VTG[1:0] == MAX_VTG_temp) ? {2'b00, 1'b0, tl_item.PRE[1:0], 1'b1, tl_item.VTG[1:0]} :
                              (tl_item.PRE[1:0] == MAX_PRE_temp) ? {2'b00, 1'b1, tl_item.PRE[1:0], 1'b0, tl_item.VTG[1:0]} :
                              {2'b00, 1'b0, tl_item.PRE[1:0], 1'b0, tl_item.VTG[1:0]},
                              (tl_item.VTG[3:2] == MAX_VTG_temp && tl_item.PRE[3:2] == MAX_PRE_temp) ? {2'b00, 1'b1, tl_item.PRE[3:2], 1'b1, tl_item.VTG[3:2]} :
                              (tl_item.VTG[3:2] == MAX_VTG_temp) ? {2'b00, 1'b0, tl_item.PRE[3:2], 1'b1, tl_item.VTG[3:2]} :
                              (tl_item.PRE[3:2] == MAX_PRE_temp) ? {2'b00, 1'b1, tl_item.PRE[3:2], 1'b0, tl_item.VTG[3:2]} :
                              {2'b00, 1'b0, tl_item.PRE[3:2], 1'b0, tl_item.VTG[3:2]},
                              (tl_item.VTG[5:4] == MAX_VTG_temp && tl_item.PRE[5:4] == MAX_PRE_temp) ? {2'b00, 1'b1, tl_item.PRE[5:4], 1'b1, tl_item.VTG[5:4]} :
                              (tl_item.VTG[5:4] == MAX_VTG_temp) ? {2'b00, 1'b0, tl_item.PRE[5:4], 1'b1, tl_item.VTG[5:4]} :
                              (tl_item.PRE[5:4] == MAX_PRE_temp) ? {2'b00, 1'b1, tl_item.PRE[5:4], 1'b0, tl_item.VTG[5:4]} :
                              {2'b00, 1'b0, tl_item.PRE[5:4], 1'b0, tl_item.VTG[5:4]},
                              (tl_item.VTG[7:6] == MAX_VTG_temp && tl_item.PRE[7:6] == MAX_PRE_temp) ? {2'b00, 1'b1, tl_item.PRE[7:6], 1'b1, tl_item.VTG[7:6]} :
                              (tl_item.VTG[7:6] == MAX_VTG_temp) ? {2'b00, 1'b0, tl_item.PRE[7:6], 1'b1, tl_item.VTG[7:6]} :
                              (tl_item.PRE[7:6] == MAX_PRE_temp) ? {2'b00, 1'b1, tl_item.PRE[7:6], 1'b0, tl_item.VTG[7:6]} :
                              {2'b00, 1'b0, tl_item.PRE[7:6], 1'b0, tl_item.VTG[7:6]}} // Override data
                        );
                    end
    
                    next_state = READ_TRAINING_INTERVAL;
                end
    
                READ_TRAINING_INTERVAL: begin
                    // Step 2: Read TRAINING_AUX_RD_INTERVAL
                    `uvm_info(get_type_name(), "Reading TRAINING_AUX_RD_INTERVAL", UVM_LOW);
    
                    generate_native_aux_read_transaction(
                        sink_item,       // Input transaction from sink
                        tl_item,         // Input transaction from tl
                        expected_transaction,       // Output transaction
                        4'b1001,                    // Override command (AUX_NATIVE_READ)
                        20'h0000E,                  // Override address (0x0000E)
                        8'h00                       // Override length (1 byte)
                    );
    
                    next_state = WAIT_AND_READ_LINK_STATUS;
                end
                
                //     constraint eq_rd_value_constraint {
                //     EQ_RD_Value[7] == 1'b1; // Ensure the MSB is always 1
                //     EQ_RD_Value[6:0] inside {7'h00, 7'h01, 7'h02, 7'h03, 7'h04}; // Allowed values for the lower 7 bits

                WAIT_AND_READ_LINK_STATUS: begin
                    // Step 3: Wait for the interval and read Link Status registers
                    `uvm_info(get_type_name(), "Waiting for TRAINING_AUX_RD_INTERVAL and reading Link Status registers", UVM_LOW);
                    ref_model_in_port.get(tl_item); //Lpm_seq_item
                    // Wait EQ_RD_Value

                    // read Link Status registers (0X00202) TO (OX00207)
                    generate_native_aux_read_transaction(
                        sink_item,       // Input transaction from sink
                        tl_item,         // Input transaction from tl
                        expected_transaction,       // Output transaction
                        4'b1001,                    // Override command (AUX_NATIVE_READ)
                        20'h00202,                  // Override address (0x00202)
                        8'h05                       // Override length (6 bytes)
                    );
    
                    next_state = CHECK_CR;
                end
    
                CHECK_CR: begin
                // Step 4: Check CR_DONE
                `uvm_info(get_type_name(), "Checking CR parameters", UVM_LOW);

                    // Wait for the next transaction
                    ref_model_in_port.get(tl_item); //Lpm_seq_item   

		           if((CURRENT_LANE_COUNT == 'b11) && (&tl_item.CR_DONE))
                   begin
                    next_state = CHECK_EQUALIZATION;			
                   end
                   else if((CURRENT_LANE_COUNT == 'b01) && (&tl_item.CR_DONE[1:0]))
                   begin
                    next_state = CHECK_EQUALIZATION;			
                   end
                   else if((CURRENT_LANE_COUNT == 'b00) && (tl_item.CR_DONE[0]))
                   begin
                    next_state = CHECK_EQUALIZATION;			
                   end
                   else if(CURRENT_LANE_COUNT == 'b10)   // Error Value of LC so it goes to the IDLE STATE 
                   begin
                    next_state = IDLE;			
                   end
			       else
			       begin
                    expected_transaction.FSM_CR_Failed = 1'b1;
                    ref_model_out_port.write(expected_transaction); // Send the expected transaction to the scoreboard 
                    next_state = CHECK_IF_ONE_LANE_USED; // Check if one lane is used
                   end
                   end	

                CHECK_EQUALIZATION: begin

                // Step 5: Check EQUALIZATION
                `uvm_info(get_type_name(), "Checking EQ parameters", UVM_LOW);  

                   if((CURRENT_LANE_COUNT == 'b11) && (tl_item.Lane_Align == 8'b11111111) && (tl_item.Channel_EQ[0] == 1'b1) && (tl_item.Symbol_Locked[0] == 1'b1))
                   begin
                    next_state = SUCCESS;			
                   end
                   else if((CURRENT_LANE_COUNT == 'b01) && (tl_item.Lane_Align == 8'b11111111) && (tl_item.Channel_EQ[1:0] == 2'b11) && (tl_item.Symbol_Locked[1:0] == 2'b11))
                   begin
                    next_state = SUCCESS;			
                   end
                   else if((CURRENT_LANE_COUNT == 'b00) && (tl_item.Lane_Align == 8'b11111111) && (tl_item.Channel_EQ[0] == 1'b1) && (tl_item.Symbol_Locked[0] == 1'b1))
                   begin
                    next_state = SUCCESS;			
                   end
                   else if(CURRENT_LANE_COUNT == 'b10)   // Error Value of LC so it goes to the IDLE STATE 
                   begin
                    next_state = IDLE;			
                   end
			       else
			       begin
                    Loop_Counter = Loop_Counter + 1; 
                    if(Loop_Counter == 6)
                    begin
                        next_state = IDLE;
                        Max_Loop_Counter = 1;
                        expected_transaction.FSM_CR_Failed = 1'b1;
                        ref_model_out_port.write(expected_transaction); // Send the expected transaction to the scoreboard                   
                    end
                    else
                    begin
                        next_state = WRITE_ADJUSTED_DRIVING_PARAMETERS;
                    end 
                   end

                end	

    
                WRITE_ADJUSTED_DRIVING_PARAMETERS: begin
                    // Step 5: Read Adjusted Training Parameters
                    `uvm_info(get_type_name(), "Reading Adjusted Training Parameters", UVM_LOW);

                    // signals sent to phy layer to transmit TPS
                    if (CURRENT_LANE_COUNT == 2'b00) begin
                        // Configure Lane 0
                        generate_native_aux_write_transaction(
                            sink_item,       // Input transaction from sink
                            tl_item,         // Input transaction from tl
                            expected_transaction,       // Output transaction
                            4'b1000,                    // Override command (AUX_NATIVE_WRITE)
                            20'h00102,                  // Override address (0x00102)
                            8'h01,                      // Override length (2 byte)
                            '{(tl_item.VTG[1:0] == MAX_VTG_temp && tl_item.PRE[1:0] == MAX_PRE_temp) ? {2'b00, 1'b1, tl_item.PRE[1:0], 1'b1, tl_item.VTG[1:0]} :
                              (tl_item.VTG[1:0] == MAX_VTG_temp) ? {2'b00, 1'b0, tl_item.PRE[1:0], 1'b1, tl_item.VTG[1:0]} :
                              (tl_item.PRE[1:0] == MAX_PRE_temp) ? {2'b00, 1'b1, tl_item.PRE[1:0], 1'b0, tl_item.VTG[1:0]} :
                              {2'b00, 1'b0, tl_item.PRE[1:0], 1'b0, tl_item.VTG[1:0]}} // Override data
                        );
                    end else if (CURRENT_LANE_COUNT == 2'b01) begin
                        // Configure Lanes 0 and 1
                        generate_native_aux_write_transaction(
                            sink_item,       // Input transaction from sink
                            tl_item,         // Input transaction from tl
                            expected_transaction,       // Output transaction
                            4'b1000,                    // Override command (AUX_NATIVE_WRITE)
                            20'h00102,                  // Override address (0x00102)
                            8'h02,                      // Override length (3 bytes)
                            '{(tl_item.VTG[1:0] == MAX_VTG_temp && tl_item.PRE[1:0] == MAX_PRE_temp) ? {2'b00, 1'b1, tl_item.PRE[1:0], 1'b1, tl_item.VTG[1:0]} :
                              (tl_item.VTG[1:0] == MAX_VTG_temp) ? {2'b00, 1'b0, tl_item.PRE[1:0], 1'b1, tl_item.VTG[1:0]} :
                              (tl_item.PRE[1:0] == MAX_PRE_temp) ? {2'b00, 1'b1, tl_item.PRE[1:0], 1'b0, tl_item.VTG[1:0]} :
                              {2'b00, 1'b0, tl_item.PRE[1:0], 1'b0, tl_item.VTG[1:0]},
                              (tl_item.VTG[3:2] == MAX_VTG_temp && tl_item.PRE[3:2] == MAX_PRE_temp) ? {2'b00, 1'b1, tl_item.PRE[3:2], 1'b1, tl_item.VTG[3:2]} :
                              (tl_item.VTG[3:2] == MAX_VTG_temp) ? {2'b00, 1'b0, tl_item.PRE[3:2], 1'b1, tl_item.VTG[3:2]} :
                              (tl_item.PRE[3:2] == MAX_PRE_temp) ? {2'b00, 1'b1, tl_item.PRE[3:2], 1'b0, tl_item.VTG[3:2]} :
                              {2'b00, 1'b0, tl_item.PRE[3:2], 1'b0, tl_item.VTG[3:2]}} // Override data
                        );
                    end else begin
                        // Configure Lanes 0, 1, 2, and 3
                        generate_native_aux_write_transaction(
                            sink_item,       // Input transaction from sink
                            tl_item,         // Input transaction from tl
                            expected_transaction,       // Output transaction
                            4'b1000,                    // Override command (AUX_NATIVE_WRITE)
                            20'h00102,                  // Override address (0x00102)
                            8'h04,                      // Override length (5 bytes)
                            '{(tl_item.VTG[1:0] == MAX_VTG_temp && tl_item.PRE[1:0] == MAX_PRE_temp) ? {2'b00, 1'b1, tl_item.PRE[1:0], 1'b1, tl_item.VTG[1:0]} :
                              (tl_item.VTG[1:0] == MAX_VTG_temp) ? {2'b00, 1'b0, tl_item.PRE[1:0], 1'b1, tl_item.VTG[1:0]} :
                              (tl_item.PRE[1:0] == MAX_PRE_temp) ? {2'b00, 1'b1, tl_item.PRE[1:0], 1'b0, tl_item.VTG[1:0]} :
                              {2'b00, 1'b0, tl_item.PRE[1:0], 1'b0, tl_item.VTG[1:0]},
                              (tl_item.VTG[3:2] == MAX_VTG_temp && tl_item.PRE[3:2] == MAX_PRE_temp) ? {2'b00, 1'b1, tl_item.PRE[3:2], 1'b1, tl_item.VTG[3:2]} :
                              (tl_item.VTG[3:2] == MAX_VTG_temp) ? {2'b00, 1'b0, tl_item.PRE[3:2], 1'b1, tl_item.VTG[3:2]} :
                              (tl_item.PRE[3:2] == MAX_PRE_temp) ? {2'b00, 1'b1, tl_item.PRE[3:2], 1'b0, tl_item.VTG[3:2]} :
                              {2'b00, 1'b0, tl_item.PRE[3:2], 1'b0, tl_item.VTG[3:2]},
                              (tl_item.VTG[5:4] == MAX_VTG_temp && tl_item.PRE[5:4] == MAX_PRE_temp) ? {2'b00, 1'b1, tl_item.PRE[5:4], 1'b1, tl_item.VTG[5:4]} :
                              (tl_item.VTG[5:4] == MAX_VTG_temp) ? {2'b00, 1'b0, tl_item.PRE[5:4], 1'b1, tl_item.VTG[5:4]} :
                              (tl_item.PRE[5:4] == MAX_PRE_temp) ? {2'b00, 1'b1, tl_item.PRE[5:4], 1'b0, tl_item.VTG[5:4]} :
                              {2'b00, 1'b0, tl_item.PRE[5:4], 1'b0, tl_item.VTG[5:4]},
                              (tl_item.VTG[7:6] == MAX_VTG_temp && tl_item.PRE[7:6] == MAX_PRE_temp) ? {2'b00, 1'b1, tl_item.PRE[7:6], 1'b1, tl_item.VTG[7:6]} :
                              (tl_item.VTG[7:6] == MAX_VTG_temp) ? {2'b00, 1'b0, tl_item.PRE[7:6], 1'b1, tl_item.VTG[7:6]} :
                              (tl_item.PRE[7:6] == MAX_PRE_temp) ? {2'b00, 1'b1, tl_item.PRE[7:6], 1'b0, tl_item.VTG[7:6]} :
                              {2'b00, 1'b0, tl_item.PRE[7:6], 1'b0, tl_item.VTG[7:6]}} // Override data
                        );
                    end
    
                    next_state = READ_TRAINING_INTERVAL;
                end


            // Check if RBR is used
            CHECK_IF_RBR: begin

           if (CURRENT_LINK_RATE == == 8'h06) // is Bandwidth used is RBR?
            begin
             next_state = FAILURE;
            end
           else
            begin
             next_state = REDUCE_LINK_RATE;
            end

            end

            // Check if one lane is used
            CHECK_IF_ONE_LANE_USED: begin
              if (tl_item.CR_DONE == 4'b0000) // is one lane used?
            begin
             next_state = CHECK_IF_RBR;
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
            restart = 1 // restart CR process  
            next_state = IDLE; // Reset to IDLE for the next phase  
            // restart clock recovery with updated lane count and bandwidth
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
            restart = 1 // restart CR process
            next_state = IDLE; // Reset to IDLE for the next phase
            // restart clock recovery with updated lane count and bandwidth 
            end

            SUCCESS: begin
                    // Step 8: EQ successful, Clear 0x00102 and set EQ_LT_Pass
                    `uvm_info(get_type_name(), "Channel Equalization successful", UVM_LOW);
                    
                generate_native_aux_write_transaction(
                    sink_item,       // Input transaction from sink
                    tl_item,         // Input transaction from tl
                    expected_transaction,       // Output transaction
                    4'b1000,                    // Override command (AUX_NATIVE_WRITE)
                    20'h00102,                  // Override address (0x00102)
                    8'h00,                      // Override length (1 byte)
                    8'h00                       // Override data
                );

                    expected_transaction.EQ_LT_Pass = 1'b1;
                    expected_transaction.EQ_Final_ADJ_BW = CURRENT_LINK_RATE;
                    expected_transaction.EQ_Final_ADJ_LC = CURRENT_LANE_COUNT;
    
                    ref_model_out_port.write(expected_transaction); // Send the expected transaction to the scoreboard
                    EQ_DONE = 1;
                    next_state = IDLE; // Reset to IDLE for the next phase
                    break;
                end
    
            FAILURE: begin
                    // Step 9: EQ failed
                    `uvm_error(get_type_name(), "Channel Equalization failed", UVM_LOW);
    
                    generate_native_aux_write_transaction(
                    sink_item,       // Input transaction from sink
                    tl_item,         // Input transaction from tl
                    expected_transaction,       // Output transaction
                    4'b1000,                    // Override command (AUX_NATIVE_WRITE)
                    20'h00102,                  // Override address (0x00102)
                    8'h00,                      // Override length (1 byte)
                    8'h00                       // Override data
             );

                    expected_transaction.EQ_Failed = 1'b1;
                    ref_model_out_port.write(expected_transaction); // Send the expected transaction to the scoreboard
                    EQ_DONE = 0;
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
            if (current_state == IDLE && (EQ_DONE || next_state == FAILURE)) begin
                break;
            end
        end
    
        return EQ_DONE;
    endfunction


    // Function to generate the expected transaction for Link Training Flow
    function void generate_link_training_flow(
    input dp_sink_sequence_item sink_item,  // Transaction from dp_sink_monitor
    input dp_tl_sequence_item tl_item,      // Transaction from dp_tl_monitor
    output dp_transaction expected_transaction // Generated expected transaction
    );
        bit [3:0] command;       // First 4 bits: Command

        // Initialize internal flags
        bit CR_DONE = 0;
        bit EQ_DONE = 0;
    
        // Step 2: Read DPCD capabilities (0x00000–0x000FF)
        `uvm_info(get_type_name(), "Reading DPCD capabilities", UVM_LOW);

        for (int i = 0; i < 16; i++) begin
        // Native AUX Transaction Scenario
        generate_native_aux_read_transaction(
            sink_item,       // Input transaction from sink
            tl_item,         // Input transaction from tl
            expected_transaction        // Output transaction
        );
        end
        
        // need to understand better
        // need to handle how to get Link_BW_CR and Link_LC_CR
        // Step 3: Writing to the Link Configuration field (offsets 0x00100–0x00101) to set the Link Bandwidth and Lane Count  clears register 0x00102 to 00h in the same write 
        //transaction.

                // Assign the encoded value to aux_in_out
                // Encoded value: 1000|0000 -> 00000001 -> 00000000 -> 00000010 -> Link_BW_CR -> Link_LC_CR -> 00000000
                
                // Call the Native aux write function to handle the transaction
                generate_native_aux_write_transaction(
                    sink_item,       // Input transaction from sink
                    tl_item,         // Input transaction from tl
                    expected_transaction,       // Output transaction
                    4'b1000,                    // Override command (AUX_NATIVE_WRITE)
                    20'h00100,                  // Override address (0x00100)
                    8'h03,                      // Override length (3 byte(s)) (length + 1)
                    '{8'Link_BW_CR, 8'Link_LC_CR, 8'h00}      // Override data
                );

    
        // Step 4: Begin Clock Recovery Phase
        CR_DONE = generate_clock_recovery_phase(sink_item, tl_item, expected_transaction);
    
        // Step 5: Begin Channel Equalization Phase if CR is successful
        if (CR_DONE) begin
            EQ_DONE = generate_channel_equalization_phase(sink_item, tl_item, expected_transaction);
        end
    
        // Step 6: Finalize Link Training
        if (EQ_DONE) begin
            expected_transaction.EQ_LT_Pass = 1'b1;
            expected_transaction.final_bw = 
            expected_transaction.final_lane_count = 
            `uvm_info(get_type_name(), $sformatf("Link Training successful: BW=%0d, Lanes=%0d",
                                                 expected_transaction.final_bw,
                                                 expected_transaction.final_lane_count), UVM_LOW);
        end else begin
            expected_transaction.EQ_Failed = 1'b1;
            `uvm_error(get_type_name(), "Link Training failed");
        end
    endfunction

endclass