module iso_lanes_top (
input	 wire	        clk,
input	 wire	        rst_n,
input	 wire  	[7:0]   main_steered,
input	 wire	[7:0]   sec_steered,
input    wire           sec_steered_vld,
input	 wire   [1:0]   td_lane_count,
input	 wire	[1:0]   sched_stream_state,
input	 wire  	        sched_stream_en,
input	 wire	        sched_blank_id,
input	 wire	[1:0]   sched_blank_state,
input	 wire	        sched_blank_en,
input	 wire  	        sched_idle_en,
input	 wire	[1:0]   sched_stream_idle_sel,

output	 wire   [7:0]   iso_symbols,
output	 wire           iso_control_sym_flag,
output	 wire	        idle_activate_en,
output	 wire	[1:0]   blank_steering_state
);

////////////////////////////////////////////////////////////////

wire    [7:0]	active_symbols,
				blank_symbols,
				idle_symbols,
				mux_idle_stream_symbols;

wire			active_control_sym_flag,
				blank_control_sym_flag,
				idle_control_sym_flag,
				mux_control_sym_flag;

////////////////////////////////////////////////////////////////							

active_mapper active_mapper_x (
.clk(clk),
.rst_n(rst_n),
.main_steered(main_steered),
.sched_stream_state(sched_stream_state),
.sched_stream_en(sched_stream_en),
.am_control_sym_flag(active_control_sym_flag),
.am_active_symbol(active_symbols)
);

////////////////////////////////////////////////////////////////

blank_mapper blank_mapper_x(
.clk(clk),
.rst_n(rst_n),
.sec_steered_out(sec_steered),
.sec_steered_vld(sec_steered_vld),
.td_lane_count(td_lane_count),
.sched_blank_id(sched_blank_id),
.sched_blank_state(sched_blank_state),
.sched_blank_en(sched_blank_en),
.blank_symbols(blank_symbols),
.blank_control_sym_flag(blank_control_sym_flag),
.blank_steering_state(blank_steering_state)
);

////////////////////////////////////////////////////////////////

idle_pattern idle_pattern_x(
.clk(clk),
.rst_n(rst_n),
.sched_idle_en(sched_idle_en),
.idle_symbols(idle_symbols),
.idle_control_sym_flag(idle_control_sym_flag),
.idle_activate_en(idle_activate_en)
);

////////////////////////////////////////////////////////////////

sr_insertion sr_insertion_x(
.clk(clk),
.rst_n(rst_n),
.mux_idle_stream_symbols(mux_idle_stream_symbols),
.mux_control_sym_flag(mux_control_sym_flag),
.iso_symbols(iso_symbols),
.iso_control_sym_flag(iso_control_sym_flag)
);

////////////////////////////////////////////////////////////////

stream_idle_mux stream_idle_mux_x(
.clk(clk),
.rst_n(rst_n),	
.active_symbols(active_symbols),
.active_control_sym_flag(active_control_sym_flag),
.blank_symbols(blank_symbols),
.blank_control_sym_flag(blank_control_sym_flag),
.idle_symbols(idle_symbols),
.idle_control_sym_flag(idle_control_sym_flag),
.mux_idle_stream_symbols(mux_idle_stream_symbols),
.mux_control_sym_flag(mux_control_sym_flag),
.sched_stream_idle_sel(sched_stream_idle_sel)
);

endmodule
