///////////////////////////////////////////////////////////////////////////////
// File:        dp_dpcd_reg_guid.svh
// Author:      Amira Atef
// Date:        20-3-2025
// Description: Definition of the GUID register from address 0_00_30h
//              to address 0_00_3Fh in the DP DPCD Receiver Capability Field.
///////////////////////////////////////////////////////////////////////////////

class dp_dpcd_reg_guid extends uvm_reg;
    `uvm_object_utils(dp_dpcd_reg_guid)

    rand uvm_reg_field GUID_OCTET_0;    // 0_00_30h
    
    rand uvm_reg_field GUID_OCTET_1;    // 0_00_31h

    rand uvm_reg_field GUID_OCTET_2;    // 0_00_32h

    rand uvm_reg_field GUID_OCTET_3;    // 0_00_33h

    rand uvm_reg_field GUID_OCTET_4;    // 0_00_34h

    rand uvm_reg_field GUID_OCTET_5;    // 0_00_35h

    rand uvm_reg_field GUID_OCTET_6;    // 0_00_36h

    rand uvm_reg_field GUID_OCTET_7;    // 0_00_37h

    rand uvm_reg_field GUID_OCTET_8;    // 0_00_38h

    rand uvm_reg_field GUID_OCTET_9;    // 0_00_39h

    rand uvm_reg_field GUID_OCTET_A;    // 0_00_3Ah

    rand uvm_reg_field GUID_OCTET_B;    // 0_00_3Bh

    rand uvm_reg_field GUID_OCTET_C;    // 0_00_3Ch

    rand uvm_reg_field GUID_OCTET_D;    // 0_00_3Dh

    rand uvm_reg_field GUID_OCTET_E;    // 0_00_3Eh

    rand uvm_reg_field GUID_OCTET_F;    // 0_00_3Fh

    function new(string name = "dp_dpcd_reg_guid");
        super.new(.name(name), .n_bits(128), .has_coverage(UVM_NO_COVERAGE));
    endfunction
  
    virtual function void build();
        GUID_OCTET_0 = uvm_reg_field::type_id::create(.name("GUID_OCTET_0"), .parent(null), .contxt(get_full_name()));
        GUID_OCTET_1 = uvm_reg_field::type_id::create(.name("GUID_OCTET_1"), .parent(null), .contxt(get_full_name()));
        GUID_OCTET_2 = uvm_reg_field::type_id::create(.name("GUID_OCTET_2"), .parent(null), .contxt(get_full_name()));
        GUID_OCTET_3 = uvm_reg_field::type_id::create(.name("GUID_OCTET_3"), .parent(null), .contxt(get_full_name()));
        GUID_OCTET_4 = uvm_reg_field::type_id::create(.name("GUID_OCTET_4"), .parent(null), .contxt(get_full_name()));
        GUID_OCTET_5 = uvm_reg_field::type_id::create(.name("GUID_OCTET_5"), .parent(null), .contxt(get_full_name()));
        GUID_OCTET_6 = uvm_reg_field::type_id::create(.name("GUID_OCTET_6"), .parent(null), .contxt(get_full_name()));
        GUID_OCTET_7 = uvm_reg_field::type_id::create(.name("GUID_OCTET_7"), .parent(null), .contxt(get_full_name()));
        GUID_OCTET_8 = uvm_reg_field::type_id::create(.name("GUID_OCTET_8"), .parent(null), .contxt(get_full_name()));
        GUID_OCTET_9 = uvm_reg_field::type_id::create(.name("GUID_OCTET_9"), .parent(null), .contxt(get_full_name()));
        GUID_OCTET_A = uvm_reg_field::type_id::create(.name("GUID_OCTET_A"), .parent(null), .contxt(get_full_name()));
        GUID_OCTET_B = uvm_reg_field::type_id::create(.name("GUID_OCTET_B"), .parent(null), .contxt(get_full_name()));
        GUID_OCTET_C = uvm_reg_field::type_id::create(.name("GUID_OCTET_C"), .parent(null), .contxt(get_full_name()));
        GUID_OCTET_D = uvm_reg_field::type_id::create(.name("GUID_OCTET_D"), .parent(null), .contxt(get_full_name()));
        GUID_OCTET_E = uvm_reg_field::type_id::create(.name("GUID_OCTET_E"), .parent(null), .contxt(get_full_name()));
        GUID_OCTET_F = uvm_reg_field::type_id::create(.name("GUID_OCTET_F"), .parent(null), .contxt(get_full_name()));

        GUID_OCTET_0.configure(
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

        GUID_OCTET_1.configure(
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

        GUID_OCTET_2.configure(
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

        GUID_OCTET_3.configure(
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

        GUID_OCTET_4.configure(
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

        GUID_OCTET_5.configure(
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

        GUID_OCTET_6.configure(
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

        GUID_OCTET_7.configure(
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

        GUID_OCTET_8.configure(
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

        GUID_OCTET_9.configure(
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

        GUID_OCTET_A.configure(
            .parent(this),
            .size(8),
            .lsb_pos(80),
            .access("RO"),
            .volatile(0),
            .reset(0),    // Correct Value 
            .has_reset(1),
            .is_rand(1),
            .individually_accessible(1)
        );

        GUID_OCTET_B.configure(
            .parent(this),
            .size(8),
            .lsb_pos(88),
            .access("RO"),
            .volatile(0),
            .reset(0),    // Correct Value 
            .has_reset(1),
            .is_rand(1),
            .individually_accessible(1)
        );

        GUID_OCTET_C.configure(
            .parent(this),
            .size(8),
            .lsb_pos(96),
            .access("RO"),
            .volatile(0),
            .reset(0),    // Correct Value 
            .has_reset(1),
            .is_rand(1),
            .individually_accessible(1)
        );

        GUID_OCTET_D.configure(
            .parent(this),
            .size(8),
            .lsb_pos(104),
            .access("RO"),
            .volatile(0),
            .reset(0),    // Correct Value 
            .has_reset(1),
            .is_rand(1),
            .individually_accessible(1)
        );

        GUID_OCTET_E.configure(
            .parent(this),
            .size(8),
            .lsb_pos(112),
            .access("RO"),
            .volatile(0),
            .reset(0),    // Correct Value 
            .has_reset(1),
            .is_rand(1),
            .individually_accessible(1)
        );

        GUID_OCTET_F.configure(
            .parent(this),
            .size(8),
            .lsb_pos(120),
            .access("RO"),
            .volatile(0),
            .reset(0),    // Correct Value 
            .has_reset(1),
            .is_rand(1),
            .individually_accessible(1)
        );
    endfunction
endclass