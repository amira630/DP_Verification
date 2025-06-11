module dp_source(dp_tl_if.DUT tl_if, dp_sink_if.DUT sink_if);

    /////////////////////////////////////////////////////
    ///////////////////   AUX   /////////////////////////
    /////////////////////////////////////////////////////

    //=========//                 
    // inputs  //      
    //=========//

    logic        clk;                
    logic        rst_n;              
    logic        spm_transaction_vld;
    logic [1:0]  spm_cmd;            
    logic [19:0] spm_address;        
    logic [7:0]  spm_len;            
    logic [7:0]  spm_data;           
    logic        lpm_transaction_vld;
    logic [1:0]  lpm_cmd;            
    logic [19:0] lpm_address;        
    logic [7:0]  lpm_len;            
    logic [7:0]  lpm_data; 
    logic        hpd_signal; 

    // phy interface
    logic        phy_start_stop;
    
    // lpm interface with cr fsm and cahnnell eq fsm 
    logic [7:0]  vtg;
    logic [7:0]  pre;

    // channell eq fsm with lpm interface 
    logic [3:0]  eq_cr_dn;
    logic [3:0]  channel_eq;
    logic [3:0]  symbol_lock;
    logic [7:0]  lane_align;
    logic        eq_data_vld;
    logic [1:0]  tps;          
    logic        tps_vld;

    // channell eq fsm ; cr fsm with lpm interface     
    logic [1:0]  max_vtg; // this signal is input to cr err chk      
    logic [1:0]  max_pre;


    // lpm with ctr interface
    logic [7:0]  eq_rd_value;


    //  eq err chk fsm ; cr err chk fsm and cr fsm with lpm interface
    logic        config_param_vld; 
    logic [7:0]  lpm_link_bw; 
    logic [1:0]  lpm_link_lc; 


    // lpm with cr fsm interface
    logic        lpm_start_cr; 
    logic        driving_param_vld;
    logic        cr_done_vld;
    logic [3:0]  cr_done;          



    //=========//                 
    // outputs //      
    //=========//

    logic         aux_start_stop;
    logic         timer_timeout;
    logic         hpd_irq;
    logic         hpd_detect;
    logic         ctrl_native_failed;  
    logic         ctrl_i2c_failed;

    // reply decoder with spm interface signals    
    logic [7:0]   spm_reply_data;
    logic         spm_reply_data_vld;  
    logic [1:0]   spm_reply_ack;
    logic         spm_reply_ack_vld; 
    logic         spm_native_i2c; 

    // reply decoder with lpm interface signals    
    logic [7:0]   lpm_reply_data;
    logic         lpm_reply_data_vld;  
    logic [1:0]   lpm_reply_ack;
    logic         lpm_reply_ack_vld; 
    logic         lpm_native_i2c; 

    //
    logic [1:0]         phy_instruct;
    logic               phy_instruct_vld;
    logic [1:0]         phy_adj_lc;
    logic [7:0]         phy_adj_bw;

    // cr fsm with lpm and err chk interface 
    logic         fsm_cr_failed;
    logic         cr_completed;

    // channell eq fsm interface with lpm 
    logic  [1:0]  eq_final_adj_lc;
    logic  [7:0]  eq_final_adj_bw;
    logic         eq_lt_failed;
    logic         eq_lt_pass;
    logic         eq_fsm_cr_failed;
    logic         eq_fsm_loop_max;
    logic         eq_fsm_repeat;
    
    // from cr err chk to lpm
    logic         lpm_cr_apply_new_driving_param;
    logic         lpm_cr_apply_new_bw_lc;

    logic [7:0] reply_data;
    logic       reply_data_vld;
    logic [1:0] reply_ack;
    logic       reply_ack_vld;
    logic       reply_i2c_native;


    // bidirectional data bus
    wire [7:0]  aux_in_out;

    /////////////////////////////////////////////////////
    /////////////////////////////////////////////////////
    /////////////////////////////////////////////////////

    /////////////////////////////////////////////////////
    ///////////////////   ISO   /////////////////////////
    /////////////////////////////////////////////////////
    
    //=========//                 
    // inputs  //      
    //=========//

    logic            hbr3_clk;
    logic            hbr2_clk;
    logic            hbr_clk;
    logic            rbr_clk;
    logic    [1:0]   spm_bw_sel;
    // logic            rst_n;
    logic    [47:0]  ms_pixel_data;
    logic            ms_stm_clk;
    logic            ms_de;
    logic    [9:0]   ms_stm_bw;
    logic            ms_stm_bw_valid;
    logic            ms_vsync;
    logic            ms_hsync;
    logic            spm_iso_start;
    logic    [2:0]   spm_lane_count;
    logic    [15:0]  spm_lane_bw;
    logic    [191:0] spm_msa;
    logic            spm_msa_vld;
    logic            ms_rst_n;

    //=========//                 
    // outputs //      
    //=========//

    logic    [7:0]   iso_symbols_lane0;
    logic            iso_control_sym_flag_lane0;
    logic    [7:0]   iso_symbols_lane1;
    logic            iso_control_sym_flag_lane1;
    logic    [7:0]   iso_symbols_lane2;
    logic            iso_control_sym_flag_lane2;
    logic    [7:0]   iso_symbols_lane3;
    logic            iso_control_sym_flag_lane3;

    logic            wfull;


    /////////////////////////////////////////////////////
    /////////////////////////////////////////////////////
    /////////////////////////////////////////////////////

    /////////////////////////////////////////////////////
    ///////////////////   AUX   /////////////////////////
    /////////////////////////////////////////////////////

    //=========//                 
    // inputs  //      
    //=========//

    assign clk = tl_if.clk_AUX;              
    assign rst_n = tl_if.rst_n;              
    assign spm_transaction_vld = tl_if.SPM_Transaction_VLD;
    assign spm_cmd = tl_if.SPM_CMD;          
    assign spm_address = tl_if.SPM_Address;        
    assign spm_len = tl_if.SPM_LEN;     
    assign spm_data = tl_if.SPM_Data;           
    assign lpm_transaction_vld = tl_if.LPM_Transaction_VLD;
    assign lpm_cmd = tl_if.LPM_CMD;
    assign lpm_address = tl_if.LPM_Address;        
    assign lpm_len = tl_if.LPM_LEN;    
    assign lpm_data = tl_if.LPM_Data; 
    
    // LPM INTERFACE WITH CR FSM AND CAHNNELL EQ FSM 
    assign vtg = tl_if.VTG;
    assign pre = tl_if.PRE;

    // CHANNELL EQ FSM WITH LPM INTERFACE 
    assign eq_cr_dn = tl_if.EQ_CR_DN;
    assign channel_eq = tl_if.Channel_EQ;
    assign symbol_lock = tl_if.Symbol_Lock;
    assign lane_align = tl_if.Lane_Align;
    assign eq_data_vld = tl_if.EQ_Data_VLD;
    assign tps = tl_if.MAX_TPS_SUPPORTED;
    assign tps_vld = tl_if.MAX_TPS_SUPPORTED_VLD;

    // CHANNELL EQ FSM , CR FSM WITH LPM INTERFACE     
    assign max_vtg = tl_if.MAX_VTG;               
    assign max_pre = tl_if.MAX_PRE;               


    // LPM WITH CTR INTERFACE
    assign eq_rd_value = tl_if.EQ_RD_Value; 


    //  EQ ERR CHK FSM , CR ERR CHK FSM AND CR FSM WITH LPM INTERFACE
    assign config_param_vld = tl_if.Config_Param_VLD;
    assign lpm_link_bw = tl_if.Link_BW_CR;
    assign lpm_link_lc = tl_if.Link_LC_CR;


    // LPM WITH CR FSM INTERFACE
    assign lpm_start_cr = tl_if.LPM_Start_CR;
    assign driving_param_vld = tl_if.Driving_Param_VLD;
    assign cr_done_vld = tl_if.CR_DONE_VLD;
    assign cr_done = tl_if.CR_DONE;         

    // PHY INTERFACE
    assign phy_start_stop = sink_if.PHY_START_STOP;
    assign hpd_signal = sink_if.HPD_Signal;

    // Bidirectional Data Bus
    assign sink_if.AUX_IN_OUT = sink_if.AUX_START_STOP ? aux_in_out : 8'bz; // The AUX_IN_OUT signal is a bidirectional signal used for the DisplayPort auxiliary channel communication. It carries the data between the source and sink devices.

    assign aux_in_out = sink_if.PHY_START_STOP ? sink_if.AUX_IN_OUT : 8'bz; // The AUX_IN_OUT signal is driven by the PHY_START_STOP signal. When PHY_START_STOP is high, the aux_data is driven onto the AUX_IN_OUT line. Otherwise, it is in high impedance state (8'bz).

    assign spm_reply_data = reply_data;
    assign spm_reply_data_vld = reply_data_vld;
    assign spm_reply_ack = reply_ack;
    assign spm_reply_ack_vld = reply_ack_vld;
    assign spm_native_i2c = reply_i2c_native;

    assign lpm_reply_data = reply_data;
    assign lpm_reply_data_vld = reply_data_vld;
    assign lpm_reply_ack = reply_ack;
    assign lpm_reply_ack_vld = reply_ack_vld;
    assign lpm_native_i2c = reply_i2c_native;

    //=========//                 
    // outputs //      
    //=========//

    assign sink_if.AUX_START_STOP = aux_start_stop;
    assign tl_if.Timer_Timeout = timer_timeout;
    assign tl_if.HPD_IRQ = hpd_irq;
    assign tl_if.HPD_Detect = hpd_detect;

    // REPLY DECODER WITH SPM INTERFACE SIGNALS    
    assign tl_if.SPM_Reply_Data = spm_reply_data;
    assign tl_if.SPM_Reply_Data_VLD = spm_reply_data_vld;
    assign tl_if.SPM_Reply_ACK = spm_reply_data_vld;
    assign tl_if.SPM_Reply_ACK_VLD = spm_reply_ack_vld;
    assign tl_if.SPM_NATIVE_I2C = spm_native_i2c;
    assign tl_if.CTRL_I2C_Failed = ctrl_i2c_failed;

    // REPLY DECODER WITH LPM INTERFACE SIGNALS    
    assign tl_if.LPM_Reply_Data = lpm_reply_data;
    assign tl_if.LPM_Reply_Data_VLD = lpm_reply_data_vld;
    assign tl_if.LPM_Reply_ACK = lpm_reply_ack;
    assign tl_if.LPM_Reply_ACK_VLD = lpm_reply_ack_vld;
    assign tl_if.LPM_NATIVE_I2C = lpm_native_i2c;
    assign tl_if.CTRL_Native_Failed = ctrl_native_failed;

    // Link Training WITH PHY LAYER INTERFACE
    assign sink_if.PHY_Instruct = phy_instruct;
    assign sink_if.PHY_Instruct_VLD = phy_instruct_vld;
    assign sink_if.PHY_ADJ_LC = phy_adj_lc;
    assign sink_if.PHY_ADJ_BW = phy_adj_bw;

    // CR FSM WITH LPM AND ERR CHK INTERFACE 
    assign tl_if.FSM_CR_Failed = fsm_cr_failed;
    assign tl_if.CR_Completed = cr_completed;
    assign tl_if.LPM_CR_Apply_New_Driving_Param = lpm_cr_apply_new_driving_param;
    assign tl_if.LPM_CR_Apply_New_BW_LC = lpm_cr_apply_new_bw_lc;

    // CHANNELL EQ FSM INTERFACE WITH LPM 
    assign tl_if.EQ_Final_ADJ_LC = eq_final_adj_lc;
    assign tl_if.EQ_Final_ADJ_BW = eq_final_adj_bw;
    assign tl_if.EQ_Failed = eq_lt_failed;
    assign tl_if.EQ_LT_Pass = eq_lt_pass;
    assign tl_if.EQ_FSM_CR_Failed = eq_fsm_cr_failed;
    assign tl_if.EQ_FSM_Repeat = eq_fsm_repeat;

    /////////////////////////////////////////////////////
    /////////////////////////////////////////////////////
    /////////////////////////////////////////////////////

    /////////////////////////////////////////////////////
    ///////////////////   ISO   /////////////////////////
    /////////////////////////////////////////////////////

    //=========//                 
    // inputs  //      
    //=========//

    assign hbr3_clk = tl_if.clk_HBR3;              
    assign hbr2_clk = tl_if.clk_HBR2;            
    assign hbr_clk = tl_if.clk_HBR;  
    assign rbr_clk = tl_if.clk_RBR;         
    assign spm_bw_sel = tl_if.SPM_BW_Sel;        
    // assign rst_n = tl_if.rst_n;     
    assign ms_pixel_data = tl_if.MS_Pixel_Data;           
    assign ms_stm_clk = tl_if.MS_Stm_CLK;  
    assign ms_de = tl_if.MS_DE;
    assign ms_stm_bw = tl_if.MS_Stm_BW;        
    assign ms_stm_bw_valid = tl_if.MS_Stm_BW_VLD;
    assign ms_vsync = tl_if.MS_VSYNC;
    assign ms_hsync = tl_if.MS_HSYNC;     
    assign spm_iso_start = tl_if.SPM_ISO_start;           
    assign spm_lane_count = tl_if.SPM_Lane_Count;
    assign spm_lane_bw = tl_if.SPM_Lane_BW;
    assign spm_msa = tl_if.SPM_Full_MSA;        
    assign spm_msa_vld = tl_if.SPM_MSA_VLD;    
    assign ms_rst_n = tl_if.rst_n;

    //=========//                 
    // outputs //      
    //=========//

    assign sink_if.ISO_symbols_lane0 = iso_symbols_lane0;
    assign sink_if.Control_sym_flag_lane0 = iso_control_sym_flag_lane0;
    assign sink_if.ISO_symbols_lane1 = iso_symbols_lane1;
    assign sink_if.Control_sym_flag_lane1 = iso_control_sym_flag_lane1;
    assign sink_if.ISO_symbols_lane2 = iso_symbols_lane2;
    assign sink_if.Control_sym_flag_lane2 = iso_control_sym_flag_lane2;
    assign sink_if.ISO_symbols_lane3 = iso_symbols_lane3;
    assign sink_if.Control_sym_flag_lane3 = iso_control_sym_flag_lane3;
    assign tl_if.WFULL = wfull;  //// Don't know what to do with
    
    

    /////////////////////////////////////////////////////
    /////////////////////////////////////////////////////
    /////////////////////////////////////////////////////

    /////////////////////////////////////////////////////
    ///////////////////   AUX   /////////////////////////
    /////////////////////////////////////////////////////

    //===================//                 
    // Local Parameters  //      
    //===================//

    // ctrl unit interface signals
    wire         ctrl_tr_vld; 
    wire  [1:0]  ctrl_msg_cmd;
    wire  [19:0] ctrl_msg_address;
    wire  [7:0]  ctrl_msg_len;
    wire  [7:0]  ctrl_msg_data;
    wire  [7:0]  ctrl_done_data_number; 
    wire         ctrl_native_retrans;
    wire         ctrl_ack_flag;
    wire         ctrl_i2c_native;

    // demux interface signals
    wire [1:0]   de_mux_native_cmd;    
    wire [7:0]   de_mux_native_data;
    wire [19:0]  de_mux_native_address;
    wire [7:0]   de_mux_native_len;
    wire         de_mux_native_tr_vld;
    wire [1:0]   de_mux_i2c_cmd;
    wire [19:0]  de_mux_i2c_address;
    wire [7:0]   de_mux_i2c_len;
    wire         de_mux_i2c_tr_vld;

    // native encoder interface signals
    wire  [7:0]  native_splitted_msg;
    wire         native_msg_vld;

    // mux interface signals
    wire [7:0]  mux_aux_out;
    wire        mux_aux_out_vld;

    // i2c interface signals
    wire        i2c_fsm_complete;  
    wire [7:0]  i2c_splitted_msg;  
    wire        i2c_msg_vld;       

    //bidirectional_aux_phy_interface signals
    wire [7:0] bdi_aux_in;
    wire       bdi_aux_in_vld;
    wire       bdi_timer_reset;

    // interface signals with link trainning and control unit 
    wire        cr_transaction_vld; 
    wire [1:0]  cr_cmd;             
    wire [19:0] cr_address;         
    wire [7:0]  cr_len;             
    wire [7:0]  cr_data;           
    wire        eq_transaction_vld; 
    wire [1:0]  eq_cmd;             
    wire [19:0] eq_address;         
    wire [7:0]  eq_len;             
    wire [7:0]  eq_data;

    // Mux Phy Interface signals for Link Training
    wire [1:0]  mux_cr_phy_instruct;
    wire        mux_cr_phy_instruct_vld;
    wire [1:0]  mux_cr_adj_lc;
    wire [7:0]  mux_cr_adj_bw;
    wire [1:0]  mux_eq_adj_lc;
    wire [7:0]  mux_eq_adj_bw;
    wire [1:0]  mux_eq_phy_instruct;
    wire        mux_eq_phy_instruct_vld;

    /////////////////////////////////////////////////////
    /////////////////////////////////////////////////////
    /////////////////////////////////////////////////////

    /////////////////////////////////////////////////////
    ///////////////////   ISO   /////////////////////////
    /////////////////////////////////////////////////////
    
    wire             ls_clk;

    wire    [8:0]    td_misc0_1;
    wire    [1:0]    td_lane_count;
    wire             td_vld_data;

    wire             sched_steering_en;
    wire    [1:0]    sched_stream_state;
    wire             sched_stream_en_lane0;
    wire             sched_stream_en_lane1;
    wire             sched_stream_en_lane2;
    wire             sched_stream_en_lane3;
    wire             sched_blank_id;
    wire    [1:0]    sched_blank_state;
    wire             sched_blank_en_lane0;
    wire             sched_blank_en_lane1;
    wire             sched_blank_en_lane2;
    wire             sched_blank_en_lane3;
    wire             sched_idle_en_lane0;
    wire             sched_idle_en_lane1;
    wire             sched_idle_en_lane2;
    wire             sched_idle_en_lane3;
    wire    [1:0]    sched_stream_idle_sel_lane0;
    wire    [1:0]    sched_stream_idle_sel_lane1;
    wire    [1:0]    sched_stream_idle_sel_lane2;
    wire    [1:0]    sched_stream_idle_sel_lane3;

    wire             idle_activate_en_lane0;
    wire             idle_activate_en_lane1;
    wire             idle_activate_en_lane2;
    wire             idle_activate_en_lane3;

    wire    [7:0]    main_steered_lane0;
    wire    [7:0]    main_steered_lane1;
    wire    [7:0]    main_steered_lane2;
    wire    [7:0]    main_steered_lane3;

    wire    [1:0]    blank_steering_state_lane0;
    wire    [1:0]    blank_steering_state_lane1;
    wire    [1:0]    blank_steering_state_lane2;
    wire    [1:0]    blank_steering_state_lane3;

    wire    [7:0]    sec_steered_lane0;
    wire    [7:0]    sec_steered_lane1;
    wire    [7:0]    sec_steered_lane2;
    wire    [7:0]    sec_steered_lane3;
    wire             sec_steered_vld;

    wire    [95:0]   fifo_pixel_data;
    wire             rd_data_valid;
    wire             fifo_almost_empty;
    wire             mbs_empty_regs;

    /////////////////////////////////////////////////////
    /////////////////////////////////////////////////////
    /////////////////////////////////////////////////////

    //===================//                 
    // Local Parameters  //      
    //===================//

    // Bidirectional Data Bus
    // always_comb begin
    //     if (sink_if.AUX_START_STOP == 1'b1) begin
    //         sink_if.AUX_IN_OUT = aux_in_out;
    //     end else if (sink_if.PHY_START_STOP == 1'b1) begin
    //         aux_in_out = sink_if.AUX_IN_OUT;
    //     end else begin
    //         sink_if.AUX_IN_OUT = 1'b0; // Default value when neither condition is true
    //     end
    // end


