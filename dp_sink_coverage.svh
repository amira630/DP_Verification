class dp_sink_coverage extends uvm_component;
    `uvm_component_utils(dp_sink_coverage)
    uvm_analysis_export #(dp_sink_sequence_item) cov_export;
    uvm_tlm_analysis_fifo #(dp_sink_sequence_item) cov_fifo;
    dp_sink_sequence_item sequence_item_cov;

    covergroup sink_cvr_grp;

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
            cov_fifo.get(sequence_item_cov);
            sink_cvr_grp.sample();
        end
    endtask

endclass

