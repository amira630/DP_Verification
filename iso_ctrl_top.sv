module iso_ctrl_top (
input	 wire	        clk,
input	 wire	        rst_n,
input	 wire  	        ms_de,
input	 wire	[9:0]   ms_stm_bw,
input	 wire	        ms_stm_bw_valid,
input	 wire           ms_vsync,
input	 wire	        ms_hsync,
input	 wire  	        spm_iso_start,
input	 wire	[2:0]   spm_lane_count,
input	 wire	[15:0]  spm_lane_bw,
input    wire   [15:0]  htotal,             // total horizontal pixels
input    wire   [15:0]  hwidth,             // active horizontal width
input    wire   [15:0]  vtotal,             // total vertical pixels
input    wire   [15:0]  vheight,            // active vertical height
input    wire   [7:0]   misc0,              // provide colormitry information as color depth and pixel format bpc   
input    wire   [7:0]   misc1,              // additional miscellaneous data
input    wire           h_sync_polarity,    // horizontal sync polarity
input    wire           v_sync_polarity,    // vertical sync polarity
input	 wire  	        spm_msa_vld,
input	 wire	        idle_activate_en_lane0,
input	 wire	        idle_activate_en_lane1,
input	 wire  	        idle_activate_en_lane2,
input	 wire	        idle_activate_en_lane3,


output	 wire   [8:0]   td_misc0_1,
output	 wire   [1:0]   td_lane_count,
output	 wire	        td_vld_data,
output	 wire	        sched_steering_en,
output	 wire   [1:0]   sched_stream_state,
output	 wire           sched_stream_en_lane0,
output	 wire	        sched_stream_en_lane1,
output	 wire           sched_stream_en_lane2,
output	 wire           sched_stream_en_lane3,
output	 wire	        sched_blank_id,
output	 wire   [1:0]   sched_blank_state,
output	 wire           sched_blank_en_lane0,
output	 wire	        sched_blank_en_lane1,
output	 wire           sched_blank_en_lane2,
output	 wire           sched_blank_en_lane3,
output	 wire	        sched_idle_en_lane0,
output	 wire           sched_idle_en_lane1,
output	 wire           sched_idle_en_lane2,
output	 wire	        sched_idle_en_lane3,
output	 wire   [1:0]   sched_stream_idle_sel_lane0,
output	 wire   [1:0]   sched_stream_idle_sel_lane1,
output	 wire	[1:0]   sched_stream_idle_sel_lane2,
output	 wire   [1:0]   sched_stream_idle_sel_lane3
);


////////////////////////////////////////////////////////////////

wire	         td_vld_data_internal;
wire	         td_scheduler_start;
wire    [1:0]    td_lane_count_internal;
wire	[13:0]   td_h_blank_ctr;
wire	[15:0]   td_h_active_ctr;
wire	[9:0]    td_v_blank_ctr;
wire	[12:0]   td_v_active_ctr;
wire	[5:0]    td_tu_vld_data_size;
wire	[5:0]    td_tu_stuffed_data_size;
wire	         td_hsync;
wire	         td_vsync;
wire	         td_de;
wire	[3:0]    td_tu_alternate_up;
wire	[3:0]    td_tu_alternate_down;
wire	[15:0]   td_h_total_ctr;
wire	         td_hsync_polarity;
wire	         td_vsync_polarity;

////////////////////////////////////////////////////////////////							

assign td_lane_count = td_lane_count_internal;
assign td_vld_data = td_vld_data_internal;

////////////////////////////////////////////////////////////////

timing_decision_block timing_decision_block_0 (
.clk(clk),
.rst_n(rst_n),
.ms_de(ms_de),
.ms_stm_bw_valid(ms_stm_bw_valid),
.ms_stm_bw(ms_stm_bw),
.ms_vsync(ms_vsync),
.ms_hsync(ms_hsync),
.htotal(htotal),             // total horizontal pixels
.hwidth(hwidth),             // active horizontal width
.vtotal(vtotal),             // total vertical pixels
.vheight(vheight),            // active vertical height
.misc0(misc0),              // provide colormitry information as color depth and pixel format bpc   
.misc1(misc1),              // additional miscellaneous data
.h_sync_polarity(h_sync_polarity),    // horizontal sync polarity
.v_sync_polarity(v_sync_polarity),    // vertical sync polarity
.spm_iso_start(spm_iso_start),
.spm_lane_count(spm_lane_count),
.spm_lane_bw(spm_lane_bw),
//.spm_msa(spm_msa),
.spm_msa_vld(spm_msa_vld),
.td_misc0_1(td_misc0_1),
.td_vld_data(td_vld_data_internal),
.td_scheduler_start(td_scheduler_start),
.td_lane_count(td_lane_count_internal),
.td_h_blank_ctr(td_h_blank_ctr),
.td_h_active_ctr(td_h_active_ctr),
.td_v_blank_ctr(td_v_blank_ctr),
.td_v_active_ctr(td_v_active_ctr),
.td_tu_vld_data_size(td_tu_vld_data_size),
.td_tu_stuffed_data_size(td_tu_stuffed_data_size),
.td_hsync(td_hsync),
.td_vsync(td_vsync),
.td_de(td_de),
.td_tu_alternate_up(td_tu_alternate_up),
.td_tu_alternate_down(td_tu_alternate_down),
.td_h_total_ctr(td_h_total_ctr),
.td_hsync_polarity(td_hsync_polarity),
.td_vsync_polarity(td_vsync_polarity)
);

////////////////////////////////////////////////////////////////

iso_scheduler iso_scheduler_0(
.clk(clk),
.rst_n(rst_n),
.td_vld_data(td_vld_data_internal),
.td_scheduler_start(td_scheduler_start),
.td_lane_count(td_lane_count_internal),
.td_h_blank_ctr(td_h_blank_ctr),
.td_h_active_ctr(td_h_active_ctr),
.td_v_blank_ctr(td_v_blank_ctr),
.td_v_active_ctr(td_v_active_ctr),
.td_tu_vld_data_size(td_tu_vld_data_size),
.td_tu_stuffed_data_size(td_tu_stuffed_data_size),
.td_hsync(td_hsync),
.td_vsync(td_vsync),
.td_de(td_de),
.td_tu_alternate_up(td_tu_alternate_up),
.td_tu_alternate_down(td_tu_alternate_down),
.td_h_total_ctr(td_h_total_ctr),
.td_hsync_polarity(td_hsync_polarity),
.td_vsync_polarity(td_vsync_polarity),
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
.idle_activate_en_lane0(idle_activate_en_lane0),
.idle_activate_en_lane1(idle_activate_en_lane1),
.idle_activate_en_lane2(idle_activate_en_lane2),
.idle_activate_en_lane3(idle_activate_en_lane3),
.sched_stream_idle_sel_lane0(sched_stream_idle_sel_lane0),
.sched_stream_idle_sel_lane1(sched_stream_idle_sel_lane1),
.sched_stream_idle_sel_lane2(sched_stream_idle_sel_lane2),
.sched_stream_idle_sel_lane3(sched_stream_idle_sel_lane3)
);

endmodule