/////////////////////////////////////////////////////
///////////////////   AUX   /////////////////////////
/////////////////////////////////////////////////////

// Instantiate the AUX_CTRL_UNIT module
aux_ctrl_unit  aux_ctrl_unit_inst 
(
.clk                   (clk),
.rst_n                 (rst_n),
.spm_transaction_vld   (spm_transaction_vld),
.spm_cmd               (spm_cmd),
.spm_address           (spm_address),
.spm_len               (spm_len),
.spm_data              (spm_data),
.lpm_transaction_vld   (lpm_transaction_vld),
.lpm_cmd               (lpm_cmd),
.lpm_address           (lpm_address),
.lpm_len               (lpm_len),
.lpm_data              (lpm_data),
.cr_transaction_vld    (cr_transaction_vld),
.cr_cmd                (cr_cmd),
.cr_address            (cr_address),
.cr_len                (cr_len),
.cr_data               (cr_data),
.eq_transaction_vld    (eq_transaction_vld),
.eq_cmd                (eq_cmd),
.eq_address            (eq_address),
.eq_len                (eq_len),
.eq_data               (eq_data),
.reply_data_vld        (reply_data_vld),
.reply_data            (reply_data),
.reply_ack             (reply_ack),
.reply_ack_vld         (reply_ack_vld),
.timer_timeout         (timer_timeout),
.i2c_complete          (i2c_fsm_complete),
.i2c_fsm_failed        (i2c_fsm_failed),
.ctrl_tr_vld           (ctrl_tr_vld),
.ctrl_msg_cmd          (ctrl_msg_cmd),
.ctrl_msg_address      (ctrl_msg_address),
.ctrl_msg_len          (ctrl_msg_len),
.ctrl_msg_data         (ctrl_msg_data),
.ctrl_done_data_number (ctrl_done_data_number),
.ctrl_native_retrans   (ctrl_native_retrans),
.ctrl_ack_flag         (ctrl_ack_flag), // aux_cttrl_ack_flag
.ctrl_i2c_native       (ctrl_i2c_native),
.ctrl_native_failed    (ctrl_native_failed),
.ctrl_i2c_failed       (ctrl_i2c_failed)
);

