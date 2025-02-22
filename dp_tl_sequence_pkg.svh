class dp_tl_sequence extends uvm_sequence #(dp_tl_sequence_item);
    `uvm_object_utils(dp_tl_sequence);

    dp_tl_sequence_item seq_item;

    function new(string name = "dp_tl_sequence");
        super.new(name);
    endfunction //new()

    task body();
        seq_item = dp_tl_sequence_item::type_id::create("seq_item");
        start_item(seq_item);
        seq_item.name_1 = "Aya_tl";
        seq_item.name_2 = "Amira_tl";
        seq_item.name_3 = "M_Ayman_tl";
        finish_item(seq_item);
    endtask
endclass //dp_tl_sequence extends superClass