class dp_tl_base_sequence extends uvm_sequence #(dp_tl_sequence_item);
    `uvm_object_utils(dp_tl_base_sequence);

    dp_tl_spm_sequence_item seq_item_SPM;
    dp_tl_lpm_sequence_item seq_item_LPM;

    function new(string name = "dp_tl_base_sequence");
        super.new(name);
    endfunction //new()

    // NATIVE AUX READ REQUEST TRANSACTION
    task native_read_req_aux(input logic [19:0] address, [7:0] LEN);
        seq_item_LPM = dp_tl_lpm_sequence_item::type_id::create("seq_item_LPM");
        start_item(seq_item_LPM);
            seq_item_LPM.LPM_CMD = 2'b01;             // Read
            ///// IN interface //////////////
            //seq_item_SPM.SPM_Transaction_VLD = 1'b0;  // SPM is going to request an I2C transaction
            ///// IN interface //////////////
            seq_item_LPM.LPM_Address = address;       // Address
            seq_item_LPM.LPM_LEN = LEN;               // Length
            seq_item_LPM.LPM_Transaction_VLD = 1'b1;  // LPM is going to request a Native transaction    
        finish_item(seq_item_LPM);
        `uvm_info("TL_BASE_SEQ", $sformatf("Native AUX read request transaction sent: addr=0x%0h, Data Length=0x%0d, Command = 0x%0b, Transaction Validity = 0x%0b", seq_item_LPM.LPM_Address, seq_item_LPM.LPM_LEN, seq_item_LPM.LPM_CMD, seq_item_LPM.LPM_Transaction_VLD), UVM_MEDIUM)
    endtask

    // READ THE RECEIVER CAPABILITY FIELD in the DPCD Register File
    task read_rec_cap_aux();
        native_read_req_aux(20'h0_00_00, 8'hFF);
    endtask

    // NATIVE AUX WRITE REQUEST TRANSACTION
    task native_write_req_aux (input logic [19:0] address, [7:0] LEN);
        seq_item_LPM = dp_tl_lpm_sequence_item::type_id::create("seq_item_LPM");
        start_item(seq_item_LPM);
            seq_item_LPM.rand_mode(0);
            seq_item_LPM.LPM_Data.rand_mode(1);
            initialize_data_queue(LEN + 1);           // Data
            seq_item_LPM.LPM_CMD = 2'b00;             // WRITE
            ///// IN interface //////////////
            //seq_item_SPM.SPM_Transaction_VLD = 1'b0;  // SPM is going to request an I2C transaction
            ///// IN interface //////////////
            seq_item_LPM.LPM_Address = address;       // Address
            seq_item_LPM.LPM_LEN = LEN;               // Length
            
            seq_item_LPM.LPM_Transaction_VLD = 1'b1;  // LPM is going to request a Native transaction
        finish_item(seq_item_LPM);
        `uvm_info("TL_BASE_SEQ", $sformatf("Native AUX write request transaction sent: addr=0x%0h, Data Length=0x%0d, Command = 0x%0b, Transaction Validity = 0x%0b", seq_item_LPM.LPM_Address, seq_item_LPM.LPM_LEN, seq_item_LPM.LPM_CMD, seq_item_LPM.LPM_Transaction_VLD), UVM_MEDIUM)
    endtask

    // Task to initialize the data queue with random values
    task initialize_data_queue(int size = 1);
        seq_item_LPM.LPM_Data = {};  // Clear the queue
        for (int i = 0; i < size; i++) begin
            bit [7:0] random_byte;
            assert(seq_item_LPM.randomize()); // Not entirely sure yet
        end
        `uvm_info(get_type_name(), $sformatf("Initialized data queue with %0d random bytes", size), UVM_MEDIUM)
    endtask

    // Prevent the base sequence from running directly
    task body();
        `uvm_fatal("TL_BASE_SEQ", "Base sequence should not be executed directly!")
    endtask
endclass //dp_tl_base_sequence extends superClass