// Instantiate the demux module
native_i2c_de_mux  native_i2c_de_mux_inst 
(
.ctrl_msg_cmd         (ctrl_msg_cmd),
.ctrl_msg_data        (ctrl_msg_data),
.ctrl_msg_address     (ctrl_msg_address),
.ctrl_msg_len         (ctrl_msg_len),
.ctrl_tr_vld          (ctrl_tr_vld),
.ctrl_i2c_native      (ctrl_i2c_native),
.de_mux_native_cmd    (de_mux_native_cmd),
.de_mux_native_data   (de_mux_native_data),
.de_mux_native_address(de_mux_native_address),
.de_mux_native_len    (de_mux_native_len),
.de_mux_native_tr_vld (de_mux_native_tr_vld),
.de_mux_i2c_cmd       (de_mux_i2c_cmd),
.de_mux_i2c_address   (de_mux_i2c_address),
.de_mux_i2c_len       (de_mux_i2c_len),
.de_mux_i2c_tr_vld    (de_mux_i2c_tr_vld)
);

// Instantiate the native_message_encoder module
native_message_encoder native_message_encoder_inst 
(
.clk                  (clk),
.rst_n                (rst_n),
.ctrl_done_data_number(ctrl_done_data_number),
.ctrl_native_retrans  (ctrl_native_retrans),
.de_mux_native_cmd    (de_mux_native_cmd),
.de_mux_native_data   (de_mux_native_data),
.de_mux_native_address(de_mux_native_address),
.de_mux_native_len    (de_mux_native_len),
.de_mux_native_tr_vld (de_mux_native_tr_vld),
.native_splitted_msg  (native_splitted_msg),
.native_msg_vld       (native_msg_vld)
);

