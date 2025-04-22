import uvm_pkg::*;
    `include "uvm_macros.svh"

import dp_transactions_pkg::*;

class dp_tl_base_sequence extends uvm_sequence #(dp_tl_sequence_item);
    `uvm_object_utils(dp_tl_base_sequence);

    dp_tl_sequence_item seq_item;

    function new(string name = "dp_tl_base_sequence");
        super.new(name);
    endfunction //new()

/////////////////////////// Reset /////////////////////////////////////
task reset_task();
    // Reset the DUT and wait for it to be ready
    `uvm_info(get_type_name(), "Resetting DUT", UVM_MEDIUM)
    seq_item = dp_tl_sequence_item::type_id::create("seq_item");
    start_item(seq_item);
        seq_item.operation = reset_op;
        seq_item.LPM_Transaction_VLD = 1'b1; // LPM is on
    finish_item(seq_item);
    `uvm_info(get_type_name(), "DUT Reset complete", UVM_MEDIUM)
    
endtask


////////////////////////////////////// HPD //////////////////////////////////////

// // HPD Detect
//     task HPD_Detect_sequence ();
        
//     endtask

//////////////////////////// I2C AUX REQUEST TRANSACTION //////////////////////////////////

// I2C AUX REQUEST TRANSACTION sequence
    task i2c_request(input i2c_aux_request_cmd_e CMD, logic [19:0] address);
        int ack_count = 0;
        seq_item = dp_tl_sequence_item::type_id::create("seq_item");

        seq_item.CTRL_I2C_Failed = 1;

        while (seq_item.CTRL_I2C_Failed) begin
            seq_item.CTRL_I2C_Failed = 0;
            start_item(seq_item);
                seq_item.SPM_Address.rand_mode(0);    // randomization off
                seq_item.SPM_CMD.rand_mode(0);        // randomization off

                seq_item.SPM_CMD = CMD;               // Read
                seq_item.SPM_Transaction_VLD = 1'b1;  // SPM is going to request a Native transaction 
                seq_item.SPM_Address = address;       // Address
                seq_item.SPM_LEN = 0;               // Length
                // if (CMD == AUX_I2C_WRITE) begin
                //     seq_item.SPM_Data.delete();  // Clear the queue
                //     assert(seq_item.randomize() with { SPM_Data.size() == 1;});
                // end
            finish_item(seq_item);
            while(ack_count<1) begin
                // Wait for the response from the DUT
                get_response(seq_item);
                if(seq_item.SPM_NATIVE_I2C) begin
                    if (seq_item.CTRL_I2C_Failed) begin
                        `uvm_info("TL_I2C_REQ_SEQ", $sformatf("I2C AUX %s request transaction failed: addr=0x%0h, Data Length=0x%0d, Transaction Validity = 0x%0b",  seq_item.SPM_CMD, seq_item.SPM_Address, seq_item.SPM_LEN +1, seq_item.SPM_Transaction_VLD), UVM_MEDIUM)
                        break;
                    end
                    else if(seq_item.SPM_Reply_ACK_VLD) begin
                        if(seq_item.SPM_Reply_ACK == I2C_ACK[3:2]) begin
                            ack_count++;
                        end
                    end
                end
            end
            ack_count = 0;
        end
        // 
        `uvm_info("TL_I2C_REQ_SEQ", $sformatf("I2C AUX %s request transaction sent: addr=0x%0h, Data Length=0x%0d, Transaction Validity = 0x%0b",  seq_item.SPM_CMD, seq_item.SPM_Address, seq_item.SPM_LEN +1, seq_item.SPM_Transaction_VLD), UVM_MEDIUM)
    endtask


/////////////////////////////////// NATIVE AUX REQUEST TRANSACTION //////////////////////////////////

