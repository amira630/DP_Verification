///////////////////////////////////////////////////////////////////////////////
// File:        dp_dpcd_reg_sink_video_fallback_formats.svh
// Author:      Amira Atef
// Date:        20-3-2025
// Description: Definition of the SINK_VIDEO_FALLBACK_FORMATS register at address 0_00_20h
//              in the DP DPCD Receiver Capability Field.
///////////////////////////////////////////////////////////////////////////////

class dp_dpcd_reg_sink_video_fallback_formats extends uvm_reg;
    `uvm_object_utils(dp_dpcd_reg_sink_video_fallback_formats)

    rand uvm_reg_field _1024x768_AT_60HZ_24BPP_SUPPORT;
    
    rand uvm_reg_field _1280x720_AT_60HZ_24BPP_SUPPORT;

    rand uvm_reg_field _1920x1080_AT_60HZ_24BPP_SUPPORT;

    function new(string name = "dp_dpcd_reg_sink_video_fallback_formats");
        super.new(.name(name), .n_bits(8), .has_coverage(UVM_NO_COVERAGE));
    endfunction
  
    virtual function void build();
        _1024x768_AT_60HZ_24BPP_SUPPORT = uvm_reg_field::type_id::create(.name("_1024x768_AT_60HZ_24BPP_SUPPORT"), .parent(null), .contxt(get_full_name()));
        _1280x720_AT_60HZ_24BPP_SUPPORT = uvm_reg_field::type_id::create(.name("_1280x720_AT_60HZ_24BPP_SUPPORT"), .parent(null), .contxt(get_full_name()));
        _1920x1080_AT_60HZ_24BPP_SUPPORT = uvm_reg_field::type_id::create(.name("_1920x1080_AT_60HZ_24BPP_SUPPORT"), .parent(null), .contxt(get_full_name()));
        
        _1024x768_AT_60HZ_24BPP_SUPPORT.configure(
            .parent(this),
            .size(1),
            .lsb_pos(0),
            .access("RO"),
            .volatile(0),
            .reset(0),    // Correct Value 
            .has_reset(1),
            .is_rand(1),
            .individually_accessible(0)
        );

        _1280x720_AT_60HZ_24BPP_SUPPORT.configure(
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

        _1920x1080_AT_60HZ_24BPP_SUPPORT.configure(
            .parent(this),
            .size(1),
            .lsb_pos(2),
            .access("RO"),
            .volatile(0),
            .reset(1),      // Correct Value
            .has_reset(1),
            .is_rand(1),
            .individually_accessible(0)
        );
    endfunction
endclass