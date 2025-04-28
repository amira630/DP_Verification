class dp_source_config extends uvm_object;
    `uvm_object_utils(dp_source_config)

    bit rst_n; // Active low Reset signal
    
    // Virtual Interfaces
    virtual dp_tl_if dp_tl_vif;
    virtual dp_sink_if dp_sink_vif;

    function new(string name = "dp_source_config");
        super.new(name);
        rst_n = 1'b1; // Default value for reset signal
    endfunction
endclass 