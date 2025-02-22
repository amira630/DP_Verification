class dp_tl_coverage extends uvm_component;
    `uvm_component_utils(dp_tl_coverage)
    uvm_analysis_export #(dp_tl_seq_item) cov_export;
    uvm_tlm_analysis_fifo #(dp_tl_seq_item) cov_fifo;
    dp_tl_seq_item seq_item_cov;

    covergroup tl_cvr_grp;

    endgroup
 

    function new(string name = "dp_tl_coverage", uvm_component parent = null);
        super.new(name, parent);
        tl_cvr_grp = new();
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
            cov_fifo.get(seq_item_cov);
            tl_cvr_grp.sample();
        end
    endtask

endclass