// Need to write separate task for Native AUX read and write request transactions
// As for in case of read burst fail I will re-request the whole burst
// for write burst i can start from the point where it failed based on the M value
    task native_read_request(input logic [19:0] address, [7:0] LEN);
        int ack_count = 0;
        seq_item = dp_tl_sequence_item::type_id::create("seq_item");

        seq_item.CTRL_Native_Failed = 1;
        while (seq_item.CTRL_Native_Failed) begin
            seq_item.CTRL_Native_Failed = 0;
            
            start_item(seq_item);
                seq_item.LPM_CMD = AUX_NATIVE_READ;   // Read
                seq_item.LPM_Transaction_VLD = 1'b1;  // LPM is going to request a Native transaction 
                seq_item.LPM_Address = address;       // Address
                seq_item.LPM_LEN = LEN;               // Length
                assert(seq_item.randomize());                 // Randomize the data
            finish_item(seq_item);
            while(ack_count<1) begin
                // Wait for the response from the DUT
                get_response(seq_item);
                //seq_item.LPM_Transaction_VLD = 1'b0;
                if(seq_item.LPM_NATIVE_I2C) begin
                    if (seq_item.CTRL_Native_Failed) begin
                        `uvm_info("TL_Native_REQ_SEQ", $sformatf("Native AUX %s request transaction failed: addr=0x%0h, Data Length=0x%0d, Transaction Validity = 0x%0b",  seq_item.LPM_CMD, seq_item.LPM_Address, seq_item.LPM_LEN +1, seq_item.LPM_Transaction_VLD), UVM_MEDIUM)
                        break;
                    end
                    else if(seq_item.LPM_Reply_ACK_VLD) begin
                        if(seq_item.LPM_Reply_ACK == AUX_ACK[1:0]) begin
                            ack_count++;
                        end
                    end
                end
            end
            ack_count = 0;
            while (ack_count < LEN) begin
                get_response(seq_item);
                if(seq_item.LPM_NATIVE_I2C && seq_item.LPM_Reply_Data_VLD)
                    ack_count++;
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
                    if(seq_item.LPM_NATIVE_I2C) begin
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
            end
            while (ack_count < 1) begin
                // Wait for the response from the DUT
                get_response(seq_item);
                if(seq_item.LPM_NATIVE_I2C) begin
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
            end
            ack_count = 0;
        end
        `uvm_info("TL_Native_REQ_SEQ", $sformatf("Native AUX %s request transaction sent: addr=0x%0h, Data Length=0x%0d, Transaction Validity = 0x%0b", seq_item.LPM_CMD, seq_item.LPM_Address, seq_item.LPM_LEN + 1, seq_item.LPM_Transaction_VLD), UVM_MEDIUM)
    endtask

