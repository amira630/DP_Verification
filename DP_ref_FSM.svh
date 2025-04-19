function bit generate_clock_recovery_phase_fsm(
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

    // Initialize the FSM
    current_state = IDLE;

    forever begin
        case (current_state)
            IDLE: begin
                // Start the clock recovery process
                `uvm_info(get_type_name(), "Starting Clock Recovery Phase", UVM_LOW);
                next_state = WRITE_LINK_CONFIG;
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
                    '{8'Link_BW_CR, 8'Link_LC_CR, 8'h00} // Override data
                );
                next_state = ENABLE_TRAINING_PATTERN;
            end

            ENABLE_TRAINING_PATTERN: begin
                // Step 2: Enable Training Pattern 1 and disable scrambling
                `uvm_info(get_type_name(), "Enabling Training Pattern 1 and disabling scrambling", UVM_LOW);
                generate_native_aux_write_transaction(
                    received_transaction,       // Input transaction
                    expected_transaction,       // Output transaction
                    4'b1000,                    // Override command (AUX_NATIVE_WRITE)
                    20'h00102,                  // Override address (0x00102)
                    8'h00,                      // Override length (1 byte)
                    8'h00                       // Override data
                );
                next_state = CONFIGURE_DRIVING_SETTINGS;
            end

            CONFIGURE_DRIVING_SETTINGS: begin
                // Step 3: Configure initial driving settings
                `uvm_info(get_type_name(), "Configuring initial driving settings", UVM_LOW);
                generate_native_aux_write_transaction(
                    received_transaction,       // Input transaction
                    expected_transaction,       // Output transaction
                    4'b1000,                    // Override command (AUX_NATIVE_WRITE)
                    20'h00103,                  // Override address (0x00103)
                    8'h03,                      // Override length (4 byte(s))
                    '{8'h00, 8'h00, 8'h00, 8'h00} // Override data
                );
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
                // Step 5: Wait for the interval and read Link Status registers
                `uvm_info(get_type_name(), "Waiting for TRAINING_AUX_RD_INTERVAL and reading Link Status registers", UVM_LOW);
                generate_native_aux_read_transaction(
                    received_transaction,       // Input transaction
                    expected_transaction,       // Output transaction
                    4'b1001,                    // Override command (AUX_NATIVE_READ)
                    20'h00202,                  // Override address (0x00202)
                    8'h05                       // Override length (6 byte(s))
                );

                // Simulate success or failure
                if ($urandom_range(0, 1)) begin
                    CR_DONE = 1;
                    next_state = SUCCESS;
                end else begin
                    next_state = FAILURE;
                end
            end

            FAILURE: begin
                // Step 6: Handle failure
                `uvm_error(get_type_name(), "Clock Recovery failed after retries");
                CR_DONE = 0;
                next_state = IDLE; // Reset to IDLE for retry
                break;
            end

            SUCCESS: begin
                // Clock Recovery successful
                `uvm_info(get_type_name(), "Clock Recovery successful", UVM_LOW);
                CR_DONE = 1;
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