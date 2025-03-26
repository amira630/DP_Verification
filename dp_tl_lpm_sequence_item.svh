class dp_tl_lpm_sequence_item extends uvm_sequence_item;
    `uvm_object_utils(dp_tl_lpm_sequence_item);

    rand bit rst_n;   // Reset is asynchronous active low

    ///////////////////////////////////////////////////////////////
    //////////////////// LINK POLICY MAKER ////////////////////////
    ///////////////////////////////////////////////////////////////
    
    // input Data to DUT
    logic [AUX_ADDRESS_WIDTH-1:0]      LPM_Address;
    rand logic [AUX_DATA_WIDTH-1:0]    LPM_LEN;
    rand logic [AUX_DATA_WIDTH-1:0]    LPM_Data[$];
    native_aux_request_cmd_e           LPM_CMD; // 00 Write and 01 Read
    bit                                LPM_Transaction_VLD;

    // output Data from DUT
    logic [1:0]                        LPM_Reply_ACK;
    logic                              LPM_Reply_ACK_VLD, LPM_Reply_Data_VLD, LPM_NATIVE_I2C;
    logic [AUX_DATA_WIDTH-1:0]         LPM_Reply_Data;
    logic                              HPD_Detect, HPD_IRQ, CTRL_Native_Failed;

    ////////////////// LINK Training Signals //////////////////////
    
    // input Data to DUT
    logic [AUX_DATA_WIDTH-1:0] Lane_Align, MAX_VTG, EQ_RD_Value, PRE, VTG, Link_BW_CR;
    logic [3:0]                CR_Done, EQ_CR_DN, Channel_EQ, Symbol_Lock;
    logic [1:0]                MAX_TPS_SUPPORTED, Link_LC_CR; 
    logic                      EQ_Data_VLD, Driving_Param_VLD, LPM_Start_CR, MAX_TPS_SUPPORTED_VLD;

    // output Data from DUT
    logic [AUX_DATA_WIDTH-1:0] EQ_Final_ADJ_BW;
    logic [1:0]                EQ_Final_ADJ_LC;
    logic                      FSM_CR_Failed, EQ_Failed, EQ_LT_Pass;

    rand op_code operation;

    ///////////////////////////////////////////////////////////////
    /////////////////////// CONSTRAINTS ///////////////////////////
    ///////////////////////////////////////////////////////////////

    

    ///////////////////////////////////////////////////////////////
    /////////////////////// CONSTRUCTOR ///////////////////////////
    ///////////////////////////////////////////////////////////////

    function new(string name = "dp_tl_lpm_sequence_item");
        super.new(name);
    endfunction //new()

    ///////////////////////////////////////////////////////////////
    ///////////////////////// METHODS /////////////////////////////
    ///////////////////////////////////////////////////////////////

    // function string convert2string();
    //     return $sformatf("%s name_1 = %0s, name_2 = %0s, name_3 = %0s", super.convert2string(), name_1, name_2, name_3);
    // endfunction

endclass //dp_tl_lpm_sequence_item extends superClass