///////////////////////////////////// LINK TRAINING CR /////////////////////////////////////////

    task CR_LT();
        int ack_count = 0;
        bit done = 0;
        seq_item = dp_tl_sequence_item::type_id::create("seq_item");
        seq_item.FSM_CR_Failed = 1;
        while (seq_item.FSM_CR_Failed) begin
            seq_item.FSM_CR_Failed = 0;
            // We go in the first cycle, give the LL all the max allowed values nad minimum VTG and PRE
            start_item(seq_item);
            seq_item.rand_mode(0);
            seq_item.Link_BW_CR.rand_mode(1);  // Randomize max Link rate
            seq_item.Link_LC_CR.rand_mode(1);  // Randomize max Lane count
            seq_item.MAX_VTG.rand_mode(1);     // Randomize max voltage swing level
            seq_item.MAX_PRE.rand_mode(1);     // Randomize max pre-emphasis swing level
            seq_item.LPM_Transaction_VLD = 1'b1; // LPM is on
            seq_item.LPM_Start_CR = 1;           // Start the link training (Clock recovery Stage)
            seq_item.VTG = 0;                    // Set the voltage swing to 0 initially
            seq_item.PRE = 0;                    // Set the pre-emphasis to 0 initially
            seq_item.CR_DONE_VLD = 0;    
            seq_item.Driving_Param_VLD = 1'b1;   // Driving parameters are valid
            seq_item.Config_Param_VLD = 1'b1;    // Config parameters are valid
            assert(seq_item.randomize());
            finish_item(seq_item);
            // Now LL is supposed to native write all the configurations to the Sink (3 writes and 1 read)
                // Wait for the response from the DUT
            while(~done) begin
                get_response(seq_item);
                if(seq_item.LPM_NATIVE_I2C) begin
                    if (seq_item.CTRL_Native_Failed) begin
                        `uvm_info("TL_Native_REQ_SEQ", $sformatf("Native AUX %s request transaction failed: addr=0x%0h, Data Length=0x%0d, Transaction Validity = 0x%0b",  seq_item.LPM_CMD, seq_item.LPM_Address, seq_item.LPM_LEN +1, seq_item.LPM_Transaction_VLD), UVM_MEDIUM)
                        break;
                    end
                    else if(seq_item.LPM_Reply_ACK_VLD) begin
                        if(seq_item.LPM_Reply_ACK == AUX_ACK[1:0]) begin
                            ack_count++;
                        end
                    end
                    else if(ack_count==4 && seq_item.LPM_Reply_Data_VLD)
                        done = 0; 
                    else if(ack_count==4 && !seq_item.LPM_Reply_Data_VLD)
                        done = 1; 
                end
            end
            done = 0;
            start_item(seq_item);
            seq_item.rand_mode(0);
            seq_item.EQ_RD_Value.rand_mode(1);  // Randomize the EQ_RD_Value
            seq_item.LPM_Transaction_VLD = 1'b1; // LPM is on
            seq_item.Driving_Param_VLD = 1'b0;  // Driving parameters are not valid
            seq_item.LPM_Start_CR = 0; 
            seq_item.CR_DONE_VLD = 0; 
            seq_item.Config_Param_VLD= 1'b0;    // Config parameters are not valid
            assert(seq_item.randomize());
            finish_item(seq_item);
            ack_count = 0;
            // Waiting for DPCD reg 0000E to be read and value be returned
            while (~seq_item.CR_Completed) begin
                // Wait for 202 to 207 to be read
                while(~done) begin
                    get_response(seq_item);
                    if(seq_item.LPM_NATIVE_I2C) begin
                        if (seq_item.FSM_CR_Failed) begin
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
                end
                ack_count = 0;
                done = 0;
                if (seq_item.CR_Completed) begin
                    continue; // Exit the loop if CR is completed
                end
                else if(seq_item.FSM_CR_Failed) begin
                    break; // Exit the loop if CR is failed
                end
                start_item(seq_item);
                seq_item.rand_mode(0);
                seq_item.VTG.rand_mode(1);
                seq_item.PRE.rand_mode(1);
                seq_item.CR_DONE.rand_mode(1);
                seq_item.CR_DONE_VLD = 1'b1; // CR_DONE is valid
                seq_item.LPM_Transaction_VLD = 1'b1;
                seq_item.Driving_Param_VLD = 1'b1;
                seq_item.LPM_Start_CR = 0;
                seq_item.Config_Param_VLD= 1'b0;    // Config parameters are not valid
                seq_item.rand_mode(1);
                finish_item(seq_item);
                // Wait for 103 to 106 to be written
                while(ack_count<1) begin
                    get_response(seq_item);
                    if(seq_item.LPM_NATIVE_I2C) begin
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
                        end
                    end
                end
                ack_count = 0;
                if(seq_item.FSM_CR_Failed) begin
                    break; // Exit the loop if CR is failed
                end
            end
            ack_count = 0;
        end
    endtask

/////////////////////////////////////////// LINK TRAINING EQ /////////////////////////////////////////

    task CR_LT_eq();
        int ack_count = 0;
        bit done = 0;
        seq_item.FSM_CR_Failed = 1;
        while (seq_item.FSM_CR_Failed) begin
            seq_item.FSM_CR_Failed = 0;
            // We go in the first cycle, give the LL all the max allowed values nad minimum VTG and PRE
            start_item(seq_item);
            seq_item.rand_mode(0);
            seq_item.LPM_Transaction_VLD = 1'b1; // LPM is on
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
                if(seq_item.LPM_NATIVE_I2C) begin
                    if (seq_item.CTRL_Native_Failed) begin
                        `uvm_info("TL_Native_REQ_SEQ", $sformatf("Native AUX %s request transaction failed: addr=0x%0h, Data Length=0x%0d, Transaction Validity = 0x%0b",  seq_item.LPM_CMD, seq_item.LPM_Address, seq_item.LPM_LEN +1, seq_item.LPM_Transaction_VLD), UVM_MEDIUM)
                        break;
                    end
                    else if(seq_item.LPM_Reply_ACK_VLD) begin
                        if(seq_item.LPM_Reply_ACK == AUX_ACK[1:0]) begin
                            ack_count++;
                        end
                    end
                    else if(ack_count==4 && seq_item.LPM_Reply_Data_VLD)
                        done = 0; 
                    else if(ack_count==4 && !seq_item.LPM_Reply_Data_VLD)
                        done = 1; 
                end
            end
            done = 0;
            start_item(seq_item);
            seq_item.rand_mode(0);
            seq_item.EQ_RD_Value.rand_mode(1);  // Randomize the EQ_RD_Value
            seq_item.LPM_Transaction_VLD = 1'b1; // LPM is on
            seq_item.Driving_Param_VLD = 1'b0;  // Driving parameters are not valid
            seq_item.LPM_Start_CR = 1'b0; 
            seq_item.CR_DONE_VLD = 1'b0; 
            seq_item.Config_Param_VLD= 1'b0;    // Config parameters are not valid
            assert(seq_item.randomize());
            finish_item(seq_item);
            ack_count = 0;
            // Waiting for DPCD reg 0000E to be read and value be returned
            while (~seq_item.CR_Completed) begin
                // Wait for 202 to 207 to be read
                while(~done) begin
                    get_response(seq_item);
                    if(seq_item.LPM_NATIVE_I2C) begin
                        if (seq_item.FSM_CR_Failed) begin
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
                end
                ack_count = 0;
                done = 0;
                if (seq_item.CR_Completed) begin
                    continue; // Exit the loop if CR is completed
                end
                else if(seq_item.FSM_CR_Failed) begin
                    break; // Exit the loop if CR is failed
                end
                start_item(seq_item);
                seq_item.rand_mode(0);
                seq_item.VTG.rand_mode(1);
                seq_item.PRE.rand_mode(1);
                seq_item.CR_DONE.rand_mode(1);
                seq_item.CR_DONE_VLD = 1'b1; // CR_DONE is valid
                seq_item.LPM_Transaction_VLD = 1'b1;
                seq_item.Driving_Param_VLD = 1'b1;
                seq_item.LPM_Start_CR = 0;
                seq_item.Config_Param_VLD= 1'b0;    // Config parameters are not valid
                assert(seq_item.randomize());
                finish_item(seq_item);
                // Wait for 103 to 106 to be written
                while(ack_count<1) begin
                    get_response(seq_item);
                    if(seq_item.LPM_NATIVE_I2C) begin
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
                        end
                    end
                end
                ack_count = 0;
                if(seq_item.FSM_CR_Failed) begin
                    break; // Exit the loop if CR is failed
                end
            end
            ack_count = 0;
        end
    endtask

