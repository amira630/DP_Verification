    import uvm_pkg::*;
    `include "uvm_macros.svh"

    import test_parameters_pkg::*;
class dp_sink_driver extends uvm_driver #(dp_sink_sequence_item);
    `uvm_component_utils(dp_sink_driver);

    virtual dp_sink_if dp_sink_vif;
    dp_sink_sequence_item stim_seq_item;
    
    function new(string name = "dp_sink_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        `uvm_info("DP_SINK_DRIVER", "Before get_next_item", UVM_MEDIUM);

        forever begin
            `uvm_info("DP_SINK_DRIVER", "Before get_next_item", UVM_MEDIUM);
            `uvm_info(get_type_name(), $sformatf("Time=%0t: start not ready function", $time), UVM_MEDIUM)

            // Get sequence item from sequencer
            stim_seq_item = dp_sink_sequence_item::type_id::create("stim_seq_item");
            seq_item_port.get_next_item(stim_seq_item);

            `uvm_info("DP_SINK_DRIVER", $sformatf("Start driver at time = %0t", $time), UVM_MEDIUM);


            // Check if the interface is available
            if (dp_sink_vif == null) begin
                `uvm_fatal("DP_SINK_DRIVER", "Virtual interface is not set")
            end
            // Check if the sequence item is valid
            if (stim_seq_item == null) begin
                `uvm_fatal("DP_SINK_DRIVER", "Sequence item is not set")
            end

            // Drive the values to the interface according to the operation
            @(posedge dp_sink_vif.clk_AUX);
            case (stim_seq_item.sink_operation)
                Reset: begin
                    // Reset operation
                    `uvm_info("DP_SINK_DRIVER", $sformatf("NOT ACTIVE SINK"), UVM_MEDIUM);
                    dp_sink_vif.SINK_Reset();
                end
                Ready: begin
                    // HPD operation
                    `uvm_info("DP_SINK_DRIVER", $sformatf("ACTIVE SINK"), UVM_MEDIUM);
                    dp_sink_vif.Active(stim_seq_item.AUX_START_STOP, stim_seq_item.AUX_IN_OUT, stim_seq_item.PHY_Instruct, 
                                       stim_seq_item.PHY_ADJ_BW, stim_seq_item.PHY_ADJ_LC, stim_seq_item.PHY_Instruct_VLD,
                                       stim_seq_item.ISO_symbols_lane0, stim_seq_item.ISO_symbols_lane1, 
                                       stim_seq_item.ISO_symbols_lane2, stim_seq_item.ISO_symbols_lane3,
                                       stim_seq_item.Control_sym_flag_lane0, stim_seq_item.Control_sym_flag_lane1,
                                       stim_seq_item.Control_sym_flag_lane2, stim_seq_item.Control_sym_flag_lane3);
                    if (stim_seq_item.AUX_START_STOP) begin
                        stim_seq_item.aux_in_out.push_back(stim_seq_item.AUX_IN_OUT); // Store the AUX_IN_OUT values while the AUX_START_STOP is high
                    end
                end
                Reply_operation: begin
                    // Reply operation
                    dp_sink_vif.drive_aux_in_out(stim_seq_item.PHY_IN_OUT);
                end
                Interrupt_operation: begin
                    // Interrupt sequence
                    `uvm_info("DP_SINK_DRIVER", $sformatf("Driving Interrupt"), UVM_MEDIUM);
                    dp_sink_vif.HPD_Interrupt();
                end
                HPD_test_operation: begin
                    // Random HPD sequence
                    `uvm_info("DP_SINK_DRIVER", $sformatf("Driving TEST HPD"), UVM_MEDIUM);
                    dp_sink_vif.HPD_Test();
                end
                default: 
                    begin
                        // dp_sink_vif = null; // Set the interface to null if the operation is not supported
                        `uvm_warning("DP_SINK_DRIVER", "Unknown sink_operation type.")
                        `uvm_error("DP_SINK_DRIVER", "Unsupported operation in sink transaction")
                    end
            endcase

            // Send response back properly via seq_item_port
            @(negedge dp_sink_vif.clk_AUX);
            seq_item_port.item_done(stim_seq_item);
            `uvm_info("run_phase", stim_seq_item.convert2string(), UVM_HIGH);
        end
    endtask
endclass
