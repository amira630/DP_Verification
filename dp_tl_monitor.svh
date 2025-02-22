// package dp_tl_monitor;
// import uvm_pkg::*;
// import dp_tl_seq_item::*;
// //import shared_pkg::*;
// `include "uvm_macros.svh"

class dp_tl_monitor extends uvm_monitor;
  `uvm_component_utils(dp_tl_monitor)

  virtual dp_tl_if dp_tl_vif;
  dp_tl_seq_item rsp_seq_item;
  uvm_analysis_port #(dp_tl_seq_item) mon_ap;

  function new(string name = "dp_tl_monitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mon_ap = new("mon_ap", this);
  endfunction

  task run_phase(uvm_phase phase);
   super.run_phase(phase);
   forever begin
     rsp_seq_item = dp_tl_seq_item::type_id::create("rsp_seq_item");
     @(negedge dp_tl_vif.clk);
     
    //  rsp_seq_item.reset = dp_tl_vif.reset;
    //  rsp_seq_item.a = dp_tl_vif.a;
    //  rsp_seq_item.b = dp_tl_vif.b;
    //  rsp_seq_item.cin = dp_tl_vif.cin; 
    //  rsp_seq_item.ctl = dp_tl_vif.ctl;
    //  rsp_seq_item.valid_in = dp_tl_vif.valid_in;
  
    //  rsp_seq_item.valid_out = dp_tl_vif.valid_out;
    //  rsp_seq_item.alu = dp_tl_vif.alu;
    //  rsp_seq_item.carry = dp_tl_vif.carry;
    //  rsp_seq_item.zero = dp_tl_vif.zero;

     mon_ap.write(rsp_seq_item);
        `uvm_info("run_phase", rsp_seq_item.convert2string(), UVM_LOW) 
   end
  endtask
 
endclass

endpackage

