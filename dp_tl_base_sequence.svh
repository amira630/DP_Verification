    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import test_parameters_pkg::*;
class dp_tl_base_sequence extends uvm_sequence #(dp_tl_sequence_item);
    `uvm_object_utils(dp_tl_base_sequence);

    dp_tl_sequence_item seq_item;

    dp_source_config seq_cfg; 

    function new(string name = "dp_tl_base_sequence");
        super.new(name);
    endfunction //new()

    task pre_body();
        super.pre_body();
        `uvm_info("TL BASE SEQ", "Trying to get CFG now!", UVM_MEDIUM);
        
        // Try to get config with more specific paths
       if (!uvm_config_db #(dp_source_config)::get(uvm_root::get(), "uvm_test_top.*", "CFG",seq_cfg))
             `uvm_fatal("SEQ_build_phase","Unable to get configuration object in TL base sequence!");
    endtask

/////////////////////////////// FSM ///////////////////////////////////////
task FLOW_FSM();
        tl_flow_stages_e cs, ns; // Declare current and next state variables
        
        seq_item = dp_tl_sequence_item::type_id::create("seq_item");
        seq_item.rst_n = seq_cfg.rst_n; // Reset signal for the sequence item
        seq_item.isflow= 1'b1; // Set the isflow flag to indicate that this is a flow sequence
        fork
            begin
                forever begin
                    case(cs)
                        DETECTING:begin
                            detect_wait(seq_item.HPD_Detect);
                            if(seq_item.HPD_Detect) begin
                                // cs = CR_STAGE;
                                // `uvm_info("TL_BASE_SEQ", $sformatf("HPD detected, moving to CR stage"), UVM_MEDIUM)
                                cs = ISO_STAGE;
                                `uvm_info("TL_BASE_SEQ", $sformatf("HPD detected, moving to ISO stage"), UVM_MEDIUM)
                            end
                            else begin
                                cs = DETECTING;
                                `uvm_info("TL_BASE_SEQ", $sformatf("No HPD detected, staying in DETECTING state"), UVM_MEDIUM)
                            end
                        end
                        CR_STAGE: begin
                            CR_LT();
                            if(seq_item.HPD_Detect) begin
                                if(~seq_item.LT_Failed) begin
                                    cs = EQ_STAGE;
                                    `uvm_info("TL_BASE_SEQ", $sformatf("Link Training CR passed, moving to EQ stage"), UVM_MEDIUM)
                                end
                                else begin
                                    cs = CR_STAGE;
                                    `uvm_info("TL_BASE_SEQ", $sformatf("Link Training CR failed, moving back to DETECTING state"), UVM_MEDIUM)
                                end
                            end
                            else begin
                                cs = DETECTING;
                                `uvm_info("TL_BASE_SEQ", $sformatf("No HPD detected, moving back to DETECTING state"), UVM_MEDIUM)
                            end
                        end
                        EQ_STAGE: begin
                            EQ_LT();
                            if(seq_item.HPD_Detect) begin
                                if(seq_item.LT_Pass) begin
                                    cs = ISO_STAGE;
                                    `uvm_info("TL_BASE_SEQ", $sformatf("Link Training (EQ) has been successful , moving to ISO stage"), UVM_MEDIUM)
                                end
                                else if(seq_item.LT_Failed) begin
                                    cs = CR_STAGE;
                                    `uvm_info("TL_BASE_SEQ", $sformatf("Link Training EQ failed, moving back to DETECTING state"), UVM_MEDIUM)
                                end
                            end
                            else begin
                                cs = DETECTING;
                                `uvm_info("TL_BASE_SEQ", $sformatf("No HPD detected, moving back to DETECTING state"), UVM_MEDIUM)
                            end
                        end
                        ISO_STAGE: begin
                            fork
                                begin
                                    ISO_INIT();
                                    Main_Stream(1);
                                end
                                // begin 
                                //     forever begin
                                //         if(~seq_item.HPD_Detect) begin
                                //             cs = DETECTING;
                                //             seq_item.SPM_ISO_start = 1'b0; // Stop the ISO stream
                                //             `uvm_info("TL_BASE_SEQ", $sformatf("HPD not detected, moving back to DETECTING state"), UVM_MEDIUM)
                                //         end
                                //         else if(seq_item.HPD_IRQ) begin
                                //             // Call Interrput task
                                //             HPD_IRQ_sequence();
                                //             if(seq_item.error_flag) begin
                                //                 cs = CR_STAGE;
                                //                 seq_item.SPM_ISO_start = 1'b0; // Stop the ISO stream
                                //                 `uvm_info("TL_BASE_SEQ", $sformatf("ISO stage completed, moving to IRQ state"), UVM_MEDIUM)
                                //             end
                                //             else begin
                                //                 cs = ISO_STAGE;
                                //                 `uvm_info("TL_BASE_SEQ", $sformatf("ISO stage not completed, staying in ISO stage"), UVM_MEDIUM)
                                //             end
                                //         end
                                //     end
                                // end
                            join
                        end
                        default: begin
                            cs = DETECTING;
                            `uvm_fatal("TL_BASE_SEQ", "Invalid state in FLOW_FSM")
                        end
                    endcase
                end
            end

            begin
                forever begin
                    wait(~seq_cfg.rst_n);                  // Wait for the reset signal to go low
                        reset_task();                  // Set the current state to Not Ready
                        `uvm_info(get_type_name(), $sformatf("Time=%0t: TL at wait ~rst", $time), UVM_MEDIUM)
                    wait(seq_cfg.rst_n);                  // Wait for the reset signal to go high
                        cs = DETECTING;                  // Set the current state to next_state
                        `uvm_info(get_type_name(), $sformatf("Time=%0t: TL at wait rst", $time), UVM_MEDIUM)
                end
            end
        join 
        seq_item.isflow= 1'b0;
    endtask


////////////////////////////// Detecting //////////////////////////////

    task detect_wait(output logic HPD_Detect);
        `uvm_info(get_type_name(), "Detect wait DUT", UVM_MEDIUM)
        // seq_item = dp_tl_sequence_item::type_id::create("seq_item");
        start_item(seq_item);
            seq_item.operation = DETECT_op;
        finish_item(seq_item);
        `uvm_info(get_type_name(), "Detect wait complete", UVM_MEDIUM)
        get_response(seq_item);
        HPD_Detect = seq_item.HPD_Detect;
        if(seq_item.HPD_Detect) begin
            `uvm_info(get_type_name(), $sformatf("HPD detected"), UVM_MEDIUM)
        end
        else begin
            `uvm_info(get_type_name(), $sformatf("No HPD detected"), UVM_MEDIUM)
        end

    endtask

/////////////////////////// Reset /////////////////////////////////////

    task reset_task();
        // Reset the DUT and wait for it to be ready
        `uvm_info(get_type_name(), "Resetting DUT", UVM_MEDIUM)
        seq_item = dp_tl_sequence_item::type_id::create("seq_item");
        start_item(seq_item);
            seq_item.operation = reset_op;
            seq_item.LPM_Transaction_VLD = 1'b0; // LPM is off
            seq_item.LT_Failed = 1'b0; 
            seq_item.LT_Pass = 1'b0;
        finish_item(seq_item);
        `uvm_info(get_type_name(), "DUT Reset complete", UVM_MEDIUM)
        get_response(seq_item);
    endtask

////////////////////////////////////// HPD //////////////////////////////////////

    task HPD_IRQ_sequence();
        for(int i=0; i<16; i++)
            native_read_request(20'h200 + i*16, 8'h0F);   // Read Link/Sink Device Status Register
        start_item(seq_item);
            `uvm_info(get_type_name(), "HPD IRQ sequence", UVM_MEDIUM)
            seq_item.error_flag.rand_mode(1);  
            assert(seq_item.randomize());                 // Randomize the data
            if (seq_item.error_flag) begin
                seq_item.SPM_ISO_start = 1'b0;
                seq_item.LT_Pass = 1'b0;
            end
        finish_item(seq_item);
        `uvm_info(get_type_name(), "HPD IRQ sequence complete", UVM_MEDIUM)
        get_response(seq_item);
    endtask

//////////////////////////// I2C AUX REQUEST TRANSACTION //////////////////////////////////

// I2C AUX REQUEST TRANSACTION sequence
    task i2c_request(input i2c_aux_request_cmd_e CMD, logic [19:0] address);
        int ack_count = 0;
        int data_count = 0;
        seq_item = dp_tl_sequence_item::type_id::create("seq_item");

        seq_item.CTRL_I2C_Failed = 1;
        while (seq_item.CTRL_I2C_Failed) begin
            seq_item.CTRL_I2C_Failed = 0;
            start_item(seq_item);
                seq_item.SPM_Address.rand_mode(0);    // randomization off
                seq_item.SPM_CMD.rand_mode(0);        // randomization off
                seq_item.operation = I2C_READ;
                seq_item.SPM_CMD = CMD;               // Read
                seq_item.SPM_Transaction_VLD = 1'b1;  // SPM is going to request a Native transaction 
                seq_item.SPM_Address = address;       // Address
                seq_item.SPM_LEN = 0;               // Length
                seq_item.SPM_Data = 0;               // Data
            finish_item(seq_item);

            while ((ack_count <= seq_item.SPM_LEN) && (data_count <= seq_item.SPM_LEN)) begin
                start_item(seq_item);
                seq_item.SPM_Transaction_VLD = 1'b0; 
                seq_item.operation = WAIT_REPLY;
                finish_item(seq_item);
                get_response(seq_item);

                if (seq_item.CTRL_I2C_Failed) begin
                    `uvm_info("TL_I2C_REQ_SEQ_FAILED", $sformatf("I2C AUX %s request transaction failed: addr=0x%0h, Data Length=0x%0d, Transaction Validity = 0x%0b",  seq_item.SPM_CMD, seq_item.SPM_Address, seq_item.SPM_LEN +1, seq_item.SPM_Transaction_VLD), UVM_MEDIUM)
                    break;
                end

                if(seq_item.SPM_NATIVE_I2C && seq_item.SPM_Reply_ACK_VLD) begin
                    if (seq_item.SPM_Reply_ACK == I2C_ACK[3:2]) begin
                        ack_count++;
                    end
                end
                else if (seq_item.SPM_NATIVE_I2C && seq_item.SPM_Reply_Data_VLD) begin
                    data_count++;
                end
                `uvm_info(get_type_name(), $sformatf("ACK Counter = %0d, DATA Counter = %0d",ack_count, data_count), UVM_MEDIUM)
                if (ack_count == 130) begin
                    break; // Exit the loop if ACK count reaches 130 (2 for address-only transaction + 128 for data)
                end
            end          
        end
        // 
        `uvm_info("TL_I2C_REQ_SEQ_SUCCESS", $sformatf("I2C AUX %s request transaction sent: addr=0x%0h, Data Length=0x%0d, Transaction Validity = 0x%0b",  seq_item.SPM_CMD, seq_item.SPM_Address, seq_item.SPM_LEN +1, seq_item.SPM_Transaction_VLD), UVM_MEDIUM)
    endtask


/////////////////////////////////// NATIVE AUX REQUEST TRANSACTION //////////////////////////////////

// Need to write separate task for Native AUX read and write request transactions
// As for in case of read burst fail I will re-request the whole burst
// for write burst i can start from the point where it failed based on the M value
    task native_read_request(input logic [19:0] address, [7:0] LEN);
        int ack_count = 0;
        int data_count = 0;
        seq_item = dp_tl_sequence_item::type_id::create("seq_item");

        seq_item.CTRL_Native_Failed = 1;
        seq_item.operation = NATIVE_READ;
        while (seq_item.CTRL_Native_Failed) begin
            seq_item.CTRL_Native_Failed = 0;
            
            start_item(seq_item);
                seq_item.LPM_CMD = AUX_NATIVE_READ;   // Read
                seq_item.LPM_Transaction_VLD = 1'b1;  // LPM is going to request a Native transaction 
                seq_item.LPM_Address = address;       // Address
                seq_item.LPM_LEN = LEN;               // Length
                assert(seq_item.randomize());                 // Randomize the data
            finish_item(seq_item);
            // Wait for the response from the DUT
            while ((ack_count <= seq_item.LPM_LEN) || (data_count <= seq_item.LPM_LEN)) begin
                start_item(seq_item);
                seq_item.LPM_Transaction_VLD = 1'b0; 
                seq_item.operation = WAIT_REPLY;
                finish_item(seq_item);
                get_response(seq_item);

                if (seq_item.CTRL_I2C_Failed) begin
                    `uvm_info("TL_Native_REQ_SEQ", $sformatf("Native AUX %s request transaction failed: addr=0x%0h, Data Length=0x%0d, Transaction Validity = 0x%0b",  seq_item.LPM_CMD, seq_item.LPM_Address, seq_item.LPM_LEN +1, seq_item.LPM_Transaction_VLD), UVM_MEDIUM)
                    break;
                end

                if(seq_item.LPM_NATIVE_I2C && seq_item.LPM_Reply_ACK_VLD) begin
                    if (seq_item.LPM_Reply_ACK == I2C_ACK[3:2]) begin
                        ack_count++;
                    end
                end
                else if (seq_item.LPM_NATIVE_I2C && seq_item.LPM_Reply_Data_VLD) begin
                    data_count++;
                end
                `uvm_info(get_type_name(), $sformatf("ACK Counter = %0d, DATA Counter = %0d",ack_count, data_count), UVM_MEDIUM)
            end
        end
        `uvm_info("TL_Native_REQ_SEQ", $sformatf("Native AUX %s request transaction sent: addr=0x%0h, Data Length=0x%0d, Transaction Validity = 0x%0b",  seq_item.LPM_CMD, seq_item.LPM_Address, seq_item.LPM_LEN +1, seq_item.LPM_Transaction_VLD), UVM_MEDIUM)
    endtask

//////////////////////////////////// NATIVE AUX WRITE REQUEST TRANSACTION /////////////////////////////////////////

    task native_write_request(input logic [19:0] address, input [7:0] LEN);
        int ack_count = 0;
        int burst =1;
        seq_item = dp_tl_sequence_item::type_id::create("seq_item");
    
        seq_item.CTRL_Native_Failed = 1;
        seq_item.operation = NATIVE_WRITE;
        while (seq_item.CTRL_Native_Failed) begin
            seq_item.CTRL_Native_Failed = 0;
    
            start_item(seq_item);
                seq_item.LPM_Data_queue.delete();           // Clear the queue
                seq_item.rand_mode(0);
                seq_item.LPM_Data_queue.rand_mode(1);       // randomization on for data
                seq_item.LPM_CMD = AUX_NATIVE_WRITE;  // Write
                seq_item.LPM_Transaction_VLD = 1'b1;  // LPM is going to request a Native transaction
                seq_item.LPM_Address = address;       // Address
                seq_item.LPM_LEN = LEN;               // Length
                assert(seq_item.randomize());                 // Randomize the data
                seq_item.LPM_Data = seq_item.LPM_Data_queue[0];
            finish_item(seq_item);
            repeat(seq_item.LPM_Data_queue.size()-1) begin
                while (ack_count < 1) begin
                    // Wait for the response from the DUT
                    get_response(seq_item);
                    while(~seq_item.LPM_NATIVE_I2C) begin
                        get_response(seq_item);
                    end                   
                    if (seq_item.CTRL_Native_Failed) begin
                        `uvm_info("TL_Native_REQ_SEQ", $sformatf("Native AUX %s request transaction failed: addr=0x%0h, Data Length=0x%0d, Transaction Validity = 0x%0b", seq_item.LPM_CMD, seq_item.LPM_Address, seq_item.LPM_LEN + 1, seq_item.LPM_Transaction_VLD), UVM_MEDIUM)
                        burst = 0;
                        break;
                    end else if (seq_item.LPM_Reply_ACK_VLD) begin
                        if (seq_item.LPM_Reply_ACK == AUX_ACK[1:0]) begin
                            ack_count++;
                        end 
                    end
                   
                end
                if (seq_item.CTRL_Native_Failed)
                    break; // Exit the loop if CTRL_Native_Failed is set
                ack_count = 0;
                start_item(seq_item);
                seq_item.rand_mode(0);
                    seq_item.LPM_CMD = AUX_NATIVE_WRITE;  // Write
                    seq_item.LPM_Transaction_VLD = 1'b1;  // LPM is going to request a Native transaction
                    seq_item.LPM_Address = address + burst;       // Address
                    seq_item.LPM_LEN = LEN;               // Length
                    seq_item.LPM_Data= seq_item.LPM_Data_queue[burst];
                finish_item(seq_item);
                burst++;
                get_response(seq_item);
            end
            while (ack_count < 1) begin
                // Wait for the response from the DUT
                get_response(seq_item);
                while(~seq_item.LPM_NATIVE_I2C) begin
                    get_response(seq_item);
                end
                if (seq_item.CTRL_Native_Failed) begin
                    `uvm_info("TL_Native_REQ_SEQ", $sformatf("Native AUX %s request transaction failed: addr=0x%0h, Data Length=0x%0d, Transaction Validity = 0x%0b", seq_item.LPM_CMD, seq_item.LPM_Address, seq_item.LPM_LEN + 1, seq_item.LPM_Transaction_VLD), UVM_MEDIUM)
                    burst = 0;
                    break;
                end else if (seq_item.LPM_Reply_ACK_VLD) begin
                    if (seq_item.LPM_Reply_ACK == AUX_ACK[1:0]) begin
                        ack_count++;
                    end 
                end
            end
            ack_count = 0;
        end
        `uvm_info("TL_Native_REQ_SEQ", $sformatf("Native AUX %s request transaction sent: addr=0x%0h, Data Length=0x%0d, Transaction Validity = 0x%0b", seq_item.LPM_CMD, seq_item.LPM_Address, seq_item.LPM_LEN + 1, seq_item.LPM_Transaction_VLD), UVM_MEDIUM)
    endtask

///////////////////////////////////// LINK TRAINING CR /////////////////////////////////////////

    task CR_LT();
        int ack_count = 0;
        bit done = 0;
        
        // if(!seq_item.isflow)
        // seq_item = dp_tl_sequence_item::type_id::create("seq_item");
        
        seq_item.LT_Failed = 1'b0; 
        seq_item.LT_Pass = 1'b0;
        seq_item.operation = CR_LT_op;
        `uvm_info("TL_CR_LT", $sformatf("We are inside CLOCK RECOVERY"), UVM_MEDIUM)
        // We go in the first cycle, give the LL all the max allowed values and minimum VTG and PRE
        start_item(seq_item);
        seq_item.rand_mode(1);
        // seq_item.Link_BW_CR.rand_mode(1);  // Randomize max Link rate
        // seq_item.Link_LC_CR.rand_mode(1);  // Randomize max Lane count
        // seq_item.MAX_VTG.rand_mode(1);     // Randomize max voltage swing level
        // seq_item.MAX_PRE.rand_mode(1);     // Randomize max pre-emphasis swing level
        seq_item.LPM_Transaction_VLD = 1'b0; // LPM is on
        seq_item.SPM_Transaction_VLD = 1'b0; // SPM is off
        seq_item.LPM_Start_CR = 1;           // Start the link training (Clock recovery Stage)
        seq_item.VTG = 0;                    // Set the voltage swing to 0 initially
        seq_item.PRE = 0;                    // Set the pre-emphasis to 0 initially
        seq_item.CR_DONE_VLD = 0;    
        seq_item.Driving_Param_VLD = 1'b1;   // Driving parameters are valid
        seq_item.Config_Param_VLD = 1'b1;    // Config parameters are valid
        assert(seq_item.randomize());
        finish_item(seq_item);
        // Now LL is supposed to native write all the configurations to the Sink (3 writes and 1 read)
        // Waiting for DPCD reg 0000E to be read and value be returned
        // the DPCD reg 0000E read is incorrect at this stage so was removed
        // Wait for the response from the DUT
        seq_item.MAX_PRE_in = seq_item.MAX_PRE; // Store the max PRE value for later use
        seq_item.MAX_VTG_in = seq_item.MAX_VTG; // Store the max VTG value for later use
        while(~done) begin
            get_response(seq_item);
            if (seq_item.FSM_CR_Failed) begin 
                `uvm_info("TL_Native_REQ_SEQ", $sformatf("Native AUX %s request transaction failed: addr=0x%0h, Data Length=0x%0d, Transaction Validity = 0x%0b",  seq_item.LPM_CMD, seq_item.LPM_Address, seq_item.LPM_LEN +1, seq_item.LPM_Transaction_VLD), UVM_MEDIUM)
                break;
            end 
            while(seq_item.LPM_NATIVE_I2C) begin
                start_item(seq_item);
                    seq_item.LPM_Transaction_VLD = 1'b0; // LPM is off
                    seq_item.LPM_Start_CR = 0;          
                    seq_item.Driving_Param_VLD = 1'b0;   // Driving parameters are not valid
                    seq_item.Config_Param_VLD = 1'b0;    // Config parameters are not valid
                finish_item(seq_item);
                get_response(seq_item);
            end
            if (seq_item.FSM_CR_Failed || seq_item.CTRL_Native_Failed) begin 
                `uvm_info("TL_Native_REQ_SEQ", $sformatf("Native AUX %s request transaction failed: addr=0x%0h, Data Length=0x%0d, Transaction Validity = 0x%0b",  seq_item.LPM_CMD, seq_item.LPM_Address, seq_item.LPM_LEN +1, seq_item.LPM_Transaction_VLD), UVM_MEDIUM)
                break;
            end
            else if(seq_item.LPM_Reply_ACK_VLD) begin
                if(seq_item.LPM_Reply_ACK == AUX_ACK[1:0]) begin
                    ack_count++;
                end
                if(ack_count == 3) begin
                    done = 1; 
                end
                start_item(seq_item);
                    seq_item.LPM_Transaction_VLD = 1'b0; // LPM is off
                    seq_item.LPM_Start_CR = 0; 
                    seq_item.Driving_Param_VLD = 1'b0;   // Driving parameters are not valid
                    seq_item.Config_Param_VLD = 1'b0;    // Config parameters are not valid     
                finish_item(seq_item);
                if (done)
                    get_response(seq_item);
            end
            else begin
                start_item(seq_item);
                    seq_item.LPM_Transaction_VLD = 1'b0; // LPM is off
                    seq_item.LPM_Start_CR = 0; 
                    seq_item.Driving_Param_VLD = 1'b0;   // Driving parameters are not valid
                    seq_item.Config_Param_VLD = 1'b0;    // Config parameters are not valid
                finish_item(seq_item);  
            end
            // else if(ack_count==4 && seq_item.LPM_Reply_Data_VLD) begin
            //     done = 0; 
            //     start_item(seq_item);
            //         seq_item.LPM_Transaction_VLD = 1'b0; // LPM is off
            //         seq_item.LPM_Start_CR = 0;      
            //         seq_item.Driving_Param_VLD = 1'b0;   // Driving parameters are not valid
            //         seq_item.Config_Param_VLD = 1'b0;    // Config parameters are not valid
            //     finish_item(seq_item);
            // end
        end
        done = 0;
        if(!seq_item.FSM_CR_Failed && !seq_item.CTRL_Native_Failed) begin
            // I think I will comment this to not give the link layer EQ_RD_Value now but in EQ stage.
            // start_item(seq_item);
            // seq_item.rand_mode(0);
            // seq_item.EQ_RD_Value.rand_mode(1);  // Randomize the EQ_RD_Value
            // seq_item.LPM_Transaction_VLD = 1'b0; // LPM is off
            // seq_item.Driving_Param_VLD = 1'b0;  // Driving parameters are not valid
            // seq_item.LPM_Start_CR = 0; 
            // seq_item.CR_DONE_VLD = 0; 
            // seq_item.Config_Param_VLD= 1'b0;    // Config parameters are not valid
            // assert(seq_item.randomize());
            // finish_item(seq_item);
            // get_response(seq_item);
            // if (seq_item.FSM_CR_Failed) begin 
            //     `uvm_info("TL_Native_REQ_SEQ", $sformatf("Native AUX %s request transaction failed: addr=0x%0h, Data Length=0x%0d, Transaction Validity = 0x%0b",  seq_item.LPM_CMD, seq_item.LPM_Address, seq_item.LPM_LEN +1, seq_item.LPM_Transaction_VLD), UVM_MEDIUM)
            // end
            // else begin
                ack_count = 0;
                while (~seq_item.CR_Completed) begin
                    // Wait for 202 to 207 to be read
                    while(~done) begin
                        do begin
                            start_item(seq_item);
                                seq_item.LPM_Transaction_VLD = 1'b0; // LPM is off
                            finish_item(seq_item);
                            get_response(seq_item);
                        end while(seq_item.LPM_NATIVE_I2C);
                        if (seq_item.FSM_CR_Failed || seq_item.CTRL_Native_Failed) begin
                            `uvm_info("TL_Native_REQ_SEQ", $sformatf("Native AUX %s request transaction failed: addr=0x%0h, Data Length=0x%0d, Transaction Validity = 0x%0b",  seq_item.LPM_CMD, seq_item.LPM_Address, seq_item.LPM_LEN +1, seq_item.LPM_Transaction_VLD), UVM_MEDIUM)
                            break;
                        end
                        else if(seq_item.CR_Completed) begin
                            `uvm_info("TL_CR_LT_SEQ", $sformatf("Link Training CR transaction Successful: addr=0x%0h, Data Length=0x%0d, Transaction Validity = 0x%0b",  seq_item.LPM_Address, seq_item.LPM_LEN +1, seq_item.LPM_Transaction_VLD), UVM_MEDIUM)
                            break; // Exit the loop if CR is completed
                        end
                        else if(seq_item.LPM_Reply_ACK_VLD) begin
                            if(seq_item.LPM_Reply_ACK == AUX_ACK[1:0]) begin
                                ack_count++;
                            end
                        end
                        else if(ack_count==1 && seq_item.LPM_Reply_Data_VLD) 
                            done = 0;
                        else if(ack_count==1 && !seq_item.LPM_Reply_Data_VLD)
                            done = 1;        
                    end
                    ack_count = 0;
                    done = 0;
                    if (seq_item.CR_Completed) begin
                        continue; // Exit the loop if CR is completed
                    end
                    else if(seq_item.FSM_CR_Failed || seq_item.CTRL_Native_Failed) begin
                        seq_item.LT_Failed = 1'b1; 
                        break; // Exit the loop if CR is failed
                    end
                    start_item(seq_item);
                    seq_item.rand_mode(0);
                    seq_item.VTG.rand_mode(1);
                    seq_item.PRE.rand_mode(1);
                    seq_item.CR_DONE.rand_mode(1);
                    seq_item.CR_DONE_VLD = 1'b1; // CR_DONE is valid
                    seq_item.LPM_Transaction_VLD = 1'b0;
                    seq_item.Driving_Param_VLD = 1'b1;
                    seq_item.LPM_Start_CR = 0;
                    seq_item.Config_Param_VLD= 1'b0;    // Config parameters are not valid
                    seq_item.rand_mode(1);
                    finish_item(seq_item);
                    // Wait for 103 to 106 to be written
                    while(ack_count<1) begin
                        get_response(seq_item);
                        if (seq_item.FSM_CR_Failed) begin 
                            `uvm_info("TL_Native_REQ_SEQ", $sformatf("Native AUX %s request transaction failed: addr=0x%0h, Data Length=0x%0d, Transaction Validity = 0x%0b",  seq_item.LPM_CMD, seq_item.LPM_Address, seq_item.LPM_LEN +1, seq_item.LPM_Transaction_VLD), UVM_MEDIUM)
                            break;
                        end
                        while(seq_item.LPM_NATIVE_I2C) begin
                            start_item(seq_item);
                                seq_item.LPM_Transaction_VLD = 1'b0; // LPM is off
                                seq_item.Driving_Param_VLD = 1'b0;   // Driving parameters are not valid
                            finish_item(seq_item);
                            get_response(seq_item);
                        end
                        if (seq_item.FSM_CR_Failed) begin
                            `uvm_info("TL_CR_LT_SEQ", $sformatf("Link Training CR transaction failed: addr=0x%0h, Data Length=0x%0d, Transaction Validity = 0x%0b",  seq_item.LPM_Address, seq_item.LPM_LEN +1, seq_item.LPM_Transaction_VLD), UVM_MEDIUM)
                            break;
                        end
                        else if(seq_item.CR_Completed) begin
                            `uvm_info("TL_CR_LT_SEQ", $sformatf("Link Training CR transaction Successful: addr=0x%0h, Data Length=0x%0d, Transaction Validity = 0x%0b",  seq_item.LPM_Address, seq_item.LPM_LEN +1, seq_item.LPM_Transaction_VLD), UVM_MEDIUM)
                            break; // Exit the loop if CR is completed
                        end
                        else if(seq_item.LPM_Reply_ACK_VLD) begin
                            if(seq_item.LPM_Reply_ACK == AUX_ACK[1:0]) begin
                                ack_count++;
                            end
                            else begin
                                start_item(seq_item);
                                    seq_item.LPM_Transaction_VLD = 1'b0; // LPM is off
                                    seq_item.Driving_Param_VLD = 1'b0;   // Driving parameters are not valid
                                finish_item(seq_item);
                            end
                        end
                        else begin
                            start_item(seq_item);
                                seq_item.LPM_Transaction_VLD = 1'b0; // LPM is off
                                seq_item.Driving_Param_VLD = 1'b0;   // Driving parameters are not valid
                            finish_item(seq_item);  
                        end
                    end
                    ack_count = 0;
                    if(seq_item.FSM_CR_Failed) begin
                        seq_item.LT_Failed = 1'b1; 
                        break; // Exit the loop if CR is failed
                    end
                end
            // end
        end
        else begin
            seq_item.LT_Failed = 1'b1; 
            seq_item.LPM_Start_CR = 0;      
        end
    endtask

/////////////////////////////////////////// LINK TRAINING EQ /////////////////////////////////////////

    task CR_LT_eq();
        int ack_count = 0;
        bit done = 0;
        // We go in the first cycle, give the LL all the max allowed values and minimum VTG and PRE
        start_item(seq_item);
        seq_item.rand_mode(0);
        seq_item.LPM_Transaction_VLD = 1'b0; // LPM is on
        seq_item.LPM_Start_CR = 1;           // Start the link training (Clock recovery Stage)
        seq_item.VTG = 0;                    // Set the voltage swing to 0 initially
        seq_item.PRE = 0;                    // Set the pre-emphasis to 0 initially
        seq_item.CR_DONE_VLD = 0;    
        seq_item.Driving_Param_VLD = 1'b1;   // Driving parameters are valid
        seq_item.Config_Param_VLD = 1'b0;    // Config parameters are not valid
        assert(seq_item.randomize());
        finish_item(seq_item);
        // Now LL is supposed to native write all the configurations to the Sink (3 writes and 1 read)
            // Wait for the response from the DUT
        while(~done) begin
            get_response(seq_item);
            if (seq_item.EQ_FSM_CR_Failed) begin 
                `uvm_info("TL_Native_REQ_SEQ", $sformatf("Native AUX %s request transaction failed: addr=0x%0h, Data Length=0x%0d, Transaction Validity = 0x%0b",  seq_item.LPM_CMD, seq_item.LPM_Address, seq_item.LPM_LEN +1, seq_item.LPM_Transaction_VLD), UVM_MEDIUM)
                break;
            end
            while(seq_item.LPM_NATIVE_I2C) begin
                start_item(seq_item);
                    seq_item.LPM_Transaction_VLD = 1'b0; // LPM is off
                    seq_item.Driving_Param_VLD = 1'b0;   // Driving parameters are not valid
                finish_item(seq_item);
                get_response(seq_item);
            end
            if (seq_item.EQ_FSM_CR_Failed || seq_item.CTRL_Native_Failed) begin
                `uvm_info("TL_Native_REQ_SEQ", $sformatf("Native AUX %s request transaction failed: addr=0x%0h, Data Length=0x%0d, Transaction Validity = 0x%0b",  seq_item.LPM_CMD, seq_item.LPM_Address, seq_item.LPM_LEN +1, seq_item.LPM_Transaction_VLD), UVM_MEDIUM)
                break;
            end
            else if(seq_item.LPM_Reply_ACK_VLD) begin
                if(seq_item.LPM_Reply_ACK == AUX_ACK[1:0]) begin
                    ack_count++;
                end
                if(ack_count == 3) begin
                    done = 1; 
                end
                else begin
                    start_item(seq_item);
                        seq_item.LPM_Transaction_VLD = 1'b0; // LPM is off
                        seq_item.LPM_Start_CR = 0; 
                        seq_item.Driving_Param_VLD = 1'b0;   // Driving parameters are not valid
                        seq_item.Config_Param_VLD = 1'b0;    // Config parameters are not valid     
                    finish_item(seq_item);
                end
            end
            else begin
                start_item(seq_item);
                    seq_item.LPM_Transaction_VLD = 1'b0; // LPM is off
                    seq_item.LPM_Start_CR = 0; 
                    seq_item.Driving_Param_VLD = 1'b0;   // Driving parameters are not valid
                    seq_item.Config_Param_VLD = 1'b0;    // Config parameters are not valid
                finish_item(seq_item);  
            end
        end
        done = 0;
        if(~seq_item.EQ_FSM_CR_Failed) begin
            start_item(seq_item);
            // seq_item.rand_mode(0);
            // // seq_item.EQ_RD_Value.rand_mode(1);  // Randomize the EQ_RD_Value
            // seq_item.LPM_Transaction_VLD = 1'b0; // LPM is off
            // seq_item.Driving_Param_VLD = 1'b0;  // Driving parameters are not valid
            // seq_item.LPM_Start_CR = 1'b0; 
            // seq_item.CR_DONE_VLD = 1'b0; 
            // seq_item.Config_Param_VLD= 1'b0;    // Config parameters are not valid
            // assert(seq_item.randomize());
            // finish_item(seq_item);
            // get_response(seq_item);
            ack_count = 0;
            // Waiting for DPCD reg 0000E (no) to be read and value be returned
            while (~seq_item.CR_Completed) begin
                // Wait for 202 to 207 to be read
                while(~done) begin
                    do begin
                        start_item(seq_item);
                            seq_item.LPM_Transaction_VLD = 1'b0; // LPM is off
                        finish_item(seq_item);
                        get_response(seq_item);
                    end while(seq_item.LPM_NATIVE_I2C);
                    if (seq_item.EQ_FSM_CR_Failed) begin
                        `uvm_info("TL_Native_REQ_SEQ", $sformatf("Native AUX %s request transaction failed: addr=0x%0h, Data Length=0x%0d, Transaction Validity = 0x%0b",  seq_item.LPM_CMD, seq_item.LPM_Address, seq_item.LPM_LEN +1, seq_item.LPM_Transaction_VLD), UVM_MEDIUM)
                        break;
                    end
                    else if(seq_item.LPM_Reply_ACK_VLD) begin
                        if(seq_item.LPM_Reply_ACK == AUX_ACK[1:0]) begin
                            ack_count++;
                        end
                    end
                    else if(ack_count==1 && seq_item.LPM_Reply_Data_VLD)
                        done = 0; 
                    else if(ack_count==1 && !seq_item.LPM_Reply_Data_VLD) 
                        done = 1; 
                end
                ack_count = 0;
                done = 0;
                if(seq_item.EQ_FSM_CR_Failed) begin
                    seq_item.LT_Failed = 1'b1;
                    break; // Exit the loop if CR is failed
                end
                start_item(seq_item);
                seq_item.rand_mode(0);
                seq_item.VTG.rand_mode(1);
                seq_item.PRE.rand_mode(1);
                seq_item.CR_DONE.rand_mode(1);
                seq_item.CR_DONE_VLD = 1'b1; // CR_DONE is valid
                seq_item.LPM_Transaction_VLD = 1'b0;
                seq_item.Driving_Param_VLD = 1'b1;
                seq_item.LPM_Start_CR = 0;
                seq_item.Config_Param_VLD= 1'b0;    // Config parameters are not valid
                assert(seq_item.randomize());
                finish_item(seq_item);
                // Wait for 103 to 106 to be written
                while(ack_count<1) begin
                    get_response(seq_item);
                    while(seq_item.LPM_NATIVE_I2C) begin
                        start_item(seq_item);
                            seq_item.LPM_Transaction_VLD = 1'b0; // LPM is off
                            seq_item.Driving_Param_VLD = 1'b0;   // Driving parameters are not valid
                        finish_item(seq_item);
                        get_response(seq_item);
                    end
                    if (seq_item.EQ_FSM_CR_Failed) begin
                        `uvm_info("TL_CR_LT_SEQ", $sformatf("Link Training CR transaction failed: addr=0x%0h, Data Length=0x%0d, Transaction Validity = 0x%0b",  seq_item.LPM_Address, seq_item.LPM_LEN +1, seq_item.LPM_Transaction_VLD), UVM_MEDIUM)
                        break;
                    end
                    else if(seq_item.CR_Completed) begin
                        `uvm_info("TL_CR_LT_SEQ", $sformatf("Link Training CR transaction Successful: addr=0x%0h, Data Length=0x%0d, Transaction Validity = 0x%0b",  seq_item.LPM_Address, seq_item.LPM_LEN +1, seq_item.LPM_Transaction_VLD), UVM_MEDIUM)
                        break; // Exit the loop if CR is completed
                    end
                    else if(seq_item.LPM_Reply_ACK_VLD) begin
                        if(seq_item.LPM_Reply_ACK == AUX_ACK[1:0]) begin
                            ack_count++;
                        end
                        else begin
                            start_item(seq_item);
                                seq_item.LPM_Transaction_VLD = 1'b0; // LPM is off
                                seq_item.Driving_Param_VLD = 1'b0;   // Driving parameters are not valid
                            finish_item(seq_item);
                        end
                    end
                    else begin
                        start_item(seq_item);
                            seq_item.LPM_Transaction_VLD = 1'b0; // LPM is off
                            seq_item.Driving_Param_VLD = 1'b0;   // Driving parameters are not valid
                        finish_item(seq_item);  
                    end
                end
                ack_count = 0;
                if(seq_item.EQ_FSM_CR_Failed) begin
                    seq_item.LT_Failed = 1'b1;
                    break; // Exit the loop if CR is failed
                end
            end
        end
        ack_count = 0;
    endtask

//////////////////////////////////////////////// LINK TRAINING EQ_LT /////////////////////////////////////////

    task EQ_LT();
        int ack_count = 0; // Counter to track acknowledgment responses
        bit restart= 1; // Flag to indicate if a restart is needed
        bit done = 0; 
        // Create a sequence item for link policy maker (LPM) communication
       // seq_item = dp_tl_sequence_item::type_id::create("seq_item");
       seq_item.operation = EQ_LT_op;
        
        // Loop until equalization succeeds
        while (restart) begin
            // Start sending the initial equalization sequence
            restart = 0;
            start_item(seq_item);
            seq_item.rand_mode(0);                      // Disable randomization for all fields
            seq_item.LPM_Transaction_VLD = 1'b0;        
            seq_item.EQ_Data_VLD = 0;                   // Indicate that EQ data is not valid
            seq_item.MAX_TPS_SUPPORTED_VLD = 1;         // Indicate change of max TPS
            seq_item.MAX_TPS_SUPPORTED.rand_mode(1);    // Randomize the max TPS value
            seq_item.VTG.rand_mode(1);
            seq_item.PRE.rand_mode(1);
            seq_item.Driving_Param_VLD = 1'b1;   // Driving parameters are valid

            assert(seq_item.randomize()); // Randomize enabled fields
            finish_item(seq_item); // Finish transaction
            // Wait for acknowledgment from the DUT for 2 writes and 1 read transactions
            while(~done) begin
                get_response(seq_item);
                if (seq_item.EQ_Failed) begin
                    `uvm_info("TL_Native_REQ_SEQ", $sformatf("Native AUX %s request transaction failed: addr=0x%0h, Data Length=0x%0d, Transaction Validity = 0x%0b",  seq_item.LPM_CMD, seq_item.LPM_Address, seq_item.LPM_LEN +1, seq_item.LPM_Transaction_VLD), UVM_MEDIUM)
                    break;
                end
                while(seq_item.LPM_NATIVE_I2C) begin
                    start_item(seq_item);
                        seq_item.LPM_Transaction_VLD = 1'b0; // LPM is off
                        seq_item.Driving_Param_VLD = 1'b0;   // Driving parameters are not valid
                    finish_item(seq_item);
                    get_response(seq_item);
                end
                if (seq_item.EQ_Failed) begin
                    `uvm_info("TL_Native_REQ_SEQ", $sformatf("Native AUX %s request transaction failed: addr=0x%0h, Data Length=0x%0d, Transaction Validity = 0x%0b",  seq_item.LPM_CMD, seq_item.LPM_Address, seq_item.LPM_LEN +1, seq_item.LPM_Transaction_VLD), UVM_MEDIUM)
                    break;
                end
                else if(seq_item.LPM_Reply_ACK_VLD) begin
                    if(seq_item.LPM_Reply_ACK == AUX_ACK[1:0]) begin
                        ack_count++;
                    end
                    start_item(seq_item);
                        seq_item.LPM_Transaction_VLD = 1'b0; // LPM is off
                        seq_item.Driving_Param_VLD = 1'b0;   // Driving parameters are not valid
                    finish_item(seq_item);
                end
                else if(ack_count==2 && seq_item.LPM_Reply_Data_VLD) begin
                    done = 0; 
                    start_item(seq_item);
                        seq_item.LPM_Transaction_VLD = 1'b0; // LPM is off
                        seq_item.Driving_Param_VLD = 1'b0;   // Driving parameters are not valid
                    finish_item(seq_item);
                end
                else if(ack_count==2 && !seq_item.LPM_Reply_Data_VLD) begin
                    done = 1; 
                end
                else begin
                    start_item(seq_item);
                        seq_item.LPM_Transaction_VLD = 1'b0; // LPM is off
                        seq_item.Driving_Param_VLD = 1'b0;   // Driving parameters are not valid
                    finish_item(seq_item);  
                end
            end
            done = 0;
            if (seq_item.EQ_Failed) begin
                seq_item.LT_Failed = 1'b1; 
                break;
            end 
            // start_item(seq_item);
            // seq_item.rand_mode(0);
            // seq_item.EQ_RD_Value.rand_mode(1);  // Randomize the EQ_RD_Value
            // seq_item.MAX_TPS_SUPPORTED_VLD = 0; // Indicate change of max TPS
            // seq_item.LPM_Transaction_VLD = 1'b0; // LPM is off
            // seq_item.EQ_Data_VLD = 0; // Indicate that EQ data is not valid
            // seq_item.Driving_Param_VLD = 1'b0;
            // assert(seq_item.randomize());
            // finish_item(seq_item);
            // get_response(seq_item);
            ack_count = 0;
            // wait for dut to receive EQ_RD_Value
            
            // Check Link Status registers until all conditions are met
            while (~seq_item.EQ_Failed) begin
                // Wait for 202 to 207 to be read
                while(~done) begin
                    do begin
                        start_item(seq_item);
                            seq_item.MAX_TPS_SUPPORTED_VLD = 0; // Indicate change of max TPS
                            seq_item.LPM_Transaction_VLD = 1'b0; // LPM is off
                            seq_item.EQ_Data_VLD = 0; // Indicate that EQ data is not valid
                            seq_item.Driving_Param_VLD = 1'b0;
                        finish_item(seq_item);
                        get_response(seq_item);
                    end while(seq_item.LPM_NATIVE_I2C);
                    if (seq_item.EQ_Failed) begin
                            `uvm_info("TL_Native_REQ_SEQ", $sformatf("Native AUX %s request transaction failed: addr=0x%0h, Data Length=0x%0d, Transaction Validity = 0x%0b",  seq_item.LPM_CMD, seq_item.LPM_Address, seq_item.LPM_LEN +1, seq_item.LPM_Transaction_VLD), UVM_MEDIUM)
                            break;
                    end 
                    else if(seq_item.LPM_Reply_ACK_VLD) begin
                        if(seq_item.LPM_Reply_ACK == AUX_ACK[1:0]) begin
                            ack_count++;
                        end
                    end
                    else if(ack_count==1 && seq_item.LPM_Reply_Data_VLD)
                        done = 0; 
                    else if(ack_count==1 && !seq_item.LPM_Reply_Data_VLD)
                        done = 1; 
                end
                done = 0;
                ack_count = 0; // Reset acknowledgment count
                if (seq_item.EQ_Failed) begin
                    seq_item.LT_Failed = 1'b1; 
                    break;
                end 
                // Step 4: Check EQ completion status
                start_item(seq_item);
                seq_item.rand_mode(0);
                seq_item.Lane_Align.rand_mode(1);
                seq_item.Channel_EQ.rand_mode(1);
                seq_item.Symbol_Lock.rand_mode(1);
                seq_item.EQ_CR_DN.rand_mode(1);
                seq_item.CR_DONE.rand_mode(1);
                seq_item.CR_DONE_VLD = 1'b1; // CR_DONE is valid
                seq_item.MAX_TPS_SUPPORTED_VLD = 0; // Indicate change of max TPS
                seq_item.LPM_Transaction_VLD = 1'b0;
                seq_item.EQ_Data_VLD = 1;
                seq_item.Driving_Param_VLD = 1'b1;
                seq_item.VTG.rand_mode(1);
                seq_item.PRE.rand_mode(1);
                assert(seq_item.randomize());
                finish_item(seq_item);
                
                get_response(seq_item);
                while(seq_item.LPM_NATIVE_I2C) begin
                    start_item(seq_item);
                        seq_item.LPM_Transaction_VLD = 1'b0; // LPM is off
                        seq_item.Driving_Param_VLD = 1'b0;   // Driving parameters are not valid
                    finish_item(seq_item);
                    get_response(seq_item);
                end
                if (seq_item.EQ_Failed) begin
                        `uvm_info("TL_EQ_SEQ", $sformatf("Native AUX %s request transaction failed: addr=0x%0h, Data Length=0x%0d, Transaction Validity = 0x%0b",  seq_item.LPM_CMD, seq_item.LPM_Address, seq_item.LPM_LEN +1, seq_item.LPM_Transaction_VLD), UVM_MEDIUM)
                        break;
                end
                else if(seq_item.EQ_LT_Pass) begin
                    `uvm_info("TL_EQ_SEQ", $sformatf("Link Training EQ transaction Successful: addr=0x%0h, Data Length=0x%0d, Transaction Validity = 0x%0b",  seq_item.LPM_Address, seq_item.LPM_LEN +1, seq_item.LPM_Transaction_VLD), UVM_MEDIUM)
                    break; // Exit the loop if EQ is completed
                end
                // Step 5: Check if CR is done
                else if(seq_item.EQ_FSM_CR_Failed) begin
                    CR_LT_eq(); // Call the CR_LT task to perform clock recovery
                    if(!seq_item.LT_Failed)
                        restart = 1; // Set the restart flag to indicate a restart is needed
                    break;
                end
                while(ack_count < 1) begin
                    do begin
                        start_item(seq_item);
                            seq_item.LPM_Transaction_VLD = 1'b0; // LPM is off
                            seq_item.Driving_Param_VLD = 1'b0;   // Driving parameters are not valid
                        finish_item(seq_item);
                        get_response(seq_item);
                    end while(seq_item.LPM_NATIVE_I2C);
                    if (seq_item.EQ_Failed) begin
                            `uvm_info("TL_EQ_SEQ", $sformatf("Native AUX %s request transaction failed: addr=0x%0h, Data Length=0x%0d, Transaction Validity = 0x%0b",  seq_item.LPM_CMD, seq_item.LPM_Address, seq_item.LPM_LEN +1, seq_item.LPM_Transaction_VLD), UVM_MEDIUM)
                            break;
                    end 
                    else if(seq_item.LPM_Reply_ACK_VLD) begin
                        if(seq_item.LPM_Reply_ACK == AUX_ACK[1:0]) begin
                            ack_count++;
                        end
                    end
                end
                done = 0;
                ack_count = 0; // Reset acknowledgment count
            end
            if (seq_item.EQ_Failed || seq_item.LT_Failed) begin
                seq_item.LT_Failed = 1'b1; 
                break;
            end 
            else if (restart) begin 
                continue; // Restart the loop if needed
            end
            else if(seq_item.EQ_LT_Pass) begin
                seq_item.ISO_LC = seq_item.EQ_Final_ADJ_LC;
                seq_item.ISO_BW = seq_item.EQ_Final_ADJ_BW; 
                seq_item.LT_Pass = 1'b1;
            end
            ack_count = 0;
        end
        if(~seq_item.LT_Failed && seq_item.LT_Pass) begin   
            // Step 6: Write 00h to offset 0x00102 to disable Link Training
            start_item(seq_item);
            seq_item.rand_mode(0);
            seq_item.MAX_TPS_SUPPORTED_VLD = 0; // Indicate no TPS
            seq_item.LPM_Transaction_VLD = 1'b0;
            seq_item.Driving_Param_VLD = 1'b0;
            seq_item.EQ_Data_VLD = 1'b0; // Indicate that EQ data is not valid
            assert(seq_item.randomize());
            finish_item(seq_item);
            
            // Wait for acknowledgment from the DUT for write transaction
            while(ack_count<1) begin
                get_response(seq_item);
                while(seq_item.LPM_NATIVE_I2C) begin
                    start_item(seq_item);
                        seq_item.LPM_Transaction_VLD = 1'b0; // LPM is off
                    finish_item(seq_item);
                    get_response(seq_item);
                end
                if (seq_item.CTRL_Native_Failed) begin
                    `uvm_info("TL_Native_REQ_SEQ", $sformatf("Native AUX %s request transaction failed: addr=0x%0h, Data Length=0x%0d, Transaction Validity = 0x%0b",  seq_item.LPM_CMD, seq_item.LPM_Address, seq_item.LPM_LEN +1, seq_item.LPM_Transaction_VLD), UVM_MEDIUM)
                    break;
                end
                else if(seq_item.LPM_Reply_ACK_VLD) begin
                    if(seq_item.LPM_Reply_ACK == AUX_ACK[1:0]) begin
                        ack_count++;
                    end
                    else begin
                        start_item(seq_item);
                            seq_item.LPM_Transaction_VLD = 1'b0; // LPM is off
                        finish_item(seq_item);
                    end
                end
                else begin
                    start_item(seq_item);
                        seq_item.LPM_Transaction_VLD = 1'b0; // LPM is off
                    finish_item(seq_item);  
                end
            end
        end
    endtask

    task ISO_INIT();
        if(!seq_item.isflow)
            seq_item = dp_tl_sequence_item::type_id::create("seq_item");
        start_item(seq_item);
        // seq_item.rand_mode(1);
        // seq_item.Mvid.rand_mode(1); seq_item.Nvid.rand_mode(1); seq_item.HTotal.rand_mode(1); seq_item.VTotal.rand_mode(1); seq_item.HStart.rand_mode(1); seq_item.VStart.rand_mode(1); seq_item.HSP.rand_mode(1); seq_item.VSP.rand_mode(1);
        // seq_item.HSW.rand_mode(1); seq_item.VSW.rand_mode(1); seq_item.HWidth.rand_mode(1); seq_item.VHeight.rand_mode(1); seq_item.MISC0.rand_mode(1); seq_item.MISC1.rand_mode(1);
        seq_item.SPM_Transaction_VLD = 1'b0;
        seq_item.LPM_Transaction_VLD = 1'b0;
        seq_item.SPM_MSA_VLD = 1'b1;
        seq_item.SPM_ISO_start = 1'b1;
        seq_item.operation = ISO;
        // case (seq_item.ISO_BW) // Made Case statement for SPM_Lane_BW
        //     8'h06: begin
        //             seq_item.SPM_BW_Sel = 2'b00;
        //             seq_item.SPM_Lane_BW = 16'd162; // 1.62 Gbps/lane
        //            end
        //     8'h0A: begin
        //             seq_item.SPM_BW_Sel = 2'b01;
        //             seq_item.SPM_Lane_BW = 16'd270; // 2.7 Gbps/lane
        //            end
        //     8'h14: begin
        //             seq_item.SPM_BW_Sel = 2'b10;
        //             seq_item.SPM_Lane_BW = 16'd540; // 5.4 Gbps/lane
        //            end
        //     8'h1E: begin
        //             seq_item.SPM_BW_Sel = 2'b11;
        //             seq_item.SPM_Lane_BW = 16'd810; // 8.1 Gbps/lane
        //            end
        //     default: begin
        //         seq_item.SPM_BW_Sel = 2'b00;
        //         seq_item.SPM_Lane_BW = 16'd162; // 1.62 Gbps/lane
        //         `uvm_info("TL_ISO_INIT_SEQ", $sformatf("The stored lane BW is incorrect!"), UVM_MEDIUM)
        //     end
        // endcase
        // case (seq_item.ISO_LC) // Made Case statement for SPM_Lane_Count
        //     2'b00: seq_item.SPM_Lane_Count = 3'b001; // 1 lane
        //     2'b01: seq_item.SPM_Lane_Count = 3'b010; // 2 lanes
        //     2'b11: seq_item.SPM_Lane_Count = 3'b100; // 4 lanes
        //     default: begin
        //         seq_item.SPM_Lane_Count = 3'b001; // 1 lane
        //         `uvm_info("TL_ISO_INIT_SEQ", $sformatf("The stored lane count is incorrect!"), UVM_MEDIUM)
        //     end
        // endcase
        seq_item.SPM_BW_Sel = 2'b00;
        seq_item.SPM_Lane_BW = 16'd162; // 1.62 Gbps/lane
        seq_item.SPM_Lane_Count = 3'b001; // 1 lane
        // seq_item.MS_Stm_BW.rand_mode(1); // Randomize the stream bandwidth
        seq_item.MS_Stm_BW_VLD = 1'b1; // Stream bandwidth is valid
        //seq_item.MS_Stm_BW = 10'd80; // 80MHz for now, should be randomized
        seq_item.MS_DE = 0;
        assert(seq_item.randomize());   
        seq_item.SPM_MSA[0]  = seq_item.Mvid[7:0];     seq_item.SPM_MSA[1]  = seq_item.Mvid[15:8];               seq_item.SPM_MSA[2] = seq_item.Mvid[23:16];
        seq_item.SPM_MSA[3]  = seq_item.Nvid[7:0];     seq_item.SPM_MSA[4]  = seq_item.Nvid[15:8];               seq_item.SPM_MSA[5] = seq_item.Nvid[23:16];
        seq_item.SPM_MSA[6]  = seq_item.HTotal[7:0];   seq_item.SPM_MSA[7]  = seq_item.HTotal[15:8];             seq_item.SPM_MSA[8] = seq_item.VTotal[7:0];
        seq_item.SPM_MSA[9]  = seq_item.VTotal[15:8];  seq_item.SPM_MSA[10] = seq_item.HStart[7:0];              seq_item.SPM_MSA[11] = seq_item.HStart[15:8];
        seq_item.SPM_MSA[12] = seq_item.VStart[7:0];   seq_item.SPM_MSA[13] = seq_item.VStart[15:8];             seq_item.SPM_MSA[14] = {seq_item.HSW[6:0], seq_item.HSP};
        seq_item.SPM_MSA[15] = seq_item.HSW[14:7];     seq_item.SPM_MSA[16] = {seq_item.VSW[6:0], seq_item.VSP}; seq_item.SPM_MSA[17] = seq_item.VSW[14:7];
        seq_item.SPM_MSA[18] = seq_item.HWidth[7:0];   seq_item.SPM_MSA[19] = seq_item.HWidth[15:8];             seq_item.SPM_MSA[20] = seq_item.VHeight[7:0];
        seq_item.SPM_MSA[21] = seq_item.VHeight[15:8]; seq_item.SPM_MSA[22] = seq_item.MISC0;                    seq_item.SPM_MSA[23] = seq_item.MISC1;
        // Concatenate all 24 bytes of MSA data into SPM_Full_MSA
        seq_item.SPM_Full_MSA = {seq_item.SPM_MSA[23], seq_item.SPM_MSA[22], seq_item.SPM_MSA[21], seq_item.SPM_MSA[20],
                        seq_item.SPM_MSA[19], seq_item.SPM_MSA[18], seq_item.SPM_MSA[17], seq_item.SPM_MSA[16],
                        seq_item.SPM_MSA[15], seq_item.SPM_MSA[14], seq_item.SPM_MSA[13], seq_item.SPM_MSA[12],
                        seq_item.SPM_MSA[11], seq_item.SPM_MSA[10], seq_item.SPM_MSA[9],  seq_item.SPM_MSA[8],
                        seq_item.SPM_MSA[7],  seq_item.SPM_MSA[6],  seq_item.SPM_MSA[5],  seq_item.SPM_MSA[4],
                        seq_item.SPM_MSA[3],  seq_item.SPM_MSA[2],  seq_item.SPM_MSA[1],  seq_item.SPM_MSA[0]};
        if(seq_item.HSP) // HSP is active high, so set MS_HSYNC to 0 
            seq_item.MS_HSYNC = 1'b0; // HSP is active high, so set MS_HSYNC to 0
        else
            seq_item.MS_HSYNC = 1'b1; // HSP is active low, so set MS_HSYNC to 1
        if(seq_item.VSP) // VSP is active high, so set MS_VSYNC to 0
            seq_item.MS_VSYNC = 1'b0; // VSP is active high, so set MS_VSYNC to 0
        else
            seq_item.MS_VSYNC = 1'b1; // VSP is active low, so set MS_VSYNC to 1
        if(seq_item.MISC0[7:5] == 3'b001)
            seq_item.CLOCK_PERIOD = (24/seq_item.MS_Stm_BW);
        else if(seq_item.MISC0[7:5] == 3'b100)
            seq_item.CLOCK_PERIOD = (48/seq_item.MS_Stm_BW);
        finish_item(seq_item);
        get_response(seq_item);
        `uvm_info("TL_ISO_INIT_SEQ", $sformatf("ISO_INIT_SPM: ISO_start=%0b, SPM_Lane_BW=0x%0h, SPM_Lane_Count=0x%0h, Mvid=0x%0h, Nvid=0x%0h, HTotal=0x%0h, VTotal=0x%0h, HStart=0x%0h, VStart=0x%0h, HSP=0x%0h, VSP=0x%0h, HSW=0x%0h, VSW=0x%0h, HWidth=0x%0h, VHeight=0x%0h, MISC0=0x%0h, MISC1=0x%0h", seq_item.SPM_ISO_start, seq_item.SPM_Lane_BW, seq_item.SPM_Lane_Count, seq_item.Mvid, seq_item.Nvid, seq_item.HTotal, seq_item.VTotal, seq_item.HStart, seq_item.VStart, seq_item.HSP, seq_item.VSP, seq_item.HSW, seq_item.VSW, seq_item.HWidth, seq_item.VHeight, seq_item.MISC0, seq_item.MISC1), UVM_MEDIUM); 
    endtask


    task Main_Stream(input [15:0] frames);
        int countv = 1;
        int counth = 1;
        bit new_frame;
        // New Video Stream
        repeat(frames) begin // Start new frame
            new_frame = 1;
            repeat(seq_item.VTotal) begin // Start new line
                repeat(seq_item.HTotal) begin // start new pixel
                    start_item(seq_item);
                    //seq_item.rand_mode(0);
                    seq_item.MS_Stm_BW_VLD = 1'b0; // Stream bandwidth is not valid
                    seq_item.SPM_Transaction_VLD = 1'b0;
                    if(new_frame) begin
                        seq_item.SPM_MSA_VLD = 1'b1;
                        // /*seq_item.Mvid.rand_mode(1); seq_item.Nvid.rand_mode(1);*/ seq_item.HTotal.rand_mode(1); seq_item.VTotal.rand_mode(1); seq_item.HStart.rand_mode(1); seq_item.VStart.rand_mode(1); seq_item.HSP.rand_mode(1); seq_item.VSP.rand_mode(1);
                        // seq_item.HSW.rand_mode(1); seq_item.VSW.rand_mode(1); seq_item.HWidth.rand_mode(1); seq_item.VHeight.rand_mode(1); //seq_item.MISC0.rand_mode(1); seq_item.MISC1.rand_mode(1);
                        new_frame = 0;
                    end
                    else
                        seq_item.SPM_MSA_VLD = 1'b0;
                    if(countv >= seq_item.VStart && counth >= seq_item.HStart) begin // inside active video
                        seq_item.MS_DE = 1;
                        // seq_item.MS_Pixel_Data.rand_mode(1);
                    end
                    else begin // outside active video
                        seq_item.MS_DE = 0;
                    end
                    assert(seq_item.randomize());
                    // seq_item.SPM_MSA[0]  = seq_item.Mvid[7:0];    seq_item.SPM_MSA[1]  = seq_item.Mvid[15:8];               seq_item.SPM_MSA[2] = seq_item.Mvid[23:16];
                    // seq_item.SPM_MSA[3]  = seq_item.Nvid[7:0];     seq_item.SPM_MSA[4]  = seq_item.Nvid[15:8];               seq_item.SPM_MSA[5] = seq_item.Nvid[23:16];
                    seq_item.SPM_MSA[6]  = seq_item.HTotal[7:0];   seq_item.SPM_MSA[7]  = seq_item.HTotal[15:8];             seq_item.SPM_MSA[8] = seq_item.VTotal[7:0];
                    seq_item.SPM_MSA[9]  = seq_item.VTotal[15:8];  seq_item.SPM_MSA[10] = seq_item.HStart[7:0];              seq_item.SPM_MSA[11] = seq_item.HStart[15:8];
                    seq_item.SPM_MSA[12] = seq_item.VStart[7:0];   seq_item.SPM_MSA[13] = seq_item.VStart[15:8];             seq_item.SPM_MSA[14] = {seq_item.HSW[6:0], seq_item.HSP};
                    seq_item.SPM_MSA[15] = seq_item.HSW[14:7];     seq_item.SPM_MSA[16] = {seq_item.VSW[6:0], seq_item.VSP}; seq_item.SPM_MSA[17] = seq_item.VSW[14:7];
                    seq_item.SPM_MSA[18] = seq_item.HWidth[7:0];   seq_item.SPM_MSA[19] = seq_item.HWidth[15:8];             seq_item.SPM_MSA[20] = seq_item.VHeight[7:0];
                    seq_item.SPM_MSA[21] = seq_item.VHeight[15:8]; // seq_item.SPM_MSA[22] = seq_item.MISC0;                    seq_item.SPM_MSA[23] = seq_item.MISC1;
                    // Concatenate all 24 bytes of MSA data into SPM_Full_MSA
                    seq_item.SPM_Full_MSA = {seq_item.SPM_MSA[23], seq_item.SPM_MSA[22], seq_item.SPM_MSA[21], seq_item.SPM_MSA[20],
                                    seq_item.SPM_MSA[19], seq_item.SPM_MSA[18], seq_item.SPM_MSA[17], seq_item.SPM_MSA[16],
                                    seq_item.SPM_MSA[15], seq_item.SPM_MSA[14], seq_item.SPM_MSA[13], seq_item.SPM_MSA[12],
                                    seq_item.SPM_MSA[11], seq_item.SPM_MSA[10], seq_item.SPM_MSA[9],  seq_item.SPM_MSA[8],
                                    seq_item.SPM_MSA[7],  seq_item.SPM_MSA[6],  seq_item.SPM_MSA[5],  seq_item.SPM_MSA[4],
                                    seq_item.SPM_MSA[3],  seq_item.SPM_MSA[2],  seq_item.SPM_MSA[1],  seq_item.SPM_MSA[0]};
                    if(countv >= seq_item.VFront && countv < seq_item.VFront + seq_item.VSW) begin // turn on VSYNC
                        if(seq_item.VSP) // VSP is active high, so set MS_VSYNC to  turning on VSYNC
                            seq_item.MS_VSYNC = 1'b1; // VSP is active high, so set MS_VSYNC to 1
                        else
                            seq_item.MS_VSYNC = 1'b0; // VSP is active low, so set MS_VSYNC to 0
                    end
                    else begin 
                        if(seq_item.VSP) // VSP is active high, so set MS_VSYNC to 0, turning off VSYNC
                            seq_item.MS_VSYNC = 1'b0; // VSP is active high, so set MS_VSYNC to 0
                        else
                            seq_item.MS_VSYNC = 1'b1; // VSP is active low, so set MS_VSYNC to 1
                    end
                    if(counth >= seq_item.HFront && counth < seq_item.HFront + seq_item.HSW) begin // turn on HSYNC
                        if(seq_item.HSP) // HSP is active high, so set MS_HSYNC to 1
                            seq_item.MS_HSYNC = 1'b1; // HSP is active high, so set MS_HSYNC to 1
                        else
                            seq_item.MS_HSYNC = 1'b0; // HSP is active low, so set MS_HSYNC to 0
                        counth = 0; // reset the counter    
                    end
                    else begin
                        if(seq_item.HSP) // HSP is active high, so set MS_HSYNC to 0, turning off HSYNC
                            seq_item.MS_HSYNC = 1'b0; // HSP is active high, so set MS_HSYNC to 0
                        else
                            seq_item.MS_HSYNC = 1'b1; // HSP is active low, so set MS_HSYNC to 1
                    end
                    counth++;
                    finish_item(seq_item);
                    get_response(seq_item); 
                end
                counth = 0; // reset the counter
                countv++;
            end
            countv=0;
        end
        start_item(seq_item);
        // seq_item.rand_mode(0);
        seq_item.SPM_Transaction_VLD = 1'b0;
        seq_item.SPM_MSA_VLD = 1'b0;
        seq_item.SPM_ISO_start = 1'b0; // NEED TO ADD A CONDITION FOR ERROR THAT RELATES TO THE HPD_IRQ // I think I will need to add a flag in the IRQ task that I will check here
        finish_item(seq_item);
        get_response(seq_item); 
    endtask

endclass //dp_tl_base_sequence extends superClass