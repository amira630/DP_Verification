package dp_source_config_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    class dp_source_config extends uvm_object;
        `uvm_object_utils(dp_source_config)
        
        // Virtual Interfaces
        virtual dp_tl_if dp_tl_vif;
        virtual dp_sink_if dp_sink_vif;

        function new(string name = "dp_source_config");
            super.new(name);
        endfunction
    endclass 

endpackage
