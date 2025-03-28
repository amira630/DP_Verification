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
    logic [AUX_DATA_WIDTH-1:0] Lane_Align, EQ_RD_Value;
    rand logic [AUX_DATA_WIDTH-1:0] Link_BW_CR, MAX_VTG, PRE, VTG;
    logic [3:0]                EQ_CR_DN, Channel_EQ, Symbol_Lock;
    rand logic [3:0]           CR_Done;
    rand logic [1:0]           Link_LC_CR, MAX_TPS_SUPPORTED;
    bit                        EQ_Data_VLD, Driving_Param_VLD, LPM_Start_CR, TPS_VLD;

    // output Data from DUT
    logic [AUX_DATA_WIDTH-1:0] EQ_Final_ADJ_BW;
    logic [1:0]                EQ_Final_ADJ_LC;
    logic                      FSM_CR_Failed, EQ_Failed, EQ_LT_Pass;

    rand op_code operation;
    bit cr_done_reached = 0; // State variable to track if 4'b1111 has been reached
    bit link_values_locked = 0; // State variable to lock values after first randomization

    ///////////////////////////////////////////////////////////////
    /////////////////////// CONSTRAINTS ///////////////////////////
    ///////////////////////////////////////////////////////////////

    constraint link_bw_cr_constraint {
        Link_BW_CR inside {8'h06, 8'h0A, 8'h14, 8'h1E}; // Allowed values for Link_BW_CR
    }

    constraint link_lc_cr_constraint {
        Link_LC_CR != 2'b10; // Prevent Link_LC_CR from taking the value 10b
    }

    constraint max_vtg_constraint {
        foreach (MAX_VTG[i]) {
            MAX_VTG[i*2 +: 2] inside {2'b10, 2'b11}; // Each 2-bit slice must be 10b or 11b
        }
    }

    constraint pre_vtg_constraint {
        foreach (PRE[i]) {
            VTG[i*2 +: 2] <= MAX_VTG[i*2 +: 2]; // VTG must be less than or equal to MAX_VTG
            case (VTG[i*2 +: 2]) // Check each 2-bit slice of VTG
                2'b00: PRE[i*2 +: 2] inside {2'b00, 2'b01, 2'b10, 2'b11}; // VTG = 0
                2'b01: PRE[i*2 +: 2] inside {2'b00, 2'b01, 2'b10};        // VTG = 1
                2'b10: PRE[i*2 +: 2] inside {2'b00, 2'b01};               // VTG = 2
                2'b11: PRE[i*2 +: 2] inside {2'b00, 2'b01};               // VTG = 3
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
    constraint cr_done_constraint {
        if (!cr_done_reached) {
            CR_Done != 4'b1111; // Prevent CR_Done from being 4'b1111 until the state variable is set
        }
    }
    constraint link_values_lock_constraint {
        if (link_values_locked) {
            Link_BW_CR dist {Link_BW_CR := 1}; // Lock Link_BW_CR
            Link_LC_CR dist {Link_LC_CR := 1}; // Lock Link_LC_CR
        }
    }

    // Post-randomization logic to eventually allow 4'b1111
    function void post_randomize();
        if (!cr_done_reached && CR_Done == 4'b1111) begin
            cr_done_reached = 1; // Mark that 4'b1111 has been reached
        end
        if (!link_values_locked) begin
            link_values_locked = 1; // Lock the values after the first randomization
        end
    endfunction
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