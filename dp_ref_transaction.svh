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
    bit       FSM_CR_Failed, EQ_FSM_CR_Failed, EQ_LT_Failed, EQ_LT_Pass;
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

    // -------------------------------------------------------------
    // Clone implementation (returns a copy of this object)
    // -------------------------------------------------------------
    function uvm_object clone();
        dp_ref_transaction c;
        c = dp_ref_transaction::type_id::create("c");
        c.copy(this);
        return c;
    endfunction

    // -------------------------------------------------------------
    // Copy implementation (copies all fields from another object)
    // -------------------------------------------------------------
    function void copy(uvm_object rhs);
        dp_ref_transaction rhs_;
        super.copy(rhs);
        if (!$cast(rhs_, rhs)) return;

        // Stream Policy Maker
        this.SPM_Reply_Data      = rhs_.SPM_Reply_Data;
        this.SPM_Reply_ACK       = rhs_.SPM_Reply_ACK;
        this.SPM_Reply_ACK_VLD   = rhs_.SPM_Reply_ACK_VLD;
        this.SPM_Reply_Data_VLD  = rhs_.SPM_Reply_Data_VLD;
        this.SPM_NATIVE_I2C      = rhs_.SPM_NATIVE_I2C;
        this.CTRL_I2C_Failed     = rhs_.CTRL_I2C_Failed;

        // Link Policy Maker
        this.LPM_Reply_Data      = rhs_.LPM_Reply_Data;
        this.LPM_Reply_ACK       = rhs_.LPM_Reply_ACK;
        this.LPM_Reply_ACK_VLD   = rhs_.LPM_Reply_ACK_VLD;
        this.LPM_Reply_Data_VLD  = rhs_.LPM_Reply_Data_VLD;
        this.HPD_Detect          = rhs_.HPD_Detect;
        this.HPD_IRQ             = rhs_.HPD_IRQ;
        this.CTRL_Native_Failed  = rhs_.CTRL_Native_Failed;
        this.LPM_NATIVE_I2C      = rhs_.LPM_NATIVE_I2C;

        // Link Training Signals
        this.EQ_Final_ADJ_BW     = rhs_.EQ_Final_ADJ_BW;
        this.EQ_Final_ADJ_LC     = rhs_.EQ_Final_ADJ_LC;
        this.FSM_CR_Failed       = rhs_.FSM_CR_Failed;
        this.EQ_FSM_CR_Failed    = rhs_.EQ_FSM_CR_Failed;
        this.EQ_LT_Failed        = rhs_.EQ_LT_Failed;
        this.EQ_LT_Pass          = rhs_.EQ_LT_Pass;
        this.CR_Completed        = rhs_.CR_Completed;
        this.Timer_Timeout       = rhs_.Timer_Timeout;

        // Physical Layer
        this.PHY_ADJ_BW          = rhs_.PHY_ADJ_BW;
        this.PHY_ADJ_LC          = rhs_.PHY_ADJ_LC;
        this.PHY_Instruct        = rhs_.PHY_Instruct;
        this.AUX_START_STOP      = rhs_.AUX_START_STOP;
        this.PHY_Instruct_VLD    = rhs_.PHY_Instruct_VLD;
        this.AUX_IN_OUT          = rhs_.AUX_IN_OUT;

        // Isochronous Transport
        this.ISO_symbols_lane0   = rhs_.ISO_symbols_lane0;
        this.ISO_symbols_lane1   = rhs_.ISO_symbols_lane1;
        this.ISO_symbols_lane2   = rhs_.ISO_symbols_lane2;
        this.ISO_symbols_lane3   = rhs_.ISO_symbols_lane3;
        this.Control_sym_flag_lane0 = rhs_.Control_sym_flag_lane0;
        this.Control_sym_flag_lane1 = rhs_.Control_sym_flag_lane1;
        this.Control_sym_flag_lane2 = rhs_.Control_sym_flag_lane2;
        this.Control_sym_flag_lane3 = rhs_.Control_sym_flag_lane3;

        // Main Stream Source
        this.WFULL               = rhs_.WFULL;
    endfunction

endclass