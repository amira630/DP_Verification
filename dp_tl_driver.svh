class dp_tl_driver extends uvm_driver #(dp_tl_sequence_item);
    `uvm_component_utils(dp_tl_driver);

    virtual dp_tl_if dp_tl_vif;
    dp_tl_sequence_item stimulus_seq_item, response_seq_item;
    
    function new(string name = "dp_tl_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
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
            @(posedge dp_tl_vif.clk_AUX);
            if(stimulus_seq_item.SPM_Transaction_VLD == 1 && stimulus_seq_item.LPM_Transaction_VLD == 0) begin
                // SPM transaction
                case (stimulus_seq_item.operation)
                    reset_op: dp_tl_vif.Reset();                             // Reset the interface
                    I2C_READ: dp_tl_vif.I2C_READ(stimulus_seq_item.SPM_Address,stimulus_seq_item.SPM_LEN,stimulus_seq_item.SPM_CMD,stimulus_seq_item.SPM_Transaction_VLD);      // I2C READ
                    I2C_WRITE: dp_tl_vif.I2C_WRITE(stimulus_seq_item.SPM_Address,stimulus_seq_item.SPM_LEN,stimulus_seq_item.SPM_CMD, stimulus_seq_item.SPM_Data, stimulus_seq_item.SPM_Transaction_VLD);     // I2C WRITE
                    ISO: dp_tl_vif.ISO(stimulus_seq_item.CLOCK_PERIOD, stimulus_seq_item.SPM_ISO_start, stimulus_seq_item.SPM_MSA_VLD, stimulus_seq_item.MS_DE, stimulus_seq_item.MS_VSYNC, stimulus_seq_item.MS_HSYNC, stimulus_seq_item.SPM_Lane_BW, stimulus_seq_item.SPM_Lane_Count, stimulus_seq_item.SPM_BW_Sel, stimulus_seq_item.MS_Pixel_Data, stimulus_seq_item.MS_Stm_BW, stimulus_seq_item.SPM_MSA); // ISO
                    DETECT: `uvm_info("DP_TL_DRIVER", "Source is still detecting the sink.", UVM_MEDIUM) // Detect
                    default: begin
                        dp_tl_vif = null; // Set the interface to null if the operation is not supported
                        `uvm_error("DP_TL_DRIVER", "Unsupported operation in SPM transaction")
                    end
                endcase
            end
            else if (stimulus_seq_item.SPM_Transaction_VLD == 0 && stimulus_seq_item.LPM_Transaction_VLD == 1) begin
                // LPM transaction
                case (stimulus_seq_item.operation)
                    reset_op: dp_tl_vif.Reset();
                    NATIVE_READ: dp_tl_vif.NATIVE_READ(stimulus_seq_item.LPM_Address,stimulus_seq_item.LPM_LEN,stimulus_seq_item.LPM_CMD,stimulus_seq_item.LPM_Transaction_VLD);       // NATIVE READ
                    NATIVE_WRITE: dp_tl_vif.NATIVE_WRITE(stimulus_seq_item.LPM_Address,stimulus_seq_item.LPM_LEN,stimulus_seq_item.LPM_CMD, stimulus_seq_item.LPM_Data, stimulus_seq_item.LPM_Transaction_VLD);      // NATIVE WRITE
                    CR_LT: dp_tl_vif.LT_CT(stimulus_seq_item.Config_Param_VLD, stimulus_seq_item.Driving_Param_VLD, stimulus_seq_item.LPM_Start_CR, stimulus_seq_item.CR_DONE_VLD, stimulus_seq_item.PRE, stimulus_seq_item.VTG, stimulus_seq_item.Link_BW_CR, stimulus_seq_item.EQ_RD_Value, stimulus_seq_item.CR_DONE, stimulus_seq_item.Link_LC_CR, stimulus_seq_item.MAX_VTG, stimulus_seq_item.MAX_PRE); // CR_LT
                    EQ_LT: dp_tl_vif.LT_EQ(stimulus_seq_item.Driving_Param_VLD, stimulus_seq_item.CR_DONE_VLD, stimulus_seq_item.EQ_Data_VLD, stimulus_seq_item.MAX_TPS_SUPPORTED_VLD, stimulus_seq_item.PRE, stimulus_seq_item.VTG, stimulus_seq_item.Lane_Align, stimulus_seq_item.CR_DONE, stimulus_seq_item.EQ_CR_DN, stimulus_seq_item.Channel_EQ, stimulus_seq_item.Symbol_Lock, stimulus_seq_item.MAX_TPS_SUPPORTED);  // EQ_LT
                    ISO: dp_tl_vif.ISO(stimulus_seq_item.CLOCK_PERIOD, stimulus_seq_item.SPM_ISO_start, stimulus_seq_item.SPM_MSA_VLD, stimulus_seq_item.MS_DE, stimulus_seq_item.MS_VSYNC, stimulus_seq_item.MS_HSYNC, stimulus_seq_item.SPM_Lane_BW, stimulus_seq_item.SPM_Lane_Count, stimulus_seq_item.SPM_BW_Sel, stimulus_seq_item.MS_Pixel_Data, stimulus_seq_item.MS_Stm_BW, stimulus_seq_item.SPM_MSA); // ISO
                    DETECT: `uvm_info("DP_TL_DRIVER", "Source is still detecting the sink.", UVM_MEDIUM) // Detect
                    default: begin
                        dp_tl_vif = null;    // Set the interface to null if the operation is not supported
                        `uvm_error("DP_TL_DRIVER", "Unsupported operation in SPM transaction")
                    end
                endcase
            end
            else begin
                case (stimulus_seq_item.operation)
                    reset_op: dp_tl_vif.Reset();    
                    ISO: dp_tl_vif.ISO(stimulus_seq_item.CLOCK_PERIOD, stimulus_seq_item.SPM_ISO_start, stimulus_seq_item.SPM_MSA_VLD, stimulus_seq_item.MS_DE, stimulus_seq_item.MS_VSYNC, stimulus_seq_item.MS_HSYNC, stimulus_seq_item.SPM_Lane_BW, stimulus_seq_item.SPM_Lane_Count, stimulus_seq_item.SPM_BW_Sel, stimulus_seq_item.MS_Pixel_Data, stimulus_seq_item.MS_Stm_BW, stimulus_seq_item.SPM_MSA); // ISO                         // Reset the interface
                    DETECT: `uvm_info("DP_TL_DRIVER", "Source is still detecting the sink.", UVM_MEDIUM) // Detect
                    default: begin
                        dp_tl_vif = null; // Set the interface to null if the operation is not supported
                        `uvm_error("DP_TL_DRIVER", "Unsupported operation in SPM transaction")
                    end
                endcase
            end

            // Send response back properly via seq_item_port
            @(negedge dp_tl_vif.clk_AUX);
            seq_item_port.item_done(stimulus_seq_item);

            `uvm_info("run_phase", $sformatf("Driver Done"), UVM_HIGH);
            `uvm_info("run_phase", stimulus_seq_item.convert2string(), UVM_HIGH);
        end
    endtask
endclass
