class dp_sink_sequence_item extends uvm_sequence_item;
    `uvm_object_utils(dp_sink_sequence_item);

    rand bit HPD_Signal;

    bit rst_n;           // Reset signal for the PHY Layer
    
    bit AUX_START_STOP, PHY_START_STOP;
    logic [7:0] AUX_IN_OUT;       // AUX_IN_OUT signal from the DUT (To receive the dut output data)

    logic [7:0] PHY_IN_OUT;       // PHY_IN_OUT signal from the sink (To send the data to the dut)

// Reply Command Signal 
    rand i2c_aux_reply_cmd_e i2c_reply_cmd;
    rand native_aux_reply_cmd_e native_reply_cmd;

// Reply Data Signal
//    rand logic [7:0] reply_data; // Reply data from the PHY Layer

// Output Signals across from DUT to the PHY Layer
    logic [1:0] PHY_ADJ_LC, PHY_Instruct;
    logic [7:0] PHY_ADJ_BW;
    logic       PHY_Instruct_VLD;

// AUX fields moved from base_sequence
// These fields are used to store the values of the AUX command, address, length, and data

    bit [7:0] aux_in_out[$]; // store the AUX_IN_OUT values while the AUX_START_STOP is high

    logic [3:0] command;    // Command of the operation
    logic [19:0] address;   // Address of the data to be sent or received
    logic [7:0] length;     // Length of the data to be sent
    logic [7:0] data[$];    // Data sent by the DUT to the PHY Layer

// Flags
    sink_op_code sink_operation; // Operation type (HPD or Reply)

    ///////////////////////////////////////////////////////////////
    /////////////////////// CONSTRAINTS ///////////////////////////
    ///////////////////////////////////////////////////////////////

    constraint valid_i2c_aux_reply_cmd_c {
        i2c_reply_cmd == I2C_ACK;  // Always set to ACK
    }

    constraint valid_native_aux_reply_cmd_c {
        native_reply_cmd == AUX_ACK;  // Always set to ACK
    }

    // constraint valid_i2c_aux_reply_cmd_c {
    //     i2c_reply_cmd dist {
    //         // Strongly prefer ACK, but occasionally allow NACK or DEFER
    //         I2C_ACK      := 96,  // 90% of the time
    //         I2C_NACK     := 2,   // 5% of the time
    //         I2C_DEFER    := 2    // 5% of the time
    //     };
    // }

    // constraint valid_native_aux_reply_cmd_c {
    //     // Strongly prefer ACK, but occasionally allow NACK or DEFER
    //     native_reply_cmd dist {
    //         AUX_ACK      := 90,
    //         AUX_NACK     := 5,
    //         AUX_DEFER    := 5
    //     };
    // }

    ///////////////////////////////////////////////////////////////
    /////////////////////// CONSTRUCTOR ///////////////////////////
    ///////////////////////////////////////////////////////////////

    function new(string name = "dp_sink_sequence_item");
        super.new(name);
    endfunction //new()

    ///////////////////////////////////////////////////////////////
    ///////////////////////// METHODS /////////////////////////////
    ///////////////////////////////////////////////////////////////

    function string convert2string();
        string aux_data = "";
        string data_str = "";

        foreach(aux_in_out[i]) begin
            aux_data = {aux_data, $sformatf("aux_in_out[%0d]=%0h ", i, aux_in_out[i])};
        end

        foreach(data[i]) begin
            data_str = {data_str, $sformatf("data[%0d]=%0h ", i, data[i])};
        end
        
        return $sformatf("%s HPD_Signal = %0b, AUX_START_STOP = %0b, PHY_START_STOP = %0b, I2C_Reply = %0b, NATIVE_Reply = 0b, PHY_ADJ_LC = %0b, PHY_ADJ_BW = %0b, PHY_Instruct = %0b, PHY_Instruct_VLD = %0b, AUX_COMMAND = %0h, AUX_ADDRESS = %0h, AUX_LENGTH = %0h, AUX_DATA = %s", super.convert2string(),HPD_Signal, AUX_START_STOP, PHY_START_STOP, i2c_reply_cmd, native_reply_cmd, PHY_ADJ_LC, PHY_ADJ_BW, PHY_Instruct, PHY_Instruct_VLD, command, address, length, data_str);
    endfunction
    
endclass //dp_sink_sequence_item extends superClass