class dp_sink_monitor extends uvm_monitor;
  `uvm_component_utils(dp_sink_monitor)

  virtual dp_sink_if dp_sink_vif;
  dp_sink_seq_item rsp_seq_item;
  uvm_analysis_port #(dp_sink_seq_item) mon_ap;

  function new(string name = "dp_sink_monitor", uvm_component parent = null);
    super.new(name, parent);
  endfunction

  function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    mon_ap = new("mon_ap", this);
  endfunction

  task run_phase(uvm_phase phase);
   super.run_phase(phase);
   forever begin
     rsp_seq_item = dp_sink_seq_item::type_id::create("rsp_seq_item");
     @(negedge dp_sink_vif.clk);

     rsp_seq_item.name_1 = dp_sink_vif.name_1;
     rsp_seq_item.name_2 = dp_sink_vif.name_2;
     rsp_seq_item.name_3 = dp_sink_vif.name_3;
     
     mon_ap.write(rsp_seq_item);
        `uvm_info("run_phase", rsp_seq_item.convert2string_stimulus(), UVM_LOW) 
   end
  endtask
 
endclass
