class DP_SINK_driver extends uvm_driver #(DP_SINK_sequence_item);
    `uvm_component_utils(DP_SINK_driver);

    virtual DP_SINK_if DP_SINK_driver_vif;
    DP_SINK_sequence_item stim_seq_item;
    
    function new(string name = "DP_SINK_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        forever begin
            stim_seq_item = DP_SINK_sequence_item::type_id::create("stim_seq_item");
            seq_item_port.get_next_item(stim_seq_item);
            DP_SINK_driver_vif.ctl      = stim_seq_item.ctl;
            @(negedge DP_SINK_driver_vif.clk);
            seq_item_port.item_done();
            `uvm_info("run_phase", stim_seq_item.convert2string_stimulus(), UVM_HIGH);
        end
    endtask
endclass
