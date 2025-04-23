///////////////////////////////////////////////////////////////////////////////
// File:        dp_dpcd_reg_av_sync_data_block.svh
// Author:      Amira Atef
// Date:        20-3-2025
// Description: Definition of the AV_SYNC_DATA_BLOCK register block starting from address 0_00_24h
//              to address 0_00_2Dh in the DP DPCD Receiver Capability Field.
///////////////////////////////////////////////////////////////////////////////

class dp_dpcd_reg_av_sync_data_block extends uvm_reg;
    `uvm_object_utils(dp_dpcd_reg_av_sync_data_block)

    rand uvm_reg_field AUD_DEC_LAT7_0;      // 0_00_24h

    rand uvm_reg_field AUD_DEC_LAT15_8;     // 0_00_25h

    rand uvm_reg_field AUD_PP_LAT7_0;       // 0_00_26h

    rand uvm_reg_field AUD_PP_LAT15_8;      // 0_00_27h

    rand uvm_reg_field VID_INTER_LAT7_0;    // 0_00_28h

    rand uvm_reg_field VID_PROG_LAT7_0;     // 0_00_29h

    rand uvm_reg_field REP_LAT7_0;          // 0_00_2Ah

    rand uvm_reg_field AUD_DEL_INS7_0;     // 0_00_2Bh

    rand uvm_reg_field AUD_DEL_INS15_8;     // 0_00_2Ch

    rand uvm_reg_field AUD_DEL_INS23_16;    // 0_00_2Dh

    function new(string name = "dp_dpcd_reg_av_sync_data_block");
        super.new(.name(name), .n_bits(80), .has_coverage(UVM_NO_COVERAGE));
    endfunction
  
    virtual function void build();
        AUD_DEC_LAT7_0 = uvm_reg_field::type_id::create(.name("AUD_DEC_LAT7_0"), .parent(null), .contxt(get_full_name()));
        AUD_DEC_LAT15_8 = uvm_reg_field::type_id::create(.name("AUD_DEC_LAT15_8"), .parent(null), .contxt(get_full_name()));
        AUD_PP_LAT7_0 = uvm_reg_field::type_id::create(.name("AUD_PP_LAT7_0"), .parent(null), .contxt(get_full_name()));
        AUD_PP_LAT15_8 = uvm_reg_field::type_id::create(.name("AUD_PP_LAT15_8"), .parent(null), .contxt(get_full_name()));
        VID_INTER_LAT7_0 = uvm_reg_field::type_id::create(.name("VID_INTER_LAT7_0"), .parent(null), .contxt(get_full_name()));
        VID_PROG_LAT7_0 = uvm_reg_field::type_id::create(.name("VID_PROG_LAT7_0"), .parent(null), .contxt(get_full_name()));
        REP_LAT7_0 = uvm_reg_field::type_id::create(.name("REP_LAT7_0"), .parent(null), .contxt(get_full_name()));
        AUD_DEL_INS7_0 = uvm_reg_field::type_id::create(.name("AUD_DEL_INS7_0"), .parent(null), .contxt(get_full_name()));
        AUD_DEL_INS15_8 = uvm_reg_field::type_id::create(.name("AUD_DEL_INS15_8"), .parent(null), .contxt(get_full_name()));
        AUD_DEL_INS23_16 = uvm_reg_field::type_id::create(.name("AUD_DEL_INS23_16"), .parent(null), .contxt(get_full_name()));

        AUD_DEC_LAT7_0.configure(
            .parent(this),
            .size(8),
            .lsb_pos(0),
            .access("RO"),
            .volatile(0),
            .reset(0),    // Correct Value 
            .has_reset(1),
            .is_rand(1),
            .individually_accessible(1)
        );

        AUD_DEC_LAT15_8.configure(
            .parent(this),
            .size(8),
            .lsb_pos(8),
            .access("RO"),
            .volatile(0),
            .reset(0),    // Correct Value 
            .has_reset(1),
            .is_rand(1),
            .individually_accessible(1)
        );

        AUD_PP_LAT7_0.configure(
            .parent(this),
            .size(8),
            .lsb_pos(16),
            .access("RO"),
            .volatile(0),
            .reset(0),    // Correct Value 
            .has_reset(1),
            .is_rand(1),
            .individually_accessible(1)
        );

        AUD_PP_LAT15_8.configure(
            .parent(this),
            .size(8),
            .lsb_pos(24),
            .access("RO"),
            .volatile(0),
            .reset(0),    // Correct Value 
            .has_reset(1),
            .is_rand(1),
            .individually_accessible(1)
        );

        VID_INTER_LAT7_0.configure(
            .parent(this),
            .size(8),
            .lsb_pos(32),
            .access("RO"),
            .volatile(0),
            .reset(0),    // Correct Value 
            .has_reset(1),
            .is_rand(1),
            .individually_accessible(1)
        );

        VID_PROG_LAT7_0.configure(
            .parent(this),
            .size(8),
            .lsb_pos(40),
            .access("RO"),
            .volatile(0),
            .reset(0),    // Correct Value 
            .has_reset(1),
            .is_rand(1),
            .individually_accessible(1)
        );

        REP_LAT7_0.configure(
            .parent(this),
            .size(8),
            .lsb_pos(48),
            .access("RO"),
            .volatile(0),
            .reset(0),    // Correct Value 
            .has_reset(1),
            .is_rand(1),
            .individually_accessible(1)
        );

        AUD_DEL_INS7_0.configure(
            .parent(this),
            .size(8),
            .lsb_pos(56),
            .access("RO"),
            .volatile(0),
            .reset(0),    // Correct Value 
            .has_reset(1),
            .is_rand(1),
            .individually_accessible(1)
        );

        AUD_DEL_INS15_8.configure(
            .parent(this),
            .size(8),
            .lsb_pos(64),
            .access("RO"),
            .volatile(0),
            .reset(0),    // Correct Value 
            .has_reset(1),
            .is_rand(1),
            .individually_accessible(1)
        );

        AUD_DEL_INS23_16.configure(
            .parent(this),
            .size(8),
            .lsb_pos(72),
            .access("RO"),
            .volatile(0),
            .reset(0),    // Correct Value 
            .has_reset(1),
            .is_rand(1),
            .individually_accessible(1)
        );
    endfunction
endclass