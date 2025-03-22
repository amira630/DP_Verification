class dp_sink_sequence_item extends uvm_sequence_item;
    `uvm_object_utils_begin(dp_sink_sequence_item)
        `uvm_field_int(addr, UVM_ALL_ON)
        `uvm_field_int(data, UVM_ALL_ON)
        `uvm_field_int(read, UVM_ALL_ON)
    `uvm_object_utils_end

    string name_1, name_2, name_3;

    function new(string name = "dp_sink_sequence_item");
        super.new(name);
    endfunction //new()

    function string convert2string();
        return $sformatf("%s name_1 = %0s, name_2 = %0s, name_3 = %0s", super.convert2string(), name_1, name_2, name_3);
    endfunction
    
endclass //dp_sink_sequence_item extends superClass
