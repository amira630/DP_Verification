package DP_TL_agent_pkg;

    import uvm_pkg::*;
    import DP_TL_sequencer_pkg::*;
    import DP_TL_driver_pkg::*;
    import DP_TL_monitor_pkg::*;
    import DP_SOURCE_config_pkg::*;
    `include "uvm_macros.svh"

    class DP_TL_agent extends uvm_agent;
        `uvm_component_utils(DP_TL_agent)
        
        DP_TL_sequencer sqr;
        DP_TL_drive drv;
        DP_TL_monitor mon;
        DP_SOURCE_config DP_SOURCE_cfg;
        uvm_analysis_port #(DP_TL_seq_item) agt_ap;

        function new(string name = "DP_TL_agent", uvm_component parent = null);
            super.new(name, parent);
        endfunction //new()

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);

            if(!uvm_config_db #(DP_SOURCE_config):: get(this, "","CFG", DP_SOURCE_cfg))
                `uvm_fatal("build_phase","Test - Unable to get configuration object");
            
            //buikding the Transport Layer sequencer, driver and monitor
            sqr = DP_TL_sequencer::type_id::create("sqr", this);
            drv = DP_TL_drive::type_id::create("drv", this);
            mon = DP_TL_monitor::type_id::create("mon", this);
            // building the Transport Layer agent analysis port
            agt_ap = new("agt_ap", this);
        endfunction

        function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);

            //connecting the virtual interface to the monitor and driver
            drv.DP_TL_vif = DP_SOURCE_cfg.DP_TL_vif;
            mon.DP_TL_vif = DP_SOURCE_cfg.DP_TL_vif;

            //connecting the driver TLM port to the sequencer TLM export
            drv.seq_item_port.connect(sqr.seq_item_export);

            //connecting the monitor analysis port to the agent analysis port
            mon.mon_ap.connect(agt_ap);
        endfunction
    endclass
endpackage