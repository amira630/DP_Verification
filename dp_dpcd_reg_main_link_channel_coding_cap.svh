///////////////////////////////////////////////////////////////////////////////
// File:        dp_dpcd_reg_main_link_channel_coding_cap.svh
// Author:      Amira Atef
// Date:        20-3-2025
// Description: Definition of the MAIN_LINK_CHANNEL_CODING_CAP register at address 0_00_06h
//              in the DP DPCD Receiver Capability Field.
///////////////////////////////////////////////////////////////////////////////

class dp_dpcd_reg_main_link_channel_coding_cap extends uvm_reg;
    `uvm_object_utils(dp_dpcd_reg_main_link_channel_coding_cap)

    rand uvm_reg_field _8b10b_DP_SUPPORTED;

    rand uvm_reg_field _128b132b_DP_SUPPORTED;

    function new(string name = "dp_dpcd_reg_main_link_channel_coding_cap");
        super.new(.name(name), .n_bits(8), .has_coverage(UVM_NO_COVERAGE));
    endfunction
  
    virtual function void build();
        _8b10b_DP_SUPPORTED = uvm_reg_field::type_id::create(.name("_8b10b_DP_SUPPORTED"), .parent(null), .contxt(get_full_name()));
        _128b132b_DP_SUPPORTED = uvm_reg_field::type_id::create(.name("_128b132b_DP_SUPPORTED"), .parent(null), .contxt(get_full_name()));

        _8b10b_DP_SUPPORTED.configure(
            .parent(this),
            .size(1),
            .lsb_pos(0),
            .access("RO"),
            .volatile(0),
            .reset(1),  // Correct Value   MUSTTTTTT BE SET 
            .has_reset(1),
            .is_rand(1),
            .individually_accessible(0)
        );
        _128b132b_DP_SUPPORTED.configure(  
            .parent(this),
            .size(1),
            .lsb_pos(1),
            .access("RO"),
            .volatile(0),
            .reset(0),      // Correct Value
            .has_reset(1),
            .is_rand(1), 
            .individually_accessible(0)
        );        
    endfunction
endclass