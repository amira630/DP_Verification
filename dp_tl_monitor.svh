class dp_tl_monitor extends uvm_monitor;
  `uvm_component_utils(dp_tl_monitor)

  virtual dp_tl_if dp_tl_vif;
  dp_tl_sequence_item rsp_seq_item;
  dp_tl_sequence_item iso_seq_item;
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
  //  forever begin
  //   rsp_seq_item = dp_tl_sequence_item::type_id::create("rsp_seq_item");
  //   fork
  //     begin
  //       @(negedge dp_tl_vif.clk_AUX);         
  //         // Read the signals from the DUT and assign them to the sequence item
  //         rsp_seq_item.rst_n = dp_tl_vif.rst_n;
  //         rsp_seq_item.HPD_Detect = dp_tl_vif.HPD_Detect;
  //         rsp_seq_item.HPD_IRQ = dp_tl_vif.HPD_IRQ;
  //         rsp_seq_item.Timer_Timeout = dp_tl_vif.Timer_Timeout;

  //         // SPM signals
            
  //           // Input Data to DUT
  //         rsp_seq_item.SPM_Address = dp_tl_vif.SPM_Address;
  //         rsp_seq_item.SPM_LEN = dp_tl_vif.SPM_LEN;
  //         rsp_seq_item.SPM_CMD = i2c_aux_request_cmd_e'(dp_tl_vif.SPM_CMD);
  //         rsp_seq_item.SPM_Data = dp_tl_vif.SPM_Data;
  //         rsp_seq_item.SPM_Transaction_VLD = dp_tl_vif.SPM_Transaction_VLD;

  //           // Output Data from DUT
  //         rsp_seq_item.SPM_Reply_ACK = dp_tl_vif.SPM_Reply_ACK;
  //         rsp_seq_item.SPM_Reply_ACK_VLD = dp_tl_vif.SPM_Reply_ACK_VLD;
  //         rsp_seq_item.SPM_Reply_Data = dp_tl_vif.SPM_Reply_Data;
  //         rsp_seq_item.SPM_Reply_Data_VLD = dp_tl_vif.SPM_Reply_Data_VLD;
  //         rsp_seq_item.SPM_NATIVE_I2C = dp_tl_vif.SPM_NATIVE_I2C;
  //         rsp_seq_item.CTRL_I2C_Failed = dp_tl_vif.CTRL_I2C_Failed;
          
  //         // LPM signals
            
  //           // Input Data to DUT
  //         rsp_seq_item.LPM_Address = dp_tl_vif.LPM_Address;
  //         rsp_seq_item.LPM_LEN = dp_tl_vif.LPM_LEN;
  //         rsp_seq_item.LPM_CMD = native_aux_request_cmd_e'(dp_tl_vif.LPM_CMD);
  //         rsp_seq_item.LPM_Data = dp_tl_vif.LPM_Data;
  //         rsp_seq_item.LPM_Transaction_VLD = dp_tl_vif.LPM_Transaction_VLD;

  //           // Output Data from DUT
  //         rsp_seq_item.LPM_Reply_ACK = dp_tl_vif.LPM_Reply_ACK;
  //         rsp_seq_item.LPM_Reply_ACK_VLD = dp_tl_vif.LPM_Reply_ACK_VLD;
  //         rsp_seq_item.LPM_Reply_Data = dp_tl_vif.LPM_Reply_Data;
  //         rsp_seq_item.LPM_Reply_Data_VLD = dp_tl_vif.LPM_Reply_Data_VLD;
  //         rsp_seq_item.LPM_NATIVE_I2C = dp_tl_vif.LPM_NATIVE_I2C;
  //         rsp_seq_item.CTRL_Native_Failed = dp_tl_vif.CTRL_Native_Failed;
          

  //         // Link Training signals

  //           // Input Data to DUT
  //         rsp_seq_item.Lane_Align = dp_tl_vif.Lane_Align;
  //         rsp_seq_item.MAX_VTG = dp_tl_vif.MAX_VTG;
  //         rsp_seq_item.MAX_PRE = dp_tl_vif.MAX_PRE;
  //         rsp_seq_item.EQ_RD_Value = dp_tl_vif.EQ_RD_Value;
  //         rsp_seq_item.PRE = dp_tl_vif.PRE;
  //         rsp_seq_item.VTG = dp_tl_vif.VTG;
  //         rsp_seq_item.Link_BW_CR = link_bw_cr_e'(dp_tl_vif.Link_BW_CR);
  //         rsp_seq_item.CR_DONE = dp_tl_vif.CR_DONE;
  //         rsp_seq_item.CR_DONE_VLD = dp_tl_vif.CR_DONE_VLD;
  //         rsp_seq_item.EQ_CR_DN = dp_tl_vif.EQ_CR_DN;
  //         rsp_seq_item.Channel_EQ = dp_tl_vif.Channel_EQ;
  //         rsp_seq_item.Symbol_Lock = dp_tl_vif.Symbol_Lock;
  //         rsp_seq_item.Link_LC_CR = dp_tl_vif.Link_LC_CR;
  //         rsp_seq_item.EQ_Data_VLD = dp_tl_vif.EQ_Data_VLD;
  //         rsp_seq_item.Driving_Param_VLD = dp_tl_vif.Driving_Param_VLD;
  //         rsp_seq_item.Config_Param_VLD = dp_tl_vif.Config_Param_VLD;
  //         rsp_seq_item.LPM_Start_CR = dp_tl_vif.LPM_Start_CR;
  //         rsp_seq_item.MAX_TPS_SUPPORTED = training_pattern_t'(dp_tl_vif.MAX_TPS_SUPPORTED);
  //         rsp_seq_item.MAX_TPS_SUPPORTED_VLD = dp_tl_vif.MAX_TPS_SUPPORTED_VLD;


  //           // Output Data from DUT
  //         rsp_seq_item.EQ_Final_ADJ_BW = dp_tl_vif.EQ_Final_ADJ_BW;
  //         rsp_seq_item.EQ_Final_ADJ_LC = dp_tl_vif.EQ_Final_ADJ_LC;
  //         rsp_seq_item.FSM_CR_Failed = dp_tl_vif.FSM_CR_Failed;
  //         rsp_seq_item.EQ_LT_Failed = dp_tl_vif.EQ_LT_Failed;
  //         rsp_seq_item.EQ_LT_Pass = dp_tl_vif.EQ_LT_Pass;
  //         rsp_seq_item.CR_Completed = dp_tl_vif.CR_Completed;
  //         rsp_seq_item.EQ_FSM_CR_Failed = dp_tl_vif.EQ_FSM_CR_Failed;
  //         rsp_seq_item.LPM_CR_Apply_New_BW_LC = dp_tl_vif.LPM_CR_Apply_New_BW_LC;
  //         rsp_seq_item.LPM_CR_Apply_New_Driving_Param = dp_tl_vif.LPM_CR_Apply_New_Driving_Param;
  //         rsp_seq_item.EQ_FSM_Repeat = dp_tl_vif.EQ_FSM_Repeat;
  //     end
  //     begin
  //       @(negedge dp_tl_vif.MS_Stm_CLK);  
  //       // ISO signals
  //       // STREAM POLICY MAKER 
  //       rsp_seq_item.MS_rst_n = dp_tl_vif.MS_rst_n;
  //       rsp_seq_item.SPM_ISO_start = dp_tl_vif.SPM_ISO_start;
  //       rsp_seq_item.SPM_Lane_Count = dp_tl_vif.SPM_Lane_Count;
  //       rsp_seq_item.SPM_Lane_BW = dp_tl_vif.SPM_Lane_BW;
  //       rsp_seq_item.SPM_Full_MSA = dp_tl_vif.SPM_Full_MSA;
  //       rsp_seq_item.SPM_MSA_VLD = dp_tl_vif.SPM_MSA_VLD;
  //       rsp_seq_item.SPM_BW_Sel = dp_tl_vif.SPM_BW_Sel;

  //         // MAIN STREAM SOURCE
  //       rsp_seq_item.MS_Pixel_Data = dp_tl_vif.MS_Pixel_Data;
  //       rsp_seq_item.MS_DE = dp_tl_vif.MS_DE;
  //       rsp_seq_item.MS_Stm_BW = dp_tl_vif.MS_Stm_BW;
  //       rsp_seq_item.MS_Stm_BW_VLD = dp_tl_vif.MS_Stm_BW_VLD;
  //       rsp_seq_item.MS_VSYNC = dp_tl_vif.MS_VSYNC;
  //       rsp_seq_item.MS_HSYNC = dp_tl_vif.MS_HSYNC;
  //       rsp_seq_item.WFULL = dp_tl_vif.WFULL;
  //       mon_ap.write(rsp_seq_item);
  //     end
  //   join
  //   `uvm_info("run_phase", rsp_seq_item.convert2string_RQST(), UVM_LOW) 
  //  end

   fork
    begin
      forever begin
        rsp_seq_item = dp_tl_sequence_item::type_id::create("rsp_seq_item");
        @(negedge dp_tl_vif.clk_AUX);         
        // Read the signals from the DUT and assign them to the sequence item
        rsp_seq_item.rst_n = dp_tl_vif.rst_n;
        rsp_seq_item.HPD_Detect = dp_tl_vif.HPD_Detect;
        rsp_seq_item.HPD_IRQ = dp_tl_vif.HPD_IRQ;
        rsp_seq_item.Timer_Timeout = dp_tl_vif.Timer_Timeout;

        // SPM signals
          
          // Input Data to DUT
        rsp_seq_item.SPM_Address = dp_tl_vif.SPM_Address;
        rsp_seq_item.SPM_LEN = dp_tl_vif.SPM_LEN;
        rsp_seq_item.SPM_CMD = i2c_aux_request_cmd_e'(dp_tl_vif.SPM_CMD);
        rsp_seq_item.SPM_Data = dp_tl_vif.SPM_Data;
        rsp_seq_item.SPM_Transaction_VLD = dp_tl_vif.SPM_Transaction_VLD;

          // Output Data from DUT
        rsp_seq_item.SPM_Reply_ACK = dp_tl_vif.SPM_Reply_ACK;
        rsp_seq_item.SPM_Reply_ACK_VLD = dp_tl_vif.SPM_Reply_ACK_VLD;
        rsp_seq_item.SPM_Reply_Data = dp_tl_vif.SPM_Reply_Data;
        rsp_seq_item.SPM_Reply_Data_VLD = dp_tl_vif.SPM_Reply_Data_VLD;
        rsp_seq_item.SPM_NATIVE_I2C = dp_tl_vif.SPM_NATIVE_I2C;
        rsp_seq_item.CTRL_I2C_Failed = dp_tl_vif.CTRL_I2C_Failed;
        
        // LPM signals
          
          // Input Data to DUT
        rsp_seq_item.LPM_Address = dp_tl_vif.LPM_Address;
        rsp_seq_item.LPM_LEN = dp_tl_vif.LPM_LEN;
        rsp_seq_item.LPM_CMD = native_aux_request_cmd_e'(dp_tl_vif.LPM_CMD);
        rsp_seq_item.LPM_Data = dp_tl_vif.LPM_Data;
        rsp_seq_item.LPM_Transaction_VLD = dp_tl_vif.LPM_Transaction_VLD;

          // Output Data from DUT
        rsp_seq_item.LPM_Reply_ACK = dp_tl_vif.LPM_Reply_ACK;
        rsp_seq_item.LPM_Reply_ACK_VLD = dp_tl_vif.LPM_Reply_ACK_VLD;
        rsp_seq_item.LPM_Reply_Data = dp_tl_vif.LPM_Reply_Data;
        rsp_seq_item.LPM_Reply_Data_VLD = dp_tl_vif.LPM_Reply_Data_VLD;
        rsp_seq_item.LPM_NATIVE_I2C = dp_tl_vif.LPM_NATIVE_I2C;
        rsp_seq_item.CTRL_Native_Failed = dp_tl_vif.CTRL_Native_Failed;
        

        // Link Training signals

          // Input Data to DUT
        rsp_seq_item.Lane_Align = dp_tl_vif.Lane_Align;
        rsp_seq_item.MAX_VTG = dp_tl_vif.MAX_VTG;
        rsp_seq_item.MAX_PRE = dp_tl_vif.MAX_PRE;
        rsp_seq_item.EQ_RD_Value = dp_tl_vif.EQ_RD_Value;
        rsp_seq_item.PRE = dp_tl_vif.PRE;
        rsp_seq_item.VTG = dp_tl_vif.VTG;
        rsp_seq_item.Link_BW_CR = link_bw_cr_e'(dp_tl_vif.Link_BW_CR);
        rsp_seq_item.CR_DONE = dp_tl_vif.CR_DONE;
        rsp_seq_item.CR_DONE_VLD = dp_tl_vif.CR_DONE_VLD;
        rsp_seq_item.EQ_CR_DN = dp_tl_vif.EQ_CR_DN;
        rsp_seq_item.Channel_EQ = dp_tl_vif.Channel_EQ;
        rsp_seq_item.Symbol_Lock = dp_tl_vif.Symbol_Lock;
        rsp_seq_item.Link_LC_CR = dp_tl_vif.Link_LC_CR;
        rsp_seq_item.EQ_Data_VLD = dp_tl_vif.EQ_Data_VLD;
        rsp_seq_item.Driving_Param_VLD = dp_tl_vif.Driving_Param_VLD;
        rsp_seq_item.Config_Param_VLD = dp_tl_vif.Config_Param_VLD;
        rsp_seq_item.LPM_Start_CR = dp_tl_vif.LPM_Start_CR;
        rsp_seq_item.MAX_TPS_SUPPORTED = training_pattern_t'(dp_tl_vif.MAX_TPS_SUPPORTED);
        rsp_seq_item.MAX_TPS_SUPPORTED_VLD = dp_tl_vif.MAX_TPS_SUPPORTED_VLD;


          // Output Data from DUT
        rsp_seq_item.EQ_Final_ADJ_BW = dp_tl_vif.EQ_Final_ADJ_BW;
        rsp_seq_item.EQ_Final_ADJ_LC = dp_tl_vif.EQ_Final_ADJ_LC;
        rsp_seq_item.FSM_CR_Failed = dp_tl_vif.FSM_CR_Failed;
        rsp_seq_item.EQ_LT_Failed = dp_tl_vif.EQ_LT_Failed;
        rsp_seq_item.EQ_LT_Pass = dp_tl_vif.EQ_LT_Pass;
        rsp_seq_item.CR_Completed = dp_tl_vif.CR_Completed;
        rsp_seq_item.EQ_FSM_CR_Failed = dp_tl_vif.EQ_FSM_CR_Failed;
        rsp_seq_item.LPM_CR_Apply_New_BW_LC = dp_tl_vif.LPM_CR_Apply_New_BW_LC;
        rsp_seq_item.LPM_CR_Apply_New_Driving_Param = dp_tl_vif.LPM_CR_Apply_New_Driving_Param;
        rsp_seq_item.EQ_FSM_Repeat = dp_tl_vif.EQ_FSM_Repeat;
        mon_ap.write(rsp_seq_item);
      end
    end
    begin
      forever begin
        @(negedge dp_tl_vif.MS_Stm_CLK);  
        iso_seq_item = dp_tl_sequence_item::type_id::create("iso_seq_item");
        // ISO signals
        // STREAM POLICY MAKER 
        if (dp_tl_vif.MS_rst_n && dp_tl_vif.SPM_ISO_start) begin
          iso_seq_item.MS_rst_n = dp_tl_vif.MS_rst_n;
          iso_seq_item.SPM_ISO_start = dp_tl_vif.SPM_ISO_start;
          iso_seq_item.SPM_Lane_Count = dp_tl_vif.SPM_Lane_Count;
          iso_seq_item.SPM_Lane_BW = dp_tl_vif.SPM_Lane_BW;
          iso_seq_item.SPM_Full_MSA = dp_tl_vif.SPM_Full_MSA;
          iso_seq_item.SPM_MSA_VLD = dp_tl_vif.SPM_MSA_VLD;
          iso_seq_item.SPM_BW_Sel = dp_tl_vif.SPM_BW_Sel;
          iso_seq_item.MS_Pixel_Data = dp_tl_vif.MS_Pixel_Data;
          iso_seq_item.MS_DE = dp_tl_vif.MS_DE;
          iso_seq_item.MS_Stm_BW = dp_tl_vif.MS_Stm_BW;
          iso_seq_item.MS_Stm_BW_VLD = dp_tl_vif.MS_Stm_BW_VLD;
          iso_seq_item.MS_VSYNC = dp_tl_vif.MS_VSYNC;
          iso_seq_item.MS_HSYNC = dp_tl_vif.MS_HSYNC;
          iso_seq_item.WFULL = dp_tl_vif.WFULL;
        end
        else begin
          iso_seq_item.MS_rst_n = dp_tl_vif.MS_rst_n;
          iso_seq_item.SPM_ISO_start = dp_tl_vif.SPM_ISO_start;
        end
          // MAIN STREAM SOURCE

        mon_ap.write(iso_seq_item);
      end
    end  
   join

  endtask
 
endclass


