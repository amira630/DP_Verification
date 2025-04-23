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
            response_seq_item = dp_tl_sequence_item::type_id::create("response_seq_item");
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
            @(posedge dp_tl_vif.clk);
            if(stimulus_seq_item.SPM_Transaction_VLD == 1 && stimulus_seq_item.LPM_Transaction_VLD == 0) begin
                // SPM transaction
                case (stimulus_seq_item.operation)
                    4'b0000: dp_tl_vif.Reset();                             // Reset the interface
                    4'b0001: dp_tl_vif.I2C_READ(stimulus_seq_item.SPM_Address,stimulus_seq_item.SPM_LEN,stimulus_seq_item.SPM_CMD,stimulus_seq_item.SPM_Transaction_VLD);      // I2C READ
                    4'b0010: dp_tl_vif.I2C_WRITE(stimulus_seq_item.SPM_Address,stimulus_seq_item.SPM_LEN,stimulus_seq_item.SPM_CMD,stimulus_seq_item.SPM_Transaction_VLD, stimulus_seq_item.SPM_Data);     // I2C WRITE
                    default: begin
                        dp_tl_vif = null; // Set the interface to null if the operation is not supported
                        `uvm_error("DP_TL_DRIVER", "Unsupported operation in SPM transaction")
                    end
                endcase
            end
            else if (stimulus_seq_item.SPM_Transaction_VLD == 0 && stimulus_seq_item.LPM_Transaction_VLD == 1) begin
                // LPM transaction
                case (stimulus_seq_item.operation)
                    4'b0000: dp_tl_vif.Reset();
                    4'b0011: dp_tl_vif.NATIVE_READ(stimulus_seq_item.LPM_Address,stimulus_seq_item.LPM_LEN,stimulus_seq_item.LPM_CMD,stimulus_seq_item.LPM_Transaction_VLD);       // NATIVE READ
                    4'b0100: dp_tl_vif.NATIVE_WRITE(stimulus_seq_item.LPM_Address,stimulus_seq_item.LPM_LEN,stimulus_seq_item.LPM_CMD,stimulus_seq_item.LPM_Transaction_VLD, stimulus_seq_item.LPM_Data);      // NATIVE WRITE
                    // 4'b0101: dp_tl_vif.LINK_TRAINING(stimulus_seq_item);             // CR_LT
                    // 4'b0110: dp_tl_vif.LINK_TRAINING(stimulus_seq_item);             // EQ_LT
                    default: begin
                        dp_tl_vif = null;    // Set the interface to null if the operation is not supported
                        `uvm_error("DP_TL_DRIVER", "Unsupported operation in SPM transaction")
                    end
                endcase
            end
            else if (stimulus_seq_item.SPM_Transaction_VLD == 1 && stimulus_seq_item.LPM_Transaction_VLD == 1) begin
                dp_tl_vif = null;            // Set the interface to null if the operation is not supported
                `uvm_error("DP_TL_DRIVER", "Both SPM and LPM transactions are present")
            end
            else begin
                dp_tl_vif = null;            // Set the interface to null if the operation is not supported
                `uvm_error("DP_TL_DRIVER", "No transaction is present")
            end

            // Copy the values from the stimulus to the response sequence item
            // This is done to ensure that the response sequence item has the same values as the stimulus
            $cast(response_seq_item, stimulus_seq_item.clone());

            // Wait for DUT reponse
            // wait(dp_tl_vif.ready == 1)
            
            // Copy the values from the DUT to the response sequence item
            // response_seq_item.copy_from_vif(dp_tl_vif);

            // Send response back properly via seq_item_port
            @(negedge dp_tl_vif.clk);
            seq_item_port.item_done(stimulus_seq_item);

            `uvm_info("run_phase", $sformatf("Driver Done"), UVM_HIGH);
            `uvm_info("run_phase", stimulus_seq_item.convert2string(), UVM_HIGH);
        end
    endtask
endclass
