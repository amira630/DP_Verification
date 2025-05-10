vlog -f src_files.list

vsim -c -voptargs="+acc" work.top

add wave -r /top/*

run -all