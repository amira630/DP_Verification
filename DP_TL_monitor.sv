package DP_TL_monitor;
import uvm_pkg::*;
import DP_TL_sequence::*;
//import shared_pkg::*;
`include "uvm_macros.svh"

class DP_TL_monitor extends uvm_monitor;
  `uvm_component_utils(DP_TL_monitor)

  virtual DP_TL_if DP_TL_vif;
  DP_TL_sequence rsp_seq_item;
  uvm_analysis_port #(DP_TL_sequence) mon_ap;

  function new(string name = "DP_TL_monitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mon_ap = new("mon_ap", this);
  endfunction

  task run_phase(uvm_phase phase);
   super.run_phase(phase);
   forever begin
     rsp_seq_item = DP_TL_sequence::type_id::create("rsp_seq_item");
     @(negedge DP_TL_vif.clk);
     rsp_seq_item.cin = DP_TL_vif.cin;
     rsp_seq_item.red_op_A = DP_TL_vif.red_op_A;
     rsp_seq_item.red_op_B = DP_TL_vif.red_op_B;
     rsp_seq_item.bypass_A = DP_TL_vif.bypass_A; 
     rsp_seq_item.bypass_B = DP_TL_vif.bypass_B;
     rsp_seq_item.direction = DP_TL_vif.direction;
     rsp_seq_item.serial_in = DP_TL_vif.serial_in;
     rsp_seq_item.opcode = opcode_e'(DP_TL_vif.opcode);
     rsp_seq_item.A = DP_TL_vif.A;
     rsp_seq_item.B = DP_TL_vif.B;
     rsp_seq_item.rst = DP_TL_vif.rst;
     rsp_seq_item.out = DP_TL_vif.out;
     rsp_seq_item.leds = DP_TL_vif.leds;
     mon_ap.write(rsp_seq_item);
        `uvm_info("run_phase", rsp_seq_item.convert2string(), UVM_LOW) 
   end
  endtask
 
endclass

endpackage