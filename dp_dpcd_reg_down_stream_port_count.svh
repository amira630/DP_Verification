///////////////////////////////////////////////////////////////////////////////
// File:        dp_dpcd_reg_down_stream_port_count.svh
// Author:      Amira Atef
// Date:        20-3-2025
// Description: Definition of the DOWN_STREAM_PORT_COUNT register at address 0_00_07h
//              in the DP DPCD Receiver Capability Field.
///////////////////////////////////////////////////////////////////////////////

class dp_dpcd_reg_down_stream_port_count extends uvm_reg;
    `uvm_object_utils(dp_dpcd_reg_down_stream_port_count)

    rand uvm_reg_field DFP_COUNT;

    rand uvm_reg_field MSA_TIMING_PAR_IGNORED;

    rand uvm_reg_field OUI_SUPPORT;

    function new(string name = "dp_dpcd_reg_down_stream_port_count");
        super.new(.name(name), .n_bits(8), .has_coverage(UVM_NO_COVERAGE));
    endfunction
  
    virtual function void build();
        DFP_COUNT = uvm_reg_field::type_id::create(.name("DFP_COUNT"), .parent(null), .contxt(get_full_name()));
        MSA_TIMING_PAR_IGNORED = uvm_reg_field::type_id::create(.name("MSA_TIMING_PAR_IGNORED"), .parent(null), .contxt(get_full_name()));
        OUI_SUPPORT = uvm_reg_field::type_id::create(.name("OUI_SUPPORT"), .parent(null), .contxt(get_full_name()));

        DFP_COUNT.configure(
            .parent(this),
            .size(4),
            .lsb_pos(0),
            .access("RO"),
            .volatile(0),
            .reset(0),  // Correct Value  
            .has_reset(1),
            .is_rand(1),
            .individually_accessible(0)
        );
        /////////// IDK MUST READ MORE /////////////
        MSA_TIMING_PAR_IGNORED.configure(  
            .parent(this),
            .size(1),
            .lsb_pos(6),
            .access("RO"),
            .volatile(0),
            .reset(0),      // Correct Value
            .has_reset(1),
            .is_rand(1), 
            .individually_accessible(0)
        );    

        OUI_SUPPORT.configure(  
            .parent(this),
            .size(1),
            .lsb_pos(7),
            .access("RO"),
            .volatile(0),
            .reset(1),      // Correct Value
            .has_reset(1),
            .is_rand(1), 
            .individually_accessible(0)
        );  
    endfunction
endclass