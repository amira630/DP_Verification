package DP_scoreboard;
import uvm_pkg::*;
import DP_TL_sequence::*;
import DP_SOURCE_config_pkg::*;
import shared_pkg::*;
`include "uvm_macros.svh"

class DP_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(DP_scoreboard)
    uvm_analysis_export #(DP_TL_sequence) sb_export;
    uvm_tlm_analysis_fifo #(DP_TL_sequence) sb_fifo;
    DP_TL_sequence seq_item_sb;
    DP_SOURCE_config_pkg DP_SOURCE_config_pkg_scoreboard;
    virtual DP_TL_if DP_scoreboard_vif;

    // bit signed [5:0] out_exp;
    // bit [15:0] leds_exp;

    // // Internals to register the stimulus for golden model
    // bit red_op_A_reg, red_op_B_reg, bypass_A_reg, bypass_B_reg, direction_reg, serial_in_reg;
    // bit cin_reg;
    // bit [2:0] opcode_reg;
    // bit signed [2:0] A_reg, B_reg;

    int error_count = 0;
    int correct_count = 0;

    function new(string name = "DP_scoreboard", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        sb_export = new("sb_export", this);
        sb_fifo = new("sb_fifo", this);
    super.build_phase(phase);
    if (!uvm_config_db #(DP_SOURCE_config_pkg)::get(this, "", "CFG", DP_SOURCE_config_pkg_scoreboard)) begin
      `uvm_fatal("build_phase", "Driver - Unable to get configuration object")
    end
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        sb_export.connect(sb_fifo.analysis_export);
        DP_scoreboard_vif = DP_SOURCE_config_pkg_scoreboard.DP_TL_vif;
    endfunction

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        forever begin
            sb_fifo.get(seq_item_sb);
            ref_model(seq_item_sb);
        end
    endtask

// task check_rst();
// @(negedge DP_scoreboard_vif.clk);

//     if (seq_item_sb.out != 0 || seq_item_sb.leds != 0) begin
//         $display("Error in reset");
//         error_count++;
//     end else begin
//         correct_count++;
//     end

//     reset_internals();
// endtask

// task reset_internals();
//     {red_op_A_reg, red_op_B_reg, bypass_A_reg, bypass_B_reg, direction_reg, serial_in_reg} = 6'b000000;
//     cin_reg = 2'b00;
//     opcode_reg = 3'b000;
//     {A_reg, B_reg} = 2'b00;
// endtask

// // check results task
// task check_results();
// @(negedge DP_scoreboard_vif.clk);

//             if ((seq_item_sb.out == out_exp) && (seq_item_sb.leds == leds_exp)) begin
//                 `uvm_info("run_phase", $sformatf("Correct ALSU out: %s", seq_item_sb.convert2string()), UVM_HIGH);
//                 correct_count++;
//             end else begin
//                 `uvm_error("run_phase", $sformatf("Comparison failed, Transaction received by the DUT:%s  While the reference out:0b%0b", seq_item_sb.convert2string(), out_exp));
//                 error_count++;
//             end
// endtask

// function bit is_invalid();
//     //invalid case 1
//     if (opcode_reg == INVALID_6 || opcode_reg == INVALID_7) begin
//         return 1;
//     end
//     //invalid case 2
//     else if ((opcode_reg > 3'b001) && (red_op_A_reg || red_op_B_reg)) begin
//         return 1;
//     end else begin
//         return 0;
//     end
// endfunction

//     task ref_model(DP_TL_sequence seq_item_chk);
//             if (seq_item_chk.rst) begin
//             check_rst();
//             reset_internals();
//         end else begin
//             golden_model();
//             check_results();
//             end
//     endtask

//     task golden_model();
    

//     // Handle leds_exp
//     if (is_invalid()) begin
//         leds_exp = ~leds_exp;
//     end else begin
//         leds_exp = 0;
//     end
   
//         // Handle bypass, invalid and valid opcodes for out_exp
//         // Check Bypass
//         if (bypass_A_reg && bypass_B_reg) begin
//             out_exp = A_reg;
//         end else if (bypass_A_reg) begin
//             out_exp = A_reg;
//         end else if (bypass_B_reg) begin
//             out_exp = B_reg;
//         end 
//             // Check invalid
//            else if (is_invalid()) begin
//                 out_exp = 0;
//             end else begin
//                 // Valid opcodes
//                 if (opcode_reg == OR) begin
//                     if (red_op_A_reg) begin
//                         out_exp = |A_reg;
//                     end else if (red_op_B_reg) begin
//                         out_exp = |B_reg;
//                     end else begin
//                         out_exp = A_reg | B_reg;
//                     end
//                 end else if (opcode_reg == XOR) begin
//                     if (red_op_A_reg) begin
//                         out_exp = ^A_reg;
//                     end else if (red_op_B_reg) begin
//                         out_exp = ^B_reg;
//                     end else begin
//                         out_exp = A_reg ^ B_reg;
//                     end
//                 end else if (opcode_reg == ADD) begin
//                     out_exp = A_reg + B_reg + cin_reg;
//                 end else if (opcode_reg == MULT) begin
//                     out_exp = A_reg * B_reg;
//                 end else if (opcode_reg == SHIFT) begin
//                     if (direction_reg) begin
//                         out_exp = {out_exp[4:0], serial_in_reg};
//                     end else begin
//                         out_exp = {serial_in_reg, out_exp[5:1]};
//                     end
//                 end else if (opcode_reg == ROTATE) begin
//                     if (direction_reg) begin
//                         out_exp = {out_exp[4:0], out_exp[5]};
//                     end else begin
//                         out_exp = {out_exp[0], out_exp[5:1]};
//                     end
//                 end
//             end

//     update_internals();
// endtask

// task update_internals();
//     cin_reg = seq_item_sb.cin;
//     red_op_B_reg = seq_item_sb.red_op_B;
//     red_op_A_reg = seq_item_sb.red_op_A;
//     bypass_B_reg = seq_item_sb.bypass_B;
//     bypass_A_reg = seq_item_sb.bypass_A;
//     direction_reg = seq_item_sb.direction;
//     serial_in_reg = seq_item_sb.serial_in;
//     opcode_reg = seq_item_sb.opcode;
//     A_reg = seq_item_sb.A;
//     B_reg = seq_item_sb.B;
// endtask


function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    `uvm_info("report_phase", $sformatf("Total successful transactions: %d", correct_count), UVM_MEDIUM);
    `uvm_info("report_phase", $sformatf("Total failed transactions: %d", error_count), UVM_MEDIUM);
endfunction

endclass

endpackage
