class dp_tl_iso_sequence extends dp_tl_base_sequence;
    `uvm_object_utils(dp_tl_iso_sequence);
    
    function new(string name = "dp_tl_iso_sequence");
        super.new(name);
    endfunction
    
    task body();
        // `uvm_info(get_type_name(), "Testing Isochronous with RBR, 640x480, 1 lane, RGB, 8bpc, with 24MHz input rate", UVM_MEDIUM)
        // ISO_INIT_config(2'b00, 2'b00, 16'd162, 3'b001, 3'b001, 3'b000, 10'd24);
        // Main_Stream_config(1);
        // `uvm_info(get_type_name(), "Completed Isochronous with RBR, 640x480, 1 lane, RGB, 8bpc, with 24MHz input rate", UVM_MEDIUM)

        // `uvm_info(get_type_name(), "Testing Isochronous with HBR, 640x480, 2 lanes, YCbCr, 8bpc, with 24MHz input rate", UVM_MEDIUM)
        // ISO_INIT_config(2'b01, 2'b00, 16'd270, 3'b010, 3'b001, 3'b110, 10'd24);
        // Main_Stream_config(1);
        // `uvm_info(get_type_name(), "Completed Isochronous with HBR, 640x480, 2 lanes, YCbCr, 8bpc, with 24MHz input rate", UVM_MEDIUM)

        // `uvm_info(get_type_name(), "Testing Isochronous with HBR2, 640x480, 4 lanes, RGB, 8bpc, with 24MHz input rate", UVM_MEDIUM)
        // ISO_INIT_config(2'b10, 2'b00, 16'd540, 3'b100, 3'b001, 3'b000, 10'd24);
        // Main_Stream_config(1);
        // `uvm_info(get_type_name(), "Completed Isochronous with HBR2, 640x480, 4 lanes, RGB, 8bpc, with 24MHz input rate", UVM_MEDIUM)      

        `uvm_info(get_type_name(), "Testing Isochronous with HBR3, 640x480, 4 lanes, RGB, 8bpc, with 80MHz input rate", UVM_MEDIUM)
        ISO_INIT_config(2'b11, 2'b00, 16'd810, 3'b100, 3'b001, 3'b000, 10'd80);
        Main_Stream_config(1);
        `uvm_info(get_type_name(), "Completed Isochronous with HBR3, 640x480, 4 lanes, RGB, 8bpc, with 80MHz input rate", UVM_MEDIUM)    
    endtask
endclass //dp_tl_iso_sequence extends superClass