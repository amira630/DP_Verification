    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import test_parameters_pkg::*;
class dp_tl_driver extends uvm_driver #(dp_tl_sequence_item);
    `uvm_component_utils(dp_tl_driver);

    dp_source_config tl_drv_Database;
    virtual dp_tl_if dp_tl_vif;
    dp_tl_sequence_item stimulus_seq_item;

    bit drv_rst;                    // added
    
    function new(string name = "dp_tl_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        @(negedge dp_tl_vif.clk_AUX);
        forever begin
            // Get sequence item from sequencer
            stimulus_seq_item = dp_tl_sequence_item::type_id::create("stimulus_seq_item");
            // Get the next sequence item from the sequencer
            seq_item_port.get_next_item(stimulus_seq_item);

            // Check if the interface is available
            if (dp_tl_vif == null) begin
                `uvm_fatal("DP_TL_DRIVER", "Virtual interface is not set")
            end
            // Check if the sequence item is valid
            if (stimulus_seq_item == null) begin
                `uvm_fatal("DP_TL_DRIVER", "Sequence item is not set")
            end

            // Check if the sequence item is SPM or LPM then drive the values to the interface according to the operation
            // @(negedge dp_tl_vif.clk_AUX);
            if(stimulus_seq_item.SPM_Transaction_VLD == 1 && stimulus_seq_item.LPM_Transaction_VLD == 0) begin
                // SPM transaction
                case (stimulus_seq_item.operation)
                    reset_op: begin
                        dp_tl_vif.Reset();                  // Reset the interface
                        drv_rst = 1'b0;       // Set the reset signal to low
                        #10000                              // Wait for 10us to allow the reset to propagate
                        drv_rst = 1'b1;       // Set the reset signal to high
                    end 
                    I2C_READ: dp_tl_vif.I2C_READ(stimulus_seq_item.SPM_Address,stimulus_seq_item.SPM_LEN,stimulus_seq_item.SPM_CMD,stimulus_seq_item.SPM_Transaction_VLD);      // I2C READ
                    I2C_WRITE: dp_tl_vif.I2C_WRITE(stimulus_seq_item.SPM_Address,stimulus_seq_item.SPM_LEN,stimulus_seq_item.SPM_CMD, stimulus_seq_item.SPM_Data, stimulus_seq_item.SPM_Transaction_VLD);     // I2C WRITE
                    WAIT_REPLY: dp_tl_vif.Wait_Reply_Data(stimulus_seq_item.SPM_Reply_Data, stimulus_seq_item.SPM_Reply_ACK, stimulus_seq_item.SPM_Reply_ACK_VLD, stimulus_seq_item.SPM_Reply_Data_VLD, stimulus_seq_item.SPM_NATIVE_I2C, stimulus_seq_item.LPM_Reply_Data, stimulus_seq_item.LPM_Reply_ACK, stimulus_seq_item.LPM_Reply_ACK_VLD, stimulus_seq_item.LPM_Reply_Data_VLD, stimulus_seq_item.LPM_NATIVE_I2C); // Wait for reply data
                    ISO: dp_tl_vif.ISO(stimulus_seq_item.CLOCK_PERIOD,stimulus_seq_item.SPM_ISO_start, stimulus_seq_item.SPM_MSA_VLD, stimulus_seq_item.MS_Stm_BW_VLD, stimulus_seq_item.MS_DE, stimulus_seq_item.MS_VSYNC, stimulus_seq_item.MS_HSYNC,stimulus_seq_item.SPM_Lane_BW, stimulus_seq_item.SPM_Lane_Count, stimulus_seq_item.SPM_BW_Sel, stimulus_seq_item.MS_Pixel_Data, stimulus_seq_item.MS_Stm_BW, stimulus_seq_item.SPM_Full_MSA, stimulus_seq_item.HPD_Detect, stimulus_seq_item.HPD_IRQ); // ISO
                    DETECT_op: begin
                        `uvm_info("DP_TL_DRIVER", "Source is still detecting the sink.", UVM_MEDIUM) // Detect
                        dp_tl_vif.rst_n = 1'b1;       // Set the reset signal to high
                        dp_tl_vif.DETECT(stimulus_seq_item.HPD_Detect);
                    end
                    default: begin
                        dp_tl_vif = null; // Set the interface to null if the operation is not supported
                        `uvm_error("DP_TL_DRIVER", "Unsupported operation in SPM transaction")
                    end
                endcase
            end
            else if (stimulus_seq_item.SPM_Transaction_VLD == 0 && stimulus_seq_item.LPM_Transaction_VLD == 1) begin
                // LPM transaction
                case (stimulus_seq_item.operation)
                    reset_op: begin
                        dp_tl_vif.Reset();                  // Reset the interface
                        drv_rst = 1'b0;       // Set the reset signal to low
                        #10000                              // Wait for 10us to allow the reset to propagate
                        drv_rst = 1'b1;       // Set the reset signal to high
                    end 
                    NATIVE_READ: dp_tl_vif.NATIVE_READ(stimulus_seq_item.LPM_Address, stimulus_seq_item.LPM_LEN, stimulus_seq_item.LPM_CMD, stimulus_seq_item.LPM_Transaction_VLD);       // NATIVE READ
                    NATIVE_WRITE: dp_tl_vif.NATIVE_WRITE(stimulus_seq_item.LPM_Address, stimulus_seq_item.LPM_LEN, stimulus_seq_item.LPM_CMD, stimulus_seq_item.LPM_Data, stimulus_seq_item.LPM_Transaction_VLD);      // NATIVE WRITE
                    WAIT_REPLY: dp_tl_vif.Wait_Reply_Data(stimulus_seq_item.SPM_Reply_Data, stimulus_seq_item.SPM_Reply_ACK, stimulus_seq_item.SPM_Reply_ACK_VLD, stimulus_seq_item.SPM_Reply_Data_VLD, stimulus_seq_item.SPM_NATIVE_I2C, stimulus_seq_item.LPM_Reply_Data, stimulus_seq_item.LPM_Reply_ACK, stimulus_seq_item.LPM_Reply_ACK_VLD, stimulus_seq_item.LPM_Reply_Data_VLD, stimulus_seq_item.LPM_NATIVE_I2C); // Wait for reply data
                    ISO: dp_tl_vif.ISO(stimulus_seq_item.CLOCK_PERIOD,stimulus_seq_item.SPM_ISO_start, stimulus_seq_item.SPM_MSA_VLD, stimulus_seq_item.MS_Stm_BW_VLD, stimulus_seq_item.MS_DE, stimulus_seq_item.MS_VSYNC, stimulus_seq_item.MS_HSYNC,stimulus_seq_item.SPM_Lane_BW, stimulus_seq_item.SPM_Lane_Count, stimulus_seq_item.SPM_BW_Sel, stimulus_seq_item.MS_Pixel_Data, stimulus_seq_item.MS_Stm_BW, stimulus_seq_item.SPM_Full_MSA, stimulus_seq_item.HPD_Detect, stimulus_seq_item.HPD_IRQ); // ISO
                    DETECT_op: begin
                        `uvm_info("DP_TL_DRIVER", "Source is still detecting the sink.", UVM_MEDIUM) // Detect
                        dp_tl_vif.rst_n = 1'b1;       // Set the reset signal to high
                        dp_tl_vif.DETECT(stimulus_seq_item.HPD_Detect);
                    end
                    default: begin
                        dp_tl_vif = null;    // Set the interface to null if the operation is not supported
                        `uvm_error("DP_TL_DRIVER", "Unsupported operation in SPM transaction")
                    end
                endcase
            end
            else begin
                case (stimulus_seq_item.operation)
                    reset_op: begin
                        dp_tl_vif.Reset();                  // Reset the interface
                        drv_rst = 1'b0;       // Set the reset signal to low
                        #10000                              // Wait for 10us to allow the reset to propagate
                        drv_rst = 1'b1;       // Set the reset signal to high
                    end    
                    CR_LT_op: dp_tl_vif.LT_CT(stimulus_seq_item.Config_Param_VLD, stimulus_seq_item.Driving_Param_VLD, stimulus_seq_item.LPM_Start_CR, stimulus_seq_item.CR_DONE_VLD, stimulus_seq_item.MAX_TPS_SUPPORTED_VLD, stimulus_seq_item.PRE, stimulus_seq_item.VTG, stimulus_seq_item.EQ_RD_Value, stimulus_seq_item.Link_BW_CR, stimulus_seq_item.CR_DONE, stimulus_seq_item.Link_LC_CR, stimulus_seq_item.MAX_VTG, stimulus_seq_item.MAX_PRE, stimulus_seq_item.MAX_TPS_SUPPORTED, stimulus_seq_item.HPD_Detect, stimulus_seq_item.HPD_IRQ, stimulus_seq_item.LPM_Reply_Data_VLD, stimulus_seq_item.LPM_NATIVE_I2C, stimulus_seq_item.CTRL_Native_Failed, stimulus_seq_item.FSM_CR_Failed, stimulus_seq_item.CR_Completed, stimulus_seq_item.Timer_Timeout, stimulus_seq_item.LPM_CR_Apply_New_BW_LC, stimulus_seq_item.LPM_CR_Apply_New_Driving_Param, stimulus_seq_item.LPM_Reply_ACK_VLD, stimulus_seq_item.LPM_Reply_ACK, stimulus_seq_item.LPM_Reply_Data); // CR_LT
                    EQ_LT_op: dp_tl_vif.LT_EQ(stimulus_seq_item.Driving_Param_VLD, stimulus_seq_item.CR_DONE_VLD, stimulus_seq_item.EQ_Data_VLD, stimulus_seq_item.PRE, stimulus_seq_item.VTG, stimulus_seq_item.Lane_Align, stimulus_seq_item.CR_DONE, stimulus_seq_item.EQ_CR_DN, stimulus_seq_item.Channel_EQ, stimulus_seq_item.Symbol_Lock, stimulus_seq_item.HPD_Detect, stimulus_seq_item.HPD_IRQ, stimulus_seq_item.LPM_Reply_Data_VLD, stimulus_seq_item.LPM_NATIVE_I2C, stimulus_seq_item.CTRL_Native_Failed, stimulus_seq_item.FSM_CR_Failed, stimulus_seq_item.EQ_Failed, stimulus_seq_item.EQ_LT_Pass, stimulus_seq_item.CR_Completed, stimulus_seq_item.EQ_FSM_CR_Failed, stimulus_seq_item.Timer_Timeout, stimulus_seq_item.LPM_CR_Apply_New_BW_LC, stimulus_seq_item.LPM_CR_Apply_New_Driving_Param, stimulus_seq_item.LPM_Reply_ACK_VLD, stimulus_seq_item.LPM_Reply_ACK, stimulus_seq_item.EQ_Final_ADJ_LC, stimulus_seq_item.LPM_Reply_Data, stimulus_seq_item.EQ_Final_ADJ_BW);  // EQ_LT
                    WAIT_REPLY: dp_tl_vif.Wait_Reply_Data(stimulus_seq_item.SPM_Reply_Data, stimulus_seq_item.SPM_Reply_ACK, stimulus_seq_item.SPM_Reply_ACK_VLD, stimulus_seq_item.SPM_Reply_Data_VLD, stimulus_seq_item.SPM_NATIVE_I2C, stimulus_seq_item.LPM_Reply_Data, stimulus_seq_item.LPM_Reply_ACK, stimulus_seq_item.LPM_Reply_ACK_VLD, stimulus_seq_item.LPM_Reply_Data_VLD, stimulus_seq_item.LPM_NATIVE_I2C); // Wait for reply data
                    ISO: dp_tl_vif.ISO(stimulus_seq_item.CLOCK_PERIOD,stimulus_seq_item.SPM_ISO_start, stimulus_seq_item.SPM_MSA_VLD, stimulus_seq_item.MS_Stm_BW_VLD, stimulus_seq_item.MS_DE, stimulus_seq_item.MS_VSYNC, stimulus_seq_item.MS_HSYNC,stimulus_seq_item.SPM_Lane_BW, stimulus_seq_item.SPM_Lane_Count, stimulus_seq_item.SPM_BW_Sel, stimulus_seq_item.MS_Pixel_Data, stimulus_seq_item.MS_Stm_BW, stimulus_seq_item.SPM_Full_MSA, stimulus_seq_item.HPD_Detect, stimulus_seq_item.HPD_IRQ); // ISO                         // Reset the interface
                    DETECT_op:begin
                        `uvm_info("DP_TL_DRIVER", "Source is still detecting the sink.", UVM_MEDIUM) // Detect
                        dp_tl_vif.rst_n = 1'b1;       // Set the reset signal to high
                        dp_tl_vif.DETECT(stimulus_seq_item.HPD_Detect);
                    end
                    default: begin
                        dp_tl_vif.Transaction_wait(stimulus_seq_item.LPM_Transaction_VLD, stimulus_seq_item.SPM_Transaction_VLD); // Wait for the transaction to complete
                        //dp_tl_vif = null; // Set the interface to null if the operation is not supported
                        `uvm_info("DP_TL_DRIVER", "no operation in SPM && LPM transaction",UVM_MEDIUM)
                    end
                endcase
            end

            // Send response back properly via seq_item_port
            @(negedge dp_tl_vif.clk_AUX)
            `uvm_info("run_phase", $sformatf("Driver Done"), UVM_HIGH);
            case (stimulus_seq_item.operation)
                CR_LT_op: `uvm_info("run_phase", stimulus_seq_item.convert2string_CR_LT(), UVM_HIGH)
                EQ_LT_op: `uvm_info("run_phase", stimulus_seq_item.convert2string_EQ_LT(), UVM_HIGH)
                default:  `uvm_info("run_phase", stimulus_seq_item.convert2string_RQST(), UVM_HIGH)
            endcase
            seq_item_port.item_done(stimulus_seq_item);
        end
    endtask
endclass
