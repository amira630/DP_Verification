package dp_source_test_pkg;
    
    import uvm_pkg::*;
    import dp_source_env_pkg::*;
    `include "dp_source_config.sv"
    `include "dp_tl_sequence.sv"
    `include "dp_sink_sequence.sv"
    `include "uvm_macros.svh"

    class dp_source_test extends uvm_test;
        `uvm_component_utils(dp_source_test) //Registering the class in the UVM factory
        
        // Environment and Configuration object
        dp_source_env env;
        dp_source_config dp_source_cfg;
        
        // Virtual Interfaces
        virtual dp_tl_if dp_tl_vif;
        virtual dp_sink_if dp_sink_vif;
        
        // Sequences
        dp_tl_sequence dp_tl_seq;
        dp_sink_sequence dp_sink_seq;

        function new(string name = "dp_source_test", uvm_component parent = null);
            super.new(name, parent);
        endfunction //new()

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            // building the environment, TL_sequence, Sink_sequence and configurations object
            env = dp_source_env::type_id::create("env",this);
            dp_source_cfg = dp_source_config::type_id::create("dp_source_cfg");
            dp_tl_seq = dp_tl_sequence::type_id::create("dp_tl_seq", this);
            dp_sink_seq = dp_sink_sequence::type_id::create("dp_sink_seq", this);
            
            // add virtual interfaces for each interface to the configurations database
            if(!uvm_config_db #(virtual dp_tl_if):: get(this, "","dp_tl_vif", dp_source_cfg.dp_tl_vif))
                `uvm_fatal("build_phase","Test - Unable to get the virtual interface of the Transport Layer from the uvm_config_db");
            if(!uvm_config_db #(virtual dp_sink_if):: get(this, "","dp_sink_vif", dp_source_cfg.dp_sink_vif))
                `uvm_fatal("build_phase","Test - Unable to get the virtual interface of the DP Sink from the uvm_config_db"); 
            // pass the virtual interfaces on to the agents
            uvm_config_db #(dp_source_config)::set(this,"*", "CFG", dp_source_cfg);   
        endfunction

        task run_phase(uvm_phase phase);
            super.run_phase(phase);

            phase.raise_objection(phase);
            
            // Transport Layer Sequence
            `uvm_info("run_phase", "TL stimulus generation started", UVM_LOW);
            dp_tl_seq.start(env.tl_agt.sqr);
            `uvm_info("run_phase", "TL stimulus generation ended", UVM_LOW);
            
            // DP Sink Sequence
            `uvm_info("run_phase", "Sink stimulus generation started", UVM_LOW);
            dp_sink_seq.start(env.sink_agt.sqr);
            `uvm_info("run_phase", "Sink stimulus generation ended", UVM_LOW);

            phase.drop_objection(this);
        endtask      
    endclass //className extends superClass
endpackage
