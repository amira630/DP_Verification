module cr_top
(
  ////////////////// Inputs //////////////////
  input  wire        clk,
  input  wire        rst_n,  
  // LPM
  input  wire        lpm_start_cr, 
  input  wire        driving_param_vld,
  input  wire        config_param_vld,             
  input  wire [7:0]  vtg,
  input  wire [7:0]  pre,
  input  wire [7:0]  link_bw_cr,
  input  wire [1:0]  link_lc_cr,
  input  wire        cr_done_vld,                  
  input  wire [3:0]  cr_done,
  input  wire [1:0]  max_vtg,                      
  input  wire [1:0]  max_pre,                      
  // EQ ERR CHK
  input  wire [7:0]  new_bw_eq,
  input  wire [1:0]  new_lc_eq,  
  input  wire        err_chk_cr_start, 
  // CTR
  input  wire        cr_ctr_fire, 
  // AUX CTRL Unit
  input  wire        ctrl_ack_flag, 
  input  wire        ctrl_native_failed,           

  ////////////////// Outputs //////////////////
  // LPM & CR ERR CHK
  output wire        fsm_cr_failed,
  output wire        cr_completed,                       
  // CTR
  output wire        cr_ctr_start,  
  // AUX CTRL Unit
  output wire        cr_transaction_vld, 
  output wire [1:0]  cr_cmd,
  output wire [19:0] cr_address,
  output wire [7:0]  cr_len,
  output wire [7:0]  cr_data,
  // EQ FSM
  output wire        eq_start,   
  output wire [7:0]  new_vtg,
  output wire [7:0]  new_pre,
  output wire [7:0]  new_bw,
  output wire [1:0]  new_lc,
  // PHY Layer
  output wire [1:0]  cr_phy_instruct,
  output wire        cr_phy_instruct_vld,
  output wire [1:0]  cr_adj_lc, 
  output wire [7:0]  cr_adj_bw     
);


// Internal Signals
  wire [7:0]  err_chk_new_bw_cr;
  wire [1:0]  err_chk_new_lc_cr;  
  wire        err_chk_err_cr_failed; 
  wire        err_chk_drive_setting_flag;
  wire        err_chk_bw_flag; 
  wire        err_chk_lc_flag;

  wire        fsm_cr_chk_start;  
  wire [7:0]  fsm_adj_vtg;
  wire [7:0]  fsm_adj_pre; 
                      


// CR FSM Block
cr_fsm cr_fsm0 
(
// *********** Inputs *********** //
.clk(clk),
.rst_n(rst_n),
// LPM
.lpm_start_cr(lpm_start_cr),
.driving_param_vld(driving_param_vld),
.config_param_vld(config_param_vld),
.vtg(vtg),
.pre(pre),
.link_bw_cr(link_bw_cr),
.link_lc_cr(link_lc_cr),
.cr_done_vld(cr_done_vld),
.cr_done(cr_done),
.max_vtg(max_vtg),
.max_pre(max_pre),
// CR ERR CHK 
.new_bw_cr(err_chk_new_bw_cr),
.new_lc_cr(err_chk_new_lc_cr),
.err_cr_failed(err_chk_err_cr_failed),
.drive_setting_flag(err_chk_drive_setting_flag),
.bw_Flag(err_chk_bw_flag),
.lc_Flag(err_chk_lc_flag),
// EQ ERR CHK
.new_bw_eq(new_bw_eq),
.new_lc_eq(new_lc_eq),
.err_chk_cr_start(err_chk_cr_start),
// CTR
.cr_ctr_fire(cr_ctr_fire),
// AUX CTRL Unit
.ctrl_ack_flag(ctrl_ack_flag),
.ctrl_native_failed(ctrl_native_failed),

// *********** Outputs *********** //
// LPM & CR ERR CHK
.fsm_cr_failed(fsm_cr_failed),
.cr_completed(cr_completed),
// CR ERR CHK
.cr_chk_start(fsm_cr_chk_start),
.adj_vtg(fsm_adj_vtg),
.adj_pre(fsm_adj_pre),
// CTR
.cr_ctr_start(cr_ctr_start),
// AUX CTRL Unit
.cr_transaction_vld(cr_transaction_vld),
.cr_cmd(cr_cmd),
.cr_address(cr_address),
.cr_len(cr_len),
.cr_data(cr_data),
// EQ FSM
.eq_start(eq_start),
.new_vtg(new_vtg),
.new_pre(new_pre),
.new_bw(new_bw),
.new_lc(new_lc),
// PHY Layer
.cr_phy_instruct(cr_phy_instruct),
.cr_phy_instruct_vld(cr_phy_instruct_vld),
.cr_adj_lc(cr_adj_lc),
.cr_adj_bw(cr_adj_bw)    
);

// CR FSM Block
cr_err_chk cr_err_chk0 
(
// *********** Inputs *********** //
.clk(clk),
.rst_n(rst_n),
// LPM
.config_param_vld(config_param_vld),
.link_bw_cr(link_bw_cr),
.link_lc_cr(link_lc_cr),
.max_vtg(max_vtg),
// CR FSM
.cr_chk_start(fsm_cr_chk_start),
.adj_vtg(fsm_adj_vtg),
.adj_pre(fsm_adj_pre),
.fsm_cr_failed(fsm_cr_failed),
.cr_completed(cr_completed),

// *********** Outputs *********** //
// CR FSM
.new_bw_cr(err_chk_new_bw_cr),
.new_lc_cr(err_chk_new_lc_cr),
.err_cr_failed(err_chk_err_cr_failed),
.drive_setting_flag(err_chk_drive_setting_flag),
.bw_flag(err_chk_bw_flag),
.lc_flag(err_chk_lc_flag)
);

endmodule

