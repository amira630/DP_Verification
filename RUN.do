vlog -f src_files.list

vsim -c -voptargs="+acc" work.top

add wave /top/*
add wave -group DUT /top/DUT/*
add wave -group TL_Interface /top/tl_if/*
add wave -group SINK_Interface /top/sink_if/*

run -all