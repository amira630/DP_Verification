module dp_sva (
    input dp_tl_sequence_item seq_item
);

    ///////////////////////////////////////////////////////////////
    /////////////// Assertions for i2c_request task ///////////////
    ///////////////////////////////////////////////////////////////

    // Assertion 1: Valid SPM_CMD in i2c_request task
    // Ensures that SPM_CMD is either AUX_I2C_READ or AUX_I2C_WRITE.
    property valid_spm_cmd;
        @(posedge clk_AUX)
        seq_item.SPM_Transaction_VLD |-> 
        (seq_item.SPM_CMD == AUX_I2C_READ || seq_item.SPM_CMD == AUX_I2C_WRITE ||seq_item.SPM_CMD == AUX_I2C_WRITE_STATUS_UPDATE);
    endproperty
    assert property (valid_spm_cmd)
        else $error("Invalid SPM_CMD value in i2c_request task");

    // Assertion 2: Valid acknowledgment in i2c_request task
    // Ensures that SPM_Reply_ACK matches the expected I2C_ACK.
    property valid_spm_ack;
        @(posedge clk_AUX)
        seq_item.SPM_NATIVE_I2C && seq_item.SPM_Reply_ACK_VLD |-> 
        (seq_item.SPM_Reply_ACK == I2C_ACK[3:2]) || (seq_item.SPM_Reply_ACK == I2C_NACK[3:2])|| (seq_item.SPM_Reply_ACK == I2C_DEFER[3:2]);
    endproperty
    assert property (valid_spm_ack)
        else $error("SPM_Reply_ACK does not match expected I2C_ACK in i2c_request task");

    // Assertion 3: Valid SPM_Transaction_VLD
    // Ensures that SPM_Transaction_VLD is asserted during a transaction.
    // property valid_spm_transaction_vld;
    //     @(posedge clk_AUX)
    //     seq_item.SPM_Transaction_VLD && !(seq_item.LPM_Transaction_VLD) |-> 1'b1;
    // endproperty
    // assert property (valid_spm_transaction_vld)
    //     else $error("SPM_Transaction_VLD is not asserted during a transaction");

    // Assertion 4: Valid SPM_Address
    // Ensures that SPM_Address is within the valid 20-bit address range.
    property valid_spm_address;
        @(posedge clk_AUX)
        if(seq_item.SPM_Transaction_VLD) seq_item.SPM_Address inside {[20'h00000:20'hFFFFF]};
    endproperty
    assert property (valid_spm_address)
        else $error("SPM_Address is out of range in i2c_request task");

    // Assertion 5: Valid SPM_LEN
    // Ensures that SPM_LEN is always 1.
    property valid_spm_len;
        @(posedge clk_AUX)
        if(seq_item.SPM_Transaction_VLD) (seq_item.SPM_LEN == 8'b0) |-> 1'b1;
    endproperty
    assert property (valid_spm_len)
        else $error("SPM_LEN is out of range in i2c_request task");
    
    // // Assertion 6: Valid SPM_DATA
    // // Ensures that SPM_LEN is always 1.
    // property valid_spm_data;
    //     @(posedge clk_AUX)
    //     seq_item.SPM_NATIVE_I2C && |-> SPM_Reply_Data_VLD; // need to know if read or write so that i can know when to expect data to be received.
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
        seq_item.LPM_Transaction_VLD |-> 
        (seq_item.LPM_CMD == AUX_NATIVE_READ) || (seq_item.LPM_CMD == AUX_NATIVE_WRITE);
    endproperty
    assert property (valid_lpm_cmd_read)
        else $error("Invalid LPM_CMD value in native_read_request task");

    // Assertion 7: Valid acknowledgment in native_read_request task
    // Ensures that LPM_Reply_ACK matches the expected AUX_ACK.
    property valid_lpm_ack;
        @(posedge clk_AUX)
        seq_item.LPM_Native_I2C && seq_item.LPM_Reply_ACK_VLD &&  (seq_item.LPM_CMD == AUX_NATIVE_READ)|-> 
        (seq_item.LPM_Reply_ACK == AUX_ACK[1:0]) || (seq_item.LPM_Reply_ACK == AUX_DEFER[1:0]);
    endproperty
    assert property (valid_lpm_ack)
        else $error("LPM_Reply_ACK does not match expected AUX_ACK in native_read_request task");

    // Assertion 8: Valid LPM_Transaction_VLD in native_read_request task
    // Ensures that LPM_Transaction_VLD is asserted during a transaction.
    // property valid_lpm_transaction_vld_read;
    //     @(posedge clk_AUX)
    //     seq_item.LPM_Transaction_VLD |-> 1'b1;
    // endproperty
    // assert property (valid_lpm_transaction_vld_read)
    //     else $error("LPM_Transaction_VLD is not asserted during native_read_request task");

    // Assertion 9: Valid LPM_Address in native_read_request task
    // Ensures that LPM_Address is within the valid 20-bit address range.
    property valid_lpm_address_read;
        @(posedge clk_AUX)
        if(seq_item.LPM_Transaction_VLD) seq_item.LPM_Address inside {[20'h00000:20'hFFFFF]};
    endproperty
    assert property (valid_lpm_address_read)
        else $error("LPM_Address is out of range in native_read_request task");

    // Assertion 10: Valid LPM_LEN in native_read_request task
    // Ensures that LPM_LEN is within the valid 8-bit range.
    property valid_lpm_len_read;
        @(posedge clk_AUX)
        if(seq_item.LPM_Transaction_VLD) seq_item.LPM_LEN inside {[8'h00:8'hFF]}; // max 16 bytes of data in 1 transaction
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
    //     seq_item.LPM_Transaction_VLD |-> 
    //     (seq_item.LPM_CMD == AUX_NATIVE_WRITE);
    // endproperty
    // assert property (valid_lpm_cmd_write)
    //     else $error("Invalid LPM_CMD value in native_write_request task");

    // Not sure if this is needed
    // Assertion 11: Valid LPM_Data size in native_write_request task
    // Ensures that the size of LPM_Data matches LPM_LEN + 1.
    // property valid_lpm_data_size;
    //     @(posedge clk_AUX)
    //     seq_item.LPM_Transaction_VLD && seq_item.LPM_CMD == AUX_NATIVE_WRITE |-> 
    //     (seq_item.LPM_Data.size() == seq_item.LPM_LEN + 1);
    // endproperty
    // assert property (valid_lpm_data_size)
    //     else $error("LPM_Data size does not match LPM_LEN + 1 in native_write_request task");

    // Assertion 12: Valid acknowledgment in native_write_request task
    // Ensures that LPM_Reply_ACK matches the expected AUX_ACK.
    property valid_lpm_ack_write;
        @(posedge clk_AUX)
        seq_item.LPM_Native_I2C && seq_item.LPM_Reply_ACK_VLD |-> 
        (seq_item.LPM_Reply_ACK == AUX_ACK[1:0]) || (seq_item.LPM_Reply_ACK == AUX_NACK[1:0]) || (seq_item.LPM_Reply_ACK == AUX_DEFER[1:0]);
    endproperty
    assert property (valid_lpm_ack_write)
        else $error("LPM_Reply_ACK does not match expected AUX_ACK in native_write_request task");

    // Assertion 13: Valid LPM_Address in native_write_request task
    // Ensures that LPM_Address is within the valid 20-bit address range.
    property valid_lpm_address_write;
        @(posedge clk_AUX)
        if(seq_item.LPM_Transaction_VLD) seq_item.LPM_Address inside {[20'h00000:20'hFFFFF]};
    endproperty
    assert property (valid_lpm_address_write)
        else $error("LPM_Address is out of range in native_write_request task");

    // Assertion 14: Valid LPM_LEN in native_write_request task
    // Ensures that LPM_LEN is within the valid 8-bit range.
    property valid_lpm_len_write;
        @(posedge clk_AUX)
        if(seq_item.LPM_Transaction_VLD) seq_item.LPM_LEN inside {[8'h00:8'hFF]};
    endproperty
    assert property (valid_lpm_len_write)
        else $error("LPM_LEN is out of range in native_write_request task");
        // Assertion 14: Valid LPM_LEN in native_write_request task

    // Assertion 14: Valid LPM_data (the M byte) in native_write_reply task
    property valid_lpm_nack_write;
        @(posedge clk_AUX)
        seq_item.LPM_Native_I2C && seq_item.LPM_Reply_ACK_VLD && (seq_item.LPM_Reply_ACK == AUX_NACK[1:0]) |=> seq_item.LPM_Reply_Data_VLD;
    endproperty

    assert property (valid_lpm_nack_write)
        else $error("LPM_LEN is out of range in native_write_request task");

    // Assertion 15: Replies cannot be sent to both LPM and SPM simultaneously
    assert property (!(seq_item.LPM_Native_I2C && seq_item.SPM_Native_I2C))
        else $error("Responses to both LPM and SPM are being sent from the Link Layer to the Policy Makers");
    
    // Assertion 16: Valid LPM_Transaction_VLD and SPM_Transaction_VLD
    assert property (!(seq_item.LPM_Transaction_VLD && seq_item.SPM_Transaction_VLD))
        else $error("Both LPM and SPM are sending transaction requests simultaneously!");    

    // Assertion 17: Valid LPM_data in native_write_reply task
    // Ensures that LPM_Reply_Data_VLD is equal to zero when we write.
    property valid_lpm_data_reply;
        @(posedge clk_AUX)
        seq_item.LPM_Native_I2C && (seq_item.operation == 4'b0100) && $past(seq_item.LPM_Reply_ACK_VLD) && ($past(seq_item.LPM_Reply_ACK) != AUX_NACK[1:0]) |-> !seq_item.LPM_Reply_Data_VLD;
    endproperty

    assert property (valid_lpm_data_reply)
        else $error("This is a native write reply there shouldn't be any data in the reply");
    
    // Assertion 18: Valid LPM_data in i2c_write_reply task
    // Ensures that SPM_Reply_Data_VLD is equal to zero when we write.
    // property valid_spm_data_reply;
    //     @(posedge clk_AUX)
    //     seq_item.SPM_Native_I2C && (seq_item.operation == 4'b0010) && $past(seq_item.SPM_Reply_ACK_VLD) |-> !seq_item.LPM_Reply_Data_VLD;
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
        seq_item.HPD_Detect && !seq_item.HPD_IRQ |=> seq_item.Driving_Param_VLD && seq_item.Config_Param_VLD && seq_item.LPM_Start_CR && seq_item.LPM_Transaction_VLD && !seq_item.SPM_Transaction_VLD;
    endproperty
    assert property (cr_lt_init)
        else $error("LPM_Start_CR is not initialized to 1 in CR_LT task");
   
    property cr_lt_pre_vtg;
        @(posedge clk_AUX)
        seq_item.LPM_Transaction_VLD && seq_item.Driving_Param_VLD |-> !($stable(seq_item.VTG)) && !($stable(seq_item.PRE));
    endproperty
    assert property (cr_lt_init)
        else $error("LPM_Start_CR is not initialized to 1 in CR_LT task");

    // Assertion 20: FSM_CR_Failed initialization
    // Ensures that FSM_CR_Failed is initialized to 1 before starting the loop.
    property cr_lt_fsm_cr_failed_init;
        @(posedge clk_AUX)
        seq_item.LPM_Transaction_VLD && seq_item.FSM_CR_Failed |=> seq_item.LPM_Start_CR;
    endproperty
    assert property (cr_lt_fsm_cr_failed_init)
        else $error("FSM_CR_Failed is not initialized to 1 in CR_LT task");

    // not sure if this is needed
    // Assertion 18: Randomization of Link Parameters
    // Ensures that Link_BW_CR, Link_LC_CR, MAX_VTG, and MAX_PRE are randomized.
    // property cr_lt_randomization;
    //     @(posedge clk_AUX)
    //     seq_item.Link_BW_CR.rand_mode == 1 &&
    //     seq_item.Link_LC_CR.rand_mode == 1 &&
    //     seq_item.MAX_VTG.rand_mode == 1 &&
    //     seq_item.MAX_PRE.rand_mode == 1;
    // endproperty
    // assert property (cr_lt_randomization)
    //     else $error("Link parameters are not randomized in CR_LT task");

    // Assertion 19: Valid Driving Parameters
    // Ensures that Driving_Param_VLD and Config_Param_VLD are valid during the transaction.
    // property cr_lt_valid_driving_params;
    //     @(posedge clk_AUX)
    //     seq_item.Driving_Param_VLD == 1'b1 &&
    //     seq_item.Config_Param_VLD == 1'b1;
    // endproperty
    // assert property (cr_lt_valid_driving_params)
    //     else $error("Driving or Config parameters are not valid in CR_LT task");

    assert property (cr_lt_completed)
        else $error("CR_Completed is not set or FSM_CR_Failed is not cleared when CR_DONE is asserted in CR_LT task");

    // Assertion 18: CR Completion
    // Ensures that CR_Completed is set when the clock recovery stage is completed.
    property cr_lt_completion;
        @(posedge clk_AUX)
        !(seq_item.CR_Completed && seq_item.FSM_CR_Failed);
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
    //     seq_item.MAX_TPS_SUPPORTED.rand_mode == 1 &&
    //     seq_item.VTG.rand_mode == 1 &&
    //     seq_item.PRE.rand_mode == 1;
    // endproperty
    // assert property (eq_lt_randomization)
    //     else $error("EQ parameters are not randomized in EQ_LT task");

    // Assertion 20: EQ Data Validity
    // Ensures that EQ_Data_VLD is asserted during the equalization process.
    property eq_lt_data_validity;
        @(posedge clk_AUX)
        seq_item.EQ_Data_VLD == 1'b1;
    endproperty
    assert property (eq_lt_data_validity)
        else $error("EQ_Data_VLD is not asserted during EQ_LT task");

    // Assertion 21: EQ Completion
    // Ensures that EQ_LT_Pass is set when equalization is completed successfully.
    property eq_lt_completion;
        @(posedge clk_AUX)
        !(seq_item.EQ_LT_Pass && seq_item.EQ_Failed);
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
        !seq_item.rst_n |-> 
        (!seq_item.LPM_Transaction_VLD && !seq_item.SPM_Transaction_VLD);
    endproperty
    assert property (valid_reset_behavior)
        else $error("Transaction validity flags are not deasserted during reset");

    // Assertion 22: Valid Detect Behavior
    // Ensures that Sink remains connected to the source
    property valid_detect_behavior;
        @(posedge clk_AUX)
        seq_item.HPD_Detect && !seq_item.rst_n |=> seq_item.HPD_Detect;
    endproperty
    assert property (valid_detect_behavior)
        else $error("Sink is not connected to the source");

    // Assertion 23: Valid Data Queue Initialization
    // Ensures that the data queue is initialized correctly during write transactions.
    // property valid_data_queue_init;
    //     @(posedge clk_AUX)
    //     seq_item.LPM_CMD == AUX_NATIVE_WRITE |-> 
    //     (seq_item.LPM_Data.size() > 0);
    // endproperty
    // assert property (valid_data_queue_init)
    //     else $error("Data queue is not initialized correctly during write transactions");

endmodule