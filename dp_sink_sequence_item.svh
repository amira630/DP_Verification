class dp_sink_sequence_item extends uvm_sequence_item;
    `uvm_object_utils(dp_sink_sequence_item);

    string name_1, name_2, name_3;

    function new(string name = "dp_sink_sequence_item");
        super.new(name);
    endfunction //new()

    function string convert2string();
        return $sformatf("%s name_1 = 0s%0s, name_2 = 0s%0s, name_3 = 0s%0s", super.convert2string(), name_1, name_2, name_3);
    endfunction
    
endclass //dp_sink_sequence_item extends superClass
