    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import test_parameters_pkg::*;
class dp_sink_base_sequence extends uvm_sequence #(dp_sink_sequence_item);
    `uvm_object_utils(dp_sink_base_sequence);

    dp_sink_sequence_item seq_item;
    dp_sink_sequence_item rsp_item;             // To capture responses
    dp_sink_sequence_item reply_seq_item;       // To rend the reply

    dp_source_config sink_seq_cfg;
    
    // Register arrays 
    rand bit [7:0] EDID_registers [128];
    rand bit [7:0] DPCD_cap_registers [256];
    rand bit [7:0] DPCD_cap_ext_registers [256];
    rand bit [7:0] DPCD_event_status_indicator_registers [512];
    rand bit [7:0] Link_status_registers [256];
    rand bit [7:0] Link_configuration_registers [256];

    // Extra Flags and signals
    int i2c_count = 0;

    function new(string name = "dp_sink_base_sequence");
        super.new(name);
    endfunction //new()

    task pre_body();
        super.pre_body();
        `uvm_info("Sink BASE SEQ", "Trying to get CFG now!", UVM_MEDIUM);
        
        // Try to get config with more specific paths
         if (!uvm_config_db #(dp_source_config)::get(uvm_root::get(), "uvm_test_top.*", "CFG",sink_seq_cfg))
             `uvm_fatal("SEQ_build_phase","Unable to get configuration object in SINK base sequence");
    endtask

    // Flow FSM Task
    task Sink_FSM();
        sink_flow_stages_e current_state, next_state;
        // Randomize all registers once at the start
        if (!(randomize(EDID_registers) &&
              randomize(DPCD_cap_registers) &&
              randomize(DPCD_cap_ext_registers) &&
              randomize(DPCD_event_status_indicator_registers) &&
              randomize(Link_configuration_registers) &&
              randomize(Link_status_registers))) begin
            `uvm_error(get_type_name(), "Failed to randomize register sets")
        end
        else begin
            `uvm_info(get_type_name(), "Successfully randomized all register sets", UVM_MEDIUM)
        end

        seq_item = dp_sink_sequence_item::type_id::create("seq_item");

        if (seq_item == null) begin
            `uvm_info(get_type_name(), "seq_item creation failed", UVM_MEDIUM)
        end

        fork
            begin:  Sink_FSM_States
                forever begin
                    case (current_state)
                            SINK_NOT_READY: begin
                                `uvm_info(get_type_name(), "Sink is not ready", UVM_MEDIUM)
                                `uvm_info(get_type_name(), $sformatf("Time=%0t: Sink is not ready", $time), UVM_MEDIUM)
                                not_ready();                            // Wait for the sink to be ready
                                `uvm_info(get_type_name(), "Sink pass the not ready task", UVM_MEDIUM)
                                current_state = SINK_LISTEN;

                            end
                            SINK_LISTEN: begin
                                `uvm_info(get_type_name(), "Sink is in Listen mode, Waiting for request command", UVM_MEDIUM)
                                ready();                            
                                if (seq_item.AUX_START_STOP) begin
                                    current_state = SINK_TALK;                         // Move to the next state
                                end else begin
                                    current_state = SINK_LISTEN;                        // Stay in the same state
                                end
                            end
                            SINK_TALK: begin
                                `uvm_info(get_type_name(), "Sink is in Talk mode, Sending reply", UVM_MEDIUM)
                                reply_transaction();                     // Send the reply transaction
                                if (seq_item.AUX_START_STOP) begin
                                    current_state = SINK_TALK;                         // Stay in the same state
                                end else begin
                                    current_state = SINK_LISTEN;                        // Move to the last state
                                end
                            end

                        // default: begin
                        //     current_state = SINK_NOT_READY;
                        // end
                    endcase
                end
            end

            begin: Sink_FSM_Reset
                forever begin
                    // if (!sink_seq_cfg.rst_n) begin
                    //     current_state = SINK_NOT_READY;
                    //     `uvm_info(get_type_name(), $sformatf("Time=%0t: sink at if condition", $time), UVM_MEDIUM)
                    // end 
                    // else
                    //     current_state = next_state;


                    wait(~sink_seq_cfg.rst_n);                  // Wait for the reset signal to go low
                        current_state = SINK_NOT_READY;                  // Set the current state to Not Ready
                        `uvm_info(get_type_name(), $sformatf("Time=%0t: sink at wait ~rst", $time), UVM_MEDIUM)
                    wait(sink_seq_cfg.rst_n);                  // Wait for the reset signal to go high
                        current_state = next_state;                  // Set the current state to next_state
                        `uvm_info(get_type_name(), $sformatf("Time=%0t: sink at wait rst", $time), UVM_MEDIUM)
                    
                end
            end
        join
    endtask

    // Not Ready Sequence
    task not_ready();
        // Initialize the state machine
        seq_item = dp_sink_sequence_item::type_id::create("seq_item");

        if (seq_item == null) begin
            `uvm_info(get_type_name(), "seq_item creation failed", UVM_MEDIUM)
        end

        `uvm_info(get_type_name(), "start not ready function", UVM_MEDIUM)
        `uvm_info(get_type_name(), $sformatf("Time=%0t: start not ready function", $time), UVM_MEDIUM)
        

        // Set the sequence item signals
        start_item(seq_item);
        `uvm_info(get_type_name(), "start_item for not ready", UVM_MEDIUM)
        seq_item.sink_operation = Reset;  // Set the operation type to Not Ready
        finish_item(seq_item);                          // Send the sequence item to the driver
        `uvm_info(get_type_name(), "finish_item for not ready", UVM_MEDIUM)
        get_response(seq_item);
    endtask

    // Ready Sequence
    task ready();
        seq_item = dp_sink_sequence_item::type_id::create("seq_item");

        if (seq_item == null) begin
            `uvm_info(get_type_name(), "seq_item creation failed", UVM_MEDIUM)
            wait(seq_item != null);
        end

        // Set the sequence item signals
        start_item(seq_item);
        `uvm_info(get_type_name(), "start_item for ready state", UVM_MEDIUM)
        seq_item.sink_operation = Ready;                // Set the operation type to Not Ready
        finish_item(seq_item);                          // Send the sequence item to the driver
        `uvm_info(get_type_name(), "finish_item for ready state", UVM_MEDIUM)
        get_response(seq_item);
    endtask

    // Reply Sequence
    task reply_transaction();
        int i = 0;
        seq_item = dp_sink_sequence_item::type_id::create("seq_item");
        // seq_item.sink_operation = Reply_operation;
        get_response(seq_item);                             // Get the response from the driver
        while (seq_item.AUX_START_STOP) begin

            if (seq_item == null) begin
                `uvm_info(get_type_name(), "Received empty response, cannot process request", UVM_MEDIUM)
                wait(seq_item != null);
            end

            seq_item.aux_in_out.push_back(seq_item.AUX_IN_OUT);

            start_item(seq_item);                          // Start the sequence item
            `uvm_info(get_type_name(), "start_item for reply transaction", UVM_MEDIUM)
            seq_item.sink_operation = Receive_op;     // Set the operation type to Reply
            finish_item(seq_item);                         // Send the sequence item to the driver

            get_response(seq_item);                         // Get the response from the driver
        end

        process_aux_data(seq_item, reply_seq_item);                // Process the AUX data from the response

        // process_sink_data(seq_item, reply_seq_item);                    // Process the sink data from the response

        for (i = 0;i < reply_seq_item.aux_in_out.size(); i++) begin
            start_item(reply_seq_item);                                 // Start the sequence item
            `uvm_info(get_type_name(), "start_item for reply transaction", UVM_MEDIUM)
            reply_seq_item.sink_operation = Reply_operation;            // Set the operation type to Reply
            reply_seq_item.PHY_IN_OUT = reply_seq_item.aux_in_out[i];
            finish_item(reply_seq_item);                                // Send the sequence item to the driver
            `uvm_info(get_type_name(), "finish_item for reply transaction", UVM_MEDIUM)
            get_response(seq_item);
        end
    endtask

    // Process the AUX data from the response
    function void process_aux_data(ref dp_sink_sequence_item rsp_item, ref dp_sink_sequence_item reply_item);
        int i = 0;
        int addr_idx;
        bit [7:0] aux_data = 0; 
        bit [19:0] full_address; 
        // Check if the AUX data is valid
        if (rsp_item.aux_in_out.size() < 3) begin
            `uvm_error(get_type_name(), "AUX data too short, cannot process request")
            return;
        end

        // Clear previous values
        rsp_item.command = 0;
        rsp_item.address = 0;
        rsp_item.length = 0;
        rsp_item.data.delete();   

        reply_item.command = 0;
        reply_item.address = 0;
        reply_item.length = 0;
        reply_item.data.delete(); 

        // Extract fields:
        for (i = 0; i < rsp_item.aux_in_out.size(); i++) begin
            aux_data = rsp_item.aux_in_out[i];
            if (i == 0) begin
                rsp_item.command = aux_data[7:4]; 
                rsp_item.address = aux_data[3:0]; 
            end 
            else if (i == 1 || i == 2) begin
                rsp_item.address = {rsp_item.address, aux_data[7:0]};
            end
            else if (i == 3) begin
                rsp_item.length = aux_data[7:0]; 
            end
            else begin
                rsp_item.data.push_back(aux_data); 
            end
        end
        
        //rsp_item.aux_in_out.delete();

        `uvm_info(get_type_name(), $sformatf("process_aux_data - Processed AUX: cmd=0x%h, addr=0x%h, len=0x%h, data_size=%0d", 
                  rsp_item.command, rsp_item.address, rsp_item.length, rsp_item.data.size()), UVM_MEDIUM)

        `uvm_info(get_type_name(), "Now, will begin to create the reply data", UVM_MEDIUM);

        // Create the reply sequence item
        reply_item = dp_sink_sequence_item::type_id::create("reply_seq_item");
        if (reply_item == null) begin
            `uvm_info(get_type_name(), "reply_seq_item creation failed", UVM_MEDIUM)
            return;
        end
        
        if (rsp_item.command[3]) begin                      // Native 
            full_address = rsp_item.address;

            if (rsp_item.command[2:0] == 000) begin         // Write Native
                // According to Address and (value(Length[7:0])+1), we can write the rsp_item.data to the registers

                // Randomize the native_reply_cmd before using it
                if (!reply_item.randomize(native_reply_cmd)) begin
                    `uvm_error(get_type_name(), "Failed to randomize native_reply_cmd")
                end
                reply_item.aux_in_out[0] = {reply_item.native_reply_cmd, 4'b0000};      // ACK for Native Write

                // Write the data into registers
                foreach (rsp_item.data[i]) begin
                    case (1)
                        (full_address inside {[20'h00000:20'h000FF]}): DPCD_cap_registers[full_address[7:0]] = rsp_item.data[i];
                        (full_address inside {[20'h02200:20'h022FF]}): DPCD_cap_ext_registers[full_address[7:0]] = rsp_item.data[i];
                        (full_address inside {[20'h02000:20'h021FF]}): DPCD_event_status_indicator_registers[full_address[8:0]] = rsp_item.data[i];
                        (full_address inside {[20'h00100:20'h001FF]}): Link_configuration_registers[full_address[7:0]] = rsp_item.data[i];
                        (full_address inside {[20'h00200:20'h002FF]}): Link_status_registers[full_address[7:0]] = rsp_item.data[i];
                        default: `uvm_warning(get_type_name(), $sformatf("Write to unsupported address 0x%h", full_address))
                    endcase
                    full_address++;  // Increment address for multi-byte writes
                end
            end 
            else if (rsp_item.command[2:0] == 001) begin    // Read Native
                // According to Address and (value(Length[7:0])+1), we can Read the data from registers and push them to the aux_in_out array

                // Randomize the native_reply_cmd before using it
                if (!reply_item.randomize(native_reply_cmd)) begin
                    `uvm_error(get_type_name(), "Failed to randomize native_reply_cmd")
                end
                reply_item.aux_in_out[0] = {reply_item.native_reply_cmd, 4'b0000};      // ACK for Native Read

                // Read (length + 1) bytes from registers
                for (i = 0; i <= rsp_item.length; i++) begin
                    case (1)
                        (full_address inside {[20'h00000:20'h000FF]}): reply_item.aux_in_out.push_back(DPCD_cap_registers[full_address[7:0]]);
                        (full_address inside {[20'h02200:20'h022FF]}): reply_item.aux_in_out.push_back(DPCD_cap_ext_registers[full_address[7:0]]);
                        (full_address inside {[20'h02000:20'h021FF]}): reply_item.aux_in_out.push_back(DPCD_event_status_indicator_registers[full_address[8:0]]);
                        (full_address inside {[20'h00100:20'h001FF]}): reply_item.aux_in_out.push_back(Link_configuration_registers[full_address[7:0]]);
                        (full_address inside {[20'h00200:20'h002FF]}): reply_item.aux_in_out.push_back(Link_status_registers[full_address[7:0]]);
                        default: begin
                            `uvm_warning(get_type_name(), $sformatf("Read from unsupported address 0x%h", full_address))
                            reply_item.aux_in_out.push_back(8'hFF); // push dummy data for invalid address
                        end
                    endcase
                    full_address++;  // Increment address for multi-byte reads
                end
            end
            else begin
                `uvm_error(get_type_name(), "Invalid command for Native")
            end
        end else begin                                      // I2C
            if (rsp_item.command[2]) begin                  // MOT   // I2C reading continue 
                if (i2c_count == 129) begin
                    `uvm_info(get_type_name(), "Reached the end of the I2C register space", UVM_MEDIUM)
                    `uvm_error(get_type_name(), "Reached the end of the I2C register space, will stop processing the reply transaction")  
                    return;
                end 
                else begin
                    `uvm_info(get_type_name(), $sformatf("i2c_count = %0d, will continue to process the reply transaction", i2c_count-1), UVM_MEDIUM)
                end

                // if counter = 0, this means that it is the address-only transaction
                if (i2c_count == 0) begin
                    // Randomize the i2c_reply_cmd before using it
                    if (!reply_item.randomize(i2c_reply_cmd)) begin
                        `uvm_error(get_type_name(), "Failed to randomize i2c_reply_cmd")
                    end
                    reply_item.aux_in_out[0] = {reply_item.i2c_reply_cmd, 4'b0000};           // ACK for I2C read
                end 
                else begin          // form 1 to 128, this means that it is the data transaction
                    // Randomize the i2c_reply_cmd before using it
                    if (!reply_item.randomize(i2c_reply_cmd)) begin
                        `uvm_error(get_type_name(), "Failed to randomize i2c_reply_cmd")
                    end
                    reply_item.aux_in_out[0] = {reply_item.i2c_reply_cmd, 4'b0000};   // ACK for I2C read
                    reply_item.aux_in_out[1] = EDID_registers[i2c_count-1];           // Data for I2C read
                end
                i2c_count++;
            end else begin                                  // I2C reading stop
                if (rsp_item.command[1:0] == 01) begin      // I2C read
                    // Randomize the i2c_reply_cmd before using it
                    if (!reply_item.randomize(i2c_reply_cmd)) begin
                        `uvm_error(get_type_name(), "Failed to randomize i2c_reply_cmd")
                    end
                    reply_item.aux_in_out[0] = {reply_item.i2c_reply_cmd, 4'b0000};           // ACK for I2C read
                end 
                else begin
                    `uvm_error(get_type_name(), "Invalid command for I2C")
                end
            end
        end
    endfunction

    // Process the sink data from the response
    // function void process_sink_data(ref dp_sink_sequence_item seq_item, ref dp_sink_sequence_item reply_seq_item);
    //     int i = 0;
    //     // Check if the sink data is valid
    //     if (seq_item.data.size() < 1) begin
    //         `uvm_error(get_type_name(), "Data too short, cannot process Reply")
    //         return;
    //     end

    //     // Clear previous values
    //     reply_seq_item.command = 0;
    //     reply_seq_item.address = 0;
    //     reply_seq_item.length = 0;
    //     reply_seq_item.data.delete();   

    //     // Extract fields:
    //     for (i = 0; i < seq_item.data.size(); i++) begin
    //         reply_seq_item.data.push_back(seq_item.data[i]); 
    //     end
        
    //     seq_item.data.delete();

    // endfunction


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
        get_response(seq_item);
    endtask

    // HPD Testing 
    task Random_HPD ();
        // Create and configure sequence item
        seq_item = dp_sink_sequence_item::type_id::create("seq_item");

        if (seq_item == null) begin
            `uvm_info(get_type_name(), "seq_item creation failed", UVM_MEDIUM)
            wait(seq_item != null);
        end

        // Set the sequence item signals
        start_item(seq_item);
        `uvm_info(get_type_name(), "start_item for HPD test", UVM_MEDIUM)
        seq_item.sink_operation = HPD_test_operation;  // Set the operation type to IRQ
        finish_item(seq_item);                          // Send the sequence item to the driver
        `uvm_info(get_type_name(), "finish_item for HPD test", UVM_MEDIUM)
        get_response(seq_item);
    endtask

endclass //dp_sink_base_sequence extends superClass
