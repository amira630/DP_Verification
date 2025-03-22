///////////////////////////////////////////////////////////////////////////////
// File:        dp_dpcd_reg_av_sync_data_block_av_granularity.svh
// Author:      Amira Atef
// Date:        20-3-2025
// Description: Definition of the AV_SYNC_DATA_BLOCK_AV_GRANULARITY register at address 0_00_23h
//              in the DP DPCD Receiver Capability Field.
///////////////////////////////////////////////////////////////////////////////

class dp_dpcd_reg_av_sync_data_block_av_granularity extends uvm_reg;
    `uvm_object_utils(dp_dpcd_reg_av_sync_data_block_av_granularity)

    rand uvm_reg_field AG_FACTOR;

    rand uvm_reg_field VG_FACTOR;

    function new(string name = "dp_dpcd_reg_av_sync_data_block_av_granularity");
        super.new(.name(name), .n_bits(8), .has_coverage(UVM_NO_COVERAGE));
    endfunction
  
    virtual function void build();
        AG_FACTOR = uvm_reg_field::type_id::create(.name("AG_FACTOR"), .parent(null), .contxt(get_full_name()));
        VG_FACTOR = uvm_reg_field::type_id::create(.name("VG_FACTOR"), .parent(null), .contxt(get_full_name()));

        AG_FACTOR.configure(
            .parent(this),
            .size(4),
            .lsb_pos(0),
            .access("RO"),
            .volatile(0),
            .reset(4'h1),    // Correct Value 
            .has_reset(1),
            .is_rand(1),
            .individually_accessible(0)
        );

        VG_FACTOR.configure(
            .parent(this),
            .size(4),
            .lsb_pos(4),
            .access("RO"),
            .volatile(0),
            .reset(4'h1),    // Correct Value 
            .has_reset(1),
            .is_rand(1),
            .individually_accessible(0)
        );
    endfunction
endclass