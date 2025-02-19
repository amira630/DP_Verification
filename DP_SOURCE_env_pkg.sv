package DP_SOURCE_env_pkg;

    import uvm_pkg::*;
    import DP_TL_agent_pkg::*;
    import DP_SINK_agent_pkg::*;
    import DP_scoreboard_pkg::*;
    import DP_SOURCE_ref_pkg::*;
    import DP_TL_coverage_pkg::*;
    import DP_SINK_coverage_pkg::*;
    `include "uvm_macros.svh"

    class DP_SOURCE_env extends uvm_env;
        `uvm_component_utils(DP_SOURCE_env)

        DP_TL_agent tl_agt;
        DP_SINK_agent sink_agt;
        DP_scoreboard sb;
        DP_SOURCE_ref ref_model;
        DP_TL_coverage tl_cov;
        DP_SINK_coverage sink_cov;

        function new(string name = "DP_SOURCE_env", uvm_component parent = null);
            super.new(name, parent);
        endfunction //new()

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            // Building the TL_agent, Sink_agent, scoreboard, reference model, TL_collector and Sink_collector
            tl_agt = DP_TL_agent::type_id::create("tl_agt", this);
            sink_agt = DP_SINK_agent::type_id::create("sink_agt", this);
            sb = DP_scoreboard::type_id::create("sb", this);
            ref_model = DP_SOURCE_ref::type_id::create("ref_model", this);
            tl_cov = DP_TL_coverage::type_id::create("tl_cov", this);
            sink_cov = DP_SINK_coverage::type_id::create("sink_cov", this);
        endfunction   
         
        function void connect_phase(uvm_phase phase);
            super.connect_phase(phase);
            // Transport Layer Agent → Scoreboard
            tl_agt.agt_ap.connect(sb.sb_tl_export);

            // Sink Agent → Scoreboard
            sink_agt.agt_ap.connect(sb.sb_sink_export);

            // Transport Layer Agent → Transport Layer Coverage Collector
            tl_agt.agt_ap.connect(tl_cov.cov_export);
            // Sink Agent → Sink Coverage Collector
            sink_agt.agt_ap.connect(sink_cov.cov_export);

            // Transport Layer Agent → Reference Model
            tl_agt.agt_ap.connect(ref_model.ref_model_export);

            // Reference Model → Scoreboard
            ref_model.ref_ap.connect(sb.sb_ref_export);
        endfunction
    endclass //className extends superClass
endpackage