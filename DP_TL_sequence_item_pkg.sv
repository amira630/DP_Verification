package DP_TL_sequence_item_pkg;
    import uvm_pkg::*;
    import macro_pkg::*;
    `include "uvm_macros.svh"

    class DP_TL_sequence_item extends uvm_sequence_item;
        `uvm_object_utils(DP_TL_sequence_item);

        rand bit reset, cin,  valid_in;
        rand bit [3:0] a,b;
        randc opcode_e ctl;
        bit carry, zero, valid_out;
        bit [3:0] alu;

        // constraint 1: Reset
        constraint rst_c {
            reset dist {0:/1, 1:/99};  //ALU_1
        }
        
        // constraint 2: cin
        constraint cin_c {
            cin dist {0:/70, 1:/30};
        }
        
        // Constraint 3: Control signal distribution
        constraint opcode_c {
            ctl inside {[SEL:XOR], [invalid_1:invalid_2]};
        }

        // Constraint 4: Valid_in
        constraint valid_in_c {
            valid_in dist {0:/10, 1:/90};
        }
        
        // constraint 5
        constraint a_b_c {
            a dist {0:/10, [4'b0001:4'b1110]:/50, 4'b1111:/40};  // Allow 0 in 10% of cases   //ALU_2
            b dist {0:/10, [4'b0001:4'b1110]:/50, 4'b1111:/40};  // Allow 0 in 10% of cases   //ALU_2 ALU_3
        }

        // constraint 6
        constraint a_b_overflow {
            if(ctl == SUB_b && cin)
                a >= b + 1;
            else if (ctl == SUB || ctl == SUB_b)  
                a >= b;  
            else if(ctl == INC)
                b < 4'hF;
            else if(ctl == DEC)
                b > 4'b0;    
        }

        function new(string name = "DP_TL_sequence_item");
            super.new(name);
        endfunction //new()
    endclass //DP_TL_sequence_item extends superClass

    function string convert2string();
        return $sformatf("%s reset = 0b%0b, valid_in = 0b%0b, opcode = 0s%0s, a = 0b%0b, b = 0b%0b, cin = 0b%0b, alu = 0b%0b, carry = 0b%0b, zero = 0b%0b, valid_out = 0b%0b",
        super.convert2string(), reset, valid_in, ctl, a, b, cin, alu, carry, zero, valid_out);
    endfunction

    function string convert2string_stimulus();
        return $sformatf("reset = 0b%0b, valid_in = 0b%0b, opcode = 0s%0s, a = 0b%0b, b = 0b%0b, , cin = 0b%0b", reset, valid_in, ctl, a, b, cin);
    endfunction

endpackage