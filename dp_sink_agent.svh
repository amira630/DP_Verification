class dp_sink_agent extends uvm_agent;
    `uvm_component_utils(dp_sink_agent)
    
    uvm_sequencer #(dp_sink_sequence_item) sqr;
    dp_sink_driver drv;
    dp_sink_monitor mon;
    dp_source_config dp_source_cfg;
    uvm_analysis_port #(dp_sink_sequence_item) agt_ap;

    function new(string name = "dp_sink_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction //new()

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);

        `uvm_info("SINK AGENT", "Trying to get CFG now!", UVM_MEDIUM);
        if (!uvm_config_db #(dp_source_config)::get(this, "", "CFG", dp_source_cfg)) 
            `uvm_fatal("build_phase","Unable to get configuration object in Sink Agent");

        //buikding the Transport Layer sequencer, driver and monitor
        sqr = uvm_sequencer#(dp_sink_sequence_item)::type_id::create("sqr", this);
        drv = dp_sink_driver::type_id::create("drv", this);
        mon = dp_sink_monitor::type_id::create("mon", this);
        // building the Transport Layer agent analysis port
        agt_ap = new("agt_ap", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);

        `uvm_info("SINK agent", $sformatf("time= %0t,Connecting driver %s to sequencer %s",$time, drv.get_full_name(), sqr.get_full_name()), UVM_LOW);

        //connecting the virtual interface to the monitor and driver
        drv.dp_sink_vif = dp_source_cfg.dp_sink_vif;
        mon.dp_sink_vif = dp_source_cfg.dp_sink_vif;

        //connecting the drive TLM port to the sequencer TLM export
        drv.seq_item_port.connect(sqr.seq_item_export);

        `uvm_info("SINK agent", $sformatf("time= %0t, Connecting driver %s to sequencer %s",$time, drv.get_full_name(), sqr.get_full_name()), UVM_LOW);
        // Response port connection
        drv.rsp_port.connect(sqr.rsp_export);
        
        //connecting the monitor analysis port to the agent analysis port
        mon.mon_ap.connect(agt_ap);

        `uvm_info("SINK agent", $sformatf("time= %0t,Connecting driver %s to sequencer %s",$time, drv.get_full_name(), sqr.get_full_name()), UVM_LOW);
    endfunction
endclass