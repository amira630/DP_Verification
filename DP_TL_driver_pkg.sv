package DP_TL_driver_pkg;
    import uvm_pkg::*;
    import DP_SOURCE_config_pkg::*;
    import DP_TL_sequence_item_pkg::*;
    `include "uvm_macros.svh"

    class DP_TL_driver extends uvm_driver #(DP_TL_sequence_item);
        `uvm_component_utils(DP_TL_driver);

        virtual DP_TL_if DP_TL_driver_vif;
        DP_TL_sequence_item stim_seq_item;
        
        function new(string name = "DP_TL_driver", uvm_component parent = null);
            super.new(name, parent);
        endfunction

        task run_phase(uvm_phase phase);
            super.run_phase(phase);
            forever begin
                stim_seq_item = DP_TL_sequence_item::type_id::create("stim_seq_item");
                seq_item_port.get_next_item(stim_seq_item);
                DP_TL_driver_vif.reset      = stim_seq_item.reset;
                DP_TL_driver_vif.valid_in   = stim_seq_item.valid_in;
                DP_TL_driver_vif.a          = stim_seq_item.a;
                DP_TL_driver_vif.b          = stim_seq_item.b;
                DP_TL_driver_vif.cin        = stim_seq_item.cin;
                @(negedge DP_TL_driver_vif.clk);
                seq_item_port.item_done();
                `uvm_info("run_phase", stim_seq_item.convert2string(), UVM_HIGH);
            end
        endtask
    endclass
endpackage
