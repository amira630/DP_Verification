class dp_sink_monitor extends uvm_monitor;
  `uvm_component_utils(dp_sink_monitor)

  virtual dp_sink_if dp_sink_vif;
  dp_sink_sequence_item rsp_sink_seq_item;
  dp_sink_sequence_item iso_sink_seq_item;
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
    fork
      begin
        forever begin
          rsp_sink_seq_item = dp_sink_sequence_item::type_id::create("rsp_sink_seq_item");
          @(negedge dp_sink_vif.clk_AUX);
          `uvm_info(get_type_name(), $sformatf("INSIDE AUX THREAD %s", rsp_sink_seq_item.convert2string()), UVM_MEDIUM)
          rsp_sink_seq_item.HPD_Signal = dp_sink_vif.HPD_Signal;
          rsp_sink_seq_item.AUX_START_STOP = dp_sink_vif.AUX_START_STOP;
          rsp_sink_seq_item.PHY_START_STOP = dp_sink_vif.PHY_START_STOP;
          rsp_sink_seq_item.AUX_IN_OUT = dp_sink_vif.AUX_IN_OUT;
          rsp_sink_seq_item.PHY_ADJ_LC = dp_sink_vif.PHY_ADJ_LC;
          rsp_sink_seq_item.PHY_ADJ_BW = dp_sink_vif.PHY_ADJ_BW;
          rsp_sink_seq_item.PHY_Instruct = dp_sink_vif.PHY_Instruct;
          rsp_sink_seq_item.PHY_Instruct_VLD = dp_sink_vif.PHY_Instruct_VLD;
          mon_ap.write(rsp_sink_seq_item);
        end
      end
      begin
        forever begin
          iso_sink_seq_item = dp_sink_sequence_item::type_id::create("iso_sink_seq_item");
          case (dp_sink_vif.Final_BW)
              BW_RBR:  @(negedge dp_sink_vif.clk_RBR);
              BW_HBR:  @(negedge dp_sink_vif.clk_HBR);
              BW_HBR2: @(negedge dp_sink_vif.clk_HBR2);
              BW_HBR3: @(negedge dp_sink_vif.clk_HBR3);
              default: @(negedge dp_sink_vif.clk_RBR);
          endcase

          // `uvm_info(get_type_name(), $sformatf("INSIDE ISO THREAD w/ LS_CLK ISO_symbols_lane0: %h, ISO_symbols_lane1: %h, ISO_symbols_lane2: %h, ISO_symbols_lane3: %h", dp_sink_vif.ISO_symbols_lane0, dp_sink_vif.ISO_symbols_lane1, dp_sink_vif.ISO_symbols_lane2, dp_sink_vif.ISO_symbols_lane3), UVM_MEDIUM)
          // ISO signals
          iso_sink_seq_item.ISO_symbols_lane0 = dp_sink_vif.ISO_symbols_lane0;
          iso_sink_seq_item.Control_sym_flag_lane0 = dp_sink_vif.Control_sym_flag_lane0;
          iso_sink_seq_item.ISO_symbols_lane1 = dp_sink_vif.ISO_symbols_lane1;
          iso_sink_seq_item.Control_sym_flag_lane1 = dp_sink_vif.Control_sym_flag_lane1;
          iso_sink_seq_item.ISO_symbols_lane2 = dp_sink_vif.ISO_symbols_lane2;
          iso_sink_seq_item.Control_sym_flag_lane2 = dp_sink_vif.Control_sym_flag_lane2;
          iso_sink_seq_item.ISO_symbols_lane3 = dp_sink_vif.ISO_symbols_lane3;
          iso_sink_seq_item.Control_sym_flag_lane3 = dp_sink_vif.Control_sym_flag_lane3;
          mon_ap.write(iso_sink_seq_item);
        end
      end
    join
  endtask
endclass