// Instantiate the mux module
native_i2c_mux native_i2c_mux_inst 
(
.native_splitted_msg  (native_splitted_msg),
.native_msg_vld       (native_msg_vld),
.i2c_splitted_msg     (i2c_splitted_msg),
.i2c_msg_vld          (i2c_msg_vld),
.ctrl_i2c_native      (ctrl_i2c_native),
.mux_aux_out          (mux_aux_out),
.mux_aux_out_vld      (mux_aux_out_vld)
);

// Instantiate the i2c_top module
i2c_top i2c_top_inst
(
.clk                (clk),
.rst_n              (rst_n),
.de_mux_i2c_tr_vld  (de_mux_i2c_tr_vld),
.reply_ack          (reply_ack),
.reply_ack_vld      (reply_ack_vld),
.timer_timeout      (timer_timeout),
.de_mux_i2c_cmd     (de_mux_i2c_cmd),
.de_mux_i2c_address (de_mux_i2c_address),
.de_mux_i2c_len     (de_mux_i2c_len),
.i2c_fsm_complete   (i2c_fsm_complete),
.i2c_splitted_msg   (i2c_splitted_msg),
.i2c_msg_vld        (i2c_msg_vld),
.i2c_fsm_failed     (i2c_fsm_failed)
);

// Instantiate the bidirectional_aux_phy_interface module
bidirectional_aux_phy_interface bidirectional_aux_phy_interface_inst
(
.clk               (clk),
.rst_n             (rst_n),
.mux_aux_out_vld   (mux_aux_out_vld),
.mux_aux_out       (mux_aux_out),
.timer_timeout     (timer_timeout),
.bdi_aux_in        (bdi_aux_in),
.bdi_aux_in_vld    (bdi_aux_in_vld),
.bdi_timer_reset   (bdi_timer_reset),
.phy_start_stop    (phy_start_stop),
.aux_start_stop    (aux_start_stop),
.aux_in_out        (aux_in_out)
);
// Instantiate the timeout_timer module
timeout_timer timeout_timer_inst
(
.clk               (clk),
.rst_n             (rst_n),
.mux_aux_out_vld   (mux_aux_out_vld),
.bdi_timer_reset   (bdi_timer_reset),
.timer_timeout     (timer_timeout)
);

