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
    logic                              HPD_Detect, HPD_IRQ, CTRL_Native_Failed, Timer_Timeout;

    ////////////////// LINK Training Signals //////////////////////
    
    // input Data to DUT
    logic [AUX_DATA_WIDTH-1:0] Lane_Align, EQ_RD_Value, PRE, VTG, Link_BW_CR;
    logic [3:0]                CR_DONE, EQ_CR_DN, Channel_EQ, Symbol_Lock;
    logic [1:0]                MAX_TPS_SUPPORTED, Link_LC_CR, MAX_PRE, MAX_VTG; 
    logic                      EQ_Data_VLD, Driving_Param_VLD, Config_Param_VLD, LPM_Start_CR, MAX_TPS_SUPPORTED_VLD, CR_DONE_VLD;

    // output Data from DUT
    logic [AUX_DATA_WIDTH-1:0] EQ_Final_ADJ_BW;
    logic [1:0]                EQ_Final_ADJ_LC;
    logic                      FSM_CR_Failed, EQ_Failed, EQ_LT_Pass, CR_Completed, EQ_FSM_CR_Failed;

    op_code operation;

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

    ////////////////// LINK Training Signals //////////////////////



    // Convert the sequence item to a string representation
    function string convert2string();
        return $sformatf("%s Operation: %0s, LPM_Data = %0b, LPM_ADDRESS = %0b, LPM_LENGTH = %0b, LPM_CMD = %0b, LPM_TRANS_VALID = %0b,LPM_REPLY_DATA = %0b, LPM_REPLY_ACK = %0b, LPM_REPLY_DATA_VALID = %0b, LPM_REPLY_ACK_VALID = %0b, LPM_NATIVE_I2C = %0bو CTRL_Native_Failed = %0b, HPD_Detect = %0b, HPD_IRQ = %0b", super.convert2string(), operation, LPM_Data, LPM_Address, LPM_LEN, LPM_CMD, LPM_Transaction_VLD, LPM_Reply_Data, LPM_Reply_ACK, LPM_Reply_Data_VLD, LPM_Reply_ACK_VLD, LPM_NATIVE_I2C, CTRL_Native_Failed, HPD_Detect, HPD_IRQ);
    endfunction

endclass //dp_tl_lpm_sequence_item extends superClass