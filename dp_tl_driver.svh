class dp_tl_driver extends uvm_driver #(dp_tl_sequence_item);
    `uvm_component_utils(dp_tl_driver);

    virtual dp_tl_if dp_tl_vif;
    dp_tl_sequence_item stim_seq_item;
    
    function new(string name = "dp_tl_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        forever begin
            stim_seq_item = dp_tl_sequence_item::type_id::create("stim_seq_item");
            seq_item_port.get_next_item(stim_seq_item);
            dp_tl_vif.name_1 = stim_seq_item.name_1;
            dp_tl_vif.name_2 = stim_seq_item.name_2;
            dp_tl_vif.name_3 = stim_seq_item.name_3;
            @(negedge dp_tl_vif.clk);
            seq_item_port.item_done();
            `uvm_info("run_phase", stim_seq_item.convert2string(), UVM_HIGH);
        end
    endtask
endclass