//////////////////////////////////////////////// LINK TRAINING EQ_LT /////////////////////////////////////////

    task EQ_LT();
        int ack_count = 0; // Counter to track acknowledgment responses
        bit restart= 1; // Flag to indicate if a restart is needed
        bit done = 0; 
        // Create a sequence item for link policy maker (LPM) communication
        seq_item = dp_tl_sequence_item::type_id::create("seq_item");
        
        // Loop until equalization succeeds
        while (restart) begin
            // Start sending the initial equalization sequence
            restart = 0;
            start_item(seq_item);
            seq_item.rand_mode(0);                      // Disable randomization for all fields
            seq_item.LPM_Transaction_VLD = 1'b1;        // Mark transaction as valid
            seq_item.EQ_Data_VLD = 0;                   // Indicate that EQ data is not valid
            seq_item.MAX_TPS_SUPPORTED_VLD = 1;                       // Indicate change of max TPS
            seq_item.MAX_TPS_SUPPORTED.rand_mode(1);    // Randomize the max TPS value
            seq_item.VTG.rand_mode(1);
            seq_item.PRE.rand_mode(1);
            seq_item.Driving_Param_VLD = 1'b1;   // Driving parameters are valid

            assert(seq_item.randomize()); // Randomize enabled fields
            finish_item(seq_item); // Finish transaction
            // Wait for acknowledgment from the DUT for 2 writes and 1 read transactions
            while(~done) begin
                get_response(seq_item);
                if(seq_item.LPM_NATIVE_I2C) begin
                    if (seq_item.CTRL_Native_Failed) begin
                        `uvm_info("TL_Native_REQ_SEQ", $sformatf("Native AUX %s request transaction failed: addr=0x%0h, Data Length=0x%0d, Transaction Validity = 0x%0b",  seq_item.LPM_CMD, seq_item.LPM_Address, seq_item.LPM_LEN +1, seq_item.LPM_Transaction_VLD), UVM_MEDIUM)
                        break;
                    end
                    else if(seq_item.LPM_Reply_ACK_VLD) begin
                        if(seq_item.LPM_Reply_ACK == AUX_ACK[1:0]) begin
                            ack_count++;
                        end
                    end
                    else if(ack_count==3 && seq_item.LPM_Reply_Data_VLD)
                        done = 0; 
                    else if(ack_count==3 && !seq_item.LPM_Reply_Data_VLD)
                        done = 1; 
                end
            end
            done = 0;
        
            start_item(seq_item);
            seq_item.rand_mode(0);
            seq_item.EQ_RD_Value.rand_mode(1);  // Randomize the EQ_RD_Value
            seq_item.MAX_TPS_SUPPORTED_VLD = 0; // Indicate change of max TPS
            seq_item.LPM_Transaction_VLD = 1'b1; // LPM is on
            seq_item.EQ_Data_VLD = 0; // Indicate that EQ data is not valid
            seq_item.Driving_Param_VLD = 1'b0;
            assert(seq_item.randomize());
            finish_item(seq_item);
            ack_count = 0;
            // wait for dut to receive EQ_RD_Value
            
            // Check Link Status registers until all conditions are met
            while (~seq_item.EQ_LT_Pass) begin
                // Wait for 202 to 207 to be read
                while(~done) begin
                    get_response(seq_item);
                    if(seq_item.LPM_NATIVE_I2C) begin
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
                end
                done = 0;
                ack_count = 0; // Reset acknowledgment count
                
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
                seq_item.LPM_Transaction_VLD = 1'b1;
                seq_item.EQ_Data_VLD = 1;
                seq_item.Driving_Param_VLD = 1'b1;
                seq_item.VTG.rand_mode(1);
                seq_item.PRE.rand_mode(1);
                assert(seq_item.randomize());
                finish_item(seq_item);
                
                get_response(seq_item);
                // Step 5: Check if CR is done
                if(seq_item.EQ_FSM_CR_Failed) begin
                    CR_LT_eq(); // Call the CR_LT task to perform clock recovery
                    restart = 1; // Set the restart flag to indicate a restart is needed
                    break;
                end
                while(ack_count < 1) begin
                    get_response(seq_item);
                    if(seq_item.LPM_NATIVE_I2C) begin
                        if (seq_item.EQ_Failed) begin
                                `uvm_info("TL_EQ_SEQ", $sformatf("Native AUX %s request transaction failed: addr=0x%0h, Data Length=0x%0d, Transaction Validity = 0x%0b",  seq_item.LPM_CMD, seq_item.LPM_Address, seq_item.LPM_LEN +1, seq_item.LPM_Transaction_VLD), UVM_MEDIUM)
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
                end
                done = 0;
                ack_count = 0; // Reset acknowledgment count
            end
            if (restart) begin 
                continue; // Restart the loop if needed
            end
            else if(seq_item.EQ_LT_Pass) begin
                seq_item.ISO_LC = seq_item.EQ_Final_ADJ_LC;
                seq_item.ISO_BW = seq_item.EQ_Final_ADJ_BW; 
            end
            ack_count = 0;
        end   
    // Step 6: Write 00h to offset 0x00102 to disable Link Training
        start_item(seq_item);
        seq_item.rand_mode(0);
        seq_item.MAX_TPS_SUPPORTED_VLD = 0; // Indicate no TPS
        seq_item.LPM_Transaction_VLD = 1'b0;
        seq_item.Driving_Param_VLD = 1'b0;
        seq_item.EQ_Data_VLD = 1'b0; // Indicate that EQ data is not valid
        assert(seq_item.randomize());
        finish_item(seq_item);
        
        get_response(seq_item);
        // Wait for acknowledgment from the DUT for write transaction
        while(ack_count<1) begin
            get_response(seq_item);
            if (seq_item.CTRL_Native_Failed) begin
                `uvm_info("TL_Native_REQ_SEQ", $sformatf("Native AUX %s request transaction failed: addr=0x%0h, Data Length=0x%0d, Transaction Validity = 0x%0b",  seq_item.LPM_CMD, seq_item.LPM_Address, seq_item.LPM_LEN +1, seq_item.LPM_Transaction_VLD), UVM_MEDIUM)
                break;
            end
            else if(seq_item.LPM_Reply_ACK_VLD) begin
                if(seq_item.LPM_Reply_ACK == AUX_ACK[1:0]) begin
                    ack_count++;
                end
            end
        end
    endtask

    // task ISO_INIT();
    //     start_item(seq_item);
    //     // seq_item.rand_mode(0);
    //     // seq_item.Mvid.rand_mode(1); seq_item.Nvid.rand_mode(1); seq_item.HTotal.rand_mode(1); seq_item.VTotal.rand_mode(1); seq_item.HStart.rand_mode(1); seq_item.VStart.rand_mode(1); seq_item.HSP.rand_mode(1); seq_item.VSP.rand_mode(1);
    //     // seq_item.HSW.rand_mode(1); seq_item.VSW.rand_mode(1); seq_item.HWidth.rand_mode(1); seq_item.VHeight.rand_mode(1); seq_item.MISC0.rand_mode(1); seq_item.MISC1.rand_mode(1);
    //     seq_item.SPM_Transaction_VLD = 1'b1;
    //     seq_item.SPM_MSA_VLD = 1'b1;
    //     seq_item.SPM_Lane_BW = seq_item.ISO_BW; 
    //     seq_item.SPM_Lane_Count = seq_item.ISO_LC;
    //     seq_item.SPM_ISO_start = 1'b1;
    //     seq_item.SPM_MSA = {seq_item.MISC1, seq_item.MISC0, seq_item.VHeight, seq_item.HWidth, seq_item.VSW, seq_item.VSP, seq_item.HSW, seq_item.HSP, seq_item.VStart, seq_item.HStart, seq_item.VTotal, seq_item.HTotal, seq_item.Nvid, seq_item.Mvid};
    //     case (seq_item.ISO_BW)
    //         8'h06: SPM_BW_Sel = 2'b00;
    //         8'h0A: SPM_BW_Sel = 2'b01;
    //         8'h14: SPM_BW_Sel = 2'b10;
    //         8'h1E: SPM_BW_Sel = 2'b11;
    //         default: begin
    //             SPM_BW_Sel = 2'b00;
    //             `uvm_info("The stored lane BW is incorrect!", UVM_MEDIUM)
    //         end
    //     endcase     
    //     seq_item.MS_Stm_BW.rand_mode(0);
    //     seq_item.MS_DE.rand_mode(0);
    //     seq_item.MS_Stm_BW = 10'd80; // 80MHz for now, should be randomized
    //     seq_item.MS_DE = 0;
    //     // seq_item.MS_VSYNC=;
    //     // seq_item.MS_HSYNC;
    //     assert(seq_item.randomize());   
    //     if(HSP) // HSP is active high, so set MS_HSYNC to 0
    //         seq_item.MS_HSYNC = 1'b0; // HSP is active high, so set MS_HSYNC to 0
    //     else
    //         seq_item.MS_HSYNC = 1'b1; // HSP is active low, so set MS_HSYNC to 1
    //     if(VSP) // VSP is active high, so set MS_VSYNC to 0
    //         seq_item.MS_VSYNC = 1'b0; // VSP is active high, so set MS_VSYNC to 0
    //     else
    //         seq_item.MS_VSYNC = 1'b1; // VSP is active low, so set MS_VSYNC to 1
    //     finish_item(seq_item);
    //     `uvm_info("TL_ISO_INIT_SEQ", $sformatf("ISO_INIT_SPM: ISO_start=%0b, SPM_Lane_BW=0x%0h, SPM_Lane_Count=0x%0h, Mvid=0x%0h, Nvid=0x%0h, HTotal=0x%0h, VTotal=0x%0h, HStart=0x%0h, VStart=0x%0h, HSP=0x%0h, VSP=0x%0h, HSW=0x%0h, VSW=0x%0h, HWidth=0x%0h, VHeight=0x%0h, MISC1=0x%0h, MISC2=0x%0h", seq_item.SPM_ISO_start, seq_item.SPM_Lane_BW, seq_item.SPM_Lane_Count, seq_item.Mvid, seq_item.Nvid, seq_item.HTotal, seq_item.VTotal, seq_item.HStart, seq_item.VStart, seq_item.HSP, seq_item.VSP, seq_item.HSW, seq_item.VSW, seq_item.HWidth, seq_item.VHeight, seq_item.MISC1, seq_item.MISC2), UVM_MEDIUM);
    // endtask

    // task Main_Stream();
    //     int countv = 1;
    //     int counth = 1;
    //     repeat(seq_item.VTotal) begin
    //         start_item(seq_item);
    //         seq_item.rand_mode(0);
    //         seq_item.SPM_Transaction_VLD = 1'b1;
    //         seq_item.SPM_MSA_VLD = 1'b0;
    //         if(countv<seq_item.VStart -1) begin
    //             seq_item.MS_DE = 0;
    //         end
    //         if(countv >= VFront && countv < VFront+VSW) begin // turn on VSYNC
    //             if(VSP) // VSP is active high, so set MS_VSYNC to 1
    //                 seq_item.MS_VSYNC = 1'b1; // VSP is active high, so set MS_VSYNC to 1
    //             else
    //                 seq_item.MS_VSYNC = 1'b0; // VSP is active low, so set MS_VSYNC to 0
    //         end
    //         else begin 
    //             if(VSP) // VSP is active high, so set MS_VSYNC to 0, turning off VSYNC
    //                 seq_item.MS_VSYNC = 1'b0; // VSP is active high, so set MS_VSYNC to 0
    //             else
    //                 seq_item.MS_VSYNC = 1'b1; // VSP is active low, so set MS_VSYNC to 1
    //         end
    //         if(counth >= HFront && counth < HFront+HSW) begin // turn on HSYNC
    //             if(HSP) // HSP is active high, so set MS_HSYNC to 1
    //                 seq_item.MS_HSYNC = 1'b1; // HSP is active high, so set MS_HSYNC to 1
    //             else
    //                 seq_item.MS_HSYNC = 1'b0; // HSP is active low, so set MS_HSYNC to 0
    //             counth = 0; // reset the counter    
    //         end
    //         else begin
    //             if(seq_item.HSP) // HSP is active high, so set MS_HSYNC to 0, turning off HSYNC
    //                 seq_item.MS_HSYNC = 1'b0; // HSP is active high, so set MS_HSYNC to 0
    //             else
    //                 seq_item.MS_HSYNC = 1'b1; // HSP is active low, so set MS_HSYNC to 1
    //         end
    //         countv++;
    //         counth++;
    //         assert(seq_item.randomize());
    //         finish_item(seq_item);
    //     end
    // endtask
    // Prevent the base sequence from running directly
    task body();
        `uvm_fatal("TL_BASE_SEQ", "Base sequence should not be executed directly!")
    endtask
endclass //dp_tl_base_sequence extends superClass