//instantiate reply decoder
reply_decoder reply_decoder_inst
(
.clk               (clk),
.rst_n             (rst_n),
.reply_data        (reply_data),
.reply_data_vld    (reply_data_vld),
.reply_ack         (reply_ack),
.reply_ack_vld     (reply_ack_vld),
.reply_dec_i2c_native  (reply_i2c_native),
.bdi_aux_in        (bdi_aux_in),
.bdi_aux_in_vld    (bdi_aux_in_vld),
.aux_ctrl_i2c_native(ctrl_i2c_native)
);

cr_eq_lt_top link_trainning_inst
(
.clk                (clk),
.rst_n              (rst_n),
.lpm_start_cr       (lpm_start_cr),
.driving_param_vld  (driving_param_vld),
.cr_done_vld        (cr_done_vld),
.cr_done            (cr_done),
.lpm_link_bw        (lpm_link_bw),
.lpm_link_lc        (lpm_link_lc),
.vtg                (vtg),
.pre                (pre),
.max_vtg            (max_vtg),
.max_pre            (max_pre),
.config_param_vld   (config_param_vld),
.fsm_cr_failed      (fsm_cr_failed),
.cr_completed       (cr_completed),
.eq_data_vld        (eq_data_vld),
.eq_rd_value        (eq_rd_value),
.eq_cr_dn           (eq_cr_dn),
.channel_eq         (channel_eq),
.symbol_lock        (symbol_lock),
.lane_align         (lane_align),
.tps                (tps),
.tps_vld            (tps_vld),
.eq_lt_failed       (eq_lt_failed),
.eq_lt_pass         (eq_lt_pass),
.eq_fsm_cr_failed   (eq_fsm_cr_failed),
.eq_final_adj_bw    (eq_final_adj_bw),
.eq_final_adj_lc    (eq_final_adj_lc),
.cr_transaction_vld (cr_transaction_vld),
.cr_cmd             (cr_cmd),
.cr_address         (cr_address),
.cr_len             (cr_len),
.cr_data            (cr_data),
.eq_transaction_vld (eq_transaction_vld),
.eq_cmd             (eq_cmd),
.eq_address         (eq_address),
.eq_len             (eq_len),
.eq_data            (eq_data),
.cr_phy_instruct    (mux_cr_phy_instruct),
.cr_phy_instruct_vld(mux_cr_phy_instruct_vld),
.cr_adj_lc          (mux_cr_adj_lc),
.cr_adj_bw          (mux_cr_adj_bw),
.eq_phy_instruct    (mux_eq_phy_instruct),
.eq_adj_lc          (mux_eq_adj_lc),
.eq_adj_bw          (mux_eq_adj_bw),
.eq_phy_instruct_vld(mux_eq_phy_instruct_vld),
.ctrl_ack_flag      (ctrl_ack_flag),
.ctrl_native_failed (ctrl_native_failed),
.lpm_cr_apply_new_driving_param (lpm_cr_apply_new_driving_param),  
.lpm_cr_apply_new_bw_lc         (lpm_cr_apply_new_bw_lc),
.eq_fsm_loop_max              (eq_fsm_loop_max),
.eq_fsm_repeat                (eq_fsm_repeat)
);

