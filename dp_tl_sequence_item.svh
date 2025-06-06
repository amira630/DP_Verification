class dp_tl_sequence_item extends uvm_sequence_item;
  `uvm_object_utils(dp_tl_sequence_item);
  
    rand bit rst_n;   // Reset is asynchronous active low

    ///////////////////////////////////////////////////////////////
    //////////////////// AUXILIARY CHANNEL ////////////////////////
    ///////////////////////////////////////////////////////////////  
    
    /////////////////// STREAM POLICY MAKER ///////////////////////

// input Data from the stream policy maker to DUT
    rand logic [AUX_DATA_WIDTH-1:0]    SPM_Data; // Randomized only if write will be supported
    rand bit [AUX_ADDRESS_WIDTH-1:0]   SPM_Address;
    bit [AUX_DATA_WIDTH-1:0]           SPM_LEN;
    rand i2c_aux_request_cmd_e         SPM_CMD; // 00 Write and 01 Read
    bit                                SPM_Transaction_VLD;

// Output Data from DUT to the stream policy maker
    logic [AUX_DATA_WIDTH-1:0] SPM_Reply_Data;
    logic [1:0]                SPM_Reply_ACK;
    logic                      SPM_NATIVE_I2C, SPM_Reply_Data_VLD, SPM_Reply_ACK_VLD, CTRL_I2C_Failed;

    //////////////////// LINK POLICY MAKER ////////////////////////
    
    // input Data to DUT
    logic [AUX_ADDRESS_WIDTH-1:0]      LPM_Address;
    rand logic [AUX_DATA_WIDTH-1:0]    LPM_LEN;
    logic [AUX_DATA_WIDTH-1:0]         LPM_Data;
    rand native_aux_request_cmd_e      LPM_CMD; // 00 Write and 01 Read
    bit                                LPM_Transaction_VLD;

    // output Data from DUT
    logic [1:0]                        LPM_Reply_ACK;
    logic                              LPM_Reply_ACK_VLD, LPM_Reply_Data_VLD, LPM_NATIVE_I2C;
    logic [AUX_DATA_WIDTH-1:0]         LPM_Reply_Data;
    logic                              HPD_Detect, HPD_IRQ, CTRL_Native_Failed;
    logic                              Timer_Timeout;

    ////////////////// LINK Training Signals //////////////////////
    
    // input Data to DUT
    rand logic [AUX_DATA_WIDTH-1:0] Lane_Align, EQ_RD_Value;
    rand logic [AUX_DATA_WIDTH-1:0] Link_BW_CR, PRE, VTG;
    rand logic [3:0]                EQ_CR_DN, Channel_EQ, Symbol_Lock;
    rand logic [3:0]                CR_DONE;
    rand training_pattern_t         MAX_TPS_SUPPORTED;
    rand logic [1:0]                Link_LC_CR, MAX_PRE, MAX_VTG; 
    bit                             EQ_Data_VLD, Driving_Param_VLD, Config_Param_VLD, LPM_Start_CR, CR_DONE_VLD, MAX_TPS_SUPPORTED_VLD;

    // output Data from DUT
    logic [AUX_DATA_WIDTH-1:0] EQ_Final_ADJ_BW;
    logic [1:0]                EQ_Final_ADJ_LC;
    bit                        FSM_CR_Failed, EQ_Failed, EQ_LT_Pass, CR_Completed, EQ_FSM_CR_Failed;

    ///////////////////////////////////////////////////////////////
    ////////////////// ISOCHRONOUS TRANSPORT //////////////////////
    ///////////////////////////////////////////////////////////////

    /////////////////// STREAM POLICY MAKER ///////////////////////

    logic [15:0]               SPM_Lane_BW; // Modified to 16 bits instead of 8 bits
    logic [191:0]              SPM_Full_MSA; // added to contain the full MSA data
    logic [7:0]                SPM_MSA [23:0];
    logic [2:0]                SPM_Lane_Count; // Modified to 3 bits instead of 2 bits
    logic [1:0]                SPM_BW_Sel;
    bit                        SPM_ISO_start, SPM_MSA_VLD;

    rand logic [23:0] Mvid;         //
    rand logic [23:0] Nvid;
    rand logic [15:0] HTotal;       // in pixels
    rand logic [15:0] VTotal;       // in lines
    rand logic [15:0] HStart;       // in pixels
    rand logic [15:0] VStart;       // in lines
    rand logic        HSP, VSP;
    rand logic [14:0] HSW;          // in pixels    
    rand logic [14:0] VSW;          // in lines
    rand logic [15:0] HWidth;       // in pixels
    rand logic [15:0] VHeight;      // in lines
    rand logic [7:0]  MISC0;        // for bpc and color format
    rand logic [7:0]  MISC1;        // for colorimetry and colorimetry range

    rand logic [15:0] HFront, HBack, VFront, VBack;

    /////////////////// MAIN STREAM SOURCE ///////////////////////

    rand logic [47:0] MS_Pixel_Data;
    rand logic [9:0]  MS_Stm_BW;        // takes values on MHz max 1Ghz
    rand logic        MS_DE, MS_VSYNC, MS_HSYNC;
    bit MS_Stm_BW_VLD;   // added to indicate if MS_Stm_BW is valid
    bit MS_rst_n; // Reset is asynchronous active low for the MS Stream
    bit WFULL;  // Indicates if the FIFO is full
    //rand bit          MS_Stm_CLK;


    op_code operation;
    
    bit     link_values_locked = 0; // State variable to lock values after first randomization
    bit [AUX_DATA_WIDTH-1:0] prev_vtg;
    bit [AUX_DATA_WIDTH-1:0] prev_pre;
    bit cr_completed_flag = 0; // State variable to track if CR_Completed is 1
    bit [1:0] ISO_LC;
    bit [AUX_DATA_WIDTH-1:0] ISO_BW;
    rand logic [AUX_DATA_WIDTH-1:0]    LPM_Data_queue[$];

    bit LT_Failed, LT_Pass, isflow;
    rand bit error_flag;

    logic [1:0] MAX_PRE_in, MAX_VTG_in;

    real CLOCK_PERIOD; // Clock period in ns

    ///////////////////////////////////////////////////////////////
    /////////////////////// SPM CONSTRAINTS ///////////////////////
    ///////////////////////////////////////////////////////////////
    
    // constraint spm_data_write_constraint {
    //     // if (SPM_CMD == AUX_I2C_WRITE) {
    //         // SPM_Data inside {[0:255]}; // Full range of SPM_Data
    //     // } else {
    //         SPM_Data == 8'bx; // Default value when not AUX_I2C_WRITE
    //     // }
    // }
    
    // constraint spm_cmd_read_only_constraint {
    //     SPM_CMD == AUX_I2C_READ; // Force SPM_CMD to always be AUX_I2C_READ
    // }

    // constraint operation_type_dist {
    //    operation inside {[reset_op:EQ_LT_op]};
    // }

    constraint hsp_vsp_constraint {
        HSP dist {1'b1 := 90, 1'b0 := 10}; // HSP is 1 90% of the time
        VSP dist {1'b1 := 90, 1'b0 := 10}; // VSP is 1 90% of the time
    }

    // // constraint vtotal_constraint {
    // //     (VHeight + VStart - 1) == VTotal; // Ensure VTotal equals VHeight + VStart - 1
    // // }

    // // constraint htotal_constraint {
    // //     (HWidth + HStart - 1) == HTotal; // Ensure HTotal equals HWidth + HStart - 1
    // // }

    // // constraint hstart_constraint {
    // //     HStart inside {[0:HTotal]}; // Ensure HStart is within the range of HTotal
    // // }

    // // constraint vstart_constraint {
    // //     VStart inside {[0:VTotal]}; // Ensure VStart is within the range of VTotal
    // // }

    // // constraint hwidth_constraint {
    // //     HWidth inside {[0:HTotal]}; // Ensure HWidth is within the range of HTotal
    // // }

    // // constraint vheight_constraint {
    // //     VHeight inside {[0:VTotal]}; // Ensure VHeight is within the range of VTotal
    // // }

    constraint misc1_constraint {
        MISC1[7:6] == 2'b00; // Ensure bits 7 and 6 are always 0
        // MISC1[5:0] can be anything, no constraint needed
    }

    constraint misc0_constraint {
        MISC0[7:5] inside {3'b001, 3'b100}; // 8bpc or 16bpc
        MISC0[4] == 1'b0;                  // MISC0[4] must always be 0
        // MISC0[3] inside {1'b0, 1'b1};      // RGB or YCbCr
        if (MISC0[3] == 1'b0) {
            MISC0[2:1] == 2'b00;           // RGB
        } else {
            MISC0[2:1] == 2'b10;           // YCbCr (4:4:4)
        }
        // MISC0[0] can be anything, no constraint needed
    }

    // // constraint hsw_constraint {
    // //     HSW == (HStart - 1) - HBack - HFront; // Ensure HSW is calculated correctly
    // // }
    
    // // constraint vsw_constraint {
    // //     VSW == (VStart - 1) - VBack - VFront; // Ensure VSW is calculated correctly
    // // }

    // // constraint hback_constraint {
    // //     HBack == (HStart - HSW); // Ensure HBack equals HStart - HSW
    // // }

    // // constraint vback_constraint {
    // //     VBack == (VStart - VSW); // Ensure HBack equals VStart - VSW
    // // }    

    // // constraint hfront_constraint {
    // //     HFront == (HTotal - (HStart + HWidth)); // Ensure HFront equals HTotal - (HStart + HWidth)
    // // }

    // // constraint vfront_constraint {
    // //     VFront == (VTotal - (VStart + VHeight)); // Ensure VFront equals VTotal - (VStart + VHeight)
    // // } 

    constraint htotal_range {
        HTotal inside {[100:200]};
    }

    constraint vtotal_range {
        VTotal inside {[100:300]};
    }

    constraint hstart_range {
        HStart inside {[0:HTotal]};
    }

    constraint vstart_range {
        VStart inside {[0:VTotal]};
    }

    constraint hwidth_range {
        HWidth inside {[0:HTotal - HStart + 1]};
    }

    constraint vheight_range {
        VHeight inside {[0:VTotal - VStart + 1]};
    }

    constraint hfront_range {
        HFront inside {[0:HTotal - (HStart + HWidth)]};
    }

    constraint vfront_range {
        VFront inside {[0:VTotal - (VStart + VHeight)]};
    }

    constraint hsw_range {
        HSW inside {[1:32]}; // example range
    }

    constraint vsw_range {
        VSW inside {[1:32]};
    }


    constraint ms_pixel_data_constraint {
        if (MISC0[7:5] == 3'b001) {
            MS_Pixel_Data[47:24] == 24'b0; // Most significant 24 bits are zero for 8bpc mode
        } 
    }

    constraint ms_stm_bw_constraint {
        MS_Stm_BW inside {[10:90]}; // Ensure MS_Stm_BW is within the range 10 to 90
    }

    constraint error_flag_constraint {
        error_flag dist {1'b0 := 90, 1'b1 := 10}; // 90% chance of being 0, 10% chance of being 1
    }

    ///////////////////////////////////////////////////////////////
    /////////////////////// LPM CONSTRAINTS ///////////////////////
    ///////////////////////////////////////////////////////////////

    constraint rst_n_constraint {
        rst_n dist {1'b1 := 90, 1'b0 := 10}; // 90% chance of being 1, 10% chance of being 0
    }

    constraint link_bw_cr_constraint {
        Link_BW_CR inside {8'h06, 8'h0A, 8'h14, 8'h1E}; // Allowed values for Link_BW_CR
    }

    constraint lane_align_constraint {
        foreach (Lane_Align[i]) { 
            if (i == 0 ) { // bit 0 is the align bit
                Lane_Align[i] dist {1'b1 := 90, 1'b0 := 10};
            } else if (i == 7) { // says there has been an update
                Lane_Align[i] == 1'b1;
            } else {
                Lane_Align[i] == 1'b0; // All other bits are set to 0
            }
        }
    }
    
    constraint max_tps_supported_c {
        if (Link_BW_CR == 8'h06 || Link_BW_CR == 8'h0A) { // RBR or HBR
            MAX_TPS_SUPPORTED inside {TPS2, TPS3, TPS4};
        } else if (Link_BW_CR == 8'h14) { // HBR2
            MAX_TPS_SUPPORTED inside {TPS3, TPS4};
        } else if (Link_BW_CR == 8'h1E) { // HBR3
            MAX_TPS_SUPPORTED == TPS4;
        }
    }

    constraint link_lc_cr_constraint {
        Link_LC_CR != 2'b10; // Prevent Link_LC_CR from taking the value 10b
    }

    // Apply distribution to signal based on the Link_LC_CR value
    // Rationale:
    // - If Link_LC_CR is 2'b11, prioritize 4'b1111 with a weight of 60%.
    // - If Link_LC_CR is 2'b01, prioritize 4'b0011 with a weight of 60%.
    // - If Link_LC_CR is 2'b00, prioritize 4'b0001 with a weight of 60%.
    // - Default weight for other values is 40%.
    
    constraint eq_cr_dn_constraint {
        EQ_CR_DN inside {4'b1111, 4'b0011, 4'b0001};
        if (Link_LC_CR == 2'b11) {
            // For 2'b11, prioritize 4'b1111 with 90% weight
            EQ_CR_DN dist {4'b1111 := 90, 4'b0011 :/ 10, 4'b0001 :/ 10};
        } else if (Link_LC_CR == 2'b01) {
            // For 2'b01, prioritize 4'b0011 with 90% weight
            EQ_CR_DN dist {4'b0011 := 90, 4'b1111 :/ 10, 4'b0001 :/ 10};
            // For 2'b00, prioritize 4'b0001 with 90% weight
        } else if (Link_LC_CR == 2'b00) {
            EQ_CR_DN dist {4'b0001 := 90, 4'b0011 :/ 10, 4'b1111 :/ 10};
        }
    }

    constraint cr_done_constraint {
        CR_DONE inside {4'b1111, 4'b0011, 4'b0001};
        if (Link_LC_CR == 2'b11) {
            // For 2'b11, prioritize 4'b1111 with 90% weight
            CR_DONE dist {4'b1111 := 90, 4'b0011 :/ 10, 4'b0001 :/ 10};
        } else if (Link_LC_CR == 2'b01) {
            // For 2'b01, prioritize 4'b0011 with 90% weight
            CR_DONE dist {4'b0011 := 90, 4'b1111 :/ 10, 4'b0001 :/ 10};
            // For 2'b00, prioritize 4'b0001 with 90% weight
        } else if (Link_LC_CR == 2'b00) {
            CR_DONE dist {4'b0001 := 90, 4'b0011 :/ 10, 4'b1111 :/ 10};
        }
    }

    constraint channel_eq_constraint {
        Channel_EQ inside {4'b1111, 4'b0011, 4'b0001};
        if (Link_LC_CR == 2'b11) {
            // For 2'b11, prioritize 4'b1111 with 90% weight
            Channel_EQ dist {4'b1111 := 90, 4'b0011 :/ 10, 4'b0001 :/ 10};
        } else if (Link_LC_CR == 2'b01) {
            // For 2'b01, prioritize 4'b0011 with 90% weight
            Channel_EQ dist {4'b0011 := 90, 4'b1111 :/ 10, 4'b0001 :/ 10};
            // For 2'b00, prioritize 4'b0001 with 90% weight
        } else if (Link_LC_CR == 2'b00) {
            Channel_EQ dist {4'b0001 := 90, 4'b0011 :/ 10, 4'b1111 :/ 10};
        }
    }

    constraint symbol_lock_constraint {
        Symbol_Lock inside {4'b1111, 4'b0011, 4'b0001};
        if (Link_LC_CR == 2'b11) {
            // For 2'b11, prioritize 4'b1111 with 90% weight
            Symbol_Lock dist {4'b1111 := 90, 4'b0011 :/ 10, 4'b0001 :/ 10};
        } else if (Link_LC_CR == 2'b01) {
            // For 2'b01, prioritize 4'b0011 with 90% weight
            Symbol_Lock dist {4'b0011 := 90, 4'b1111 :/ 10, 4'b0001 :/ 10};
            // For 2'b00, prioritize 4'b0001 with 90% weight
        } else if (Link_LC_CR == 2'b00) {
            Symbol_Lock dist {4'b0001 := 90, 4'b0011 :/ 10, 4'b1111 :/ 10};
        }
    }

    constraint max_vtg_constraint {
        MAX_VTG inside {2'b10, 2'b11};
    }

    constraint max_pre_constraint {
        MAX_PRE inside {2'b10, 2'b11};
    }

    constraint pre_vtg_constraint {
        foreach (PRE[i]) {
            if ((i*2 + 1) < AUX_DATA_WIDTH) { // Ensure we don't go out of bounds
                VTG[i*2 +: 2] <= MAX_VTG; // VTG must be less than or equal to MAX_VTG
                PRE[i*2 +: 2] <= MAX_PRE; // PRE must be less than or equal to MAX_PRE

                // Lock VTG if it equals MAX_VTG and LPM_Start_CR is 0
                if (!LPM_Start_CR && prev_vtg[i*2 +: 2] == MAX_VTG) {
                    VTG[i*2 +: 2] == prev_vtg[i*2 +: 2];
                }
                
                // Lock PRE if it equals MAX_PRE and LPM_Start_CR is 0
                if (!LPM_Start_CR && prev_pre[i*2 +: 2] == MAX_PRE) {
                    PRE[i*2 +: 2] == prev_pre[i*2 +: 2];
                }
            }
        }
    }
            
    constraint vtg_pre_relationship {
        foreach (VTG[i]) {
            if ((i*2 + 1) < AUX_DATA_WIDTH) { // Ensure we don't go out of bounds
                if (VTG[i*2 +: 2] == 2'b00) { 
                    if(MAX_PRE == 2'b11) {
                        PRE[i*2 +: 2] inside {2'b00, 2'b01, 2'b10, 2'b11}; // VTG = 0
                    }
                    else {
                        PRE[i*2 +: 2] inside {2'b00, 2'b01, 2'b10}; // VTG = 0
                    }
                } else if (VTG[i*2 +: 2] == 2'b01) {
                    PRE[i*2 +: 2] inside {2'b00, 2'b01, 2'b10};        // VTG = 1
                } else if (VTG[i*2 +: 2] == 2'b10) {
                    PRE[i*2 +: 2] inside {2'b00, 2'b01};               // VTG = 2
                } else if (VTG[i*2 +: 2] == 2'b11) {
                    PRE[i*2 +: 2] == 2'b00;                            // VTG = 3
                }
            }
        }
    }

    constraint lpm_len_constraint {
        LPM_LEN <= 8'h0F; // Ensure LPM_LEN does not exceed 0Fh
    }

    constraint lpm_data_constraint {
        if (LPM_CMD == AUX_NATIVE_WRITE && LPM_Transaction_VLD) {
            LPM_Data_queue.size() == LPM_LEN + 1; // Ensure the queue size matches LPM_LEN + 1
        } else {
            LPM_Data_queue.size() == 0; // Ensure the queue is empty for other commands
        }
    }

    constraint lpm_data_values {
        foreach (LPM_Data_queue[i]) {
                LPM_Data_queue[i] inside {[0:(1 << AUX_DATA_WIDTH) - 1]}; // Randomize valid values
        }
    }

    constraint link_values_lock_constraint {
        if (link_values_locked) {
            Link_BW_CR dist {Link_BW_CR := 1}; // Lock Link_BW_CR
            Link_LC_CR dist {Link_LC_CR := 1}; // Lock Link_LC_CR
            MAX_VTG dist {MAX_VTG:= 1}; // Lock MAX_VTG
            MAX_PRE dist {MAX_PRE:= 1}; // Lock MAX_PRE
        }
    }

    constraint eq_rd_value_constraint {
        EQ_RD_Value[7] == 1'b1; // Ensure the MSB is always 1
        EQ_RD_Value[6:0] inside {7'h00, 7'h01, 7'h02, 7'h03, 7'h04}; // Allowed values for the lower 7 bits

        if (!cr_completed_flag) {
            EQ_RD_Value == EQ_RD_Value; // Maintain the current value until CR_Completed becomes 1
        }
    }

    ///////////////////////////////////////////////////////////////
    /////////////////////// CONSTRUCTOR ///////////////////////////
    ///////////////////////////////////////////////////////////////

    function new(string name = "dp_tl_sequence_item");
      super.new(name);
    endfunction

    ///////////////////////////////////////////////////////////////
    ///////////////////////// METHODS /////////////////////////////
    ///////////////////////////////////////////////////////////////

    function void pre_randomize();
        if (LPM_Start_CR == 1) begin
            prev_vtg = '0; // Reset prev_vtg when LPM_Start_CR is 1
            prev_pre = '0; // Reset prev_pre when LPM_Start_CR is 1
        end

    endfunction

    // Post-randomization logic to eventually allow 4'b1111
    function void post_randomize();
        if (!link_values_locked && LPM_Start_CR == 1) begin
            link_values_locked = 1; // Lock the values after the first randomization
        end
        prev_vtg = VTG; // Store current VTG for next randomization
        prev_pre = PRE; // Store current PRE for next randomization
        if (CR_Completed) begin
            cr_completed_flag = 1; // Allow a new random value when CR_Completed becomes 1
        end
        HBack = HStart - HSW;
        VBack = VStart - VSW;
    endfunction

  // Convert the sequence item to a string representation
    function string convert2string_RQST();
        return $sformatf("%s Operation: %0s, SPM_DATA = %0b, SPM_ADDRESS = %0b, SPM_LEN = %0b, SPM_CMD = %0b, SPM_TRANS_VALID = %0b, SPM_Reply_Data = %0b, SPM_Reply_ACK = %0b, SPM_Reply_Data_VLD = %0b, SPM_Reply_ACK_VLD = %0b, SPM_NATIVE_I2C = %0b, CTRL_I2C_Failed = %0b, LPM_Data = %0b, LPM_ADDRESS = %0b, LPM_LENGTH = %0b, LPM_CMD = %0b, LPM_TRANS_VALID = %0b,LPM_REPLY_DATA = %0b, LPM_REPLY_ACK = %0b, LPM_REPLY_DATA_VALID = %0b, LPM_REPLY_ACK_VALID = %0b, LPM_NATIVE_I2C = %0bو CTRL_Native_Failed = %0b, HPD_Detect = %0b, HPD_IRQ = %0b", super.convert2string(), operation, SPM_Data, SPM_Address, SPM_LEN, SPM_CMD, SPM_Transaction_VLD, SPM_Reply_Data, SPM_Reply_ACK, SPM_Reply_Data_VLD, SPM_Reply_ACK_VLD, SPM_NATIVE_I2C, CTRL_I2C_Failed, LPM_Data, LPM_Address, LPM_LEN, LPM_CMD, LPM_Transaction_VLD, LPM_Reply_Data, LPM_Reply_ACK, LPM_Reply_Data_VLD, LPM_Reply_ACK_VLD, LPM_NATIVE_I2C, CTRL_Native_Failed, HPD_Detect, HPD_IRQ);
    endfunction

    // ******** Need to add anther convert2string function for the Link Training signals *********
    function string convert2string_CR_LT();
        return $sformatf("Operation: %0s, LPM_TRANS_VALID = %0b, SPM_TRANS_VALID = %0b, LPM_Start_CR = %0b, CR_DONE = %0b, CR_DONE_VLD = %0b, Link_LC_CR = %0b, Link_BW_CR = %0b, MAX_VTG = %0b, MAX_PRE = %0b, Config_Param_VLD = %0b, VTG = %0b, PRE = %0b, Driving_Param_VLD = %0b, EQ_RD_Value = %0b",
        operation, LPM_Transaction_VLD, SPM_Transaction_VLD, LPM_Start_CR, CR_DONE, CR_DONE_VLD, Link_LC_CR, Link_BW_CR, MAX_VTG, MAX_PRE, Config_Param_VLD, VTG, PRE, Driving_Param_VLD, EQ_RD_Value);
    endfunction

    function string convert2string_EQ_LT();
        return $sformatf("Operation: %0s, LPM_TRANS_VALID = %0b, SPM_TRANS_VALID = %0b, LPM_Start_CR = %0b, CR_DONE = %0b, CR_DONE_VLD = %0b, Link_LC_CR = %0b, Link_BW_CR = %0b, MAX_VTG = %0b, MAX_PRE = %0b, Config_Param_VLD = %0b, VTG = %0b, PRE = %0b, Driving_Param_VLD = %0b, EQ_CR_DN = %0b, Channel_EQ = %0b, Symbol_Lock = %0b, Lane_Align = %0b, EQ_Data_VLD = %0b, MAX_TPS_SUPPORTED = %0b, MAX_TPS_SUPPORTED_VLD = %0b",
        operation, LPM_Transaction_VLD, SPM_Transaction_VLD, LPM_Start_CR, CR_DONE, CR_DONE_VLD, Link_LC_CR, Link_BW_CR, MAX_VTG, MAX_PRE, Config_Param_VLD, VTG, PRE, Driving_Param_VLD, EQ_CR_DN, Channel_EQ, Symbol_Lock, Lane_Align, EQ_Data_VLD, MAX_TPS_SUPPORTED, MAX_TPS_SUPPORTED_VLD);
    endfunction


endclass
