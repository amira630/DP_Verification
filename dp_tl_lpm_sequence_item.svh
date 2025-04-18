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
    logic                              Timer_Timeout;

    ////////////////// LINK Training Signals //////////////////////
    
    // input Data to DUT
    logic [AUX_DATA_WIDTH-1:0]      Lane_Align, EQ_RD_Value;
    rand logic [AUX_DATA_WIDTH-1:0] Link_BW_CR, PRE, VTG;
    logic [3:0]                     EQ_CR_DN, Channel_EQ, Symbol_Lock;
    rand logic [3:0]                CR_DONE;
    rand training_pattern_t         MAX_TPS_SUPPORTED, 
    rand logic [1:0]                Link_LC_CR, MAX_PRE, MAX_VTG; 
    bit                             EQ_Data_VLD, Driving_Param_VLD, Config_Param_VLD, LPM_Start_CR, CR_DONE_VLD, MAX_TPS_SUPPORTED_VLD;

    // output Data from DUT
    logic [AUX_DATA_WIDTH-1:0] EQ_Final_ADJ_BW;
    logic [1:0]                EQ_Final_ADJ_LC;
    bit                        FSM_CR_Failed, EQ_Failed, EQ_LT_Pass, CR_Completed, EQ_FSM_CR_Failed;


    op_code operation;
    bit     link_values_locked = 0; // State variable to lock values after first randomization
    bit [AUX_DATA_WIDTH-1:0] prev_vtg;
    bit [AUX_DATA_WIDTH-1:0] prev_pre;
    logic [7:0] EQ_RD_Value;
    bit cr_completed_flag = 0; // State variable to track if CR_Completed is 1

    ///////////////////////////////////////////////////////////////
    /////////////////////// CONSTRAINTS ///////////////////////////
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

    constraint eq_cr_dn_constraint {
        apply_distribution(EQ_CR_DN, Link_LC_CR);
    }

    constraint cr_done_constraint {
        apply_distribution(CR_Done, Link_LC_CR);
    }

    constraint channel_eq_constraint {
        apply_distribution(Channel_EQ, Link_LC_CR);
    }

    constraint symbol_lock_constraint {
        apply_distribution(Symbol_Lock, Link_LC_CR);
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
            
            case (VTG[i*2 +: 2]) // Check each 2-bit slice of VTG
                2'b00: PRE[i*2 +: 2] inside {2'b00, 2'b01, 2'b10, 2'b11}; // VTG = 0
                2'b01: PRE[i*2 +: 2] inside {2'b00, 2'b01, 2'b10};        // VTG = 1
                2'b10: PRE[i*2 +: 2] inside {2'b00, 2'b01};               // VTG = 2
                2'b11: PRE[i*2 +: 2] == 2'b00;                            // VTG = 3
            endcase
        }
    }

    constraint lpm_len_constraint {
        LPM_LEN <= 8'h0F; // Ensure LPM_LEN does not exceed 0Fh
    }

    constraint lpm_data_constraint {
        if (LPM_CMD == AUX_NATIVE_WRITE) {
            LPM_Data.size() == LPM_LEN + 1; // Ensure the queue size matches LPM_LEN + 1
            foreach (LPM_Data[i]) {
                LPM_Data[i] inside {0, 1, ..., (1 << AUX_DATA_WIDTH) - 1}; // Randomize valid values
            }
        } else {
            LPM_Data.size() == 0; // Ensure the queue is empty for other commands
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

    function new(string name = "dp_tl_lpm_sequence_item");
        super.new(name);
    endfunction //new()

    ///////////////////////////////////////////////////////////////
    ///////////////////////// METHODS /////////////////////////////
    ///////////////////////////////////////////////////////////////

    // Apply distribution to signal based on the Link_LC_CR value
    // Rationale:
    // - If Link_LC_CR is 2'b11, prioritize 4'b1111 with a weight of 60%.
    // - If Link_LC_CR is 2'b01, prioritize 4'b0011 with a weight of 60%.
    // - If Link_LC_CR is 2'b00, prioritize 4'b0001 with a weight of 60%.
    // - Default weight for other values is 40%.

    function void apply_distribution(ref logic [3:0] signal, logic [1:0] lc_cr);
        if (lc_cr == 2'b11) {
            signal dist {4'b1111 := 60, default := 40};
        } else if (lc_cr == 2'b01) {
            signal dist {4'b0011 := 60, default := 40};
        } else if (lc_cr == 2'b00) {
            signal dist {4'b0001 := 60, default := 40};
        }
    endfunction

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

    // Convert the sequence item to a string representation
    function string convert2string();
        return $sformatf("%s Operation: %0s, LPM_Data = %0b, LPM_ADDRESS = %0b, LPM_LENGTH = %0b, LPM_CMD = %0b, LPM_TRANS_VALID = %0b,LPM_REPLY_DATA = %0b, LPM_REPLY_ACK = %0b, LPM_REPLY_DATA_VALID = %0b, LPM_REPLY_ACK_VALID = %0b, LPM_NATIVE_I2C = %0bو CTRL_Native_Failed = %0b, HPD_Detect = %0b, HPD_IRQ = %0b", super.convert2string(), operation, LPM_Data, LPM_Address, LPM_LEN, LPM_CMD, LPM_Transaction_VLD, LPM_Reply_Data, LPM_Reply_ACK, LPM_Reply_Data_VLD, LPM_Reply_ACK_VLD, LPM_NATIVE_I2C, CTRL_Native_Failed, HPD_Detect, HPD_IRQ);
    endfunction

endclass //dp_tl_lpm_sequence_item extends superClass