hpd hpd_inst
(
.clk       (clk),
.rst_n     (rst_n),
.hpd_signal(hpd_signal),
.hpd_detect(hpd_detect),
.hpd_irq   (hpd_irq)
);


cr_eq_mux cr_eq_mux_inst
(
.cr_phy_instruct     (mux_cr_phy_instruct),
.cr_phy_instruct_vld (mux_cr_phy_instruct_vld),
.cr_adj_lc           (mux_cr_adj_lc),
.cr_adj_bw           (mux_cr_adj_bw),
.eq_adj_lc           (mux_eq_adj_lc),
.eq_adj_bw           (mux_eq_adj_bw),
.eq_phy_instruct     (mux_eq_phy_instruct),
.eq_phy_instruct_vld (mux_eq_phy_instruct_vld),
.phy_instruct        (phy_instruct),
.phy_instruct_vld    (phy_instruct_vld),
.phy_adj_lc          (phy_adj_lc),
.phy_adj_bw          (phy_adj_bw)
);

/////////////////////////////////////////////////////
/////////////////////////////////////////////////////
/////////////////////////////////////////////////////

/////////////////////////////////////////////////////
///////////////////   ISO   /////////////////////////
/////////////////////////////////////////////////////

////////////////////////////////////////////////////////////////

iso_ctrl_top iso_ctrl_top_0 (
.clk(ls_clk),
.rst_n(rst_n),
.ms_de(ms_de),
.ms_stm_bw(ms_stm_bw),
.ms_stm_bw_valid(ms_stm_bw_valid),
.td_vld_data(td_vld_data),
.ms_vsync(ms_vsync),
.ms_hsync(ms_hsync),
.spm_iso_start(spm_iso_start),
.spm_lane_count(spm_lane_count),
.spm_lane_bw(spm_lane_bw),
.htotal(spm_msa[63:48]),             // total horizontal pixels
.hwidth(spm_msa[159:144]),             // active horizontal width
.vtotal(spm_msa[79:64]),             // total vertical pixels
.vheight(spm_msa[175:160]),            // active vertical height
.misc0(spm_msa[183:176]),              // provide colormitry information as color depth and pixel format bpc   
.misc1(spm_msa[191:184]),              // additional miscellaneous data
.h_sync_polarity(spm_msa[112]),    // horizontal sync polarity
.v_sync_polarity(spm_msa[128]),    // vertical sync polarity
//.spm_msa(spm_msa),
.spm_msa_vld(spm_msa_vld),
.idle_activate_en_lane0(idle_activate_en_lane0),
.idle_activate_en_lane1(idle_activate_en_lane1),
.idle_activate_en_lane2(idle_activate_en_lane2),
.idle_activate_en_lane3(idle_activate_en_lane3),
.td_misc0_1(td_misc0_1),
.td_lane_count(td_lane_count),
.sched_steering_en(sched_steering_en),
.sched_stream_state(sched_stream_state),
.sched_stream_en_lane0(sched_stream_en_lane0),
.sched_stream_en_lane1(sched_stream_en_lane1),
.sched_stream_en_lane2(sched_stream_en_lane2),
.sched_stream_en_lane3(sched_stream_en_lane3),
.sched_blank_id(sched_blank_id),
.sched_blank_state(sched_blank_state),
.sched_blank_en_lane0(sched_blank_en_lane0),
.sched_blank_en_lane1(sched_blank_en_lane1),
.sched_blank_en_lane2(sched_blank_en_lane2),
.sched_blank_en_lane3(sched_blank_en_lane3),
.sched_idle_en_lane0(sched_idle_en_lane0),
.sched_idle_en_lane1(sched_idle_en_lane1),
.sched_idle_en_lane2(sched_idle_en_lane2),
.sched_idle_en_lane3(sched_idle_en_lane3),
.sched_stream_idle_sel_lane0(sched_stream_idle_sel_lane0),
.sched_stream_idle_sel_lane1(sched_stream_idle_sel_lane1),
.sched_stream_idle_sel_lane2(sched_stream_idle_sel_lane2),
.sched_stream_idle_sel_lane3(sched_stream_idle_sel_lane3)
);

