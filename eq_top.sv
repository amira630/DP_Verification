module eq_top
(
    //=========================================================================
    //INPUTS
    //=========================================================================
    input  wire        clk,          // 100 kHz clock input
    input  wire        rst_n,        // Reset signal

    // CHANNELL EQUALIZATION FSM WITH LPM INTERFACE 
    input  wire [7:0]  vtg,
    input  wire [7:0]  pre,
    input  wire [3:0]  eq_cr_dn,
    input  wire [3:0]  channel_eq,
    input  wire [3:0]  symbol_lock,
    input  wire [7:0]  lane_align,
    input  wire        eq_data_vld,
    input  wire [1:0]  tps,         // max supported tps 
    input  wire        tps_vld,     // valid signal for max supported vtg and pre and tps
    input  wire [1:0]  max_vtg,
    input  wire [1:0]  max_pre,

    // LPM WITH CTR 
    input  wire [7:0]  eq_rd_value,

    // COUNTER TIMER INTERFACE WITH CR FSM 
    input  wire        cr_ctr_start,

    //  EQ ERR CHK FSM WITH LPM INTERFACE
    input  wire        config_param_vld,
    input  wire [7:0]  lpm_link_bw, // link policy maker bandwidth 
    input  wire [1:0]  lpm_link_lc, // link policy maker lane count

    // CHANNELL EQ FSM WITH CR FSM INTERFACE 
    input  wire [7:0]  new_vtg,
    input  wire [7:0]  new_pre,
    input  wire [7:0]  new_bw,
    input  wire [1:0]  new_lc,
    input  wire        eq_start,


    // CAHNELL EQUALIZATION AUX CTRL UNIT INTERFACE 
    input  wire        ctrl_ack_flag,
    input  wire        ctrl_native_failed,

    //============================================================
    //OUTPUTS 
    //============================================================

    // COUNTER INTERFACE WITH CR FSM
    output wire         cr_ctr_fire,

    // ERR CHECK CHANNEL EQUALIZATION INTERFACE WITH CR FSM
    output wire [7:0]   eq_err_chk_bw, 
    output wire [1:0]   eq_err_chk_lc,
    output wire         eq_err_chk_cr_start, 

    // CHANNELL EQ FSM INTERFACE WITH LPM
    output wire  [1:0]  eq_final_adj_lc,
    output wire  [7:0]  eq_final_adj_bw,
    output wire         eq_lt_failed,
    output wire         eq_lt_pass,
    output wire         eq_fsm_cr_failed, // flag signal asserted when channell eq failed and we will decrease LC or BW and start CR again

    // CHANNELL EQ FSM INTERFACE WITH PHY LAYER
    output wire  [1:0]  eq_phy_instruct,
    output wire  [1:0]  eq_adj_lc,
    output wire  [7:0]  eq_adj_bw,
    output wire         eq_phy_instruct_vld,

    // EQ FSM INTERFACE WITH AUX_CTRL_UNIT
    output wire  [7:0]  eq_data,
    output wire  [19:0] eq_address,
    output wire  [7:0]  eq_len,
    output wire  [1:0]  eq_cmd,
    output wire         eq_transaction_vld
);

wire         eq_ctr_start;
wire         eq_ctr_fire;
wire  [3:0]  eq_fsm_cr_dn;
wire         eq_fsm_start_cr_err;
wire         eq_fsm_start_eq_err;
wire         eq_err_chk_failed;


eq_fsm eq_fsm_inst 
(
    .clk                (clk),
    .rst_n              (rst_n),
    .vtg                (vtg),
    .pre                (pre),
    .eq_cr_dn           (eq_cr_dn),
    .channel_eq         (channel_eq),
    .symbol_lock        (symbol_lock),
    .lane_align         (lane_align),
    .eq_data_vld        (eq_data_vld),
    .tps                (tps),
    .tps_vld            (tps_vld),
    .new_vtg            (new_vtg),
    .new_pre            (new_pre),
    .new_bw             (new_bw),
    .new_lc             (new_lc),
    .eq_start           (eq_start),
    .ctrl_ack_flag      (ctrl_ack_flag),
    .eq_err_chk_failed  (eq_err_chk_failed),       
    .eq_lt_failed       (eq_lt_failed),
    .eq_lt_pass         (eq_lt_pass),
    .eq_final_adj_lc    (eq_final_adj_lc),
    .eq_final_adj_bw    (eq_final_adj_bw),
    .eq_phy_instruct    (eq_phy_instruct),
    .eq_phy_instruct_vld(eq_phy_instruct_vld),
    .eq_adj_lc          (eq_adj_lc),
    .eq_adj_bw          (eq_adj_bw),
    .eq_ctr_start       (eq_ctr_start),
    .eq_ctr_fire        (eq_ctr_fire),
    .eq_fsm_start_cr_err(eq_fsm_start_cr_err),
    .eq_fsm_start_eq_err(eq_fsm_start_eq_err),
    .eq_fsm_cr_dn       (eq_fsm_cr_dn),
    .eq_data            (eq_data),
    .eq_address         (eq_address),
    .eq_len             (eq_len),
    .eq_cmd             (eq_cmd),
    .eq_transaction_vld (eq_transaction_vld),
    .ctrl_native_failed (ctrl_native_failed),
    .max_vtg            (max_vtg),
    .max_pre            (max_pre),
    .eq_fsm_cr_failed   (eq_fsm_cr_failed)
);


eq_err_chk eq_err_chk_inst
(
    .clk                (clk),
    .rst_n              (rst_n),
    .eq_fsm_start_cr_err(eq_fsm_start_cr_err),
    .eq_fsm_start_eq_err(eq_fsm_start_eq_err),
    .eq_fsm_cr_dn       (eq_fsm_cr_dn),
    .eq_err_chk_failed  (eq_err_chk_failed),
    .eq_err_chk_bw      (eq_err_chk_bw),
    .eq_err_chk_lc      (eq_err_chk_lc),
    .eq_err_chk_cr_start(eq_err_chk_cr_start),
    .lpm_link_bw        (lpm_link_bw),
    .lpm_link_lc        (lpm_link_lc),
    .eq_start           (eq_start),
    .new_bw             (new_bw),
    .new_lc             (new_lc),
    .config_param_vld   (config_param_vld)
);

link_trainning_ctr  lt_ctr_inst
(
    .clk                (clk),
    .rst_n              (rst_n),
    .eq_ctr_start       (eq_ctr_start),
    .eq_ctr_fire        (eq_ctr_fire),
    .cr_ctr_start       (cr_ctr_start),
    .cr_ctr_fire        (cr_ctr_fire),
    .eq_rd_value        (eq_rd_value)
);
endmodule 

