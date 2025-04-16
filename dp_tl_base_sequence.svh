class dp_tl_base_sequence extends uvm_sequence #(dp_tl_spm_sequence_item, dp_tl_lpm_sequence_item);
    `uvm_object_utils(dp_tl_base_sequence);

    dp_tl_spm_sequence_item seq_item_SPM;
    dp_tl_lpm_sequence_item seq_item_LPM;

    function new(string name = "dp_tl_base_sequence");
        super.new(name);
    endfunction //new()

////////////////////////////////////// HPD //////////////////////////////////////

// HPD Detect
    task HPD_Detect_sequence ();
        
    endtask

//////////////////////////// I2C AUX REQUEST TRANSACTION //////////////////////////////////

// I2C AUX REQUEST TRANSACTION sequence
    task i2c_request(input i2c_aux_request_cmd_e CMD, logic [19:0] address);
        seq_item_SPM = dp_tl_spm_sequence_item::type_id::create("seq_item_SPM");

        int ack_count = 0;
        seq_item_SPM.CTRL_I2C_Failed = 1;

        while (seq_item_SPM.CTRL_I2C_Failed) begin
            seq_item_SPM.CTRL_I2C_Failed = 0;
            start_item(seq_item_SPM);
                seq_item_SPM.SPM_Address.rand_mode(0);    // randomization off
                seq_item_SPM.SPM_CMD.rand_mode(0);        // randomization off

                seq_item_SPM.SPM_CMD = CMD;               // Read
                seq_item_SPM.SPM_Transaction_VLD = 1'b1;  // SPM is going to request a Native transaction 
                seq_item_SPM.SPM_Address = address;       // Address
                seq_item_SPM.SPM_LEN = 0;               // Length
                // if (CMD == AUX_I2C_WRITE) begin
                //     seq_item_SPM.SPM_Data.delete();  // Clear the queue
                //     assert(seq_item_SPM.randomize() with { SPM_Data.size() == 1;});
                // end
            finish_item(seq_item_SPM);
            while(ack_count<1) begin
                // Wait for the response from the DUT
                get_response(seq_item_SPM);
                if (seq_item_SPM.CTRL_I2C_Failed) begin
                    `uvm_info("TL_I2C_REQ_SEQ", $sformatf("I2C AUX %s request transaction failed: addr=0x%0h, Data Length=0x%0d, Transaction Validity = 0x%0b",  seq_item_SPM.SPM_CMD, seq_item_SPM.SPM_Address, seq_item_SPM.SPM_LEN +1, seq_item_SPM.SPM_Transaction_VLD), UVM_MEDIUM)
                    break;
                end
                else if(seq_item_SPM.SPM_Reply_ACK_VLD) begin
                    if(seq_item_SPM.SPM_Reply_ACK == I2C_ACK[3:2]) begin
                        ack_count++;
                    end
                end
            end
        end
        // 
        `uvm_info("TL_I2C_REQ_SEQ", $sformatf("I2C AUX %s request transaction sent: addr=0x%0h, Data Length=0x%0d, Transaction Validity = 0x%0b",  seq_item_SPM.SPM_CMD, seq_item_SPM.SPM_Address, seq_item_SPM.SPM_LEN +1, seq_item_SPM.SPM_Transaction_VLD), UVM_MEDIUM)
    endtask


/////////////////////////////////// NATIVE AUX REQUEST TRANSACTION //////////////////////////////////

// Need to write separate task for Native AUX read and write request transactions
// As for in case of read burst fail I will re-request the whole burst
// for write burst i can start from the point where it failed based on the M value
    task native_read_request(input logic [19:0] address, [7:0] LEN);
        seq_item_LPM = dp_tl_lpm_sequence_item::type_id::create("seq_item_LPM");

        int ack_count = 0;
        seq_item_LPM.CTRL_Native_Failed = 1;
        while (seq_item_LPM.CTRL_Native_Failed) begin
            seq_item_LPM.CTRL_Native_Failed = 0;
            
            start_item(seq_item_LPM);
                seq_item_LPM.LPM_Address.rand_mode(0);    // randomization off
                seq_item_LPM.LPM_CMD.rand_mode(0);        // randomization off
                seq_item_LPM.LPM_LEN.rand_mode(0);        // randomization off

                seq_item_LPM.LPM_CMD = AUX_NATIVE_READ;   // Read
                seq_item_LPM.LPM_Transaction_VLD = 1'b1;  // LPM is going to request a Native transaction 
                seq_item_LPM.LPM_Address = address;       // Address
                seq_item_LPM.LPM_LEN = LEN;               // Length
                seq_item_LPM.randomize();                 // Randomize the data
            finish_item(seq_item_LPM);
            while(ack_count<1) begin
                // Wait for the response from the DUT
                get_response(seq_item_LPM);
                //seq_item_LPM.LPM_Transaction_VLD = 1'b0;
                if (seq_item_LPM.CTRL_Native_Failed) begin
                    `uvm_info("TL_Native_REQ_SEQ", $sformatf("Native AUX %s request transaction failed: addr=0x%0h, Data Length=0x%0d, Transaction Validity = 0x%0b",  seq_item_LPM.LPM_CMD, seq_item_LPM.LPM_Address, seq_item_LPM.LPM_LEN +1, seq_item_LPM.LPM_Transaction_VLD), UVM_MEDIUM)
                    break;
                end
                else if(seq_item_LPM.LPM_Reply_ACK_VLD) begin
                    if(seq_item_LPM.LPM_Reply_ACK == AUX_ACK[1:0]) begin
                        ack_count++;
                    end
                end
            end
        end
        `uvm_info("TL_Native_REQ_SEQ", $sformatf("Native AUX %s request transaction sent: addr=0x%0h, Data Length=0x%0d, Transaction Validity = 0x%0b",  seq_item_LPM.LPM_CMD, seq_item_LPM.LPM_Address, seq_item_LPM.LPM_LEN +1, seq_item_LPM.LPM_Transaction_VLD), UVM_MEDIUM)
    endtask

//////////////////////////////////// NATIVE AUX WRITE REQUEST TRANSACTION /////////////////////////////////////////

    task native_write_request(input logic [19:0] address, input [7:0] LEN);
        seq_item_LPM = dp_tl_lpm_sequence_item::type_id::create("seq_item_LPM");
    
        int ack_count = 0;
        seq_item_LPM.CTRL_Native_Failed = 1;
    
        while (seq_item_LPM.CTRL_Native_Failed) begin
            seq_item_LPM.CTRL_Native_Failed = 0;
    
            start_item(seq_item_LPM);

                seq_item_LPM.LPM_Address.rand_mode(0);    // randomization off
                seq_item_LPM.LPM_CMD.rand_mode(0);        // randomization off
                seq_item_LPM.LPM_LEN.rand_mode(0);        // randomization off
                seq_item_LPM.LPM_Data.rand_mode(1);       // randomization on for data

                seq_item_LPM.LPM_Data.delete();           // Clear the queue
                seq_item_LPM.LPM_CMD = AUX_NATIVE_WRITE;  // Write
                seq_item_LPM.LPM_Transaction_VLD = 1'b1;  // LPM is going to request a Native transaction
                seq_item_LPM.LPM_Address = address;       // Address
                seq_item_LPM.LPM_LEN = LEN;               // Length
                seq_item_LPM.randomize();                 // Randomize the data
            finish_item(seq_item_LPM);
    
            while (ack_count < 1) begin
                // Wait for the response from the DUT
                get_response(seq_item_LPM);
    
                if (seq_item_LPM.CTRL_Native_Failed) begin
                    `uvm_info("TL_Native_REQ_SEQ", $sformatf("Native AUX %s request transaction failed: addr=0x%0h, Data Length=0x%0d, Transaction Validity = 0x%0b", seq_item_LPM.LPM_CMD, seq_item_LPM.LPM_Address, seq_item_LPM.LPM_LEN + 1, seq_item_LPM.LPM_Transaction_VLD), UVM_MEDIUM)
                    break;
                end else if (seq_item_LPM.LPM_Reply_ACK_VLD) begin
                    if (seq_item_LPM.LPM_Reply_ACK == AUX_ACK[1:0]) begin
                        ack_count++;
                    end 
                end
            end
        end
    
        `uvm_info("TL_Native_REQ_SEQ", $sformatf("Native AUX %s request transaction sent: addr=0x%0h, Data Length=0x%0d, Transaction Validity = 0x%0b", seq_item_LPM.LPM_CMD, seq_item_LPM.LPM_Address, seq_item_LPM.LPM_LEN + 1, seq_item_LPM.LPM_Transaction_VLD), UVM_MEDIUM)
    endtask

///////////////////////////////////// LINK TRAINING CR /////////////////////////////////////////

    task CR_LT();
        int ack_count = 0;
        seq_item_LPM = dp_tl_lpm_sequence_item::type_id::create("seq_item_LPM");
        seq_item_LPM.FSM_CR_Failed = 1;
        while (seq_item_LPM.FSM_CR_Failed) begin
            seq_item_LPM.FSM_CR_Failed = 0;
            // We go in the first cycle, give the LL all the max allowed values nad minimum VTG and PRE
            start_item(seq_item_LPM);
            seq_item_LPM.rand_mode(0);
            seq_item_LPM.Link_BW_CR.rand_mode(1);  // Randomize max Link rate
            seq_item_LPM.Link_LC_CR.rand_mode(1);  // Randomize max Lane count
            seq_item_LPM.MAX_VTG.rand_mode(1);     // Randomize max voltage swing level
            seq_item_LPM.MAX_PRE.rand_mode(1);     // Randomize max pre-emphasis swing level
            seq_item_LPM.LPM_Transaction_VLD = 1'b1; // LPM is on
            seq_item_LPM.LPM_Start_CR = 1;           // Start the link training (Clock recovery Stage)
            seq_item_LPM.VTG = 0;                    // Set the voltage swing to 0 initially
            seq_item_LPM.PRE = 0;                    // Set the pre-emphasis to 0 initially
            seq_item_LPM.CR_DONE_VLD = 0;    
            seq_item_LPM.Driving_Param_VLD = 1'b1;   // Driving parameters are valid
            seq_item_LPM.Config_Param_VLD = 1'b1;    // Config parameters are valid
            seq_item_LPM.randomize();
            finish_item(seq_item_LPM);
            // Now LL is supposed to native write all the configurations to the Sink (3 writes and 1 read)
                // Wait for the response from the DUT
            while(ack_count<4) begin
                get_response(seq_item_LPM);
                if (seq_item_LPM.CTRL_Native_Failed) begin
                    `uvm_info("TL_Native_REQ_SEQ", $sformatf("Native AUX %s request transaction failed: addr=0x%0h, Data Length=0x%0d, Transaction Validity = 0x%0b",  seq_item_LPM.LPM_CMD, seq_item_LPM.LPM_Address, seq_item_LPM.LPM_LEN +1, seq_item_LPM.LPM_Transaction_VLD), UVM_MEDIUM)
                    break;
                end
                else if(seq_item_LPM.LPM_Reply_ACK_VLD) begin
                    if(seq_item_LPM.LPM_Reply_ACK == AUX_ACK[1:0]) begin
                        ack_count++;
                    end
                end
            end
            start_item(seq_item_LPM);
            seq_item_LPM.rand_mode(0);
            seq_item_LPM.EQ_RD_Value.rand_mode(1);  // Randomize the EQ_RD_Value
            seq_item_LPM.LPM_Transaction_VLD = 1'b1; // LPM is on
            seq_item_LPM.Driving_Param_VLD = 1'b0;  // Driving parameters are not valid
            seq_item_LPM.LPM_Start_CR = 0; 
            seq_item_LPM.CR_DONE_VLD = 0; 
            seq_item_LPM.Config_Param_VLD= 1'b0;    // Config parameters are not valid
            seq_item_LPM.randomize();
            finish_item(seq_item_LPM);
            ack_count = 0;
            // Waiting for DPCD reg 0000E to be read and value be returned
            while (~seq_item_LPM.CR_Completed) begin
                // Wait for 202 to 207 to be read
                while(ack_count<1) begin
                    get_response(seq_item_LPM);
                    if (seq_item_LPM.FSM_CR_Failed) begin
                        `uvm_info("TL_Native_REQ_SEQ", $sformatf("Native AUX %s request transaction failed: addr=0x%0h, Data Length=0x%0d, Transaction Validity = 0x%0b",  seq_item_LPM.LPM_CMD, seq_item_LPM.LPM_Address, seq_item_LPM.LPM_LEN +1, seq_item_LPM.LPM_Transaction_VLD), UVM_MEDIUM)
                        break;
                    end
                    else if(seq_item_LPM.CR_Completed) begin
                        `uvm_info("TL_CR_LT_SEQ", $sformatf("Link Training CR transaction Successful: addr=0x%0h, Data Length=0x%0d, Transaction Validity = 0x%0b",  seq_item_LPM.LPM_Address, seq_item_LPM.LPM_LEN +1, seq_item_LPM.LPM_Transaction_VLD), UVM_MEDIUM)
                        break; // Exit the loop if CR is completed
                    end
                    else if(seq_item_LPM.LPM_Reply_ACK_VLD) begin
                        if(seq_item_LPM.LPM_Reply_ACK == AUX_ACK[1:0]) begin
                            ack_count++;
                        end
                    end
                end
                ack_count = 0;
                if (seq_item_LPM.CR_Completed) begin
                    continue; // Exit the loop if CR is completed
                end
                start_item(seq_item_LPM);
                seq_item_LPM.rand_mode(0);
                seq_item_LPM.VTG.rand_mode(1);
                seq_item_LPM.PRE.rand_mode(1);
                seq_item_LPM.CR_DONE.rand_mode(1);
                seq_item_LPM.CR_DONE_VLD = 1'b1; // CR_DONE is valid
                seq_item_LPM.LPM_Transaction_VLD = 1'b1;
                seq_item_LPM.Driving_Param_VLD = 1'b1;
                seq_item_LPM.LPM_Start_CR = 0;
                seq_item_LPM.Config_Param_VLD= 1'b0;    // Config parameters are not valid
                seq_item_LPM.randomize();
                finish_item(seq_item_LPM);
                // Wait for 103 to 106 to be written
                while(ack_count<1) begin
                    get_response(seq_item_LPM);
                    if (seq_item_LPM.FSM_CR_Failed) begin
                        `uvm_info("TL_CR_LT_SEQ", $sformatf("Link Training CR transaction failed: addr=0x%0h, Data Length=0x%0d, Transaction Validity = 0x%0b",  seq_item_LPM.LPM_Address, seq_item_LPM.LPM_LEN +1, seq_item_LPM.LPM_Transaction_VLD), UVM_MEDIUM)
                        break;
                    end
                    else if(seq_item_LPM.CR_Completed) begin
                        `uvm_info("TL_CR_LT_SEQ", $sformatf("Link Training CR transaction Successful: addr=0x%0h, Data Length=0x%0d, Transaction Validity = 0x%0b",  seq_item_LPM.LPM_Address, seq_item_LPM.LPM_LEN +1, seq_item_LPM.LPM_Transaction_VLD), UVM_MEDIUM)
                        break; // Exit the loop if CR is completed
                    end
                    else if(seq_item_LPM.LPM_Reply_ACK_VLD) begin
                        if(seq_item_LPM.LPM_Reply_ACK == AUX_ACK[1:0]) begin
                            ack_count++;
                        end
                    end
                end
                ack_count = 0;
            end
        end
    endtask

