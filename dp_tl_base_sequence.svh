class dp_tl_base_sequence extends uvm_sequence #(dp_tl_spm_sequence_item, dp_tl_lpm_sequence_item);
    `uvm_object_utils(dp_tl_base_sequence);

    dp_tl_spm_sequence_item seq_item_SPM;
    dp_tl_lpm_sequence_item seq_item_LPM;

    function new(string name = "dp_tl_base_sequence");
        super.new(name);
    endfunction //new()

// I2C AUX REQUEST TRANSACTION sequence
    task EDID_reading();
        seq_item_SPM = dp_tl_spm_sequence_item::type_id::create("seq_item_SPM");
        
        start_item(seq_item_SPM);
            seq_item_SPM.SPM_Address.rand_mode(0);    // randomization off
            seq_item_SPM.SPM_CMD.rand_mode(0);        // randomization off

            seq_item_SPM.SPM_CMD = AUX_I2C_READ;               // Read
            seq_item_SPM.SPM_Transaction_VLD = 1'b1;  // SPM is going to request a Native transaction 
            seq_item_SPM.SPM_Address = 20'h0_00_00;       // Address
            seq_item_SPM.SPM_LEN = 8'h80;               // Length
            if (CMD == AUX_I2C_WRITE) begin
                seq_item_SPM.SPM_Data.delete();  // Clear the queue
                assert(seq_item_SPM.randomize() with { SPM_Data.size() == LEN; });
            end
        finish_item(seq_item_SPM);
        `uvm_info("TL_I2C_REQ_SEQ", $sformatf("I2C AUX %s request transaction sent: addr=0x%0h, Data Length=0x%0d, Transaction Validity = 0x%0b",  seq_item_SPM.SPM_CMD, seq_item_SPM.SPM_Address, seq_item_SPM.SPM_LEN +1, seq_item_SPM.SPM_Transaction_VLD), UVM_MEDIUM)
    endtask

// NATIVE AUX REQUEST TRANSACTION sequence
    task native_request(input logic [19:0] address, [7:0] LEN, native_aux_request_cmd_e CMD);
        seq_item_LPM = dp_tl_lpm_sequence_item::type_id::create("seq_item_LPM");
        
        start_item(seq_item_LPM);
            seq_item_LPM.LPM_LEN.rand_mode(0);        // randomization off

            seq_item_LPM.LPM_CMD = CMD;               // Read
            seq_item_LPM.LPM_Transaction_VLD = 1'b1;  // SPM is going to request a Native transaction 
            seq_item_LPM.LPM_Address = address;       // Address
            seq_item_LPM.LPM_LEN = LEN;               // Length
            if (CMD == AUX_NATIVE_WRITE) begin
                seq_item_LPM.LPM_Data.delete();  // Clear the queue
                assert(seq_item_LPM.randomize() with {LPM_Data.size() == LEN;});
            end
        finish_item(seq_item_LPM);
        `uvm_info("TL_Native_REQ_SEQ", $sformatf("Native AUX %s request transaction sent: addr=0x%0h, Data Length=0x%0d, Transaction Validity = 0x%0b",  seq_item_LPM.SPM_CMD, seq_item_LPM.SPM_Address, seq_item_LPM.SPM_LEN +1, seq_item_LPM.SPM_Transaction_VLD), UVM_MEDIUM)
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