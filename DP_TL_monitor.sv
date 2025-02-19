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
     
     rsp_seq_item.reset = DP_TL_vif.reset;
     rsp_seq_item.a = DP_TL_vif.a;
     rsp_seq_item.b = DP_TL_vif.b;
     rsp_seq_item.cin = DP_TL_vif.cin; 
     rsp_seq_item.ctl = DP_TL_vif.ctl;
     rsp_seq_item.valid_in = DP_TL_vif.valid_in;
  
     rsp_seq_item.valid_out = DP_TL_vif.valid_out;
     rsp_seq_item.alu = DP_TL_vif.alu;
     rsp_seq_item.carry = DP_TL_vif.carry;
     rsp_seq_item.zero = DP_TL_vif.zero;

     mon_ap.write(rsp_seq_item);
        `uvm_info("run_phase", rsp_seq_item.convert2string(), UVM_LOW) 
   end
  endtask
 
endclass

endpackage

// assign clk = intf.clk;
// assign reset = intf.reset; 
// assign a = intf.a;
// assign b = intf.b;
// assign cin = intf.cin;
// assign ctl = intf.ctl;
// assign valid_in = intf.valid_in;


// assign intf.valid_out = valid_out; 
// assign intf.alu = alu; 
// assign intf.carry = carry; 
// assign intf.zero = zero; 