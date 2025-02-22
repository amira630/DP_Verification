class dp_sink_sequence extends uvm_sequence #(dp_sink_sequence_item);
    `uvm_object_utils(dp_sink_sequence);

    dp_sink_sequence_item seq_item;

    function new(string name = "dp_sink_sequence");
        super.new(name);
    endfunction //new()

    task body();
        seq_item = dp_sink_sequence_item::type_id::create("seq_item");
        start_item(seq_item);
        seq_item.name_1 = "Aya_sink";
        seq_item.name_2 = "Amira_sink";
        seq_item.name_3 = "M_Ayman_sink";
        finish_item(seq_item);
    endtask
endclass //dp_sink_sequence extends superClass