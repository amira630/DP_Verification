package DP_SINK_sequence_item_pkg;
    import uvm_pkg::*;
    import macro_pkg::*;
    `include "uvm_macros.svh"

    class DP_SINK_sequence_item extends uvm_sequence_item;
        `uvm_object_utils(DP_SINK_sequence_item);

        randc opcode_e ctl;

        // Constraint: Control signal distribution
        constraint opcode_c {
            ctl inside {[SEL:XOR], [invalid_1:invalid_2]};
        }

        function new(string name = "DP_SINK_sequence_item");
            super.new(name);
        endfunction //new()
    endclass //DP_SINK_sequence_item extends superClass

    function string convert2string_stimulus();
        return $sformatf("%s opcode = 0s%0s", super.convert2string(), ctl);
    endfunction

/* 
    function string convert2string_stimulus();
        return $sformatf("reset = 0b%0b, valid_in = 0b%0b, opcode = 0s%0s, a = 0b%0b, b = 0b%0b, , cin = 0b%0b", reset, valid_in, ctl, a, b, cin);
    endfunction
*/
endpackage