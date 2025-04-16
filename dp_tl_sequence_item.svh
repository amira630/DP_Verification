class dp_tl_sequence_item extends uvm_sequence_item;
  `uvm_object_utils(dp_tl_sequence_item);

  dp_tl_spm_sequence_item spm;
  dp_tl_lpm_sequence_item lpm;
  rand bit is_spm;

  function new(string name = "dp_tl_sequence_item");
    super.new(name);
    `uvm_info(get_type_name(), "dp_tl_sequence_item constructor called", UVM_LOW)
    spm = dp_tl_spm_sequence_item::type_id::create("spm");
    lpm = dp_tl_lpm_sequence_item::type_id::create("lpm");
  endfunction

        // Copy the values from the virtual interface to the sequence item
        // This function is used to initialize the sequence item with values from the DUT
        // It is called by the driver to get the current state of the DUT
        // and store it in the sequence item for later use
    function void copy_from_vif(virtual dp_tl_if vif);

        // Signals from DUT to LPM
            this.lpm.LPM_Reply_Data = vif.LPM_Reply_Data;
            this.lpm.LPM_Reply_ACK = vif.LPM_Reply_ACK;
            this.lpm.LPM_NATIVE_I2C = vif.LPM_NATIVE_I2C;
            this.lpm.LPM_Reply_Data_VLD = vif.LPM_Reply_Data_VLD;
            this.lpm.LPM_Reply_ACK_VLD = vif.LPM_Reply_ACK_VLD;
            this.lpm.CTRL_Native_Failed = vif.CTRL_Native_Failed;
            this.lpm.HPD_Detect = vif.HPD_Detect;
            this.lpm.HPD_IRQ = vif.HPD_IRQ;
            this.lpm.Timer_Timeout = vif.Timer_Timeout;
                // Link Training Signals
            this.lpm.EQ_Final_ADJ_BW = vif.EQ_Final_ADJ_BW;
            this.lpm.EQ_Final_ADJ_LC = vif.EQ_Final_ADJ_LC;
            this.lpm.FSM_CR_Failed = vif.FSM_CR_Failed;
            this.lpm.EQ_Failed = vif.EQ_Failed;
            this.lpm.EQ_LT_Pass = vif.EQ_LT_Pass;
            this.lpm.CR_Completed = vif.CR_Completed;
            this.lpm.EQ_FSM_CR_Failed = vif.EQ_FSM_CR_Failed;
        
        // Signals from DUT to SPM
            this.spm.SPM_Reply_Data = vif.SPM_Reply_Data;
            this.spm.SPM_Reply_ACK = vif.SPM_Reply_ACK;
            this.spm.SPM_NATIVE_I2C = vif.SPM_NATIVE_I2C;
            this.spm.SPM_Reply_Data_VLD = vif.SPM_Reply_Data_VLD;
            this.spm.SPM_Reply_ACK_VLD = vif.SPM_Reply_ACK_VLD;
            this.spm.CTRL_I2C_Failed = vif.CTRL_I2C_Failed;
            this.spm.HPD_Detect = vif.HPD_Detect;
        
    endfunction


  function string convert2string();
    // Convert the sequence item to a string representation
    // This is useful for debugging and logging purposes
    // The string representation includes the values of the SPM and LPM fields
    if (spm.SPM_Transaction_VLD == 1 && lpm.LPM_Transaction_VLD == 0) begin
      // If the sequence item is SPM, return its string representation
      return $sformatf("SPM:\n%s", spm.convert2string());
    end else if (spm.SPM_Transaction_VLD == 0 && lpm.LPM_Transaction_VLD == 1) begin
      // If the sequence item is LPM, return its string representation
      return $sformatf("LPM:\n%s", lpm.convert2string());
    end else if (spm.SPM_Transaction_VLD == 1 && lpm.LPM_Transaction_VLD == 1) begin
      // If the sequence item is LPM, return its string representation
      `uvm_error("DP_TL_sequence_item", "LPM and SPM are both present in the sequence item")
    end else begin
        // If neither SPM nor LPM is present, return a default string
        // This case should not happen, but it's good to handle it gracefully
        // and avoid any potential errors or confusion
        `uvm_error("DP_TL_sequence_item", "Neither SPM nor LPM is present in the sequence item")
        return "Neither SPM nor LPM is present in the sequence item";
    end
  endfunction

endclass