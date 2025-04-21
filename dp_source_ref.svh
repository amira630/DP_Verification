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
    
    task generate_i2c_over_aux_transaction_fsm(
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

   
    //to be added: nack and defer conditions
   
    // Function to generate the expected transaction for Native AUX Read Transaction
        function void generate_native_aux_read_transaction(
        input dp_sink_sequence_item sink_item,  // Transaction from dp_sink_monitor
        input dp_tl_sequence_item tl_item,      // Transaction from dp_tl_monitor
        output dp_transaction expected_transaction, // Generated expected transaction
        input bit [3:0] override_command = 4'b0000,  // Default: Use tl_item.LPM_CMD
        input bit [19:0] override_address = 20'h00000, // Default: Use tl_item.LPM_Address
        input bit [7:0] override_length = 8'h00       // Default: Use tl_item.LPM_LEN
    );
        // Decode the aux_in_out signal
        bit [3:0] command;       // First 4 bits: Command
        bit [19:0] address;      // Address
        bit [7:0] length;        // Length
        bit [7:0] data[$];       // Data
        int ack_count = 0;       // Ack counter
    
        // Use overrides if provided, otherwise use defaults from tl_item
        command = (override_command != 4'b0000) ? override_command : tl_item.LPM_CMD;
        address = (override_address != 20'h00000) ? override_address : tl_item.LPM_Address;
        length = (override_length != 8'h00) ? override_length : tl_item.LPM_LEN;
    
        // while (ack_count < 1) begin
            // Wait for the next transaction
            // ref_model_in_port.get(tl_item);
    
            // // Initialize outputs
            // expected_transaction.LPM_Reply_ACK = 1'b0;
            // expected_transaction.LPM_Reply_ACK_VLD = 1'b0;
            // expected_transaction.LPM_Reply_DATA = 8'h00;
            // expected_transaction.LPM_Reply_DATA_VLD = 1'b0;
            // expected_transaction.LPM_Native_I2C = 1'b0;
    
            // Check if the transaction is valid
            if (tl_item.LPM_Transaction_VLD) begin
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
                    ref_model_in_port.get(sink_item);
    
                    // Extract the command
                    command = sink_item.aux_in_out[3:0]; // Second 4 bits
    
                    // Loop to extract data bytes based on the length
                    for (int i = 0; i < length + 1; i++) begin
                        // Wait for the next transaction for each byte
                        ref_model_in_port.get(sink_item);
    
                        // Extract the data byte(s) from aux_in_out
                        data[i] = sink_item.aux_in_out[7:0];
    
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
                            expected_transaction.CTRL_I2C_Failed = 1'b1; // Set CTRL_I2C_Failed to indicate failure
    
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
    input dp_sink_sequence_item sink_item,  // Transaction from dp_sink_monitor
    input dp_tl_sequence_item tl_item,      // Transaction from dp_tl_monitor
    output dp_transaction expected_transaction, // Generated expected transaction
    input bit [3:0] override_command = 4'b0000,  // Default: Use tl_item.LPM_CMD
    input bit [19:0] override_address = 20'h00000, // Default: Use tl_item.LPM_Address
    input bit [7:0] override_length = 8'h00,      // Default: Use tl_item.LPM_LEN
    input bit [7:0] override_data[$] = {}         // Default: Use tl_item.LPM_Data
);
    // Decode the aux_in_out signal
    bit [3:0] command;       // First 4 bits: Command
    bit [19:0] address;      // Address
    bit [7:0] length;        // Length
    bit [7:0] data[$];       // Data
    int ack_count = 0;       // Ack counter

    // Use overrides if provided, otherwise use defaults from tl_item
    command = (override_command != 4'b0000) ? override_command : tl_item.LPM_CMD;
    address = (override_address != 20'h00000) ? override_address : tl_item.LPM_Address;
    length = (override_length != 8'h00) ? override_length : tl_item.LPM_LEN;
    data = (override_data.size() > 0) ? override_data : {tl_item.LPM_Data};

    // while (ack_count < 1) begin
    // //     // Wait for the next transaction
    //     ref_model_in_port.get(tl_item); //Lpm_seq_item

        // // Initialize outputs
        // expected_transaction.LPM_Reply_ACK = 1'b0;
        // expected_transaction.LPM_Reply_ACK_VLD = 1'b0;
        // expected_transaction.LPM_Reply_DATA = 8'h00;
        // expected_transaction.LPM_Reply_DATA_VLD = 1'b0;
        // expected_transaction.LPM_Native_I2C = 1'b0;

        // Check if the transaction is valid
        if (tl_item.LPM_Transaction_VLD) begin
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
                ref_model_in_port.get(sink_item); //Sink_seq_item

                // Extract the command
                command = sink_item.aux_in_out[3:0]; // Second 4 bits

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

                if (tl_item.LPM_Start_CR && tl_item.Driving_Param_VLD && tl_item.Config_Param_VLD)
                // Start the clock recovery process
                `uvm_info(get_type_name(), "Starting Clock Recovery Phase", UVM_LOW);
                next_state = WRITE_LINK_CONFIG;
                else begin
                    next_state = IDLE; // Stay in IDLE if not valid
                end
            end

            IDLE_WITH_UPDATED_BW_OR_LC: begin
                // Wait for the next transaction
                ref_model_in_port.get(tl_item); //Lpm_seq_item

                // Store the important values
                CURRENT_LANE_COUNT = tl_item.Link_LC_CR;
                CURRENT_LINK_RATE = tl_item.Link_BW_CR;

                if (tl_item.LPM_Start_CR && tl_item.Driving_Param_VLD && tl_item.Config_Param_VLD)
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
                    sink_item,       // Input transaction from sink
                    tl_item,         // Input transaction from tl
                    expected_transaction,       // Output transaction
                    4'b1000,                    // Override command (AUX_NATIVE_WRITE)
                    20'h00100,                  // Override address (0x00100)
                    8'h03,                      // Override length (3 byte(s))
                    '{CURRENT_LINK_RATE, {3'b100, 5'(CURRENT_LANE_COUNT + 5'b01)}, 8'h00} // Override data
                );
                
                next_state = ENABLE_TRAINING_PATTERN;
            end
            
            // need manual implementation of the function to generate the expected transaction for training pattern
            ENABLE_TRAINING_PATTERN: begin
                // Step 2: Enable Training Pattern 1 and disable scrambling
                `uvm_info(get_type_name(), "Enabling Training Pattern 1 and disabling scrambling", UVM_LOW);

                expected_transaction.PHY_Instruct = 2'b00; // Training pattern 1
                expected_transaction.PHY_Instruct_VLD = 1'b1; // Set PHY_Instruct_VLD to 1
                // expected_transaction.PHY_ADJ_BW = tl_item.Link_BW_CR
                // expected_transaction.PHY_ADJ_LC = tl_item.Link_LC_CR

                generate_native_aux_write_transaction(
                    sink_item,       // Input transaction from sink
                    tl_item,         // Input transaction from tl
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
            
                if (tl_item.Link_LC_CR == 2'b00) begin
                    // Configure Lane 0
                    generate_native_aux_write_transaction(
                        sink_item,       // Input transaction from sink
                        tl_item,         // Input transaction from tl
                        expected_transaction,       // Output transaction
                        4'b1000,                    // Override command (AUX_NATIVE_WRITE)
                        20'h00103,                  // Override address (0x00103)
                        8'h00,                      // Override length (1 byte)
                        '{(tl_item.VTG[1:0] == tl_item.MAX_VTG && tl_item.PRE[1:0] == tl_item.MAX_PRE) ? {2'b00, 1'b1, tl_item.PRE[1:0], 1'b1, tl_item.VTG[1:0]} :
                          (tl_item.VTG[1:0] == tl_item.MAX_VTG) ? {2'b00, 1'b0, tl_item.PRE[1:0], 1'b1, tl_item.VTG[1:0]} :
                          (tl_item.PRE[1:0] == tl_item.MAX_PRE) ? {2'b00, 1'b1, tl_item.PRE[1:0], 1'b0, tl_item.VTG[1:0]} :
                          {2'b00, 1'b0, tl_item.PRE[1:0], 1'b0, tl_item.VTG[1:0]}} // Override data
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
                        '{(tl_item.VTG[1:0] == tl_item.MAX_VTG && tl_item.PRE[1:0] == tl_item.MAX_PRE) ? {2'b00, 1'b1, tl_item.PRE[1:0], 1'b1, tl_item.VTG[1:0]} :
                          (tl_item.VTG[1:0] == tl_item.MAX_VTG) ? {2'b00, 1'b0, tl_item.PRE[1:0], 1'b1, tl_item.VTG[1:0]} :
                          (tl_item.PRE[1:0] == tl_item.MAX_PRE) ? {2'b00, 1'b1, tl_item.PRE[1:0], 1'b0, tl_item.VTG[1:0]} :
                          {2'b00, 1'b0, tl_item.PRE[1:0], 1'b0, tl_item.VTG[1:0]},
                          (tl_item.VTG[3:2] == tl_item.MAX_VTG && tl_item.PRE[3:2] == tl_item.MAX_PRE) ? {2'b00, 1'b1, tl_item.PRE[3:2], 1'b1, tl_item.VTG[3:2]} :
                          (tl_item.VTG[3:2] == tl_item.MAX_VTG) ? {2'b00, 1'b0, tl_item.PRE[3:2], 1'b1, tl_item.VTG[3:2]} :
                          (tl_item.PRE[3:2] == tl_item.MAX_PRE) ? {2'b00, 1'b1, tl_item.PRE[3:2], 1'b0, tl_item.VTG[3:2]} :
                          {2'b00, 1'b0, tl_item.PRE[3:2], 1'b0, tl_item.VTG[3:2]}} // Override data
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
                        '{(tl_item.VTG[1:0] == tl_item.MAX_VTG && tl_item.PRE[1:0] == tl_item.MAX_PRE) ? {2'b00, 1'b1, tl_item.PRE[1:0], 1'b1, tl_item.VTG[1:0]} :
                          (tl_item.VTG[1:0] == tl_item.MAX_VTG) ? {2'b00, 1'b0, tl_item.PRE[1:0], 1'b1, tl_item.VTG[1:0]} :
                          (tl_item.PRE[1:0] == tl_item.MAX_PRE) ? {2'b00, 1'b1, tl_item.PRE[1:0], 1'b0, tl_item.VTG[1:0]} :
                          {2'b00, 1'b0, tl_item.PRE[1:0], 1'b0, tl_item.VTG[1:0]},
                          (tl_item.VTG[3:2] == tl_item.MAX_VTG && tl_item.PRE[3:2] == tl_item.MAX_PRE) ? {2'b00, 1'b1, tl_item.PRE[3:2], 1'b1, tl_item.VTG[3:2]} :
                          (tl_item.VTG[3:2] == tl_item.MAX_VTG) ? {2'b00, 1'b0, tl_item.PRE[3:2], 1'b1, tl_item.VTG[3:2]} :
                          (tl_item.PRE[3:2] == tl_item.MAX_PRE) ? {2'b00, 1'b1, tl_item.PRE[3:2], 1'b0, tl_item.VTG[3:2]} :
                          {2'b00, 1'b0, tl_item.PRE[3:2], 1'b0, tl_item.VTG[3:2]},
                          (tl_item.VTG[5:4] == tl_item.MAX_VTG && tl_item.PRE[5:4] == tl_item.MAX_PRE) ? {2'b00, 1'b1, tl_item.PRE[5:4], 1'b1, tl_item.VTG[5:4]} :
                          (tl_item.VTG[5:4] == tl_item.MAX_VTG) ? {2'b00, 1'b0, tl_item.PRE[5:4], 1'b1, tl_item.VTG[5:4]} :
                          (tl_item.PRE[5:4] == tl_item.MAX_PRE) ? {2'b00, 1'b1, tl_item.PRE[5:4], 1'b0, tl_item.VTG[5:4]} :
                          {2'b00, 1'b0, tl_item.PRE[5:4], 1'b0, tl_item.VTG[5:4]},
                          (tl_item.VTG[7:6] == tl_item.MAX_VTG && tl_item.PRE[7:6] == tl_item.MAX_PRE) ? {2'b00, 1'b1, tl_item.PRE[7:6], 1'b1, tl_item.VTG[7:6]} :
                          (tl_item.VTG[7:6] == tl_item.MAX_VTG) ? {2'b00, 1'b0, tl_item.PRE[7:6], 1'b1, tl_item.VTG[7:6]} :
                          (tl_item.PRE[7:6] == tl_item.MAX_PRE) ? {2'b00, 1'b1, tl_item.PRE[7:6], 1'b0, tl_item.VTG[7:6]} :
                          {2'b00, 1'b0, tl_item.PRE[7:6], 1'b0, tl_item.VTG[7:6]}} // Override data
                    );
                end

                next_state = READ_TRAINING_INTERVAL;
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
                next_state = WAIT_AND_READ_LINK_STATUS;
            end

            WAIT_AND_READ_LINK_STATUS: begin
       
    //     constraint eq_rd_value_constraint {
    //     EQ_RD_Value[7] == 1'b1; // Ensure the MSB is always 1
    //     EQ_RD_Value[6:0] inside {7'h00, 7'h01, 7'h02, 7'h03, 7'h04}; // Allowed values for the lower 7 bits

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

                next_state = CR_DONE_CHECK; 

            end
            
            // Need to maybe store Link_LC_CR in a temp variable
            // Step 6: Check for CR_DONE and CR_DONE_VLD
            CR_DONE_CHECK: begin
            
            same_parameters_repeated_counter = same_parameters_repeated_counter + 1;

            // Wait for the next transaction
            ref_model_in_port.get(tl_item); //Lpm_seq_item

		    if((tl_item.Link_LC_CR == 'b11) && (&tl_item.CR_DONE))
             begin
              next_state = SUCCESS;			
             end
            else if((tl_item.Link_LC_CR == 'b01) && (&tl_item.CR_DONE[1:0]))
             begin
              next_state = SUCCESS;			
             end
            else if((tl_item.Link_LC_CR == 'b00) && (tl_item.CR_DONE[0]))
             begin
              next_state = SUCCESS;			
             end
            else if(tl_item.Link_LC_CR == 'b10)   // Error Value of LC so it goes to the IDLE STATE 
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

                next_state = CHECK_NEW_CONDITIONS; 

            end
        // Conditions: 1. MAX_VTG = VTG 2. full_loop_counter > 10 3. same_parameters_repeated_counter > 5
        // Note: Should be 3 conditions but don't know
            CHECK_NEW_CONDITIONS: begin
          ref_model_in_port.get(tl_item); //Lpm_seq_item

           if ((full_loop_counter == 'd11) || (same_parameters_repeated_counter == 'd6) || (tl_item.VTG == MAX_VTG_temp))
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