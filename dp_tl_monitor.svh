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
     
     rsp_seq_item.name_1 = dp_tl_vif.name_1;
     rsp_seq_item.name_2 = dp_tl_vif.name_2;
     rsp_seq_item.name_3 = dp_tl_vif.name_3;

     mon_ap.write(rsp_seq_item);
        `uvm_info("run_phase", rsp_seq_item.convert2string(), UVM_LOW) 
   end
  endtask
 
endclass


