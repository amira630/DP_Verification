import test_parameters_pkg::*;
import uvm_pkg::*;
`include "uvm_macros.svh"

module dp_sva (dp_tl_if.DUT tl_if, dp_sink_if.DUT sink_if);

    logic rst_n;   // Reset is asynchronous active low
    bit clk_AUX, clk_RBR, clk_HBR, clk_HBR2, clk_HBR3, MS_Stm_CLK;

    ///////////////////////////////////////////////////////////////
    //////////////////// AUXILIARY CHANNEL ////////////////////////
    /////////////////////////////////////////////////////////////// 

    /////////////////// STREAM POLICY MAKER ///////////////////////

    logic [AUX_ADDRESS_WIDTH-1:0] SPM_Address;
    logic [AUX_DATA_WIDTH-1:0]  SPM_Data, SPM_LEN, SPM_Reply_Data;
    logic [1:0]  SPM_CMD, SPM_Reply_ACK;
    logic        SPM_Reply_ACK_VLD, SPM_Reply_Data_VLD, SPM_NATIVE_I2C, SPM_Transaction_VLD;
    logic        CTRL_I2C_Failed;

    //////////////////// LINK POLICY MAKER ////////////////////////
    
    logic [AUX_ADDRESS_WIDTH-1:0] LPM_Address;
    logic [AUX_DATA_WIDTH-1:0]    LPM_Data, LPM_LEN, LPM_Reply_Data;
    logic [1:0]                   LPM_CMD, LPM_Reply_ACK;
    logic                         LPM_Reply_ACK_VLD, LPM_Reply_Data_VLD,LPM_Transaction_VLD;
    logic                         HPD_Detect, HPD_IRQ, CTRL_Native_Failed;
    logic                         LPM_NATIVE_I2C;            

    ////////////////// LINK Training Signals //////////////////////

    logic [AUX_DATA_WIDTH-1:0] Link_BW_CR, PRE, VTG, EQ_RD_Value, Lane_Align, EQ_Final_ADJ_BW;
    logic [3:0] CR_DONE, EQ_CR_DN, Channel_EQ, Symbol_Lock;
    logic [1:0] Link_LC_CR, EQ_Final_ADJ_LC, MAX_TPS_SUPPORTED, MAX_VTG, MAX_PRE;
    logic       LPM_Start_CR, Driving_Param_VLD, EQ_Data_VLD, FSM_CR_Failed, EQ_FSM_CR_Failed, EQ_Failed, EQ_LT_Pass, Config_Param_VLD, CR_DONE_VLD;
    logic       LPM_Start_CR_VLD, CR_Completed, MAX_TPS_SUPPORTED_VLD, Timer_Timeout;

    ///////////////////////////////////////////////////////////////
    ////////////////// ISOCHRONOUS TRANSPORT //////////////////////
    ///////////////////////////////////////////////////////////////

    /////////////////// STREAM POLICY MAKER ///////////////////////

    logic [AUX_DATA_WIDTH-1:0] SPM_Lane_BW;
    logic [7:0]                SPM_MSA [23:0]; // 24 bytes of MSA data
    logic [1:0]                SPM_Lane_Count, SPM_BW_Sel;
    logic                      SPM_ISO_start, SPM_MSA_VLD;

    /////////////////// MAIN STREAM SOURCE ///////////////////////

    logic [47:0] MS_Pixel_Data;
    logic [9:0]  MS_Stm_BW;
    logic        MS_DE, MS_VSYNC, MS_HSYNC;

    ///////////////////////////////////////////////////////////////
    //////////////////// AUXILIARY CHANNEL ////////////////////////
    ///////////////////////////////////////////////////////////////

    ///////////////////// PHYSICAL LAYER //////////////////////////

    logic [AUX_DATA_WIDTH:0]    aux_data, PHY_ADJ_BW;
    logic [1:0]                 PHY_ADJ_LC, PHY_Instruct;
    logic                       HPD_Signal, AUX_START_STOP, PHY_START_STOP, PHY_Instruct_VLD;

    ///////////////////////////////////////////////////////////////
    ////////////////// ISOCHRONOUS TRANSPORT //////////////////////
    ///////////////////////////////////////////////////////////////

    ///////////////////// PHYSICAL LAYER //////////////////////////

    logic [AUX_DATA_WIDTH-1:0] ISO_symbols_lane0, ISO_symbols_lane1, ISO_symbols_lane2, ISO_symbols_lane3;
    logic                      Control_sym_flag_lane0, Control_sym_flag_lane1, Control_sym_flag_lane2, Control_sym_flag_lane3;

    wire [AUX_DATA_WIDTH-1:0] AUX_IN_OUT; // The AUX_IN_OUT signal is a bidirectional signal used for the DisplayPort auxiliary channel communication. It carries the data between the source and sink devices.

assign clk_AUX = tl_if.clk_AUX;
assign clk_RBR = tl_if.clk_RBR;
assign clk_HBR = tl_if.clk_HBR;
assign clk_HBR2 = tl_if.clk_HBR2;
assign clk_HBR3 = tl_if.clk_HBR3;

assign rst_n = tl_if.rst_n;

// HPD signal
assign HPD_Detect = tl_if.HPD_Detect;
assign HPD_IRQ = tl_if.HPD_IRQ;
assign HPD_Signal = sink_if.HPD_Signal;

assign Timer_Timeout = tl_if.Timer_Timeout;

// AUX - SPM
assign SPM_CMD = tl_if.SPM_CMD;
assign SPM_Transaction_VLD = tl_if.SPM_Transaction_VLD;
assign SPM_LEN = tl_if.SPM_LEN;
assign SPM_Address = tl_if.SPM_Address;
assign SPM_Data = tl_if.SPM_Data;
assign SPM_Reply_ACK = tl_if.SPM_Reply_ACK;
assign SPM_Reply_Data_VLD = tl_if.SPM_Reply_Data_VLD;
assign SPM_Reply_ACK_VLD = tl_if.SPM_Reply_ACK_VLD;
assign SPM_NATIVE_I2C = tl_if.SPM_NATIVE_I2C;
assign SPM_Reply_Data = tl_if.SPM_Reply_Data;
assign CTRL_I2C_Failed = tl_if.CTRL_I2C_Failed;
// ISO - SPM
assign SPM_Lane_BW = tl_if.SPM_Lane_BW;
assign SPM_Lane_Count = tl_if.SPM_Lane_Count;
assign SPM_MSA = tl_if.SPM_MSA;
assign SPM_MSA_VLD = tl_if.SPM_MSA_VLD;
assign SPM_BW_Sel = tl_if.SPM_BW_Sel;
assign SPM_ISO_start = tl_if.SPM_ISO_start;

// AUX - LPM
assign LPM_CMD = tl_if.LPM_CMD;
assign LPM_Transaction_VLD = tl_if.LPM_Transaction_VLD;
assign LPM_LEN = tl_if.LPM_LEN;
assign LPM_Address = tl_if.LPM_Address;
assign LPM_Data = tl_if.LPM_Data;
assign LPM_Reply_ACK = tl_if.LPM_Reply_ACK;
assign LPM_Reply_Data_VLD = tl_if.LPM_Reply_Data_VLD;
assign LPM_Reply_ACK_VLD = tl_if.LPM_Reply_ACK_VLD;
assign LPM_NATIVE_I2C = tl_if.LPM_NATIVE_I2C;
assign LPM_Reply_Data = tl_if.LPM_Reply_Data;
assign CTRL_Native_Failed = tl_if.CTRL_Native_Failed;

// AUX - LT
assign LPM_Start_CR = tl_if.LPM_Start_CR;
assign CR_DONE = tl_if.CR_DONE;
assign CR_DONE_VLD = tl_if.CR_DONE_VLD;
assign CR_Completed = tl_if.CR_Completed;
assign FSM_CR_Failed = tl_if.FSM_CR_Failed;
assign Link_LC_CR = tl_if.Link_LC_CR;
assign Link_BW_CR = tl_if.Link_BW_CR;
assign MAX_VTG = tl_if.MAX_VTG;
assign MAX_PRE = tl_if.MAX_PRE;
assign Driving_Param_VLD = tl_if.Driving_Param_VLD;
assign Config_Param_VLD = tl_if.Config_Param_VLD;
assign PRE = tl_if.PRE;
assign VTG = tl_if.VTG;
assign MAX_TPS_SUPPORTED = tl_if.MAX_TPS_SUPPORTED;
assign MAX_TPS_SUPPORTED_VLD = tl_if.MAX_TPS_SUPPORTED_VLD;
assign EQ_RD_Value = tl_if.EQ_RD_Value;
assign EQ_CR_DN = tl_if.EQ_CR_DN;
assign EQ_Data_VLD = tl_if.EQ_Data_VLD;
assign EQ_LT_Pass = tl_if.EQ_LT_Pass;
assign EQ_Failed = tl_if.EQ_Failed;
assign EQ_Final_ADJ_BW = tl_if.EQ_Final_ADJ_BW;
assign EQ_Final_ADJ_LC = tl_if.EQ_Final_ADJ_LC;
assign EQ_FSM_CR_Failed = tl_if.EQ_FSM_CR_Failed;
assign Channel_EQ = tl_if.Channel_EQ;
assign Symbol_Lock = tl_if.Symbol_Lock;
assign Lane_Align = tl_if.Lane_Align;

// MSS - ISO 
assign MS_Pixel_Data = tl_if.MS_Pixel_Data;
assign MS_Stm_BW = tl_if.MS_Stm_BW;
assign MS_DE = tl_if.MS_DE;
assign MS_VSYNC = tl_if.MS_VSYNC;
assign MS_HSYNC = tl_if.MS_HSYNC;

// AUX - PHY
assign PHY_ADJ_BW = sink_if.PHY_ADJ_BW;
assign PHY_ADJ_LC = sink_if.PHY_ADJ_LC;
assign PHY_Instruct = sink_if.PHY_Instruct;
assign PHY_Instruct_VLD = sink_if.PHY_Instruct_VLD;
assign PHY_START_STOP = sink_if.PHY_START_STOP;
assign AUX_START_STOP = sink_if.AUX_START_STOP;
assign AUX_IN_OUT = sink_if.AUX_IN_OUT;

// ISO - PHY
assign ISO_symbols_lane0 = sink_if.ISO_symbols_lane0;
assign ISO_symbols_lane1 = sink_if.ISO_symbols_lane1;
assign ISO_symbols_lane2 = sink_if.ISO_symbols_lane2;
assign ISO_symbols_lane3 = sink_if.ISO_symbols_lane3;
assign Control_sym_flag_lane0 = sink_if.Control_sym_flag_lane0;
assign Control_sym_flag_lane1 = sink_if.Control_sym_flag_lane1;
assign Control_sym_flag_lane2 = sink_if.Control_sym_flag_lane2;
assign Control_sym_flag_lane3 = sink_if.Control_sym_flag_lane3;

    ///////////////////////////////////////////////////////////////
    /////////////// Assertions for i2c_request task ///////////////
    ///////////////////////////////////////////////////////////////

    // Assertion 1: Valid SPM_CMD in i2c_request task
    // Ensures that SPM_CMD is either AUX_I2C_READ or AUX_I2C_WRITE.
    property valid_spm_cmd;
        @(posedge clk_AUX)
        SPM_Transaction_VLD |-> 
        (SPM_CMD == AUX_I2C_READ || SPM_CMD == AUX_I2C_WRITE || SPM_CMD == AUX_I2C_WRITE_STATUS_UPDATE);
    endproperty
    assert property (valid_spm_cmd)
        else $error("Invalid SPM_CMD value in i2c_request task");

    // Assertion 2: Valid acknowledgment in i2c_request task
    // Ensures that SPM_Reply_ACK matches the expected I2C_ACK.
    property valid_spm_ack;
        @(posedge clk_AUX)
        SPM_NATIVE_I2C && SPM_Reply_ACK_VLD |-> 
        (SPM_Reply_ACK == I2C_ACK[3:2]) || (SPM_Reply_ACK == I2C_NACK[3:2])|| (SPM_Reply_ACK == I2C_DEFER[3:2]);
    endproperty
    assert property (valid_spm_ack)
        else $error("SPM_Reply_ACK does not match expected I2C_ACK in i2c_request task");

    // Assertion 3: Valid SPM_Transaction_VLD
    // Ensures that SPM_Transaction_VLD is asserted during a transaction.
    // property valid_spm_transaction_vld;
    //     @(posedge clk_AUX)
    //     SPM_Transaction_VLD && !(LPM_Transaction_VLD) |-> 1'b1;
    // endproperty
    // assert property (valid_spm_transaction_vld)
    //     else $error("SPM_Transaction_VLD is not asserted during a transaction");

    // Assertion 4: Valid SPM_Address
    // Ensures that SPM_Address is within the valid 20-bit address range.
    property valid_spm_address;
        @(posedge clk_AUX)
        if(SPM_Transaction_VLD) SPM_Address inside {[20'h00000:20'hFFFFF]};
    endproperty
    assert property (valid_spm_address)
        else $error("SPM_Address is out of range in i2c_request task");

    // Assertion 5: Valid SPM_LEN
    // Ensures that SPM_LEN is always 1.
    property valid_spm_len;
        @(posedge clk_AUX)
        if(SPM_Transaction_VLD) (SPM_LEN == 8'b0) |-> 1'b1;
    endproperty
    assert property (valid_spm_len)
        else $error("SPM_LEN is out of range in i2c_request task");
    
    // // Assertion 6: Valid SPM_DATA
    // // Ensures that SPM_LEN is always 1.
    // property valid_spm_data;
    //     @(posedge clk_AUX)
    //     SPM_NATIVE_I2C && |-> SPM_Reply_Data_VLD; // need to know if read or write so that i can know when to expect data to be received.
    // endproperty
    // assert property (valid_spm_data)
    //     else $error("SPM_LEN is out of range in i2c_request task");

    ///////////////////////////////////////////////////////////////
    /////////// Assertions for native_read_request task ///////////
    ///////////////////////////////////////////////////////////////

    // Assertion 6: Valid LPM_CMD in native_read_request task
    // Ensures that LPM_CMD is set to AUX_NATIVE_READ.
    property valid_lpm_cmd_read;
        @(posedge clk_AUX)
        LPM_Transaction_VLD |-> 
        (LPM_CMD == AUX_NATIVE_READ) || (LPM_CMD == AUX_NATIVE_WRITE);
    endproperty
    assert property (valid_lpm_cmd_read)
        else $error("Invalid LPM_CMD value in native_read_request task");

    // Assertion 7: Valid acknowledgment in native_read_request task
    // Ensures that LPM_Reply_ACK matches the expected AUX_ACK.
    property valid_lpm_ack;
        @(posedge clk_AUX)
        LPM_Native_I2C && LPM_Reply_ACK_VLD &&  (LPM_CMD == AUX_NATIVE_READ)|-> 
        (LPM_Reply_ACK == AUX_ACK[1:0]) || (LPM_Reply_ACK == AUX_DEFER[1:0]);
    endproperty
    assert property (valid_lpm_ack)
        else $error("LPM_Reply_ACK does not match expected AUX_ACK in native_read_request task");

    // Assertion 8: Valid LPM_Transaction_VLD in native_read_request task
    // Ensures that LPM_Transaction_VLD is asserted during a transaction.
    // property valid_lpm_transaction_vld_read;
    //     @(posedge clk_AUX)
    //     LPM_Transaction_VLD |-> 1'b1;
    // endproperty
    // assert property (valid_lpm_transaction_vld_read)
    //     else $error("LPM_Transaction_VLD is not asserted during native_read_request task");

    // Assertion 9: Valid LPM_Address in native_read_request task
    // Ensures that LPM_Address is within the valid 20-bit address range.
    property valid_lpm_address_read;
        @(posedge clk_AUX)
        if(LPM_Transaction_VLD) LPM_Address inside {[20'h00000:20'hFFFFF]};
    endproperty
    assert property (valid_lpm_address_read)
        else $error("LPM_Address is out of range in native_read_request task");

    // Assertion 10: Valid LPM_LEN in native_read_request task
    // Ensures that LPM_LEN is within the valid 8-bit range.
    property valid_lpm_len_read;
        @(posedge clk_AUX)
        if(LPM_Transaction_VLD) LPM_LEN inside {[8'h00:8'hFF]}; // max 16 bytes of data in 1 transaction
    endproperty
    assert property (valid_lpm_len_read)
        else $error("LPM_LEN is out of range in native_read_request task");

    
    ///////////////////////////////////////////////////////////////
    /////////// Assertions for native_write_request task ///////////
    ///////////////////////////////////////////////////////////////

    // // Assertion 11: Valid LPM_CMD in native_write_request task
    // // Ensures that LPM_CMD is set to AUX_NATIVE_WRITE.
    // property valid_lpm_cmd_write;
    //     @(posedge clk_AUX)
    //     LPM_Transaction_VLD |-> 
    //     (LPM_CMD == AUX_NATIVE_WRITE);
    // endproperty
    // assert property (valid_lpm_cmd_write)
    //     else $error("Invalid LPM_CMD value in native_write_request task");

    // Not sure if this is needed
    // Assertion 11: Valid LPM_Data size in native_write_request task
    // Ensures that the size of LPM_Data matches LPM_LEN + 1.
    // property valid_lpm_data_size;
    //     @(posedge clk_AUX)
    //     LPM_Transaction_VLD && LPM_CMD == AUX_NATIVE_WRITE |-> 
    //     (LPM_Data.size() == LPM_LEN + 1);
    // endproperty
    // assert property (valid_lpm_data_size)
    //     else $error("LPM_Data size does not match LPM_LEN + 1 in native_write_request task");

    // Assertion 12: Valid acknowledgment in native_write_request task
    // Ensures that LPM_Reply_ACK matches the expected AUX_ACK.
    property valid_lpm_ack_write;
        @(posedge clk_AUX)
        LPM_Native_I2C && LPM_Reply_ACK_VLD |-> 
        (LPM_Reply_ACK == AUX_ACK[1:0]) || (LPM_Reply_ACK == AUX_NACK[1:0]) || (LPM_Reply_ACK == AUX_DEFER[1:0]);
    endproperty
    assert property (valid_lpm_ack_write)
        else $error("LPM_Reply_ACK does not match expected AUX_ACK in native_write_request task");

    // Assertion 13: Valid LPM_Address in native_write_request task
    // Ensures that LPM_Address is within the valid 20-bit address range.
    property valid_lpm_address_write;
        @(posedge clk_AUX)
        if(LPM_Transaction_VLD) LPM_Address inside {[20'h00000:20'hFFFFF]};
    endproperty
    assert property (valid_lpm_address_write)
        else $error("LPM_Address is out of range in native_write_request task");

    // Assertion 14: Valid LPM_LEN in native_write_request task
    // Ensures that LPM_LEN is within the valid 8-bit range.
    property valid_lpm_len_write;
        @(posedge clk_AUX)
        if(LPM_Transaction_VLD) LPM_LEN inside {[8'h00:8'hFF]};
    endproperty
    assert property (valid_lpm_len_write)
        else $error("LPM_LEN is out of range in native_write_request task");
        // Assertion 14: Valid LPM_LEN in native_write_request task

    // Assertion 14: Valid LPM_data (the M byte) in native_write_reply task
    property valid_lpm_nack_write;
        @(posedge clk_AUX)
        LPM_Native_I2C && LPM_Reply_ACK_VLD && (LPM_Reply_ACK == AUX_NACK[1:0]) |=> LPM_Reply_Data_VLD;
    endproperty

    assert property (valid_lpm_nack_write)
        else $error("LPM_LEN is out of range in native_write_request task");

    // Assertion 15: Replies cannot be sent to both LPM and SPM simultaneously
    assert property (!(LPM_Native_I2C && SPM_Native_I2C))
        else $error("Responses to both LPM and SPM are being sent from the Link Layer to the Policy Makers");
    
    // Assertion 16: Valid LPM_Transaction_VLD and SPM_Transaction_VLD
    assert property (!(LPM_Transaction_VLD && SPM_Transaction_VLD))
        else $error("Both LPM and SPM are sending transaction requests simultaneously!");    

    // Assertion 17: Valid LPM_data in native_write_reply task
    // Ensures that LPM_Reply_Data_VLD is equal to zero when we write.
    property valid_lpm_data_reply;
        @(posedge clk_AUX)
        LPM_Native_I2C && (operation == 4'b0100) && $past(LPM_Reply_ACK_VLD) && ($past(LPM_Reply_ACK) != AUX_NACK[1:0]) |-> !LPM_Reply_Data_VLD;
    endproperty

    assert property (valid_lpm_data_reply)
        else $error("This is a native write reply there shouldn't be any data in the reply");
    
    // Assertion 18: Valid LPM_data in i2c_write_reply task
    // Ensures that SPM_Reply_Data_VLD is equal to zero when we write.
    // property valid_spm_data_reply;
    //     @(posedge clk_AUX)
    //     SPM_Native_I2C && (operation == 4'b0010) && $past(SPM_Reply_ACK_VLD) |-> !LPM_Reply_Data_VLD;
    // endproperty

    // assert property (valid_spm_data_reply)
    //     else $error("This is an i2c write reply there shouldn't be any data in the reply");

    ///////////////////////////////////////////////////////////////
    ///////////////////Assertions for CR_LT Task///////////////////
    ///////////////////////////////////////////////////////////////
    
    // Assertion 19: FSM_CR_Failed initialization
    // Ensures that FSM_CR_Failed is initialized to 1 before starting the loop.
    property cr_lt_init;
        @(posedge clk_AUX)
        HPD_Detect && !HPD_IRQ |=> Driving_Param_VLD && Config_Param_VLD && LPM_Start_CR && LPM_Transaction_VLD && !SPM_Transaction_VLD;
    endproperty
    assert property (cr_lt_init)
        else $error("LPM_Start_CR is not initialized to 1 in CR_LT task");
   
    property cr_lt_pre_vtg;
        @(posedge clk_AUX)
        LPM_Transaction_VLD && Driving_Param_VLD |-> !($stable(VTG)) && !($stable(PRE));
    endproperty
    assert property (cr_lt_init)
        else $error("LPM_Start_CR is not initialized to 1 in CR_LT task");

    // Assertion 20: FSM_CR_Failed initialization
    // Ensures that FSM_CR_Failed is initialized to 1 before starting the loop.
    property cr_lt_fsm_cr_failed_init;
        @(posedge clk_AUX)
        LPM_Transaction_VLD && FSM_CR_Failed |=> LPM_Start_CR;
    endproperty
    assert property (cr_lt_fsm_cr_failed_init)
        else $error("FSM_CR_Failed is not initialized to 1 in CR_LT task");

    // not sure if this is needed
    // Assertion 18: Randomization of Link Parameters
    // Ensures that Link_BW_CR, Link_LC_CR, MAX_VTG, and MAX_PRE are randomized.
    // property cr_lt_randomization;
    //     @(posedge clk_AUX)
    //     Link_BW_CR.rand_mode == 1 &&
    //     Link_LC_CR.rand_mode == 1 &&
    //     MAX_VTG.rand_mode == 1 &&
    //     MAX_PRE.rand_mode == 1;
    // endproperty
    // assert property (cr_lt_randomization)
    //     else $error("Link parameters are not randomized in CR_LT task");

    // Assertion 19: Valid Driving Parameters
    // Ensures that Driving_Param_VLD and Config_Param_VLD are valid during the transaction.
    // property cr_lt_valid_driving_params;
    //     @(posedge clk_AUX)
    //     Driving_Param_VLD == 1'b1 &&
    //     Config_Param_VLD == 1'b1;
    // endproperty
    // assert property (cr_lt_valid_driving_params)
    //     else $error("Driving or Config parameters are not valid in CR_LT task");

    assert property (cr_lt_completed)
        else $error("CR_Completed is not set or FSM_CR_Failed is not cleared when CR_DONE is asserted in CR_LT task");

    // Assertion 18: CR Completion
    // Ensures that CR_Completed is set when the clock recovery stage is completed.
    property cr_lt_completion;
        @(posedge clk_AUX)
        !(CR_Completed && FSM_CR_Failed);
    endproperty
    assert property (cr_lt_completion)
        else $error("CR_Completed is not set or FSM_CR_Failed is not cleared in CR_LT task");

    ///////////////////////////////////////////////////////////////
    // Assertions for EQ_LT Task
    ///////////////////////////////////////////////////////////////

    // Assertion 19: Randomization of EQ Parameters
    // Ensures that MAX_TPS_SUPPORTED, VTG, and PRE are randomized during the transaction.
    // property eq_lt_randomization;
    //     @(posedge clk_AUX)
    //     MAX_TPS_SUPPORTED.rand_mode == 1 &&
    //     VTG.rand_mode == 1 &&
    //     PRE.rand_mode == 1;
    // endproperty
    // assert property (eq_lt_randomization)
    //     else $error("EQ parameters are not randomized in EQ_LT task");

    // Assertion 20: EQ Data Validity
    // Ensures that EQ_Data_VLD is asserted during the equalization process.
    property eq_lt_data_validity;
        @(posedge clk_AUX)
        EQ_Data_VLD == 1'b1;
    endproperty
    assert property (eq_lt_data_validity)
        else $error("EQ_Data_VLD is not asserted during EQ_LT task");

    // Assertion 21: EQ Completion
    // Ensures that EQ_LT_Pass is set when equalization is completed successfully.
    property eq_lt_completion;
        @(posedge clk_AUX)
        !(EQ_LT_Pass && EQ_Failed);
    endproperty
    assert property (eq_lt_completion)
        else $error("EQ_LT_Pass is not set or EQ_Failed is not cleared in EQ_LT task");

    ///////////////////////////////////////////////////////////////
    // General Assertions for Sequence Behavior
    ///////////////////////////////////////////////////////////////

    // Assertion 22: Valid Reset Behavior
    // Ensures that all transaction validity flags are deasserted during reset.
    property valid_reset_behavior;
        @(posedge clk_AUX)
        !rst_n |-> 
        (!LPM_Transaction_VLD && !SPM_Transaction_VLD);
    endproperty
    assert property (valid_reset_behavior)
        else $error("Transaction validity flags are not deasserted during reset");

    // Assertion 22: Valid Detect Behavior
    // Ensures that Sink remains connected to the source
    property valid_detect_behavior;
        @(posedge clk_AUX)
        HPD_Detect && !rst_n |=> HPD_Detect;
    endproperty
    assert property (valid_detect_behavior)
        else $error("Sink is not connected to the source");

    // Assertion 23: Valid Data Queue Initialization
    // Ensures that the data queue is initialized correctly during write transactions.
    // property valid_data_queue_init;
    //     @(posedge clk_AUX)
    //     LPM_CMD == AUX_NATIVE_WRITE |-> 
    //     (LPM_Data.size() > 0);
    // endproperty
    // assert property (valid_data_queue_init)
    //     else $error("Data queue is not initialized correctly during write transactions");

endmodule