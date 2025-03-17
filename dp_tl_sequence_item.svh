class dp_tl_sequence_item extends uvm_sequence_item;
    `uvm_object_utils(dp_tl_sequence_item);

    logic reset_n;   // Reset is asynchronous active low
    
    ///////////////////////////////////////////////////////////////
    /////////////////// STREAM POLICY MAKER ///////////////////////
    ///////////////////////////////////////////////////////////////

    logic [AUX_ADDRESS_WIDTH-1:0] SPM_Address;
    logic [AUX_DATA_WIDTH-1:0]    SPM_Data, SPM_LEN, SPM_Reply_Data;
    logic [1:0]                   SPM_CMD, SPM_Reply_ACK;
    logic                         SPM_Reply_ACK_VLD, SPM_Reply_Data_VLD, SPM_NATIVE_I2C, SPM_Transaction_VLD;

    ///////////////////////////////////////////////////////////////
    //////////////////// LINK POLICY MAKER ////////////////////////
    ///////////////////////////////////////////////////////////////
    
    logic [AUX_ADDRESS_WIDTH-1:0] LPM_Address;
    logic [AUX_DATA_WIDTH-1:0]    LPM_Data, LPM_LEN, LPM_Reply_Data;
    logic [1:0]                   LPM_CMD, LPM_Reply_ACK;
    logic                         LPM_Reply_ACK_VLD, LPM_Reply_Data_VLD, LPM_NATIVE_I2C,LPM_Transaction_VLD;
    logic                         HPD_Detect, HPD_IRQ;
    ////////////////// LINK Training Signals //////////////////////
    logic [AUX_DATA_WIDTH-1:0] Link_LC_CR, Link_BW_CR, PRE, VTG, EQ_RD_Value, Lane_Align, MAX_VTG, EQ_Final_ADJ_BW;
    logic [3:0] CR_Done, EQ_CR_DN, Channel_EQ, Symbol_Lock;
    logic [1:0] EQ_Final_ADJ_LC;
    logic       LPM_Start_CR, Driving_Param_VLD, EQ_Data_VLD, FSM_CR_Failed, EQ_Failed, EQ_LT_Pass;

    ///////////////////////////////////////////////////////////////
    /////////////////////// CONSTRUCTOR ///////////////////////////
    ///////////////////////////////////////////////////////////////

    function new(string name = "dp_tl_sequence_item");
        super.new(name);
    endfunction //new()

    ///////////////////////////////////////////////////////////////
    ///////////////////////// METHODS /////////////////////////////
    ///////////////////////////////////////////////////////////////

    function string convert2string();
        return $sformatf("%s name_1 = %0s, name_2 = %0s, name_3 = %0s", super.convert2string(), name_1, name_2, name_3);
    endfunction

endclass //dp_tl_sequence_item extends superClass
