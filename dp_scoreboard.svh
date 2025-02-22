class dp_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(dp_scoreboard)
    
    uvm_analysis_export #(dp_tl_seq_item) sb_tl_export;
    uvm_analysis_export #(dp_sink_seq_item) sb_sink_export;
    uvm_analysis_export #(dp_source_ref) sb_ref_export;

    uvm_tlm_analysis_fifo #(dp_tl_seq_item) sb_tl_fifo;
    uvm_tlm_analysis_fifo #(dp_sink_seq_item) sb_sink_fifo;
    uvm_tlm_analysis_fifo #(dp_source_ref) sb_ref_fifo;

    dp_tl_seq_item seq_item_sb_tl;
    dp_sink_seq_item seq_item_sb_sink;
    dp_source_ref seq_item_sb_ref;
    
    dp_source_config dp_source_config_scoreboard;
    // virtual DP_TL_if DP_TL_scoreboard_vif;
    // virtual DP_SINK_if DP_SINK_scoreboard_vif;
    
    int error_count = 0;
    int correct_count = 0;

    function new(string name = "dp_scoreboard", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        sb_tl_export = new("sb_tl_export", this);
        sb_sink_export = new("sb_sink_export", this);
        sb_ref_export = new("sb_ref_export", this);

        sb_tl_fifo = new("sb_tl_fifo", this);
        sb_sink_fifo = new("sb_sink_fifo", this);
        sb_ref_fifo = new("sb_ref_fifo", this);

        if (!uvm_config_db #(dp_source_config)::get(this, "", "CFG", dp_source_config_scoreboard)) begin
            `uvm_fatal("build_phase", "Scoreboard - Unable to get configuration object")
        end
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        sb_tl_export.connect(sb_tl_fifo.analysis_export);
        sb_sink_export.connect(sb_sink_fifo.analysis_export);
        sb_ref_export.connect(sb_ref_fifo.analysis_export);
        // DP_TL_scoreboard_vif = dp_source_config_scoreboard.DP_TL_vif;
        // DP_SINK_scoreboard_vif = dp_source_config_scoreboard.DP_SINK_vif;
    endfunction

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        forever begin
            sb_tl_fifo.get(seq_item_sb_tl);
            sb_sink_fifo.get(seq_item_sb_sink);
            sb_ref_fifo.get(seq_item_sb_ref);
            //ref_model(seq_item_sb_tl, seq_item_sb_sink);
        end
    endtask

    // task ref_model(dp_tl_seq_item seq_item_chk_tl, dp_sink_seq_item seq_item_chk_sink);
    //     if (seq_item_chk_tl.rst) begin
    //         `uvm_info("ref_model", "Reset detected, checking reset behavior.", UVM_MEDIUM);
    //     end else begin
    //         check_results(seq_item_chk_tl, seq_item_chk_sink);
    //     end
    // endtask

    // task check_results(dp_tl_seq_item seq_item_chk_tl, dp_sink_seq_item seq_item_chk_sink);
    //     @(negedge DP_TL_scoreboard_vif.clk);
    //     if (seq_item_chk_tl.out == seq_item_chk_sink.out && seq_item_chk_tl.leds == seq_item_chk_sink.leds) begin
    //         `uvm_info("check_results", "Transaction matches expected output.", UVM_HIGH);
    //         correct_count++;
    //     end else begin
    //         `uvm_error("check_results", $sformatf("Mismatch detected! TL Out: %0b, Sink Out: %0b", seq_item_chk_tl.out, seq_item_chk_sink.out));
    //         error_count++;
    //     end
    // endtask

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("report_phase", $sformatf("Total successful transactions: %d", correct_count), UVM_MEDIUM);
        `uvm_info("report_phase", $sformatf("Total failed transactions: %d", error_count), UVM_MEDIUM);
    endfunction
endclass
