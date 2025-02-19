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
            seq_item.ctl = 0;
            seq_item.a = 0;
            seq_item.b = 0;
            seq_item.cin = 0;
            finish_item(seq_item);
        endtask
    endclass //DP_TL_RESET_sequence extends superClass

    class DP_TL_SEL_sequence extends uvm_sequence #(DP_TL_sequence_item);
        `uvm_object_utils(DP_TL_SEL_sequence);

        DP_TL_sequence_item seq_item;

        function new(string name = "DP_TL_SEL_sequence");
            super.new(name);
        endfunction //new()

        task body();
            seq_item = DP_TL_sequence_item::type_id::create("seq_item");
            repeat(10) begin
                start_item(seq_item);
                SEL_seq: assert (seq_item.randomize() with {ctl == 0;})
                finish_item(seq_item);                
            end
        endtask
    endclass //DP_TL_SEL_sequence extends superClass

    class DP_TL_INC_sequence extends uvm_sequence #(DP_TL_sequence_item);
        `uvm_object_utils(DP_TL_INC_sequence);

        DP_TL_sequence_item seq_item;

        function new(string name = "DP_TL_INC_sequence");
            super.new(name);
        endfunction //new()

        task body();
            seq_item = DP_TL_sequence_item::type_id::create("seq_item");
            repeat(10) begin
                start_item(seq_item);
                INC_seq: assert (seq_item.randomize() with {ctl == 1;}) else `uvm_fatal("body", "Randomization with INC failed!");
                finish_item(seq_item);                
            end
        endtask
    endclass //DP_TL_INC_sequence extends superClass

    class DP_TL_DEC_sequence extends uvm_sequence #(DP_TL_sequence_item);
        `uvm_object_utils(DP_TL_DEC_sequence);

        DP_TL_sequence_item seq_item;

        function new(string name = "DP_TL_DEC_sequence");
            super.new(name);
        endfunction //new()

        task body();
            seq_item = DP_TL_sequence_item::type_id::create("seq_item");
            repeat(10) begin
                start_item(seq_item);
                DEC_seq: assert (seq_item.randomize() with {ctl == 2;}) else `uvm_fatal("body", "Randomization with DEC failed!");
                finish_item(seq_item);                
            end
        endtask
    endclass //DP_TL_DEC_sequence extends superClass

    class DP_TL_ADD_sequence extends uvm_sequence #(DP_TL_sequence_item);
        `uvm_object_utils(DP_TL_ADD_sequence);

        DP_TL_sequence_item seq_item;

        function new(string name = "DP_TL_ADD_sequence");
            super.new(name);
        endfunction //new()

        task body();
            seq_item = DP_TL_sequence_item::type_id::create("seq_item");
            repeat(10) begin
                start_item(seq_item);
                ADD_seq: assert (seq_item.randomize() with {ctl == 3;}) else `uvm_fatal("body", "Randomization with ADD failed!");
                finish_item(seq_item);                
            end
        endtask
    endclass //DP_TL_ADD_sequence extends superClass

    class DP_TL_ADD_C_sequence extends uvm_sequence #(DP_TL_sequence_item);
        `uvm_object_utils(DP_TL_ADD_C_sequence);

        DP_TL_sequence_item seq_item;

        function new(string name = "DP_TL_ADD_C_sequence");
            super.new(name);
        endfunction //new()

        task body();
            seq_item = DP_TL_sequence_item::type_id::create("seq_item");
            repeat(10) begin
                start_item(seq_item);
                ADD_C_seq: assert (seq_item.randomize() with {ctl == 4;}) else `uvm_fatal("body", "Randomization with ADD_C failed!");
                finish_item(seq_item);                
            end
        endtask
    endclass //DP_TL_ADD_C_sequence extends superClass

    class DP_TL_SUB_sequence extends uvm_sequence #(DP_TL_sequence_item);
        `uvm_object_utils(DP_TL_SUB_sequence);

        DP_TL_sequence_item seq_item;

        function new(string name = "DP_TL_SUB_sequence");
            super.new(name);
        endfunction //new()

        task body();
            seq_item = DP_TL_sequence_item::type_id::create("seq_item");
            repeat(10) begin
                start_item(seq_item);
                SUB_seq: assert (seq_item.randomize() with {ctl == 5;}) else `uvm_fatal("body", "Randomization with SUB failed!");
                finish_item(seq_item);                
            end
        endtask
    endclass //DP_TL_SUB_sequence extends superClass

    class DP_TL_SUB_C_sequence extends uvm_sequence #(DP_TL_sequence_item);
        `uvm_object_utils(DP_TL_SUB_C_sequence);

        DP_TL_sequence_item seq_item;

        function new(string name = "DP_TL_SUB_C_sequence");
            super.new(name);
        endfunction //new()

        task body();
            seq_item = DP_TL_sequence_item::type_id::create("seq_item");
            repeat(10) begin
                start_item(seq_item);
                SUB_C_seq: assert (seq_item.randomize() with {ctl == 6;}) else `uvm_fatal("body", "Randomization with SUB_C failed!");
                finish_item(seq_item);                
            end
        endtask
    endclass //DP_TL_SUB_C_sequence extends superClass

    class DP_TL_AND_sequence extends uvm_sequence #(DP_TL_sequence_item);
        `uvm_object_utils(DP_TL_AND_sequence);

        DP_TL_sequence_item seq_item;

        function new(string name = "DP_TL_AND_sequence");
            super.new(name);
        endfunction //new()

        task body();
            seq_item = DP_TL_sequence_item::type_id::create("seq_item");
            repeat(10) begin
                start_item(seq_item);
                AND_seq: assert (seq_item.randomize() with {ctl == 7;}) else `uvm_fatal("body", "Randomization with AND failed!");
                finish_item(seq_item);                
            end
        endtask
    endclass //DP_TL_AND_sequence extends superClass

    class DP_TL_OR_sequence extends uvm_sequence #(DP_TL_sequence_item);
        `uvm_object_utils(DP_TL_OR_sequence);

        DP_TL_sequence_item seq_item;

        function new(string name = "DP_TL_OR_sequence");
            super.new(name);
        endfunction //new()

        task body();
            seq_item = DP_TL_sequence_item::type_id::create("seq_item");
            repeat(10) begin
                start_item(seq_item);
                OR_seq: assert (seq_item.randomize() with {ctl == 8;}) else `uvm_fatal("body", "Randomization with OR failed!");
                finish_item(seq_item);                
            end
        endtask
    endclass //DP_TL_OR_sequence extends superClass

    class DP_TL_XOR_sequence extends uvm_sequence #(DP_TL_sequence_item);
        `uvm_object_utils(DP_TL_XOR_sequence);

        DP_TL_sequence_item seq_item;

        function new(string name = "DP_TL_XOR_sequence");
            super.new(name);
        endfunction //new()

        task body();
            seq_item = DP_TL_sequence_item::type_id::create("seq_item");
            repeat(10) begin
                start_item(seq_item);
                XOR_seq: assert (seq_item.randomize() with {ctl == 9;}) else `uvm_fatal("body", "Randomization with XOR failed!");
                finish_item(seq_item);                
            end
        endtask
    endclass //DP_TL_XOR_sequence extends superClass

    class DP_TL_RANDOM_sequence extends uvm_sequence #(DP_TL_sequence_item);
        `uvm_object_utils(DP_TL_RANDOM_sequence);

        DP_TL_sequence_item seq_item;

        function new(string name = "DP_TL_RANDOM_sequence");
            super.new(name);
        endfunction //new()

        task body();
            seq_item = DP_TL_sequence_item::type_id::create("seq_item");
            repeat(100) begin
                start_item(seq_item);
                rand_seq: assert (seq_item.randomize());
                finish_item(seq_item);                
            end
        endtask
    endclass //DP_TL_RANDOM_sequence extends superClass
endpackage