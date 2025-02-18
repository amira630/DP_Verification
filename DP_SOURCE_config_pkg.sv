package DP_SOURCE_config_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    class DP_SOURCE_config extends uvm_object;
        `uvm_object_utils(alsu_config_obj)
        
        // Virtual Interfaces
        virtual DP_TL_if DP_TL_vif;
        virtual DP_SINK_if DP_SINK_vif;

        function new(string name = "DP_SOURCE_config");
            super.new(name);
        endfunction
    endclass 

endpackage