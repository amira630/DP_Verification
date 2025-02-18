package DP_SINK_coverage;
import uvm_pkg::*;
import DP_SINK_sequence::*;
// import shared_pkg::*;
`include "uvm_macros.svh"

class ALSU_coverage extends uvm_component;
    `uvm_component_utils(ALSU_coverage)
    uvm_analysis_export #(DP_SINK_sequence) cov_export;
    uvm_tlm_analysis_fifo #(DP_SINK_sequence) cov_fifo;
    DP_SINK_sequence seq_item_cov;

    covergroup cvr_grp;
//   // Coverpoint for A
//   a: coverpoint seq_item_cov.A {
//     bins A_data_0 = {3'b000};
//     bins A_data_max = {MAXPOS};
//     bins A_data_min = {MAXNEG};
//     bins A_data_default = default;
//     bins A_data_walkingones[] = {3'b001, 3'b010, 3'b100} iff (seq_item_cov.red_op_A);
//   }

//   // Coverpoint for B
//  b: coverpoint seq_item_cov.B {
//     bins B_data_0 = {3'b000};
//     bins B_data_max = {MAXPOS};
//     bins B_data_min = {MAXNEG};
//     bins B_data_default = default;
//     bins B_data_walkingones[] = {3'b001, 3'b010, 3'b100} iff (seq_item_cov.red_op_B && !seq_item_cov.red_op_A);
//   }

//   // Coverpoint for ALU operations
//   op: coverpoint seq_item_cov.opcode {
//     bins Bins_shift[] = {SHIFT, ROTATE};
//     bins Bins_arith[] = {ADD, MULT};
//     bins Bins_bitwise[] = {OR, XOR};
//     illegal_bins Bins_invalid[] = {INVALID_6, INVALID_7};
//     bins Bins_trans = (OR => XOR => ADD => MULT => SHIFT);
//   }

//      //some values of A
//   a_all: coverpoint seq_item_cov.A {
//     bins allvaluesofA[] = {ZERO, MAXPOS, MAXNEG};
//     option.weight=0;
//   }

//      //some values of B
//   b_all: coverpoint seq_item_cov.B {
//     bins allvaluesofB[] = {ZERO, MAXPOS, MAXNEG};
//     option.weight=0;
//   }

//       //all values of cin
//   CIN: coverpoint seq_item_cov.cin {
//     bins allvaluesofcin[] = {0, 1};
//     option.weight=0;
//   }

//        //some values of OPCODE
//   op_individual: coverpoint seq_item_cov.opcode {
//     bins opcodeADD[] = {ADD};
//     bins opcodeSHIFT[] = {SHIFT};
//     bins opcodeNOTORorXOR[] = {ADD, MULT, SHIFT, ROTATE, INVALID_6, INVALID_7};
//     option.weight=0;
//   }
 
//        //all values of Serial_in
//   SERIAL_IN: coverpoint seq_item_cov.serial_in {
//     bins allvaluesofserial_in[] = {0, 1};
//     option.weight=0;
//   }

//        //all values of DIRECTION
//   DIRECTION: coverpoint seq_item_cov.direction {
//     bins allvaluesofdirection[] = {0, 1};
//     option.weight=0;
//   }

//          //all values of RED_OP_A
//   RED_OP_A: coverpoint seq_item_cov.red_op_A {
//     bins red_op_AisONE[] = {1};
//     bins red_op_AisZERO[] = {0};
//     bins red_op_AisEITHERONEORZERO[] = {0, 1};
//     option.weight=0;
//   }

//            //all values of RED_OP_B
//   RED_OP_B: coverpoint seq_item_cov.red_op_B {
//     bins red_op_BisONE[] = {1};
//     bins red_op_BisZERO[] = {0};
//     bins red_op_BisEITHERONEORZERO[] = {0, 1};
//     option.weight=0;
//   }

//   // Cross Coverage

//   // 1. All permutations of A and B when ALU is ADD or MULT
//   cross a_all, b_all, op {
//     bins add_mult_permutations = binsof(a_all.allvaluesofA) && binsof(b_all.allvaluesofB) && binsof(op.Bins_arith);
//     option.cross_auto_bin_max = 0;
//   }

//   // 2. When ALU is ADD, cross A, B, and cin (0 or 1)
//   cross CIN, op_individual {
//     bins add_cin = binsof(CIN.allvaluesofcin) && binsof(op_individual.opcodeADD);
//     option.cross_auto_bin_max = 0;
//   }

//   // 3. When ALU is SHIFT, cross A, B, and serial_in (0 or 1)
//   cross SERIAL_IN, op_individual {
//     bins shift_serial_in = binsof(SERIAL_IN.allvaluesofserial_in) && binsof(op_individual.opcodeSHIFT);
//     option.cross_auto_bin_max = 0;
//   }

//   // 4. When ALU is SHIFT or ROTATE, cross A, B, and direction (0 or 1)
//   cross DIRECTION, op {
//     bins shift_rotate_dir = binsof(DIRECTION.allvaluesofdirection) && binsof(op.Bins_shift);
//     option.cross_auto_bin_max = 0;
//   }

//   // 5. When ALU is OR/XOR with red_op_A, cross A (walking ones) and B = 0
//   cross a, b, RED_OP_A, op {
//     bins or_xor_red_op_A = binsof(a.A_data_walkingones) && binsof(b.B_data_0) && binsof(op.Bins_bitwise) && binsof(RED_OP_A.red_op_AisONE);
//     option.cross_auto_bin_max = 0;
//   }

//   // 6. When ALU is OR/XOR with red_op_B, cross B (walking ones) and A = 0
//   cross a, b, RED_OP_B, op {
//     bins or_xor_red_op_A = binsof(b.B_data_walkingones) && binsof(a.A_data_0) && binsof(op.Bins_bitwise) && binsof(RED_OP_B.red_op_BisONE);
//     option.cross_auto_bin_max = 0;
//   }

//   // 7. Invalid case: reduction operation active while opcode is not OR or XOR
//   cross RED_OP_A, RED_OP_B, op_individual {
//     bins invalid_reduction_case1 = binsof(op_individual.opcodeNOTORorXOR) && binsof(RED_OP_A.red_op_AisONE) && binsof(RED_OP_B.red_op_BisONE);
//     bins invalid_reduction_case2 = binsof(op_individual.opcodeNOTORorXOR) && binsof(RED_OP_A.red_op_AisONE) && binsof(RED_OP_B.red_op_BisZERO);
//     bins invalid_reduction_case3 = binsof(op_individual.opcodeNOTORorXOR) && binsof(RED_OP_A.red_op_AisZERO) && binsof(RED_OP_B.red_op_BisONE);
//     option.cross_auto_bin_max = 0;
//   }

  endgroup
 

    function new(string name = "DP_SINK_coverage", uvm_component parent = null);
        super.new(name, parent);
        cvr_grp = new();
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        cov_export = new("cov_export", this);
        cov_fifo = new("cov_fifo", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        cov_export.connect(cov_fifo.analysis_export);
    endfunction

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        forever begin
            cov_fifo.get(seq_item_cov);
            cvr_grp.sample();
        end
    endtask

endclass

endpackage
