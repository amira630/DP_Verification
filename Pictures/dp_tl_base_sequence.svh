class dp_tl_base_sequence extends uvm_sequence #(dp_tl_spm_sequence_item, dp_tl_lpm_sequence_item);
    `uvm_object_utils(dp_tl_base_sequence);

    dp_tl_spm_sequence_item seq_item_SPM;
    dp_tl_lpm_sequence_item seq_item_LPM;

    function new(string name = "dp_tl_base_sequence");
        super.new(name);
    endfunction //new()

// // function of creating sequence item of type dp_tl_spm_sequence_item
//     function dp_tl_spm_sequence_item create_spm_item();
//         dp_tl_spm_sequence_item seq_item;
//         seq_item = dp_tl_spm_sequence_item::type_id::create("seq_item");
//         return seq_item;
//     endfunction

// // function of creating sequence item of type dp_tl_lpm_sequence_item
//     function dp_tl_lpm_sequence_item create_lpm_item();
//         dp_tl_lpm_sequence_item seq_item;
//         seq_item = dp_tl_lpm_sequence_item::type_id::create("seq_item");
//         return seq_item;
//     endfunction

// HPD Detect
    task HPD_Detect_sequence ();

    endtask
// I2C AUX REQUEST TRANSACTION sequence
    task i2c_request(input i2c_aux_request_cmd_e CMD, logic [19:0] address, [7:0] len);
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
                seq_item_SPM.SPM_LEN = len;               // Length
                if (CMD == AUX_I2C_WRITE) begin
                    seq_item_SPM.SPM_Data.delete();  // Clear the queue
                    assert(seq_item_SPM.randomize() with { SPM_Data.size() == LEN; });
                end
            finish_item(seq_item_SPM);
            while(ack_count<len+1) begin
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

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// NATIVE AUX REQUEST TRANSACTION sequence
// Need to write separate task for Native AUX read and write request transactions
// As for in case of read burst fail I will re-request the whole burst
// for write burst i can start from the point where it failed based on the M value
    task native_request(input logic [19:0] address, [7:0] LEN, native_aux_request_cmd_e CMD);
        seq_item_LPM = dp_tl_lpm_sequence_item::type_id::create("seq_item_LPM");

        int ack_count = 0;
        seq_item_LPM.CTRL_Native_Failed = 1;
        while (seq_item_LPM.CTRL_Native_Failed) begin
            seq_item_LPM.CTRL_Native_Failed = 0;
            
            start_item(seq_item_LPM);
                seq_item_LPM.LPM_Address.rand_mode(0);    // randomization off
                seq_item_LPM.LPM_CMD.rand_mode(0);        // randomization off

                seq_item_LPM.LPM_CMD = CMD;                      // Read
                seq_item_LPM.LPM_Transaction_VLD = 1'b1;         // LPM is going to request a Native transaction 
                seq_item_LPM.LPM_Address = address;  // Address
                seq_item_LPM.LPM_LEN = len;                      // Length
                if (CMD == AUX_NATIVE_WRITE) begin
                    seq_item_LPM.LPM_Data.delete();  // Clear the queue
                    assert(seq_item_LPM.randomize() with {LPM_Data.size() == LEN;});
                end
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

// Link Training
    task Link_INIT(port_list);
        seq_item_SPM = dp_tl_spm_sequence_item::type_id::create("seq_item_SPM");
        seq_item_LPM = dp_tl_lpm_sequence_item::type_id::create("seq_item_LPM");

        // Wait for theHPD Detect signal to go high
        if (seq_item_SPM.HPD_Detect) begin
            EDID_reading();

            Wait(!seq_item_SPM.SPM_NATIVE_I2C);

        end
    endtask


    // // NATIVE AUX READ REQUEST TRANSACTION
    // task native_read_req_aux(input logic [19:0] address, [7:0] LEN);
    //     seq_item_LPM = dp_tl_lpm_sequence_item::type_id::create("seq_item_LPM");
    //     start_item(seq_item_LPM);
    //         seq_item_LPM.LPM_CMD = 2'b01;             // Read
    //         ///// IN interface //////////////
    //         //seq_item_LPM.SPM_Transaction_VLD = 1'b0;  // SPM is going to request an I2C transaction
    //         ///// IN interface //////////////
    //         seq_item_LPM.LPM_Address = address;       // Address
    //         seq_item_LPM.LPM_LEN = LEN;               // Length
    //         seq_item_LPM.LPM_Transaction_VLD = 1'b1;  // LPM is going to request a Native transaction    
    //     finish_item(seq_item_LPM);
    //     `uvm_info("TL_BASE_SEQ", $sformatf("Native AUX read request transaction sent: addr=0x%0h, Data Length=0x%0d, Command = 0x%0b, Transaction Validity = 0x%0b", seq_item_LPM.LPM_Address, seq_item_LPM.LPM_LEN, seq_item_LPM.LPM_CMD, seq_item_LPM.LPM_Transaction_VLD), UVM_MEDIUM)
    // endtask

    // // READ THE RECEIVER CAPABILITY FIELD in the DPCD Register File
    // task read_rec_cap_aux();
    //     native_read_req_aux(20'h0_00_00, 8'hFF);
    // endtask

    // // NATIVE AUX WRITE REQUEST TRANSACTION
    // task native_write_req_aux (input logic [19:0] address, [7:0] LEN);
    //     seq_item_LPM = dp_tl_lpm_sequence_item::type_id::create("seq_item_LPM");
    //     start_item(seq_item_LPM);
    //         seq_item_LPM.rand_mode(0);
    //         seq_item_LPM.LPM_Data.rand_mode(1);
    //         initialize_data_queue(LEN + 1);           // Data
    //         seq_item_LPM.LPM_CMD = 2'b00;             // WRITE
    //         ///// IN interface //////////////
    //         //seq_item_SPM.SPM_Transaction_VLD = 1'b0;  // SPM is going to request an I2C transaction
    //         ///// IN interface //////////////
    //         seq_item_LPM.LPM_Address = address;       // Address
    //         seq_item_LPM.LPM_LEN = LEN;               // Length
            
    //         seq_item_LPM.LPM_Transaction_VLD = 1'b1;  // LPM is going to request a Native transaction
    //     finish_item(seq_item_LPM);
    //     `uvm_info("TL_BASE_SEQ", $sformatf("Native AUX write request transaction sent: addr=0x%0h, Data Length=0x%0d, Command = 0x%0b, Transaction Validity = 0x%0b", seq_item_LPM.LPM_Address, seq_item_LPM.LPM_LEN, seq_item_LPM.LPM_CMD, seq_item_LPM.LPM_Transaction_VLD), UVM_MEDIUM)
    // endtask

    // // Task to initialize the data queue with random values
    // task initialize_data_queue(int size = 1);
    //     seq_item_LPM.LPM_Data = {};  // Clear the queue
    //     for (int i = 0; i < size; i++) begin
    //         bit [7:0] random_byte;
    //         assert(seq_item_LPM.randomize()); // Not entirely sure yet
    //     end
    //     `uvm_info(get_type_name(), $sformatf("Initialized data queue with %0d random bytes", size), UVM_MEDIUM)
    // endtask

    // task I2C_read_transaction();
    //     seq_item_SPM = dp_tl_spm_sequence_item::type_id::create("seq_item_SPM");
    //     start_item(seq_item_SPM);
    //         //seq_item_SPM.operation = "I2C_READ";
    //         WR_seq: assert (seq_item_SPM.randomize() with {SPM_Transaction_VLD == 1'b1; SPM_CMD == 2'b01; SPM_LEN == 8'b1;})
    //                     else `uvm_fatal("body", "Randomization with I2C-read constraints failed!");
    //         finish_item(seq_item_SPM);                
    // endtask

    // Prevent the base sequence from running directly
    task body();
        `uvm_fatal("TL_BASE_SEQ", "Base sequence should not be executed directly!")
    endtask
endclass //dp_tl_base_sequence extends superClass