////////////////////////////////////////////////////////////////

iso_lanes_top iso_lanes_top_0(
.clk(ls_clk),
.rst_n(rst_n),
.main_steered(main_steered_lane0),
.sec_steered(sec_steered_lane0),
.sec_steered_vld(sec_steered_vld),
.td_lane_count(td_lane_count),
.sched_stream_state(sched_stream_state),
.sched_stream_en(sched_stream_en_lane0),
.sched_blank_id(sched_blank_id),
.sched_blank_state(sched_blank_state),
.sched_blank_en(sched_blank_en_lane0),
.sched_idle_en(sched_idle_en_lane0),
.idle_activate_en(idle_activate_en_lane0),
.sched_stream_idle_sel(sched_stream_idle_sel_lane0),
.iso_symbols(iso_symbols_lane0),
.iso_control_sym_flag(iso_control_sym_flag_lane0),
.blank_steering_state(blank_steering_state_lane0)
);

////////////////////////////////////////////////////////////////

iso_lanes_top iso_lanes_top_1(
.clk(ls_clk),
.rst_n(rst_n),
.main_steered(main_steered_lane1),
.sec_steered(sec_steered_lane1),
.sec_steered_vld(sec_steered_vld),
.td_lane_count(td_lane_count),
.sched_stream_state(sched_stream_state),
.sched_stream_en(sched_stream_en_lane1),
.sched_blank_id(sched_blank_id),
.sched_blank_state(sched_blank_state),
.sched_blank_en(sched_blank_en_lane1),
.sched_idle_en(sched_idle_en_lane1),
.idle_activate_en(idle_activate_en_lane1),
.sched_stream_idle_sel(sched_stream_idle_sel_lane1),
.iso_symbols(iso_symbols_lane1),
.iso_control_sym_flag(iso_control_sym_flag_lane1),
.blank_steering_state(blank_steering_state_lane1)
);

