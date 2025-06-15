class dp_source_test extends uvm_test;
    `uvm_component_utils(dp_source_test) //Registering the class in the UVM factory
    
    // Environment and Configuration object
    dp_source_env env;
    dp_source_config dp_source_cfg;
    
    // Virtual Interfaces
    virtual dp_tl_if dp_tl_vif;
    virtual dp_sink_if dp_sink_vif;
    
    ///////////////////////////////////////////////////////////////////////////////////////////////////////
    /////////////////////////////////////////////// Sequences /////////////////////////////////////////////
    ///////////////////////////////////////////////////////////////////////////////////////////////////////

    /////////////////////////////////////////////// TL Sequences //////////////////////////////////////////

    dp_tl_flow_fsm_sequence dp_tl_seq;
    dp_tl_basic_flow_sequence dp_tl_basic_seq;
    dp_tl_reset_seq dp_tl_rst_seq;
    dp_tl_lt_sequence dp_tl_lt_seq;
    dp_tl_i2c_sequence dp_tl_i2c_seq;
    dp_tl_native_ext_receiver_cap_sequence dp_tl_native_ext_receiver_cap_seq;
    dp_tl_native_link_config_sequence dp_tl_native_link_config_seq;
    dp_tl_native_receiver_cap_sequence dp_tl_native_receiver_cap_seq;
    dp_tl_multi_read_sequence dp_tl_multi_read_seq;
    dp_tl_multi_read_with_wait_sequence dp_tl_multi_read_with_wait_seq;
    dp_tl_link_training_sequence dp_tl_link_training_seq;

    ////////////////////////////////////////////// Sink Sequences //////////////////////////////////////////

    dp_sink_full_flow_seq dp_sink_seq;
    dp_sink_interrupt_seq dp_sink_intr_seq;
    dp_sink_hpd_test_seq dp_sink_hpd_seq;


    function new(string name = "dp_source_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction //new()

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // building the environment, TL_sequence, Sink_sequence and configurations object
        env = dp_source_env::type_id::create("env",this);
        dp_source_cfg = dp_source_config::type_id::create("dp_source_cfg");
        
        // TL Sequences creation
        dp_tl_seq = dp_tl_flow_fsm_sequence::type_id::create("dp_tl_seq", this);
        dp_tl_basic_seq = dp_tl_basic_flow_sequence::type_id::create("dp_tl_basic_seq", this);
        dp_tl_rst_seq = dp_tl_reset_seq::type_id::create("dp_tl_rst_seq", this);
        dp_tl_i2c_seq = dp_tl_i2c_sequence::type_id::create("dp_tl_i2c_seq", this);
        dp_tl_lt_seq = dp_tl_lt_sequence::type_id::create("dp_tl_lt_seq", this);
        dp_tl_native_ext_receiver_cap_seq = dp_tl_native_ext_receiver_cap_sequence::type_id::create("dp_tl_native_ext_receiver_cap_seq", this);
        dp_tl_native_link_config_seq = dp_tl_native_link_config_sequence::type_id::create("dp_tl_native_link_config_seq", this);
        dp_tl_native_receiver_cap_seq = dp_tl_native_receiver_cap_sequence::type_id::create("dp_tl_native_receiver_cap_seq", this);
        dp_tl_multi_read_seq = dp_tl_multi_read_sequence::type_id::create("dp_tl_multi_read_seq", this); // This sequence is for testing multi read requests
        dp_tl_multi_read_with_wait_seq = dp_tl_multi_read_with_wait_sequence::type_id::create("dp_tl_multi_read_with_wait_seq", this); // This sequence is for testing multi read requests with waiting for ACK
        dp_tl_link_training_seq = dp_tl_link_training_sequence::type_id::create("dp_tl_link_training_seq", this);
        
        // Sink Sequences creation
        dp_sink_seq = dp_sink_full_flow_seq::type_id::create("dp_sink_seq", this);
        dp_sink_intr_seq = dp_sink_interrupt_seq::type_id::create("dp_sink_intr_seq", this);            // DONE
        dp_sink_hpd_seq = dp_sink_hpd_test_seq::type_id::create("dp_sink_hpd_seq", this);
        
        // add virtual interfaces for each interface to the configurations database
        if(!uvm_config_db #(virtual dp_tl_if):: get(this, "","dp_tl_vif", dp_source_cfg.dp_tl_vif))
            `uvm_fatal("build_phase","Test - Unable to get the virtual interface of the Transport Layer from the uvm_config_db");

        if(!uvm_config_db #(virtual dp_sink_if):: get(this, "","dp_sink_vif", dp_source_cfg.dp_sink_vif))
            `uvm_fatal("build_phase","Test - Unable to get the virtual interface of the DP Sink from the uvm_config_db"); 

        // pass the virtual interfaces on to the agents
        `uvm_info("TEST", "Setting CFG now!", UVM_MEDIUM);

        uvm_config_db #(dp_source_config)::set(this,"*", "CFG", dp_source_cfg);
    endfunction

    task run_phase(uvm_phase phase);
        super.run_phase(phase);

        phase.raise_objection(this);

        uvm_top.set_report_verbosity_level(UVM_FULL);

        repeat(3) begin
            // TL Reset Sequence
            `uvm_info("run_phase", "TL Reset seq stimulus generation started", UVM_LOW);
            dp_tl_rst_seq.start(env.tl_agt.sqr);
            `uvm_info("run_phase", "TL Reset seq stimulus generation ended", UVM_LOW);
        end

        repeat(3) begin
            `uvm_info("run_phase", "Sink Interrupt stimulus generation started", UVM_LOW);
            dp_sink_intr_seq.start(env.sink_agt.sqr);
            `uvm_info("run_phase", "Sink Interrupt stimulus generation ended", UVM_LOW); 
        end

        fork
            // DP Sink Sequences
            begin
                `uvm_info("run_phase", "Sink Full Flow stimulus generation started", UVM_LOW);
                dp_sink_seq.start(env.sink_agt.sqr);
                `uvm_info("run_phase", "Sink Full Flow stimulus generation ended", UVM_LOW);
            end
            
            // Transport Layer Sequence
            // begin
            //     `uvm_info("run_phase", "TL stimulus generation started", UVM_LOW);
            //     dp_tl_seq.start(env.tl_agt.sqr);
            //     `uvm_info("run_phase", "TL stimulus generation ended", UVM_LOW);
            // end

            // begin
            //     `uvm_info("run_phase", "TL stimulus generation started", UVM_LOW);
            //     dp_tl_basic_seq.start(env.tl_agt.sqr);
            //     `uvm_info("run_phase", "TL stimulus generation ended", UVM_LOW);
            // end

            // DPCD (RX Cap) Read Sequence
            // begin
            //     `uvm_info("run_phase", "TL DPCD stimulus generation started", UVM_LOW);
            //     dp_tl_native_receiver_cap_seq.start(env.tl_agt.sqr);
            //     `uvm_info("run_phase", "TL DPCD stimulus generation ended", UVM_LOW);
            // end

            // DPCD (Ext. RX Cap.) Read Sequence
            // begin
            //     `uvm_info("run_phase", "TL DPCD stimulus generation started", UVM_LOW);
            //     dp_tl_native_ext_receiver_cap_seq.start(env.tl_agt.sqr);
            //     `uvm_info("run_phase", "TL DPCD stimulus generation ended", UVM_LOW);
            // end

            // Multi Read Sequence
            // begin
            //     `uvm_info("run_phase", "TL Multi Read stimulus generation started", UVM_LOW);
            //     dp_tl_multi_read_seq.start(env.tl_agt.sqr);
            //     `uvm_info("run_phase", "TL Multi Read stimulus generation ended", UVM_LOW);
            // end

            // Multi Read With waiting ACK Sequence
            // begin
            //     `uvm_info("run_phase", "TL Multi Read with wait ACK stimulus generation started", UVM_LOW);
            //     dp_tl_multi_read_with_wait_seq.start(env.tl_agt.sqr);
            //     `uvm_info("run_phase", "TL Multi Read with wait ACK stimulus generation ended", UVM_LOW);
            // end

            // // TL Link Training Sequence
            // begin
            //     `uvm_info("run_phase", "TL Link Training seq stimulus generation started", UVM_LOW);
            //     dp_tl_link_training_seq.start(env.tl_agt.sqr);
            //     `uvm_info("run_phase", "TL Link Training seq stimulus generation ended", UVM_LOW);
            // end

            // EDID Read Sequence
            begin
                `uvm_info("run_phase", "TL I2C stimulus generation started", UVM_LOW);
                dp_tl_i2c_seq.start(env.tl_agt.sqr);
                `uvm_info("run_phase", "TL I2C stimulus generation ended", UVM_LOW);
            end

            // begin
            //     `uvm_info("run_phase", "Sink HPD stimulus generation started", UVM_LOW);
            //     dp_sink_hpd_seq.start(env.sink_agt.sqr);
            //     `uvm_info("run_phase", "Sink HPD stimulus generation ended", UVM_LOW);
            // end

        join
        phase.drop_objection(this);
    endtask      
endclass //className extends superClass