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

     rsp_seq_item.ctl = DP_SINK_vif.ctl;

     //rsp_seq_item.ctl = opcode_e'(DP_TL_vif.ctl);

     mon_ap.write(rsp_seq_item);
        `uvm_info("run_phase", rsp_seq_item.convert2string(), UVM_LOW) 
   end
  endtask
 
endclass

endpackage