vlog -f src_files.list

vsim -c -voptargs="+acc" work.top

add wave -r /top/tl_if/*
add wave -r /top/sink_if/*

run -all