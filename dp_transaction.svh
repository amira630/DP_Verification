// Work in Progress

class dp_transaction extends uvm_sequence_item;
    `uvm_object_utils(dp_transaction)

    // Fields for AUX transactions
    bit [7:0] aux_in_out;          // Encoded AUX command and data
    bit start_stop;                // Start/Stop signal for AUX transactions
    bit [1:0] LPM_Reply_ACK;       // Reply ACK for Native AUX transactions
    bit LPM_Reply_ACK_VLD;         // Validity of the ACK
    bit [7:0] LPM_Reply_Data;      // Reply data for Native AUX transactions
    bit LPM_Reply_Data_VLD;        // Validity of the reply data
    bit LPM_Native_I2C;            // Indicates if the transaction is Native I2C

    // Fields for I2C-over-AUX transactions
    bit [1:0] SPM_Reply_ACK;       // Reply ACK for I2C-over-AUX transactions
    bit SPM_Reply_ACK_VLD;         // Validity of the ACK
    bit [7:0] SPM_Reply_Data;      // Reply data for I2C-over-AUX transactions
    bit SPM_Reply_Data_VLD;        // Validity of the reply data
    bit I2C_Complete;              // Indicates if the I2C transaction is complete

    // Fields for connection detection
    bit HPD_Detect;                // Hot Plug Detect signal
    bit HPD_IRQ;                   // Hot Plug Detect IRQ signal

    // Fields for link training
    bit CR_Completed;              // Indicates if Clock Recovery is complete
    bit FSM_CR_Failed;             // Indicates if Clock Recovery failed
    bit EQ_LT_Pass;                // Indicates if Equalization and Link Training passed
    bit EQ_Failed;                 // Indicates if Equalization failed
    bit [7:0] final_bw;            // Final bandwidth after link training
    bit [3:0] final_lane_count;    // Final lane count after link training

    // Constructor
    function new(string name = "dp_transaction");
        super.new(name);
    endfunction

    // Convert to string for logging
    function string convert2string();
        return $sformatf("aux_in_out=0x%0h, start_stop=%0b, LPM_Reply_ACK=0x%0b, LPM_Reply_ACK_VLD=%0b, LPM_Reply_Data=0x%0h, LPM_Reply_Data_VLD=%0b, LPM_Native_I2C=%0b, SPM_Reply_ACK=0x%0b, SPM_Reply_ACK_VLD=%0b, SPM_Reply_Data=0x%0h, SPM_Reply_Data_VLD=%0b, I2C_Complete=%0b, HPD_Detect=%0b, HPD_IRQ=%0b, CR_Completed=%0b, FSM_CR_Failed=%0b, EQ_LT_Pass=%0b, EQ_Failed=%0b, final_bw=0x%0h, final_lane_count=0x%0h",
                         aux_in_out, start_stop, LPM_Reply_ACK, LPM_Reply_ACK_VLD, LPM_Reply_Data, LPM_Reply_Data_VLD, LPM_Native_I2C, SPM_Reply_ACK, SPM_Reply_ACK_VLD, SPM_Reply_Data, SPM_Reply_Data_VLD, I2C_Complete, HPD_Detect, HPD_IRQ, CR_Completed, FSM_CR_Failed, EQ_LT_Pass, EQ_Failed, final_bw, final_lane_count);
    endfunction
endclass