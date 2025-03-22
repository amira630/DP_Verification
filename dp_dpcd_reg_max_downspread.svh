///////////////////////////////////////////////////////////////////////////////
// File:        dp_dpcd_reg_max_downspread.svh
// Author:      Amira Atef
// Date:        20-3-2025
// Description: Definition of the MAX_DOWNSPREAD register at address 0_00_03h
//              in the DP DPCD Receiver Capability Field.
///////////////////////////////////////////////////////////////////////////////

class dp_dpcd_reg_max_downspread extends uvm_reg;
    `uvm_object_utils(dp_dpcd_reg_max_downspread)

    rand uvm_reg_field MAX_DOWNSPREAD;

    rand uvm_reg_field STREAM_REGENERATION_STATUS_CAPABILITY;

    rand uvm_reg_field NO_AUX_TRANSACTION_LINK_TRAINING;
    
    rand uvm_reg_field TPS4_SUPPORTED;

    function new(string name = "dp_dpcd_reg_max_downspread");
        super.new(.name(name), .n_bits(8), .has_coverage(UVM_NO_COVERAGE));
    endfunction
  
    virtual function void build();
        MAX_DOWNSPREAD = uvm_reg_field::type_id::create(.name("MAX_DOWNSPREAD"), .parent(null), .contxt(get_full_name()));
        STREAM_REGENERATION_STATUS_CAPABILITY = uvm_reg_field::type_id::create(.name("STREAM_REGENERATION_STATUS_CAPABILITY"), .parent(null), .contxt(get_full_name()));
        NO_AUX_TRANSACTION_LINK_TRAINING = uvm_reg_field::type_id::create(.name("NO_AUX_TRANSACTION_LINK_TRAINING"), .parent(null), .contxt(get_full_name()));
        TPS4_SUPPORTED = uvm_reg_field::type_id::create(.name("TPS4_SUPPORTED"), .parent(null), .contxt(get_full_name()));

        MAX_DOWNSPREAD.configure(
            .parent(this),
            .size(1),
            .lsb_pos(0),
            .access("RO"),
            .volatile(0),
            .reset(1),      // Correct Value
            .has_reset(1),
            .is_rand(1),
            .individually_accessible(0)
        );
        STREAM_REGENERATION_STATUS_CAPABILITY.configure(    // COME BACK HERE I DONT KNOW WHAT IT DOES YET
            .parent(this),
            .size(1),
            .lsb_pos(1),
            .access("RO"),
            .volatile(0),
            .reset(0), // IDK
            .has_reset(0), // IDK
            .is_rand(0), // IDK
            .individually_accessible(0)
        );        
        NO_AUX_TRANSACTION_LINK_TRAINING.configure(       
            .parent(this),
            .size(1),
            .lsb_pos(6),
            .access("RO"),
            .volatile(0),
            .reset(0),
            .has_reset(1),
            .is_rand(1),
            .individually_accessible(0)
        );        
        TPS4_SUPPORTED.configure(                   // Should be supported if DPRX is capable of supporting upto HBR3
            .parent(this),
            .size(1),
            .lsb_pos(7),
            .access("RO"),
            .volatile(0),
            .reset(1),  // Correct Value
            .has_reset(1),
            .is_rand(1),
            .individually_accessible(0)
        );
    endfunction
endclass