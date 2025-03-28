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

            // Create response sequence item to capture interface signals
            response_seq_item = dp_sink_sequence_item::type_id::create("response_seq_item");

            // Copy request to response (to preserve transaction ID and other fields)
            response_seq_item.copy(stim_seq_item);

            // Clear previous aux data
            response_seq_item.aux_in_out.delete();

            // Drive initial values to the interface
            // dp_sink_vif.HPD_Signal = stim_seq_item.hpd_signal;
            // dp_sink_vif.START_STOP = stim_seq_item.start_stop;

            // Wait for START_STOP = 1 (beginning of transaction)
            wait(dp_sink_vif.START_STOP == 1);

            // Collect data until START_STOP = 0
            // Sample interface signals based on start_stop signal
            while (dp_sink_vif.START_STOP) begin
                // Capture the current aux_in_out value from interface
                response_seq_item.aux_in_out.push_back(dp_sink_vif.AUX_IN_OUT);
                
                // Capture other signals as needed
                response_seq_item.cr_adj_lc = dp_sink_vif.CR_ADJ_LC;
                response_seq_item.cr_phy_instruct = dp_sink_vif.CR_PHY_Instruct;
                response_seq_item.eq_adj_lc = dp_sink_vif.EQ_ADJ_LC;
                response_seq_item.eq_phy_instruct = dp_sink_vif.EQ_PHY_Instruct;
                response_seq_item.cr_adj_bw = dp_sink_vif.CR_ADJ_BW;
                response_seq_item.eq_adj_bw = dp_sink_vif.EQ_ADJ_BW;
                
                @(posedge dp_sink_vif.clk);  // Wait for next clock cycle
            end

            // Send response back to sequence with captured aux_in_out queue
            // rsp_port.write(response_seq_item);  بدلتها بسطر 69 كتبت response_seq_item جوا القوسين

            // Create and send updated stimulus based on captured data
            // stim_seq_item.hpd_signal = response_seq_item.aux_in_out.size() > 0;  // Example logic
            // stim_seq_item.i2c_aux_reply_cmd = determine_reply_cmd(response_seq_item.aux_in_out);
            
            // Handle AUX_IN_OUT as inout - drive it during reply phase
            // Need to ensure proper bidirectional control
            // foreach (stim_seq_item.aux_in_out[i]) begin
            //    dp_sink_vif.AUX_IN_OUT = stim_seq_item.aux_in_out[i];
            //    dp_sink_vif.START_STOP = 1'b1;  // Start of reply
            //    @(posedge dp_sink_vif.clk);
            // end

            // End of reply
            // dp_sink_vif.START_STOP = 1'b0;

            // Send response back properly via seq_item_port
            @(negedge dp_sink_vif.clk);
            seq_item_port.item_done(response_seq_item);

            `uvm_info("run_phase", $sformatf("Response with %0d AUX bytes captured, reply generated", 
                    response_seq_item.aux_in_out.size()), UVM_HIGH);
            `uvm_info("run_phase", stim_seq_item.convert2string(), UVM_HIGH);
        end
    endtask
endclass
