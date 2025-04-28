class dp_tl_agent extends uvm_agent;
    `uvm_component_utils(dp_tl_agent)
    
    uvm_sequencer #(dp_tl_sequence_item) sqr;
    dp_tl_driver drv;
    dp_tl_monitor mon;
    dp_source_config dp_source_cfg;
    uvm_analysis_port #(dp_tl_sequence_item) agt_ap;

    function new(string name = "dp_tl_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction //new()

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        `uvm_info("TL AGENT", "Trying to get CFG now!", UVM_MEDIUM);
        if (!uvm_config_db #(dp_source_config)::get(this, "", "CFG", dp_source_cfg))
            `uvm_fatal("build_phase","Unable to get configuration object in TL Agent");
        
        //building the Transport Layer sequencer, driver and monitor
        sqr = uvm_sequencer#(dp_tl_sequence_item)::type_id::create("sqr", this);
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

        drv.tl_drv_Database = dp_source_cfg;
        mon.tl_mon_Database = dp_source_cfg;

        //connecting the driver TLM port to the sequencer TLM export
        drv.seq_item_port.connect(sqr.seq_item_export);

        // Response port connection
        drv.rsp_port.connect(sqr.rsp_export);

        //connecting the monitor analysis port to the agent analysis port
        mon.mon_ap.connect(agt_ap);
    endfunction
endclass