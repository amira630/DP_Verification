class dp_sink_driver extends uvm_driver #(dp_sink_sequence_item);
    `uvm_component_utils(dp_sink_driver);

    virtual dp_sink_if dp_sink_vif;
    dp_sink_sequence_item stim_seq_item;
    dp_sink_sequence_item response_seq_item;
    
    function new(string name = "dp_sink_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        forever begin
            // Get sequence item from sequencer
            stim_seq_item = dp_sink_sequence_item::type_id::create("stim_seq_item");
            seq_item_port.get_next_item(stim_seq_item);

            // Check if the interface is available
            if (dp_sink_vif == null) begin
                `uvm_fatal("DP_SINK_DRIVER", "Virtual interface is not set")
            end
            // Check if the sequence item is valid
            if (stim_seq_item == null) begin
                `uvm_fatal("DP_SINK_DRIVER", "Sequence item is not set")
            end

            // Clear previous aux data
            // response_seq_item.aux_in_out.delete();

            // Drive the values to the interface according to the operation
            @(posedge dp_sink_vif.clk_AUX);
            case (stim_seq_item.sink_operation)
                // HPD_operation: begin
                //     // HPD operation
                //     `uvm_info("DP_SINK_DRIVER", $sformatf("Driving HPD_Signal = %0b", stim_seq_item.HPD_Signal), UVM_MEDIUM);
                //     dp_sink_vif.drive_hpd_signal(stim_seq_item.HPD_Signal);
                // end
                Interrupt_operation: begin
                    // Interrupt sequence
                    `uvm_info("DP_SINK_DRIVER", $sformatf("Driving Interrupt"), UVM_MEDIUM);
                    dp_sink_vif.Interrupt();
                end
                // Reply_operation: begin
                //     // Reply operation
                //     dp_sink_vif.drive_aux_in_out(stim_seq_item.AUX_IN_OUT);
                // end
                default: 
                    begin
                        dp_sink_vif = null; // Set the interface to null if the operation is not supported
                        `uvm_warning("DP_SINK_DRIVER", "Unknown sink_operation type.")
                        `uvm_error("DP_SINK_DRIVER", "Unsupported operation in sink transaction")
                    end
            endcase

            // Copy the values from the stimulus to the response sequence item
            // This is done to ensure that the response sequence item has the same values as the stimulus
            $cast(response_seq_item, stim_seq_item.clone());

            // Wait for DUT response
            wait(dp_sink_vif.AUX_START_STOP == 1);

            // Copy the values from the DUT to the response sequence item
            // response_seq_item.copy_from_vif(dp_sink_vif);

            // Send response back properly via seq_item_port
            @(negedge dp_sink_vif.clk_AUX);
            seq_item_port.item_done(response_seq_item);

            `uvm_info("run_phase", $sformatf("Response with %0d AUX bytes captured, reply generated", 
                    response_seq_item.aux_in_out.size()), UVM_HIGH);
            `uvm_info("run_phase", stim_seq_item.convert2string(), UVM_HIGH);
        end
    endtask
endclass
