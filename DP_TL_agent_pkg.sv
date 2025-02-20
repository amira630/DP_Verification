package dp_tl_agent_pkg;

    import uvm_pkg::*;
    import dp_source_config_pkg::*;
    `include "dp_tl_sequencer.sv"
    `include "dp_tl_driver.sv"
    `include "dp_tl_monitor.sv"
    `include "uvm_macros.svh"

    class dp_tl_agent extends uvm_agent;
        `uvm_component_utils(dp_tl_agent)
        
        dp_tl_sequencer sqr;
        dp_tl_driver drv;
        dp_tl_monitor mon;
        dp_source_config dp_source_cfg;
        uvm_analysis_port #(dp_tl_seq_item) agt_ap;

        function new(string name = "dp_tl_agent", uvm_component parent = null);
            super.new(name, parent);
        endfunction //new()

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);

            if(!uvm_config_db #(dp_source_config):: get(this, "","CFG", dp_source_cfg))
                `uvm_fatal("build_phase","Test - Unable to get configuration object");
            
            //buikding the Transport Layer sequencer, driver and monitor
            sqr = dp_tl_sequencer::type_id::create("sqr", this);
            drv = dp_tl_driver::type_id::create("drv", this);
            mon = dp_tl_monitor::type_id::create("mon", this);
            // building the Transport Layer agent analysis port
            agt_ap = new("agt_ap", this);
        endfunction

        function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);

            //connecting the virtual interface to the monitor and driver
            drv.dp_tl_vif = dp_source_cfg.dp_tl_vif;
            mon.dp_tl_vif = dp_source_cfg.dp_tl_vif;

            //connecting the driver TLM port to the sequencer TLM export
            drv.seq_item_port.connect(sqr.seq_item_export);

            //connecting the monitor analysis port to the agent analysis port
            mon.mon_ap.connect(agt_ap);
        endfunction
    endclass
endpackage