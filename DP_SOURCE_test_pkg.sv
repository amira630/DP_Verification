package DP_SOURCE_test_pkg;
    
    import uvm_pkg::*;
    import DP_SOURCE_config_pkg::*;
    import DP_SOURCE_env_pkg::*;
    import DP_TL_sequence_pkg::*;
    import DP_SINK_sequence_pkg::*;
    `include "uvm_macros.svh"

    class DP_SOURCE_test extends uvm_test;
        `uvm_component_utils(DP_SOURCE_test) //Registering the class in the UVM factory
        
        // Environment and Configuration object
        DP_SOURCE_env env;
        DP_SOURCE_config DP_SOURCE_cfg;
        
        // Virtual Interfaces
        virtual DP_SOURCE_if DP_TL_vif;
        virtual DP_SOURCE_if DP_SINK_vif;
        
        // Sequences
        DP_TL_sequence DP_TL_seq;
        DP_SINK_sequence DP_SINK_seq;

        function new(string name = "DP_SOURCE_test", uvm_component parent = null);
            super.new(name, parent);
        endfunction //new()

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            // building the environment, TL_sequence, Sink_sequence and configurations object
            env = DP_SOURCE_env::type_id::create("env",this);
            DP_SOURCE_cfg = DP_SOURCE_config::type_id::create("DP_SOURCE_cfg");
            DP_TL_seq = DP_TL_sequence::type_id::create("DP_TL_seq", this);
            DP_SINK_seq = DP_SINK_sequence::type_id::create("DP_SINK_seq", this);
            
            // add virtual interfaces for each interface to the configurations database
            if(!uvm_config_db #(virtual DP_TL_if):: get(this, "","DP_TL_vif", DP_SOURCE_cfg.DP_TL_vif))
                `uvm_fatal("build_phase","Test - Unable to get the virtual interface of the Transport Layer from the uvm_config_db");
            if(!uvm_config_db #(virtual DP_SINK_if):: get(this, "","DP_SINK_vif", DP_SOURCE_cfg.DP_SINK_vif))
                `uvm_fatal("build_phase","Test - Unable to get the virtual interface of the DP Sink from the uvm_config_db"); 
            // pass the virtual interfaces on to the agents
            uvm_config_db #(DP_SOURCE_config)::set(this,"*", "CFG", DP_SOURCE_cfg);   
        endfunction

        task run_phase(uvm_phase phase);
            super.run_phase(phase);

            phase.raise_objection(phase);
            
            // Transport Layer Sequence
            `uvm_info("run_phase", "TL stimulus generation started", UVM_LOW);
            DP_TL_seq.start(env.tl_agt.sqr);
            `uvm_info("run_phase", "TL stimulus generation ended", UVM_LOW);
            
            // DP Sink Sequence
            `uvm_info("run_phase", "Sink stimulus generation started", UVM_LOW);
            DP_SINK_seq.start(env.sink_agt.sqr);
            `uvm_info("run_phase", "Sink stimulus generation ended", UVM_LOW);

            phase.drop_objection(this);
        endtask      
    endclass //className extends superClass
endpackage