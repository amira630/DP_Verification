module aux_top 
(
// Inputs
input  wire        clk,                
input  wire        rst_n,              
input  wire        spm_transaction_vld,
input  wire [1:0]  spm_cmd,            
input  wire [19:0] spm_address,        
input  wire [7:0]  spm_len,            
input  wire [7:0]  spm_data,           
input  wire        lpm_transaction_vld,
input  wire [1:0]  lpm_cmd,            
input  wire [19:0] lpm_address,        
input  wire [7:0]  lpm_len,            
input  wire [7:0]  lpm_data, 
input  wire        hpd_signal, 

// PHY INTERFACE
input  wire        phy_start_stop,
 
// LPM INTERFACE WITH CR FSM AND CAHNNELL EQ FSM 
input  wire [7:0]  vtg,
input  wire [7:0]  pre,

// CHANNELL EQ FSM WITH LPM INTERFACE 
input  wire [3:0]  eq_cr_dn,
input  wire [3:0]  channel_eq,
input  wire [3:0]  symbol_lock,
input  wire [7:0]  lane_align,
input  wire        eq_data_vld,
input  wire [1:0]  tps,          
input  wire        tps_vld,

// CHANNELL EQ FSM , CR FSM WITH LPM INTERFACE     
input  wire [1:0]  max_vtg, // this signal is input to cr err chk      
input  wire [1:0]  max_pre,


// LPM WITH CTR INTERFACE
input  wire [7:0]  eq_rd_value,


//  EQ ERR CHK FSM , CR ERR CHK FSM AND CR FSM WITH LPM INTERFACE
input  wire        config_param_vld, 
input  wire [7:0]  lpm_link_bw, 
input  wire [1:0]  lpm_link_lc, 


// LPM WITH CR FSM INTERFACE
input  wire        lpm_start_cr, 
input  wire        driving_param_vld,
input  wire        cr_done_vld,
input  wire [3:0]  cr_done,          



//===========================================================                   
// Outputs       
//===========================================================

output wire         aux_start_stop,
output wire         timer_timeout,
output wire         hpd_irq,
output wire         hpd_detect,
output wire         ctrl_native_failed,  
output wire         ctrl_i2c_failed,

// reply decoder with spm interface signals    
output wire [7:0]   spm_reply_data,
output wire         spm_reply_data_vld,  
output wire [1:0]   spm_reply_ack,
output wire         spm_reply_ack_vld, 
output wire         spm_native_i2c, 

// reply decoder with lpm interface signals    
output wire [7:0]   lpm_reply_data,
output wire         lpm_reply_data_vld,  
output wire [1:0]   lpm_reply_ack,
output wire         lpm_reply_ack_vld, 
output wire         lpm_native_i2c, 

// Link Training WITH PHY LAYER INTERFACE
output wire  [1:0]  phy_instruct,
output wire         phy_instruct_vld,
output wire  [1:0]  phy_adj_lc, 
output wire  [7:0]  phy_adj_bw,

// CR FSM WITH LPM AND ERR CHK INTERFACE 
output wire         fsm_cr_failed,
output wire         cr_completed,

// CHANNELL EQ FSM INTERFACE WITH LPM 
output wire  [1:0]  eq_final_adj_lc,
output wire  [7:0]  eq_final_adj_bw,
output wire         eq_lt_failed,
output wire         eq_lt_pass,
output wire         eq_fsm_cr_failed,


// Bidirectional Data Bus
inout  wire [7:0]  aux_in_out          
);

// reply interface
wire [7:0]   reply_data;
wire         reply_data_vld;
wire [1:0]   reply_ack;
wire         reply_ack_vld; 
wire         reply_i2c_native; 

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
.i2c_complete          (i2c_complete),
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
.ctrl_data_done_number(ctrl_done_data_number),
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
.i2c_fsm_failed     (i2c_fsm_failed),
.i2c_complete       (i2c_complete)
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
.reply_i2c_native  (reply_i2c_native),
.bdi_aux_in        (bdi_aux_in),
.bdi_aux_in_vld    (bdi_aux_in_vld),
.ctrl_i2c_native   (ctrl_i2c_native)
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
.ctrl_native_failed (ctrl_native_failed)
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

endmodule