package DP_TL_sequence_pkg;
    import uvm_pkg::*;
    import DP_TL_sequence_item_pkg::*;
    `include "uvm_macros.svh"

    class DP_TL_RESET_sequence extends uvm_sequence #(DP_TL_sequence_item);
        `uvm_object_utils(DP_TL_RESET_sequence);

        DP_TL_sequence_item seq_item;

        function new(string name = "DP_TL_RESET_sequence");
            super.new(name);
        endfunction //new()

        task body();
            seq_item = DP_TL_sequence_item::type_id::create("seq_item");
            start_item(seq_item);
            seq_item.reset = 0;
            seq_item.valid_in = 0;
            seq_item.a = 0;
            seq_item.b = 0;
            seq_item.cin = 0;
            finish_item(seq_item);
        endtask
    endclass //DP_TL_RESET_sequence extends superClass

    class DP_TL_RANDOM_sequence extends uvm_sequence #(DP_TL_sequence_item);
        `uvm_object_utils(DP_TL_RANDOM_sequence);

        DP_TL_sequence_item seq_item;

        function new(string name = "DP_TL_RANDOM_sequence");
            super.new(name);
        endfunction //new()

        task body();
            seq_item = DP_TL_sequence_item::type_id::create("seq_item");
            repeat(200) begin
                start_item(seq_item);
                rand_seq: assert (seq_item.randomize());
                finish_item(seq_item);                
            end
        endtask
    endclass //DP_TL_RANDOM_sequence extends superClass
endpackage