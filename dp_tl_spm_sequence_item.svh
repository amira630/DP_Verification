class dp_tl_spm_sequence_item extends uvm_sequence_item;
    `uvm_object_utils(dp_tl_spm_sequence_item);

    rand bit rst_n;   // Reset is asynchronous active low
    
    ///////////////////////////////////////////////////////////////
    /////////////////// STREAM POLICY MAKER ///////////////////////
    ///////////////////////////////////////////////////////////////

// input Data from the stream policy maker to DUT
    rand logic [AUX_DATA_WIDTH-1:0]    SPM_Data; // Randomized only if write will be supported
    rand bit [AUX_ADDRESS_WIDTH-1:0]   SPM_Address;
    bit [AUX_DATA_WIDTH-1:0]           SPM_LEN;
    rand i2c_aux_request_cmd_e         SPM_CMD; // 00 Write and 01 Read
    bit                                SPM_Transaction_VLD;

// Opration code  
    op_code operation;

// Output Data from DUT to the stream policy maker
    logic [AUX_DATA_WIDTH-1:0] SPM_Reply_Data;
    logic [1:0]                SPM_Reply_ACK;
    logic                      SPM_NATIVE_I2C, SPM_Reply_Data_VLD, SPM_Reply_ACK_VLD, CTRL_I2C_Failed, HPD_Detect;

// // From the Stream Policy Maker to Link Policy Maker
//     logic Link_Inquiry; // unsure of length right now
// // From the Link Policy Maker to Stream Policy Maker    
//     logic Link_Info;  // unsure of length right now

    ///////////////////////////////////////////////////////////////
    /////////////////////// CONSTRUCTOR ///////////////////////////
    ///////////////////////////////////////////////////////////////

    function new(string name = "dp_tl_spm_sequence_item");
        super.new(name);
    endfunction //new()

    ///////////////////////////////////////////////////////////////
    /////////////////////// CONSTRAINTS ///////////////////////////
    ///////////////////////////////////////////////////////////////
    
    constraint spm_data_write_constraint {
        if (SPM_CMD == AUX_I2C_WRITE) {
            SPM_Data inside {[0:255]}; // Full range of SPM_Data
        } else {
            SPM_Data == 8'bx; // Default value when not AUX_I2C_WRITE
        }
    }
    
    constraint spm_cmd_read_only_constraint {
        SPM_CMD == AUX_I2C_READ; // Force SPM_CMD to always be AUX_I2C_READ
    }

    constraint operation_type_dist {
        operation inside {[I2C_WRITE:I2C_READ]};
    }

    ///////////////////////////////////////////////////////////////
    ///////////////////////// METHODS /////////////////////////////
    ///////////////////////////////////////////////////////////////

    function string convert2string();
        return $sformatf("%s Operation: %0s, SPM_DATA = %0b, SPM_ADDRESS = %0b, SPM_LENGTH = %0b, SPM_CMD = %0b, SPM_TRANS_VALID = %0b,SPM_REPLY_DATA = %0b, SPM_REPLY_ACK = %0b, SPM_REPLY_DATA_VALID = %0b, SPM_REPLY_ACK_VALID = %0b, SPM_NATIVE_I2C = %0bو CTRL_I2C_Failed = %0b, HPD_Detect = %0b", super.convert2string(), operation, SPM_Data, SPM_Address, SPM_LEN, SPM_CMD, SPM_Transaction_VLD, SPM_Reply_Data, SPM_Reply_ACK, SPM_Reply_Data_VLD, SPM_Reply_ACK_VLD, SPM_NATIVE_I2C, CTRL_I2C_Failed, HPD_Detect);
    endfunction

endclass //dp_tl_spm_sequence_item extends superClass