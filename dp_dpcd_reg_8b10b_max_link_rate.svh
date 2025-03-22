///////////////////////////////////////////////////////////////////////////////
// File:        dp_dpcd_reg_8b10b_max_link_rate.svh
// Author:      Amira Atef
// Date:        20-3-2025
// Description: Definition of the _8b10b_MAX_LINK_RATE register at address 0_00_01h
//              in the DP DPCD Receiver Capability Field.
///////////////////////////////////////////////////////////////////////////////

class dp_dpcd_reg_8b10b_max_link_rate extends uvm_reg;
    `uvm_object_utils(dp_dpcd_reg_8b10b_max_link_rate)

    rand uvm_reg_field _8b10b_MAX_LINK_RATE;

    function new(string name = "dp_dpcd_reg_8b10b_max_link_rate");
        super.new(.name(name), .n_bits(8), .has_coverage(UVM_NO_COVERAGE));
    endfunction
    /////////// CONSTRAINTS /////////////

    
    /////////// CONSTRAINTS /////////////
    virtual function void build();
        _8b10b_MAX_LINK_RATE = uvm_reg_field::type_id::create(.name("_8b10b_MAX_LINK_RATE"), .parent(null), .contxt(get_full_name()));

        _8b10b_MAX_LINK_RATE.configure(
            .parent(this),
            .size(8),
            .lsb_pos(0),
            .access("RO"),
            .volatile(0),
            .reset(0),
            .has_reset(0),
            .is_rand(1),
            .individually_accessible(1)
        );
    endfunction
endclass