////////////////////////////////////////////////////////////////

iso_lanes_top iso_lanes_top_2(
.clk(ls_clk),
.rst_n(rst_n),
.main_steered(main_steered_lane2),
.sec_steered(sec_steered_lane2),
.sec_steered_vld(sec_steered_vld),
.td_lane_count(td_lane_count),
.sched_stream_state(sched_stream_state),
.sched_stream_en(sched_stream_en_lane2),
.sched_blank_id(sched_blank_id),
.sched_blank_state(sched_blank_state),
.sched_blank_en(sched_blank_en_lane2),
.sched_idle_en(sched_idle_en_lane2),
.idle_activate_en(idle_activate_en_lane2),
.sched_stream_idle_sel(sched_stream_idle_sel_lane2),
.iso_symbols(iso_symbols_lane2),
.iso_control_sym_flag(iso_control_sym_flag_lane2),
.blank_steering_state(blank_steering_state_lane2)
);

////////////////////////////////////////////////////////////////

iso_lanes_top iso_lanes_top_3(
.clk(ls_clk),
.rst_n(rst_n),
.main_steered(main_steered_lane3),
.sec_steered(sec_steered_lane3),
.sec_steered_vld(sec_steered_vld),
.td_lane_count(td_lane_count),
.sched_stream_state(sched_stream_state),
.sched_stream_en(sched_stream_en_lane3),
.sched_blank_id(sched_blank_id),
.sched_blank_state(sched_blank_state),
.sched_blank_en(sched_blank_en_lane3),
.sched_idle_en(sched_idle_en_lane3),
.idle_activate_en(idle_activate_en_lane3),
.sched_stream_idle_sel(sched_stream_idle_sel_lane3),
.iso_symbols(iso_symbols_lane3),
.iso_control_sym_flag(iso_control_sym_flag_lane3),
.blank_steering_state(blank_steering_state_lane3)
);

////////////////////////////////////////////////////////////////


main_stream_bus_steering main_stream_bus_steering_0(
.clk(ls_clk),
.rst_n(rst_n),
.sched_steering_en(sched_steering_en),
.td_vld_data(td_vld_data),
.td_lane_count(td_lane_count),
.td_misc0_1(td_misc0_1),
.fifo_pixel_data(fifo_pixel_data),
.rd_data_valid(rd_data_valid),
.fifo_almost_empty(fifo_almost_empty),
.mbs_empty_regs(mbs_empty_regs),
.main_steered_lane0(main_steered_lane0),
.main_steered_lane1(main_steered_lane1),
.main_steered_lane2(main_steered_lane2),
.main_steered_lane3(main_steered_lane3)
);

////////////////////////////////////////////////////////////////

sec_bus_steering sec_bus_steering_0(
.clk(ls_clk),
.rst_n(rst_n),
.td_lane_count(td_lane_count),
.spm_msa(spm_msa),
.spm_vld(spm_msa_vld),
.blank_steering_state0(blank_steering_state_lane0),        
.blank_steering_state1(blank_steering_state_lane1), 
.blank_steering_state2(blank_steering_state_lane2),
.blank_steering_state3(blank_steering_state_lane3),
.sec_steered_lane_vld(sec_steered_vld),
.sec_steered_lane0(sec_steered_lane0),
.sec_steered_lane1(sec_steered_lane1),
.sec_steered_lane2(sec_steered_lane2),
.sec_steered_lane3(sec_steered_lane3)        
);

////////////////////////////////////////////////////////////////


ASYNC_FIFO_TOP #(.DATA_WIDTH(48), .FIFO_DEPTH(128), .WPTR_WIDTH(8), .RPTR_WIDTH(8), .NUM_STAGES(2), .ADDR_WIDTH(7)) ASYNC_FIFO_TOP_0 (
.wr_data(ms_pixel_data),
.winc(ms_de),
.rinc(mbs_empty_regs),
.wclk(ms_stm_clk),
.wrst_n(ms_rst_n),
.rclk(ls_clk),
.rrst_n(rst_n),
.wfull(wfull),
.rempty(fifo_almost_empty),
.rd_data_valid(rd_data_valid),   
.rd_data(fifo_pixel_data)
);

////////////////////////////////////////////////////////////////

clk_mux clk_mux_0(
.hbr3_clk(hbr3_clk),
.hbr2_clk(hbr2_clk),
.hbr_clk(hbr_clk),
.rbr_clk(rbr_clk),
.spm_bw_sel(spm_bw_sel),
.ls_clk(ls_clk)
);

/////////////////////////////////////////////////////
/////////////////////////////////////////////////////
/////////////////////////////////////////////////////

endmodule