/////////////////////////////////////////// LINK TRAINING EQ /////////////////////////////////////////

    task CR_LT_eq();
        ack_count = 0;
        seq_item_LPM.FSM_CR_Failed = 1;
        while (seq_item_LPM.FSM_CR_Failed) begin
            seq_item_LPM.FSM_CR_Failed = 0;
            // We go in the first cycle, give the LL all the max allowed values nad minimum VTG and PRE
            start_item(seq_item_LPM);
            seq_item_LPM.rand_mode(0);
            seq_item_LPM.LPM_Transaction_VLD = 1'b1; // LPM is on
            seq_item_LPM.LPM_Start_CR = 1;           // Start the link training (Clock recovery Stage)
            seq_item_LPM.VTG = 0;                    // Set the voltage swing to 0 initially
            seq_item_LPM.PRE = 0;                    // Set the pre-emphasis to 0 initially
            seq_item_LPM.CR_DONE_VLD = 0;    
            seq_item_LPM.Driving_Param_VLD = 1'b1;   // Driving parameters are valid
            seq_item_LPM.Config_Param_VLD = 1'b0;    // Config parameters are not valid
            seq_item_LPM.randomize();
            finish_item(seq_item_LPM);
            // Now LL is supposed to native write all the configurations to the Sink (3 writes and 1 read)
                // Wait for the response from the DUT
            while(ack_count<4) begin
                get_response(seq_item_LPM);
                if (seq_item_LPM.CTRL_Native_Failed) begin
                    `uvm_info("TL_Native_REQ_SEQ", $sformatf("Native AUX %s request transaction failed: addr=0x%0h, Data Length=0x%0d, Transaction Validity = 0x%0b",  seq_item_LPM.LPM_CMD, seq_item_LPM.LPM_Address, seq_item_LPM.LPM_LEN +1, seq_item_LPM.LPM_Transaction_VLD), UVM_MEDIUM)
                    break;
                end
                else if(seq_item_LPM.LPM_Reply_ACK_VLD) begin
                    if(seq_item_LPM.LPM_Reply_ACK == AUX_ACK[1:0]) begin
                        ack_count++;
                    end
                end
            end
            start_item(seq_item_LPM);
            seq_item_LPM.rand_mode(0);
            seq_item_LPM.EQ_RD_Value.rand_mode(1);  // Randomize the EQ_RD_Value
            seq_item_LPM.LPM_Transaction_VLD = 1'b1; // LPM is on
            seq_item_LPM.Driving_Param_VLD = 1'b0;  // Driving parameters are not valid
            seq_item_LPM.LPM_Start_CR = 1'b0; 
            seq_item_LPM.CR_DONE_VLD = 1'b0; 
            seq_item_LPM.Config_Param_VLD= 1'b0;    // Config parameters are not valid
            seq_item_LPM.randomize();
            finish_item(seq_item_LPM);
            ack_count = 0;
            // Waiting for DPCD reg 0000E to be read and value be returned
            while (~seq_item_LPM.CR_Completed) begin
                // Wait for 202 to 207 to be read
                while(ack_count<1) begin
                    get_response(seq_item_LPM);
                    if (seq_item_LPM.FSM_CR_Failed) begin
                        `uvm_info("TL_Native_REQ_SEQ", $sformatf("Native AUX %s request transaction failed: addr=0x%0h, Data Length=0x%0d, Transaction Validity = 0x%0b",  seq_item_LPM.LPM_CMD, seq_item_LPM.LPM_Address, seq_item_LPM.LPM_LEN +1, seq_item_LPM.LPM_Transaction_VLD), UVM_MEDIUM)
                        break;
                    end
                    else if(seq_item_LPM.CR_Completed) begin
                        `uvm_info("TL_CR_LT_SEQ", $sformatf("Link Training CR transaction Successful: addr=0x%0h, Data Length=0x%0d, Transaction Validity = 0x%0b",  seq_item_LPM.LPM_Address, seq_item_LPM.LPM_LEN +1, seq_item_LPM.LPM_Transaction_VLD), UVM_MEDIUM)
                        break; // Exit the loop if CR is completed
                    end
                    else if(seq_item_LPM.LPM_Reply_ACK_VLD) begin
                        if(seq_item_LPM.LPM_Reply_ACK == AUX_ACK[1:0]) begin
                            ack_count++;
                        end
                    end
                end
                ack_count = 0;
                if (seq_item_LPM.CR_Completed) begin
                    continue; // Exit the loop if CR is completed
                end
                start_item(seq_item_LPM);
                seq_item_LPM.rand_mode(0);
                seq_item_LPM.VTG.rand_mode(1);
                seq_item_LPM.PRE.rand_mode(1);
                seq_item_LPM.CR_DONE.rand_mode(1);
                seq_item_LPM.CR_DONE_VLD = 1'b1; // CR_DONE is valid
                seq_item_LPM.LPM_Transaction_VLD = 1'b1;
                seq_item_LPM.Driving_Param_VLD = 1'b1;
                seq_item_LPM.LPM_Start_CR = 0;
                seq_item_LPM.Config_Param_VLD= 1'b0;    // Config parameters are not valid
                seq_item_LPM.randomize();
                finish_item(seq_item_LPM);
                // Wait for 103 to 106 to be written
                while(ack_count<1) begin
                    get_response(seq_item_LPM);
                    if (seq_item_LPM.FSM_CR_Failed) begin
                        `uvm_info("TL_CR_LT_SEQ", $sformatf("Link Training CR transaction failed: addr=0x%0h, Data Length=0x%0d, Transaction Validity = 0x%0b",  seq_item_LPM.LPM_Address, seq_item_LPM.LPM_LEN +1, seq_item_LPM.LPM_Transaction_VLD), UVM_MEDIUM)
                        break;
                    end
                    else if(seq_item_LPM.CR_Completed) begin
                        `uvm_info("TL_CR_LT_SEQ", $sformatf("Link Training CR transaction Successful: addr=0x%0h, Data Length=0x%0d, Transaction Validity = 0x%0b",  seq_item_LPM.LPM_Address, seq_item_LPM.LPM_LEN +1, seq_item_LPM.LPM_Transaction_VLD), UVM_MEDIUM)
                        break; // Exit the loop if CR is completed
                    end
                    else if(seq_item_LPM.LPM_Reply_ACK_VLD) begin
                        if(seq_item_LPM.LPM_Reply_ACK == AUX_ACK[1:0]) begin
                            ack_count++;
                        end
                    end
                end
                ack_count = 0;
            end
        end
    endtask

//////////////////////////////////////////////// LINK TRAINING EQ_LT /////////////////////////////////////////

    task EQ_LT();
        int ack_count = 0; // Counter to track acknowledgment responses
        bit restart= 1; // Flag to indicate if a restart is needed
        // Create a sequence item for link policy maker (LPM) communication
        seq_item_LPM = dp_tl_lpm_sequence_item::type_id::create("seq_item_LPM");
        
        // Loop until equalization succeeds
        while (restart) begin
            // Start sending the initial equalization sequence
            restart = 0;
            start_item(seq_item_LPM);
            seq_item_LPM.rand_mode(0);                      // Disable randomization for all fields
            seq_item_LPM.LPM_Transaction_VLD = 1'b1;        // Mark transaction as valid
            seq_item_LPM.EQ_Data_VLD = 0;                   // Indicate that EQ data is not valid
            seq_item_LPM.TPS_VLD = 1;                       // Indicate change of max TPS
            seq_item_LPM.MAX_TPS_SUPPORTED.rand_mode(1);    // Randomize the max TPS value
            seq_item_LPM.VTG.rand_mode(1);
            seq_item_LPM.PRE.rand_mode(1);
            seq_item_LPM.Driving_Param_VLD = 1'b1;   // Driving parameters are valid

            seq_item_LPM.randomize(); // Randomize enabled fields
            finish_item(seq_item_LPM); // Finish transaction
            // Wait for acknowledgment from the DUT for 2 writes and 1 read transactions
            while(ack_count<3) begin
                get_response(seq_item_LPM);
                if (seq_item_LPM.CTRL_Native_Failed) begin
                    `uvm_info("TL_Native_REQ_SEQ", $sformatf("Native AUX %s request transaction failed: addr=0x%0h, Data Length=0x%0d, Transaction Validity = 0x%0b",  seq_item_LPM.LPM_CMD, seq_item_LPM.LPM_Address, seq_item_LPM.LPM_LEN +1, seq_item_LPM.LPM_Transaction_VLD), UVM_MEDIUM)
                    break;
                end
                else if(seq_item_LPM.LPM_Reply_ACK_VLD) begin
                    if(seq_item_LPM.LPM_Reply_ACK == AUX_ACK[1:0]) begin
                        ack_count++;
                    end
                end
            end
        
            start_item(seq_item_LPM);
            seq_item_LPM.rand_mode(0);
            seq_item_LPM.EQ_RD_Value.rand_mode(1);  // Randomize the EQ_RD_Value
            seq_item_LPM.TPS_VLD = 0; // Indicate change of max TPS
            seq_item_LPM.LPM_Transaction_VLD = 1'b1; // LPM is on
            seq_item_LPM.EQ_Data_VLD = 0; // Indicate that EQ data is not valid
            seq_item_LPM.Driving_Param_VLD = 1'b0;
            seq_item_LPM.randomize();
            finish_item(seq_item_LPM);
            ack_count = 0;
            // wait for dut to receive EQ_RD_Value
            
            // Check Link Status registers until all conditions are met
            while (~seq_item_LPM.EQ_LT_Pass) begin
                // Wait for 202 to 207 to be read
                while(ack_count < 1) begin
                    get_response(seq_item_LPM);
                    if (seq_item_LPM.EQ_Failed) begin
                            `uvm_info("TL_Native_REQ_SEQ", $sformatf("Native AUX %s request transaction failed: addr=0x%0h, Data Length=0x%0d, Transaction Validity = 0x%0b",  seq_item_LPM.LPM_CMD, seq_item_LPM.LPM_Address, seq_item_LPM.LPM_LEN +1, seq_item_LPM.LPM_Transaction_VLD), UVM_MEDIUM)
                            break;
                    end 
                    else if(seq_item_LPM.LPM_Reply_ACK_VLD) begin
                        if(seq_item_LPM.LPM_Reply_ACK == AUX_ACK[1:0]) begin
                            ack_count++;
                        end
                    end
                end

                ack_count = 0; // Reset acknowledgment count
                
                // Step 4: Check EQ completion status
                start_item(seq_item_LPM);
                seq_item_LPM.rand_mode(0);
                seq_item_LPM.Lane_Align.rand_mode(1);
                seq_item_LPM.Channel_EQ.rand_mode(1);
                seq_item_LPM.Symbol_Locked.rand_mode(1);
                seq_item_LPM.EQ_CR_DN.rand_mode(1);
                seq_item_LPM.TPS_VLD = 0; // Indicate change of max TPS
                seq_item_LPM.LPM_Transaction_VLD = 1'b1;
                seq_item_LPM.EQ_Data_VLD = 1;
                seq_item_LPM.Driving_Param_VLD = 1'b1;
                seq_item_LPM.VTG.rand_mode(1);
                seq_item_LPM.PRE.rand_mode(1);
                seq_item_LPM.randomize();
                finish_item(seq_item_LPM);
                
                get_response(seq_item_LPM);
                // Step 5: Check if CR is done
                if(seq_item_LPM.EQ_CR_Failed) begin
                    CR_LT_eq(); // Call the CR_LT task to perform clock recovery
                    restart = 1; // Set the restart flag to indicate a restart is needed
                    break;
                end
                while(ack_count < 1) begin
                    if (seq_item_LPM.EQ_Failed) begin
                            `uvm_info("TL_EQ_SEQ", $sformatf("Native AUX %s request transaction failed: addr=0x%0h, Data Length=0x%0d, Transaction Validity = 0x%0b",  seq_item_LPM.LPM_CMD, seq_item_LPM.LPM_Address, seq_item_LPM.LPM_LEN +1, seq_item_LPM.LPM_Transaction_VLD), UVM_MEDIUM)
                            break;
                    end 
                    else if(seq_item_LPM.LPM_Reply_ACK_VLD) begin
                        if(seq_item_LPM.LPM_Reply_ACK == AUX_ACK[1:0]) begin
                            ack_count++;
                        end
                    end
                    get_response(seq_item_LPM);
                end
                ack_count = 0; // Reset acknowledgment count
            end
        end   
        if (restart) begin 
            continue; // Restart the loop if needed
        end
    // Step 6: Write 00h to offset 0x00102 to disable Link Training
        start_item(seq_item_LPM);
        seq_item_LPM.rand_mode(0);
        seq_item_LPM.TPS_VLD = 0; // Indicate no TPS
        seq_item_LPM.LPM_Transaction_VLD = 1'b0;
        seq_item_LPM.Driving_Param_VLD = 1'b0;
        seq_item_LPM.EQ_Data_VLD = 1'b0; // Indicate that EQ data is not valid
        seq_item_LPM.randomize();
        finish_item(seq_item_LPM);
        
        get_response(seq_item_LPM);
        // Wait for acknowledgment from the DUT for write transaction
        while(ack_count<1) begin
            get_response(seq_item_LPM);
            if (seq_item_LPM.CTRL_Native_Failed) begin
                `uvm_info("TL_Native_REQ_SEQ", $sformatf("Native AUX %s request transaction failed: addr=0x%0h, Data Length=0x%0d, Transaction Validity = 0x%0b",  seq_item_LPM.LPM_CMD, seq_item_LPM.LPM_Address, seq_item_LPM.LPM_LEN +1, seq_item_LPM.LPM_Transaction_VLD), UVM_MEDIUM)
                break;
            end
            else if(seq_item_LPM.LPM_Reply_ACK_VLD) begin
                if(seq_item_LPM.LPM_Reply_ACK == AUX_ACK[1:0]) begin
                    ack_count++;
                end
            end
        end
    endtask

    // Prevent the base sequence from running directly
    task body();
        `uvm_fatal("TL_BASE_SEQ", "Base sequence should not be executed directly!")
    endtask
endclass //dp_tl_base_sequence extends superClass