class dp_sink_monitor extends uvm_monitor;
  `uvm_component_utils(dp_sink_monitor)

  virtual dp_sink_if dp_sink_vif;
  dp_sink_sequence_item rsp_sink_seq_item;
  uvm_analysis_port #(dp_sink_sequence_item) mon_ap;

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
     rsp_sink_seq_item = dp_sink_sequence_item::type_id::create("rsp_sink_seq_item");
     @(negedge dp_sink_vif.clk);

      // Read the signals from the DUT and assign them to the sequence item
      // Input Data to DUT
      rsp_sink_seq_item.rst_n = dp_sink_vif.rst_n;
      rsp_sink_seq_item.HPD_Signal = dp_sink_vif.HPD_Signal;
      rsp_sink_seq_item.AUX_START_STOP = dp_sink_vif.AUX_START_STOP;
      rsp_sink_seq_item.PHY_START_STOP = dp_sink_vif.PHY_START_STOP;
      rsp_sink_seq_item.AUX_IN_OUT = dp_sink_vif.AUX_IN_OUT;
      rsp_sink_seq_item.PHY_ADJ_LC = dp_sink_vif.PHY_ADJ_LC;
      rsp_sink_seq_item.PHY_ADJ_BW = dp_sink_vif.PHY_ADJ_BW;
      rsp_sink_seq_item.PHY_Instruct = dp_sink_vif.PHY_Instruct;
      rsp_sink_seq_item.PHY_Instruct_VLD = dp_sink_vif.PHY_Instruct_VLD;

     mon_ap.write(rsp_sink_seq_item);
        // `uvm_info("run_phase", rsp_sink_seq_item.convert2string_stimulus(), UVM_LOW) 
   end
  endtask
 
endclass
