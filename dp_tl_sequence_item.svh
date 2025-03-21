class dp_tl_sequence_item extends uvm_sequence_item;
    `uvm_object_utils(dp_tl_sequence_item);

// input Data from the stream policy maker to DUT
    rand bit [AUX_DATA_WIDTH-1:0] spm_data;
    rand bit [AUX_ADDRESS_WIDTH-1:0] spm_address;
    rand bit [AUX_DATA_WIDTH-1:0] spm_length;
    rand bit [1:0] spm_cmd;
    bit spm_trans_valid;

// Opration code  
    op_code operation;

// Output Data from DUT to the stream policy maker
    logic [AUX_DATA_WIDTH-1:0] spm_reply_data;
    logic [1:0] spm_reply_ack;
    logic spm_native_i2c, spm_reply_data_valid, spm_reply_ack_valid;

// Constraints
     

    function new(string name = "dp_tl_sequence_item");
        super.new(name);
    endfunction //new()

    function string convert2string();
        return $sformatf("%s Operation: %0s, SPM_DATA = %0b, SPM_ADDRESS = %0b, SPM_LENGTH = %0b, SPM_CMD = %0b, SPM_TRANS_VALID = %0b,
         SPM_REPLY_DATA = %0b, SPM_REPLY_ACK = %0b, SPM_REPLY_DATA_VALID = %0b, SPM_REPLY_ACK_VALID = %0b, SPM_NATIVE_I2C = %0b", 
         super.convert2string(), operation, spm_data, spm_address, spm_length, spm_cmd, spm_trans_valid, spm_reply_data, spm_reply_ack,
         spm_reply_data_valid, spm_reply_ack_valid, spm_native_i2c);
    endfunction

endclass //dp_tl_sequence_item extends superClass
