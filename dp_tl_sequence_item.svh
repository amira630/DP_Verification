import uvm_pkg::*;
    `include "uvm_macros.svh"
    `include "test_parameters.svh"
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
    rand logic [AUX_DATA_WIDTH-1:0]    LPM_Data[$];
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

    logic [AUX_DATA_WIDTH-1:0] SPM_Lane_BW;
    logic [7:0]                SPM_MSA [23:0];
    logic [1:0]                SPM_Lane_Count, SPM_BW_Sel;
    logic                      SPM_ISO_start, SPM_MSA_VLD;

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

    logic [15:0] HFront, HBack, VFront, VBack;

    /////////////////// MAIN STREAM SOURCE ///////////////////////

    rand logic [47:0] MS_Pixel_Data;
    rand logic [9:0]  MS_Stm_BW;
    rand logic        MS_DE, MS_VSYNC, MS_HSYNC;
    rand bit          MS_Stm_CLK;


    op_code operation;
    bit     link_values_locked = 0; // State variable to lock values after first randomization
    bit [AUX_DATA_WIDTH-1:0] prev_vtg;
    bit [AUX_DATA_WIDTH-1:0] prev_pre;
    bit cr_completed_flag = 0; // State variable to track if CR_Completed is 1
    bit [1:0] ISO_LC;
    bit [AUX_DATA_WIDTH-1:0] ISO_BW;

    ///////////////////////////////////////////////////////////////
    /////////////////////// SPM CONSTRAINTS ///////////////////////
    ///////////////////////////////////////////////////////////////
    
    constraint spm_data_write_constraint {
        if (SPM_CMD == AUX_I2C_WRITE) {
            SPM_Data inside {[0:255]}; // Full range of SPM_Data
        } else {
            SPM_Data == 8'bx; // Default value when not AUX_I2C_WRITE
        }
    }
    
    constraint spm_cmd_read_only_constraint {
        SPM_CMD == AUX_I2C_READ; // Force SPM_CMD to always be AUX_I2C_READ
    }

    constraint operation_type_dist {
       operation inside {[Reset:EQ_LT]};
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
        if (Link_LC_CR == 2'b11) {
            // For 2'b11, prioritize 4'b1111 with 60% weight
            EQ_CR_DN dist {4'b1111 := 60, [0:$] := 40};
        } else if (Link_LC_CR == 2'b01) {
            // For 2'b01, prioritize 4'b0011 with 60% weight
            EQ_CR_DN dist {4'b0011 := 60, [0:$] := 40};
            // For 2'b00, prioritize 4'b0001 with 60% weight
        } else if (Link_LC_CR == 2'b00) {
            EQ_CR_DN dist {4'b0001 := 60, [0:$] := 40};
        }
    }

    constraint cr_done_constraint {
        if (Link_LC_CR == 2'b11) {
            // For 2'b11, prioritize 4'b1111 with 60% weight
            CR_DONE dist {4'b1111 := 60, [0:$] := 40};
        } else if (Link_LC_CR == 2'b01) {
            // For 2'b01, prioritize 4'b0011 with 60% weight
            CR_DONE dist {4'b0011 := 60, [0:$] := 40};
            // For 2'b00, prioritize 4'b0001 with 60% weight
        } else if (Link_LC_CR == 2'b00) {
            CR_DONE dist {4'b0001 := 60, [0:$] := 40};
        }
    }

    constraint channel_eq_constraint {
        if (Link_LC_CR == 2'b11) {
            // For 2'b11, prioritize 4'b1111 with 60% weight
            Channel_EQ dist {4'b1111 := 60, [0:$] := 40};
        } else if (Link_LC_CR == 2'b01) {
            // For 2'b01, prioritize 4'b0011 with 60% weight
            Channel_EQ dist {4'b0011 := 60, [0:$] := 40};
            // For 2'b00, prioritize 4'b0001 with 60% weight
        } else if (Link_LC_CR == 2'b00) {
            Channel_EQ dist {4'b0001 := 60, [0:$] := 40};
        }
    }

    constraint symbol_lock_constraint {
        if (Link_LC_CR == 2'b11) {
            // For 2'b11, prioritize 4'b1111 with 60% weight
            Symbol_Lock dist {4'b1111 := 60, [0:$] := 40};
        } else if (Link_LC_CR == 2'b01) {
            // For 2'b01, prioritize 4'b0011 with 60% weight
            Symbol_Lock dist {4'b0011 := 60, [0:$] := 40};
            // For 2'b00, prioritize 4'b0001 with 60% weight
        } else if (Link_LC_CR == 2'b00) {
            Symbol_Lock dist {4'b0001 := 60, [0:$] := 40};
        }
    }

    constraint max_vtg_constraint {
        foreach (MAX_VTG[i]) {
            MAX_VTG[i*2 +: 2] inside {2'b10, 2'b11}; // Each 2-bit slice must be 10b or 11b
        }
    }

    constraint pre_vtg_constraint {
        foreach (PRE[i]) {
            VTG[i*2 +: 2] <= MAX_VTG[i*2 +: 2]; // VTG must be less than or equal to MAX_VTG
            PRE[i*2 +: 2] <= MAX_PRE[i*2 +: 2]; // PRE must be less than or equal to MAX_PRE

            // Lock VTG if it equals MAX_VTG and LPM_Start_CR is 0
            if (!LPM_Start_CR && prev_vtg[i*2 +: 2] == MAX_VTG[i*2 +: 2]) {
                VTG[i*2 +: 2] == prev_vtg[i*2 +: 2];
            }
            
            // Lock PRE if it equals MAX_PRE and LPM_Start_CR is 0
            if (!LPM_Start_CR && prev_pre[i*2 +: 2] == MAX_PRE[i*2 +: 2]) {
                PRE[i*2 +: 2] == prev_pre[i*2 +: 2];
            }
        }
    }
            
    constraint vtg_pre_relationship {
        foreach (VTG[i]) {
            if ((i*2 + 1) < AUX_DATA_WIDTH) { // Ensure we don't go out of bounds
                if (VTG[i*2 +: 2] == 2'b00) { 
                    PRE[i*2 +: 2] inside {2'b00, 2'b01, 2'b10, 2'b11}; // VTG = 0
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
        if (LPM_CMD == AUX_NATIVE_WRITE) {
            LPM_Data.size() == LPM_LEN + 1; // Ensure the queue size matches LPM_LEN + 1
        } else {
            LPM_Data.size() == 0; // Ensure the queue is empty for other commands
        }
    }

    constraint lpm_data_values {
        foreach (LPM_Data[i]) {
                LPM_Data[i] inside {[0:(1 << AUX_DATA_WIDTH) - 1]}; // Randomize valid values
        }
    }

    constraint link_values_lock_constraint {
        if (link_values_locked) {
            Link_BW_CR dist {Link_BW_CR := 1}; // Lock Link_BW_CR
            Link_LC_CR dist {Link_LC_CR := 1}; // Lock Link_LC_CR
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
      `uvm_info(get_type_name(), "dp_tl_sequence_item constructor called", UVM_LOW)
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
        if (!link_values_locked) begin
            link_values_locked = 1; // Lock the values after the first randomization
        end
        prev_vtg = VTG; // Store current VTG for next randomization
        prev_pre = PRE; // Store current PRE for next randomization
        if (CR_Completed) begin
            cr_completed_flag = 1; // Allow a new random value when CR_Completed becomes 1
        end
    endfunction

    // Copy the values from the virtual interface to the sequence item
    // This function is used to initialize the sequence item with values from the DUT
    // It is called by the driver to get the current state of the DUT
    // and store it in the sequence item for later use
    
    // function void copy_from_vif(virtual dp_tl_if vif);

    //     // Signals from DUT to LPM
    //         this.lpm.LPM_Reply_Data = vif.LPM_Reply_Data;
    //         this.lpm.LPM_Reply_ACK = vif.LPM_Reply_ACK;
    //         this.lpm.LPM_NATIVE_I2C = vif.LPM_NATIVE_I2C;
    //         this.lpm.LPM_Reply_Data_VLD = vif.LPM_Reply_Data_VLD;
    //         this.lpm.LPM_Reply_ACK_VLD = vif.LPM_Reply_ACK_VLD;
    //         this.lpm.CTRL_Native_Failed = vif.CTRL_Native_Failed;
    //         this.lpm.HPD_Detect = vif.HPD_Detect;
    //         this.lpm.HPD_IRQ = vif.HPD_IRQ;
    //         this.lpm.Timer_Timeout = vif.Timer_Timeout;
    //             // Link Training Signals
    //         this.lpm.EQ_Final_ADJ_BW = vif.EQ_Final_ADJ_BW;
    //         this.lpm.EQ_Final_ADJ_LC = vif.EQ_Final_ADJ_LC;
    //         this.lpm.FSM_CR_Failed = vif.FSM_CR_Failed;
    //         this.lpm.EQ_Failed = vif.EQ_Failed;
    //         this.lpm.EQ_LT_Pass = vif.EQ_LT_Pass;
    //         this.lpm.CR_Completed = vif.CR_Completed;
    //         this.lpm.EQ_FSM_CR_Failed = vif.EQ_FSM_CR_Failed;
        
    //     // Signals from DUT to SPM
    //         this.spm.SPM_Reply_Data = vif.SPM_Reply_Data;
    //         this.spm.SPM_Reply_ACK = vif.SPM_Reply_ACK;
    //         this.spm.SPM_NATIVE_I2C = vif.SPM_NATIVE_I2C;
    //         this.spm.SPM_Reply_Data_VLD = vif.SPM_Reply_Data_VLD;
    //         this.spm.SPM_Reply_ACK_VLD = vif.SPM_Reply_ACK_VLD;
    //         this.spm.CTRL_I2C_Failed = vif.CTRL_I2C_Failed;
    //         this.spm.HPD_Detect = vif.HPD_Detect;
        
    // endfunction

  // Convert the sequence item to a string representation
  function string convert2string();
    if (SPM_Transaction_VLD == 1 && LPM_Transaction_VLD == 0) begin
      return $sformatf("%s Operation: %0s, SPM_DATA = %0b, SPM_ADDRESS = %0b, SPM_LEN = %0b, SPM_CMD = %0b, SPM_TRANS_VALID = %0b, SPM_Reply_Data = %0b, SPM_Reply_ACK = %0b, SPM_Reply_Data_VLD = %0b, SPM_Reply_ACK_VLD = %0b, SPM_NATIVE_I2C = %0b, CTRL_I2C_Failed = %0b", super.convert2string(), operation, SPM_Data, SPM_Address, SPM_LEN, SPM_CMD, SPM_Transaction_VLD, SPM_Reply_Data, SPM_Reply_ACK, SPM_Reply_Data_VLD, SPM_Reply_ACK_VLD, SPM_NATIVE_I2C, CTRL_I2C_Failed);
    end
    else if (SPM_Transaction_VLD == 0 && LPM_Transaction_VLD == 1) begin
      return $sformatf("%s Operation: %0s, LPM_Data = %0b, LPM_ADDRESS = %0b, LPM_LENGTH = %0b, LPM_CMD = %0b, LPM_TRANS_VALID = %0b,LPM_REPLY_DATA = %0b, LPM_REPLY_ACK = %0b, LPM_REPLY_DATA_VALID = %0b, LPM_REPLY_ACK_VALID = %0b, LPM_NATIVE_I2C = %0bو CTRL_Native_Failed = %0b, HPD_Detect = %0b, HPD_IRQ = %0b", super.convert2string(), operation, LPM_Data, LPM_Address, LPM_LEN, LPM_CMD, LPM_Transaction_VLD, LPM_Reply_Data, LPM_Reply_ACK, LPM_Reply_Data_VLD, LPM_Reply_ACK_VLD, LPM_NATIVE_I2C, CTRL_Native_Failed, HPD_Detect, HPD_IRQ);
    end
    else if (SPM_Transaction_VLD == 1 && LPM_Transaction_VLD == 1) begin
      `uvm_fatal("ERROR", "Both SPM and LPM transactions are valid. Please check the sequence item.")
    end
    else begin
      return $sformatf("%s Operation: %0s, No transaction is valid", super.convert2string(), operation);
    end
  endfunction

endclass