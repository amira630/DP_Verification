    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import test_parameters_pkg::*;
    
class dp_ref_transaction extends uvm_sequence_item;
    `uvm_object_utils(dp_ref_transaction)

    ///////////////////////////////////////////////////////////////
    //////////////////// AUXILIARY CHANNEL ////////////////////////
    /////////////////////////////////////////////////////////////// 

    /////////////////// STREAM POLICY MAKER ///////////////////////

    bit [AUX_DATA_WIDTH-1:0] SPM_Reply_Data;
    bit [1:0]  SPM_Reply_ACK;
    bit        SPM_Reply_ACK_VLD, SPM_Reply_Data_VLD, SPM_NATIVE_I2C;
    bit        CTRL_I2C_Failed;

    //////////////////// LINK POLICY MAKER ////////////////////////
    
    bit [AUX_DATA_WIDTH-1:0]    LPM_Reply_Data;
    bit [1:0]                   LPM_Reply_ACK;
    bit                         LPM_Reply_ACK_VLD, LPM_Reply_Data_VLD;
    bit                         HPD_Detect, HPD_IRQ, CTRL_Native_Failed;
    bit                         LPM_NATIVE_I2C;            

    ////////////////// LINK Training Signals //////////////////////

    bit [AUX_DATA_WIDTH-1:0] EQ_Final_ADJ_BW;
    bit [1:0] EQ_Final_ADJ_LC;
    bit       FSM_CR_Failed, EQ_FSM_CR_Failed, EQ_Failed, EQ_LT_Pass;
    bit       CR_Completed;
    bit       Timer_Timeout;

    ///////////////////////////////////////////////////////////////
    //////////////////// AUXILIARY CHANNEL ////////////////////////
    ///////////////////////////////////////////////////////////////

    ///////////////////// PHYSICAL LAYER //////////////////////////

    bit [AUX_DATA_WIDTH:0]    PHY_ADJ_BW;
    bit [1:0]                 PHY_ADJ_LC, PHY_Instruct;
    bit                       AUX_START_STOP, PHY_Instruct_VLD;
    bit [AUX_DATA_WIDTH-1:0]  AUX_IN_OUT; // The AUX_IN_OUT signal is a bidirectional signal used for the DisplayPort auxiliary channel communication. It carries the data between the source and sink devices.

    ///////////////////////////////////////////////////////////////
    ////////////////// ISOCHRONOUS TRANSPORT //////////////////////
    ///////////////////////////////////////////////////////////////

    ///////////////////// PHYSICAL LAYER //////////////////////////

    logic [AUX_DATA_WIDTH-1:0] ISO_symbols_lane0, ISO_symbols_lane1, ISO_symbols_lane2, ISO_symbols_lane3;
    bit                      Control_sym_flag_lane0, Control_sym_flag_lane1, Control_sym_flag_lane2, Control_sym_flag_lane3;

    /////////////////// MAIN STREAM SOURCE ///////////////////////
    bit        WFULL;


    // Constructor
    function new(string name = "dp_ref_transaction");
        super.new(name);
    endfunction

endclass