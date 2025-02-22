class dp_sink_driver extends uvm_driver #(dp_sink_sequence_item);
    `uvm_component_utils(dp_sink_driver);

    virtual dp_sink_if dp_sink_vif;
    dp_sink_sequence_item stim_seq_item;
    
    function new(string name = "dp_sink_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        forever begin
            stim_seq_item = dp_sink_sequence_item::type_id::create("stim_seq_item");
            seq_item_port.get_next_item(stim_seq_item);
            dp_sink_vif.name_1 = stim_seq_item.name_1;
            dp_sink_vif.name_2 = stim_seq_item.name_2;
            dp_sink_vif.name_3 = stim_seq_item.name_3;
            @(negedge dp_sink_vif.clk);
            seq_item_port.item_done();
            `uvm_info("run_phase", stim_seq_item.convert2string(), UVM_HIGH);
        end
    endtask
endclass