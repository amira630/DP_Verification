module iso_top (
input     wire            hbr3_clk,
input     wire            hbr2_clk,
input     wire            hbr_clk,
input     wire            rbr_clk,
input     wire    [1:0]   spm_bw_sel,
input     wire            rst_n,
input     wire    [47:0]  ms_pixel_data,
input     wire            ms_stm_clk,
input     wire            ms_de,
input     wire    [9:0]   ms_stm_bw,
input     wire            ms_stm_bw_valid,
input     wire            ms_vsync,
input     wire            ms_hsync,
input     wire            spm_iso_start,
input     wire    [2:0]   spm_lane_count,
input     wire    [15:0]  spm_lane_bw,
input     wire    [191:0] spm_msa,
input     wire            spm_msa_vld,
input     wire            ms_rst_n,

output    wire    [7:0]   iso_symbols_lane0,
output    wire            iso_control_sym_flag_lane0,
output    wire    [7:0]   iso_symbols_lane1,
output    wire            iso_control_sym_flag_lane1,
output    wire    [7:0]   iso_symbols_lane2,
output    wire            iso_control_sym_flag_lane2,
output    wire    [7:0]   iso_symbols_lane3,
output    wire            iso_control_sym_flag_lane3,

output    wire            wfull
);

////////////////////////////////////////////////////////////////

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
//wire             sched_idle_en_lane0;
//wire             sched_idle_en_lane1;
//wire             sched_idle_en_lane2;
//wire             sched_idle_en_lane3;
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
//.sched_idle_en_lane0(sched_idle_en_lane0),
//.sched_idle_en_lane1(sched_idle_en_lane1),
//.sched_idle_en_lane2(sched_idle_en_lane2),
//.sched_idle_en_lane3(sched_idle_en_lane3),
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
.sched_idle_en(spm_iso_start),
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
.sched_idle_en(spm_iso_start),
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
.sched_idle_en(spm_iso_start),
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
.sched_idle_en(spm_iso_start),
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
.td_vld_data(td_vld_data),
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


ASYNC_FIFO_TOP #(.DATA_WIDTH(48), .FIFO_DEPTH(256), .WPTR_WIDTH(9), .RPTR_WIDTH(9), .NUM_STAGES(2), .ADDR_WIDTH(8)) ASYNC_FIFO_TOP_0 (
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


endmodule
