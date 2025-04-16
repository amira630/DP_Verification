class dp_sink_coverage extends uvm_component;
    `uvm_component_utils(dp_sink_coverage)
    uvm_analysis_export #(dp_sink_sequence_item) cov_export;
    uvm_tlm_analysis_fifo #(dp_sink_sequence_item) cov_fifo;
    dp_sink_sequence_item cov_sink_seq_item;

    covergroup sink_cvr_grp;
        // Coverpoints for the sink sequence item signals
        HPD_Signal_c:         coverpoint cov_sink_seq_item.HPD_Signal;
        START_STOP_c:         coverpoint cov_sink_seq_item.START_STOP;
        AUX_IN_OUT_c:         coverpoint cov_sink_seq_item.AUX_IN_OUT;
        CR_ADJ_LC_c:          coverpoint cov_sink_seq_item.CR_ADJ_LC;
        CR_ADJ_BW_c:          coverpoint cov_sink_seq_item.CR_ADJ_BW;
        CR_PHY_Instruct_c:    coverpoint cov_sink_seq_item.CR_PHY_Instruct;
        EQ_ADJ_LC_c:          coverpoint cov_sink_seq_item.EQ_ADJ_LC;
        EQ_ADJ_BW_c:          coverpoint cov_sink_seq_item.EQ_ADJ_BW;
        EQ_PHY_Instruct_c:    coverpoint cov_sink_seq_item.EQ_PHY_Instruct;

        // Reply Command Signals
        i2c_reply_cmd_c:      coverpoint cov_sink_seq_item.i2c_reply_cmd;
        native_reply_cmd_c:   coverpoint cov_sink_seq_item.native_reply_cmd;
    endgroup
 

    function new(string name = "dp_sink_coverage", uvm_component parent = null);
        super.new(name, parent);
        sink_cvr_grp = new();
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        cov_export = new("cov_export", this);
        cov_fifo = new("cov_fifo", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        cov_export.connect(cov_fifo.analysis_export);
    endfunction

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        forever begin
            cov_fifo.get(cov_sink_seq_item);
            sink_cvr_grp.sample();
        end
    endtask

endclass

