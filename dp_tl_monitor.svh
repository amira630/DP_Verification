class dp_tl_monitor extends uvm_monitor;
  `uvm_component_utils(dp_tl_monitor)

  virtual dp_tl_if dp_tl_vif;
  dp_tl_sequence_item rsp_seq_item;
  uvm_analysis_port #(dp_tl_sequence_item) mon_ap;

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
    rsp_seq_item = dp_tl_sequence_item::type_id::create("rsp_seq_item");
    @(negedge dp_tl_vif.clk);
     
    // Read the signals from the DUT and assign them to the sequence item
    
    // LPM signals
      
      // Input Data to DUT
    rsp_seq_item.lpm.rst_n = dp_tl_vif.rst_n;
    rsp_seq_item.lpm.LPM_Address = dp_tl_vif.LPM_Address;
    rsp_seq_item.lpm.LPM_LEN = dp_tl_vif.LPM_LEN;
    rsp_seq_item.lpm.LPM_Data = dp_tl_vif.LPM_Data;
    rsp_seq_item.lpm.LPM_CMD = dp_tl_vif.LPM_CMD;
    rsp_seq_item.lpm.LPM_Transaction_VLD = dp_tl_vif.LPM_Transaction_VLD;

    rsp_seq_item.lpm.Lane_Align = dp_tl_vif.Lane_Align;
    rsp_seq_item.lpm.MAX_VTG = dp_tl_vif.MAX_VTG;
    rsp_seq_item.lpm.MAX_PRE = dp_tl_vif.MAX_PRE;
    rsp_seq_item.lpm.EQ_RD_Value = dp_tl_vif.EQ_RD_Value;
    rsp_seq_item.lpm.PRE = dp_tl_vif.PRE;
    rsp_seq_item.lpm.VTG = dp_tl_vif.VTG;
    rsp_seq_item.lpm.Link_BW_CR = dp_tl_vif.Link_BW_CR;
    rsp_seq_item.lpm.CR_DONE = dp_tl_vif.CR_DONE;
    rsp_seq_item.lpm.CR_DONE_VLD = dp_tl_vif.CR_DONE_VLD;
    rsp_seq_item.lpm.EQ_CR_DN = dp_tl_vif.EQ_CR_DN;
    rsp_seq_item.lpm.Channel_EQ = dp_tl_vif.Channel_EQ;
    rsp_seq_item.lpm.Symbol_Lock = dp_tl_vif.Symbol_Lock;
    rsp_seq_item.lpm.MAX_TPS_SUPPORTED = dp_tl_vif.MAX_TPS_SUPPORTED;
    rsp_seq_item.lpm.Link_LC_CR = dp_tl_vif.Link_LC_CR;
    rsp_seq_item.lpm.EQ_Data_VLD = dp_tl_vif.EQ_Data_VLD;
    rsp_seq_item.lpm.Driving_Param_VLD = dp_tl_vif.Driving_Param_VLD;
    rsp_seq_item.lpm.Config_Param_VLD = dp_tl_vif.Config_Param_VLD;
    rsp_seq_item.lpm.LPM_Start_CR = dp_tl_vif.LPM_Start_CR;
    rsp_seq_item.lpm.MAX_TPS_SUPPORTED_VLD = dp_tl_vif.MAX_TPS_SUPPORTED_VLD;

      // Output Data from DUT
    rsp_seq_item.lpm.LPM_Reply_ACK = dp_tl_vif.LPM_Reply_ACK;
    rsp_seq_item.lpm.LPM_Reply_ACK_VLD = dp_tl_vif.LPM_Reply_ACK_VLD;
    rsp_seq_item.lpm.LPM_Reply_Data = dp_tl_vif.LPM_Reply_Data;
    rsp_seq_item.lpm.LPM_Reply_Data_VLD = dp_tl_vif.LPM_Reply_Data_VLD;
    rsp_seq_item.lpm.LPM_NATIVE_I2C = dp_tl_vif.LPM_NATIVE_I2C;
    rsp_seq_item.lpm.HPD_Detect = dp_tl_vif.HPD_Detect;
    rsp_seq_item.lpm.HPD_IRQ = dp_tl_vif.HPD_IRQ;
    rsp_seq_item.lpm.CTRL_Native_Failed = dp_tl_vif.CTRL_Native_Failed;
    rsp_seq_item.lpm.Timer_Timeout = dp_tl_vif.Timer_Timeout;

    rsp_seq_item.lpm.EQ_Final_ADJ_BW = dp_tl_vif.EQ_Final_ADJ_BW;
    rsp_seq_item.lpm.EQ_Final_ADJ_LC = dp_tl_vif.EQ_Final_ADJ_LC;
    rsp_seq_item.lpm.FSM_CR_Failed = dp_tl_vif.FSM_CR_Failed;
    rsp_seq_item.lpm.EQ_Failed = dp_tl_vif.EQ_Failed;
    rsp_seq_item.lpm.EQ_LT_Pass = dp_tl_vif.EQ_LT_Pass;
    rsp_seq_item.lpm.CR_Completed = dp_tl_vif.CR_Completed;
    rsp_seq_item.lpm.EQ_FSM_CR_Failed = dp_tl_vif.EQ_FSM_CR_Failed;


    // SPM signals
      
      // Input Data to DUT
    rsp_spm_seq_item.spm.rst_n = dp_tl_vif.rst_n;
    rsp_spm_seq_item.spm.SPM_Address = dp_tl_vif.SPM_Address;
    rsp_spm_seq_item.spm.SPM_LEN = dp_tl_vif.SPM_LEN;
    rsp_spm_seq_item.spm.SPM_Data = dp_tl_vif.SPM_Data;
    rsp_spm_seq_item.spm.SPM_CMD = dp_tl_vif.SPM_CMD;
    rsp_spm_seq_item.spm.SPM_Transaction_VLD = dp_tl_vif.SPM_Transaction_VLD;

      // Output Data from DUT
    rsp_spm_seq_item.spm.SPM_Reply_ACK = dp_tl_vif.SPM_Reply_ACK;
    rsp_spm_seq_item.spm.SPM_Reply_ACK_VLD = dp_tl_vif.SPM_Reply_ACK_VLD;
    rsp_spm_seq_item.spm.SPM_Reply_Data = dp_tl_vif.SPM_Reply_Data;
    rsp_spm_seq_item.spm.SPM_Reply_Data_VLD = dp_tl_vif.SPM_Reply_Data_VLD;
    rsp_spm_seq_item.spm.SPM_NATIVE_I2C = dp_tl_vif.SPM_NATIVE_I2C;
    rsp_spm_seq_item.spm.CTRL_I2C_Failed = dp_tl_vif.CTRL_I2C_Failed;
    rsp_spm_seq_item.spm.HPD_Detect = dp_tl_vif.HPD_Detect;

    mon_ap.write(rsp_seq_item);
    `uvm_info("run_phase", rsp_seq_item.convert2string(), UVM_LOW) 
   end
  endtask
 
endclass


