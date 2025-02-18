package DP_SINK_monitor;
import uvm_pkg::*;
import DP_SINK_sequence::*;
//import shared_pkg::*;
`include "uvm_macros.svh"

class DP_SINK_monitor extends uvm_monitor;
  `uvm_component_utils(DP_SINK_monitor)

  virtual DP_SINK_if DP_SINK_vif;
  DP_SINK_sequence rsp_seq_item;
  uvm_analysis_port #(DP_SINK_sequence) mon_ap;

  function new(string name = "DP_SINK_monitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mon_ap = new("mon_ap", this);
  endfunction

  task run_phase(uvm_phase phase);
   super.run_phase(phase);
   forever begin
     rsp_seq_item = DP_SINK_sequence::type_id::create("rsp_seq_item");
     @(negedge DP_SINK_vif.clk);
     rsp_seq_item.cin = DP_SINK_vif.cin;
     rsp_seq_item.red_op_A = DP_SINK_vif.red_op_A;
     rsp_seq_item.red_op_B = DP_SINK_vif.red_op_B;
     rsp_seq_item.bypass_A = DP_SINK_vif.bypass_A; 
     rsp_seq_item.bypass_B = DP_SINK_vif.bypass_B;
     rsp_seq_item.direction = DP_SINK_vif.direction;
     rsp_seq_item.serial_in = DP_SINK_vif.serial_in;
     rsp_seq_item.opcode = opcode_e'(DP_SINK_vif.opcode);
     rsp_seq_item.A = DP_SINK_vif.A;
     rsp_seq_item.B = DP_SINK_vif.B;
     rsp_seq_item.rst = DP_SINK_vif.rst;
     rsp_seq_item.out = DP_SINK_vif.out;
     rsp_seq_item.leds = DP_SINK_vif.leds;
     mon_ap.write(rsp_seq_item);
        `uvm_info("run_phase", rsp_seq_item.convert2string(), UVM_LOW) 
   end
  endtask
 
endclass

endpackage