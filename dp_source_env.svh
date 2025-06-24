class dp_source_env extends uvm_env;
    `uvm_component_utils(dp_source_env)

    dp_tl_agent tl_agt;
    dp_sink_agent sink_agt;
    dp_scoreboard sb;
    // dp_source_ref_iso ref_model;
    dp_tl_coverage tl_cov;
    dp_sink_coverage sink_cov;

    virtual dp_ref_if ref_vif;
    dp_source_config dp_source_cfg;

    function new(string name = "dp_source_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction //new()

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // Building the TL_agent, Sink_agent, scoreboard, reference model, TL_collector and Sink_collector
        tl_agt = dp_tl_agent::type_id::create("tl_agt", this);
        sink_agt = dp_sink_agent::type_id::create("sink_agt", this);
        sb = dp_scoreboard::type_id::create("sb", this);
        // ref_model = dp_source_ref_iso::type_id::create("ref_model", this);
        tl_cov = dp_tl_coverage::type_id::create("tl_cov", this);
        sink_cov = dp_sink_coverage::type_id::create("sink_cov", this);

        `uvm_info("ENV", "Trying to get CFG now!", UVM_MEDIUM);
        if (!uvm_config_db #(dp_source_config)::get(this, "", "CFG", dp_source_cfg))
            `uvm_fatal("build_phase","Unable to get configuration object in TL Agent");
    endfunction   
        
    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        // Transport Layer Agent → Scoreboard
        tl_agt.agt_ap.connect(sb.sb_tl_export);

        // Sink Agent → Scoreboard
        sink_agt.agt_ap.connect(sb.sb_sink_export);

        // Reference Model → Scoreboard
        // ref_model.ref_model_out_port.connect(sb.sb_ref_export);

        // Transport Layer Agent → Transport Layer Coverage Collector
        // tl_agt.agt_ap.connect(tl_cov.cov_export);
        
        // Sink Agent → Sink Coverage Collector
        // sink_agt.agt_ap.connect(sink_cov.cov_export);

        // if (ref_model == null)
        // `uvm_fatal("CONNECT", "ref_model is null")

        // if (ref_model.tl_in_export == null)
        //     `uvm_fatal("CONNECT", "ref_model.tl_in_export is null")

        `uvm_info("CONNECT", "Connecting tl_agt.agt_ap to ref_model.tl_in_export", UVM_LOW)

        // Transport Layer Agent → Reference Model
        // tl_agt.agt_ap.connect(ref_model.tl_in_export);

        // Sink Agent → Reference Model
        // sink_agt.agt_ap.connect(ref_model.sink_in_port);

        // ref_model.ref_vif = dp_source_cfg.dp_ref_vif;            // added
        sb.ref_vif = dp_source_cfg.dp_ref_vif;

    endfunction
endclass //className extends superClass