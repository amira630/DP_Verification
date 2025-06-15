vlog -f src_files.list +cover -covercells

vsim -c -voptargs="+acc" work.top -cover

add wave /top/*

add wave -group DUT /top/DUT/*

add wave -group "HPD" /top/DUT/hpd_inst/*
add wave -group "AUX Control Unit" /top/DUT/aux_ctrl_unit_inst/*
add wave -group "I2C TOP" /top/DUT/i2c_top_inst/*
add wave -group "Link Training TOP" /top/DUT/link_trainning_inst/*
add wave -group "Timeout Timer" /top/DUT/timeout_timer_inst/*
add wave -group "Bidirectional AUX PHY Interface" /top/DUT/bidirectional_aux_phy_interface_inst/*
add wave -group "Reply Decoder" /top/DUT/reply_decoder_inst/*
add wave -group "Native I2C MUX" /top/DUT/native_i2c_mux_inst/*
add wave -group "Native I2C DEMUX" /top/DUT/native_i2c_de_mux_inst/*
add wave -group "Native Message Encoder" /top/DUT/native_message_encoder_inst/*
add wave -group "Native MSG ENCODER" /top/DUT/native_message_encoder_inst/*
add wave -group "CR EQ MUX" /top/DUT/cr_eq_mux_inst/*

add wave -group "CLK MUX" /top/DUT/clk_mux_0/*
add wave -group "ASYNC FIFO TOP" /top/DUT/ASYNC_FIFO_TOP_0/*
add wave -group "ISO Control" /top/DUT/iso_ctrl_top_0/*
add wave -group "ISO Lane0" /top/DUT/iso_lanes_top_0/*
add wave -group "ISO Lane1" /top/DUT/iso_lanes_top_1/*
add wave -group "ISO Lane2" /top/DUT/iso_lanes_top_2/*
add wave -group "ISO Lane3" /top/DUT/iso_lanes_top_3/*
add wave -group "Main Stream Bus Steering" /top/DUT/main_stream_bus_steering_0/*
add wave -group "Sec Stream Bus Steering" /top/DUT/sec_bus_steering_0/*

add wave -group TL_Interface /top/tl_if/*

add wave -group SINK_Interface /top/sink_if/*

coverage save DP_UVM.ucdb -onexit

vcover report DP_UVM.ucdb -details -annotate -all -output DP_UVM_cvr_rpt.txt

run -all