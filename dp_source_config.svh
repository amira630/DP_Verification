class dp_source_config extends uvm_object;
    `uvm_object_utils(dp_source_config)

    rand bit rst_n; // Active low Reset signal
    logic [1:0] SPM_BW_Sel; // Bandwidth Selection for the Sink Link Layer
    // Virtual Interfaces
    virtual dp_tl_if dp_tl_vif;
    virtual dp_sink_if dp_sink_vif;
    virtual dp_ref_if dp_ref_vif;

    function new(string name = "dp_source_config");
        super.new(name);
        rst_n = 1'b1; // Default value for reset signal
        SPM_BW_Sel = 2'b00;
    endfunction
endclass 