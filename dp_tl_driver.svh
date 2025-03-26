// Standard UVM import & include:
    // import uvm_pkg::*;
    // import dp_transactions_pkg::*;
    // `include "uvm_macros.svh"

class dp_tl_driver extends uvm_driver #(dp_tl_spm_sequence_item, dp_tl_lpm_sequence_item);
    `uvm_component_utils(dp_tl_driver);

    virtual dp_tl_if dp_tl_vif;
    dp_tl_spm_sequence_item seq_item_SPM;
    dp_tl_lpm_sequence_item seq_item_LPM;
    
    function new(string name = "dp_tl_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        forever begin
    // SPM
            // Get sequence item from sequencer
            seq_item_SPM = dp_tl_spm_sequence_item::type_id::create("seq_item_SPM");
            seq_item_port.get_next_item(seq_item_SPM);

            // Signals from SPM to the DUT
            dp_tl_vif.SPM_CMD = seq_item_SPM.SPM_CMD;
            dp_tl_vif.SPM_Address = seq_item_SPM.SPM_Address;
            dp_tl_vif.SPM_LEN = seq_item_SPM.SPM_LEN;
            dp_tl_vif.SPM_Transaction_VLD = seq_item_SPM.SPM_Transaction_VLD;
            dp_tl_vif.SPM_Data = seq_item_SPM.SPM_Data;

            // Signals from DUT to SPM
            seq_item_SPM.SPM_Reply_Data = dp_tl_vif.SPM_Reply_Data;
            seq_item_SPM.SPM_Reply_ACK = dp_tl_vif.SPM_Reply_ACK;
            seq_item_SPM.SPM_NATIVE_I2C = dp_tl_vif.SPM_NATIVE_I2C;
            seq_item_SPM.SPM_Reply_Data_VLD = dp_tl_vif.SPM_Reply_Data_VLD;
            seq_item_SPM.SPM_Reply_ACK_VLD = dp_tl_vif.SPM_Reply_ACK_VLD;
            seq_item_SPM.CTRL_I2C_Failed = dp_tl_vif.CTRL_I2C_Failed;
            seq_item_SPM.HPD_Detect = dp_tl_vif.HPD_Detect;

    // LPM
            // Get sequence item from sequencer
            seq_item_LPM = dp_tl_lpm_sequence_item::type_id::create("seq_item_LPM");
            seq_item_port.get_next_item(seq_item_LPM);

            // Signals from LPM to the DUT
            dp_tl_vif.LPM_CMD = seq_item_LPM.LPM_CMD;
            dp_tl_vif.LPM_Address = seq_item_LPM.LPM_Address;
            dp_tl_vif.LPM_LEN = seq_item_LPM.LPM_LEN;
            dp_tl_vif.LPM_Transaction_VLD = seq_item_LPM.LPM_Transaction_VLD;
            dp_tl_vif.LPM_Data = seq_item_LPM.LPM_Data;
                // Link Training Signals
            dp_tl_vif.Lane_Align = seq_item_LPM.Lane_Align;
            dp_tl_vif.MAX_VTG = seq_item_LPM.MAX_VTG;
            dp_tl_vif.EQ_RD_Value = seq_item_LPM.EQ_RD_Value;
            dp_tl_vif.PRE = seq_item_LPM.PRE;
            dp_tl_vif.VTG = seq_item_LPM.VTG;
            dp_tl_vif.Link_BW_CR = seq_item_LPM.Link_BW_CR;
            dp_tl_vif.CR_Done = seq_item_LPM.CR_Done;
            dp_tl_vif.EQ_CR_DN = seq_item_LPM.EQ_CR_DN;
            dp_tl_vif.Channel_EQ = seq_item_LPM.Channel_EQ;
            dp_tl_vif.Symbol_Lock = seq_item_LPM.Symbol_Lock;
            dp_tl_vif.MAX_TPS_SUPPORTED = seq_item_LPM.MAX_TPS_SUPPORTED;
            dp_tl_vif.Link_LC_CR = seq_item_LPM.Link_LC_CR;
            dp_tl_vif.EQ_Data_VLD = seq_item_LPM.EQ_Data_VLD;
            dp_tl_vif.Driving_Param_VLD = seq_item_LPM.Driving_Param_VLD;
            dp_tl_vif.LPM_Start_CR = seq_item_LPM.LPM_Start_CR;
            dp_tl_vif.MAX_TPS_SUPPORTED_VLD = seq_item_LPM.MAX_TPS_SUPPORTED_VLD;

            // Signals from DUT to LPM
            seq_item_LPM.LPM_Reply_Data = dp_tl_vif.LPM_Reply_Data;
            seq_item_LPM.LPM_Reply_ACK = dp_tl_vif.LPM_Reply_ACK;
            seq_item_LPM.LPM_NATIVE_I2C = dp_tl_vif.LPM_NATIVE_I2C;
            seq_item_LPM.LPM_Reply_Data_VLD = dp_tl_vif.LPM_Reply_Data_VLD;
            seq_item_LPM.LPM_Reply_ACK_VLD = dp_tl_vif.LPM_Reply_ACK_VLD;
            seq_item_LPM.CTRL_Native_Failed = dp_tl_vif.CTRL_Native_Failed;
            seq_item_LPM.HPD_Detect = dp_tl_vif.HPD_Detect;
            seq_item_LPM.HPD_IRQ = dp_tl_vif.HPD_IRQ;
                // Link Training Signals
            seq_item_LPM.EQ_Final_ADJ_BW = dp_tl_vif.EQ_Final_ADJ_BW;
            seq_item_LPM.EQ_Final_ADJ_LC = dp_tl_vif.EQ_Final_ADJ_LC;
            seq_item_LPM.FSM_CR_Failed = dp_tl_vif.FSM_CR_Failed;
            seq_item_LPM.EQ_Failed = dp_tl_vif.EQ_Failed;
            seq_item_LPM.EQ_LT_Pass = dp_tl_vif.EQ_LT_Pass;

            // Send response back properly via seq_item_port
            @(negedge dp_tl_vif.clk);
            seq_item_port.item_done(seq_item_SPM);
            seq_item_port.item_done(seq_item_LPM);

            `uvm_info("run_phase", $sformatf("Driver Done"), UVM_HIGH);
            `uvm_info("run_phase", seq_item_SPM.convert2string(), UVM_HIGH);
            `uvm_info("run_phase", seq_item_LPM.convert2string(), UVM_HIGH);
        end
    endtask
endclass
