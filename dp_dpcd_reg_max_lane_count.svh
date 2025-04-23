///////////////////////////////////////////////////////////////////////////////
// File:        dp_dpcd_reg_max_lane_count.svh
// Author:      Amira Atef
// Date:        20-3-2025
// Description: Definition of the MAX_LANE_COUNT register at address 0_00_02h
//              in the DP DPCD Receiver Capability Field.
///////////////////////////////////////////////////////////////////////////////

class dp_dpcd_reg_max_lane_count extends uvm_reg;
    `uvm_object_utils(dp_dpcd_reg_max_lane_count)

    rand uvm_reg_field MAX_LANE_COUNT;

    rand uvm_reg_field POST_LT_ADJ_REQ_SUPPORTED;

    rand uvm_reg_field TPS3_SUPPORTED;
    
    rand uvm_reg_field ENHANCED_FRAME_CAP;

    function new(string name = "dp_dpcd_reg_max_lane_count");
        super.new(.name(name), .n_bits(8), .has_coverage(UVM_NO_COVERAGE));
    endfunction
  
    virtual function void build();
        MAX_LANE_COUNT = uvm_reg_field::type_id::create(.name("MAX_LANE_COUNT"), .parent(null), .contxt(get_full_name()));
        POST_LT_ADJ_REQ_SUPPORTED = uvm_reg_field::type_id::create(.name("POST_LT_ADJ_REQ_SUPPORTED"), .parent(null), .contxt(get_full_name()));
        TPS3_SUPPORTED = uvm_reg_field::type_id::create(.name("TPS3_SUPPORTED"), .parent(null), .contxt(get_full_name()));
        ENHANCED_FRAME_CAP = uvm_reg_field::type_id::create(.name("ENHANCED_FRAME_CAP"), .parent(null), .contxt(get_full_name()));

        MAX_LANE_COUNT.configure(
            .parent(this),
            .size(5),
            .lsb_pos(0),
            .access("RO"),
            .volatile(0),
            .reset(0),
            .has_reset(0),
            .is_rand(1),
            .individually_accessible(0)
        );
        POST_LT_ADJ_REQ_SUPPORTED.configure(    // Should be supported if TPS4 is not supported by the DPRX
            .parent(this),
            .size(1),
            .lsb_pos(5),
            .access("RO"),
            .volatile(0),
            .reset(0),  // Correct Value
            .has_reset(1),
            .is_rand(1),
            .individually_accessible(0)
        );        
        TPS3_SUPPORTED.configure(       // Should be supported if DPRX is capable of supporting upto HBR2 but not HBR3
            .parent(this),
            .size(1),
            .lsb_pos(6),
            .access("RO"),
            .volatile(0),
            .reset(0),
            .has_reset(0),
            .is_rand(1),
            .individually_accessible(0)
        );        
        ENHANCED_FRAME_CAP.configure(
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