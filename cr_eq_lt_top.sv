module cr_eq_lt_top 
(
    //============================================================
    // INPUTS 
    //============================================================
    input  wire        clk,          // 100 kHz clock input
    input  wire        rst_n,        // Reset signal

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

    // CR FSM AND CAHNELL EQUALIZATION FSM WITH AUX CTRL UNIT INTERFACE 
    input  wire        ctrl_ack_flag,
    input  wire        ctrl_native_failed,

    //  EQ ERR CHK FSM , CR ERR CHK FSM AND CR FSM WITH LPM INTERFACE
    input  wire        config_param_vld, 
    input  wire [7:0]  lpm_link_bw, 
    input  wire [1:0]  lpm_link_lc, 


    // LPM WITH CR FSM INTERFACE
    input  wire        lpm_start_cr, 
    input  wire        driving_param_vld,
    input  wire        cr_done_vld,
    input  wire [3:0]  cr_done,

    //==========================================================
    // OUTPUTS
    //==========================================================
 
    // CR FSM WITH AUX CTRL UNIT INTERFACE
    output wire         cr_transaction_vld, 
    output wire  [1:0]  cr_cmd,
    output wire  [19:0] cr_address,
    output wire  [7:0]  cr_len,
    output wire  [7:0]  cr_data,

    // CR FSM WITH LPM AND ERR CHK INTERFACE 
    output wire         fsm_cr_failed,
    output wire         cr_completed,

    // CR FSM WITH PHY LAYER INTERFACE
    output wire  [1:0]  cr_phy_instruct,
    output wire         cr_phy_instruct_vld,
    output wire  [1:0]  cr_adj_lc,
    output wire  [7:0]  cr_adj_bw,
    // CHANNELL EQ FSM INTERFACE WITH LPM 
    output wire  [1:0]  eq_final_adj_lc,
    output wire  [7:0]  eq_final_adj_bw,
    output wire         eq_lt_failed,
    output wire         eq_lt_pass,
    output wire         eq_fsm_cr_failed,

    // CHANNELL EQ FSM INTERFACE WITH PHY LAYER 
    output wire  [1:0]  eq_phy_instruct,
    output wire  [1:0]  eq_adj_lc,
    output wire  [7:0]  eq_adj_bw,
    output wire         eq_phy_instruct_vld,

    // CHANNELL EQ FSM INTERFACE WITH AUX_CTRL_UNIT
    output wire  [7:0]  eq_data,
    output wire  [19:0] eq_address,
    output wire  [7:0]  eq_len,
    output wire  [1:0]  eq_cmd,
    output wire         eq_transaction_vld
);

//===========================================================
// INTERNAL SIGNALS
//===========================================================

// CR FSM AND CHANNELL EQ FSM
wire [7:0]  new_vtg;
wire [7:0]  new_pre;
wire [7:0]  new_bw;
wire [1:0]  new_lc;
wire        eq_start;

// ERR CHECK CHANNEL EQUALIZATION INTERFACE WITH CR FSM
wire [7:0]   eq_err_chk_bw; 
wire [1:0]   eq_err_chk_lc;
wire         eq_err_chk_cr_start;

// CR FSM INTERFACE WITH CTR
wire         cr_ctr_start;
wire         cr_ctr_fire;



cr_top clock_recovery_inst
(
   .clk                (clk),
   .rst_n              (rst_n),
   .lpm_start_cr       (lpm_start_cr),
   .driving_param_vld  (driving_param_vld),
   .vtg                (vtg),
   .pre                (pre),
   .cr_cmd             (cr_cmd),
   .cr_len             (cr_len),
   .new_bw             (new_bw),
   .new_lc             (new_lc),
   .cr_data            (cr_data),
   .cr_done            (cr_done),
   .max_pre            (max_pre),
   .max_vtg            (max_vtg),
   .new_pre            (new_pre),
   .new_vtg            (new_vtg),
   .eq_start           (eq_start),
   .cr_adj_bw          (cr_adj_bw),
   .cr_adj_lc          (cr_adj_lc),
   .cr_address         (cr_address),
   .cr_ctr_fire        (cr_ctr_fire),
   .cr_done_vld        (cr_done_vld),
   .cr_completed       (cr_completed),
   .cr_ctr_start       (cr_ctr_start),
   .ctrl_ack_flag      (ctrl_ack_flag),
   .fsm_cr_failed      (fsm_cr_failed),
   .cr_phy_instruct    (cr_phy_instruct),
   .config_param_vld   (config_param_vld),
   .cr_transaction_vld (cr_transaction_vld),
   .ctrl_native_failed (ctrl_native_failed),
   .cr_phy_instruct_vld(cr_phy_instruct_vld),
   .link_bw_cr         (lpm_link_bw),
   .link_lc_cr         (lpm_link_lc),
   .new_bw_eq          (new_bw),
   .new_lc_eq          (new_lc),
   .err_chk_cr_start   (eq_err_chk_cr_start)  
);

eq_top channell_eq_top 
(
    .clk                (clk),
    .rst_n              (rst_n),
    .new_bw             (new_bw),
    .new_lc             (new_lc),
    .vtg                (vtg),
    .pre                (pre),
    .max_pre            (max_pre),
    .max_vtg            (max_vtg),
    .new_pre            (new_pre),
    .new_vtg            (new_vtg),
    .eq_start           (eq_start),
    .cr_ctr_fire        (cr_ctr_fire),
    .cr_ctr_start       (cr_ctr_start),
    .ctrl_ack_flag      (ctrl_ack_flag),
    .config_param_vld   (config_param_vld),
    .ctrl_native_failed (ctrl_native_failed),
    .lpm_link_bw        (lpm_link_bw),
    .lpm_link_lc        (lpm_link_lc),
    .eq_err_chk_cr_start(eq_err_chk_cr_start),
    .tps                (tps),
    .eq_cmd             (eq_cmd),
    .eq_len             (eq_len),
    .eq_data            (eq_data),
    .tps_vld            (tps_vld),
    .eq_cr_dn           (eq_cr_dn),
    .eq_adj_bw          (eq_adj_bw),
    .eq_adj_lc          (eq_adj_lc),
    .channel_eq         (channel_eq),
    .eq_address         (eq_address),
    .eq_lt_pass         (eq_lt_pass),
    .lane_align         (lane_align),
    .eq_data_vld        (eq_data_vld),
    .eq_rd_value        (eq_rd_value),
    .symbol_lock        (symbol_lock),
    .eq_lt_failed       (eq_lt_failed),
    .eq_err_chk_bw      (eq_err_chk_bw),
    .eq_err_chk_lc      (eq_err_chk_lc),
    .eq_final_adj_bw    (eq_final_adj_bw),
    .eq_final_adj_lc    (eq_final_adj_lc),
    .eq_phy_instruct    (eq_phy_instruct),
    .eq_transaction_vld (eq_transaction_vld),
    .eq_phy_instruct_vld(eq_phy_instruct_vld)
);



endmodule