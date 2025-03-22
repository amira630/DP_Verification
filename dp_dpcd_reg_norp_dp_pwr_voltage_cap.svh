///////////////////////////////////////////////////////////////////////////////
// File:        dp_dpcd_reg_norp_dp_pwr_voltage_cap.svh
// Author:      Amira Atef
// Date:        20-3-2025
// Description: Definition of the NORP & DP_PWR_VOLTAGE_CAP register at address 0_00_04h
//              in the DP DPCD Receiver Capability Field.
///////////////////////////////////////////////////////////////////////////////

class dp_dpcd_reg_norp_dp_pwr_voltage_cap extends uvm_reg;
    `uvm_object_utils(dp_dpcd_reg_norp_dp_pwr_voltage_cap)

    rand uvm_reg_field NORP;

    rand uvm_reg_field CRC_3D_OPTIONS_SUPPORTED;

    rand uvm_reg_field _5V_DP_PWR_CAP;
    
    rand uvm_reg_field _12V_DP_PWR_CAP;

    rand uvm_reg_field _18V_DP_PWR_CAP;

    function new(string name = "dp_dpcd_reg_norp_dp_pwr_voltage_cap");
        super.new(.name(name), .n_bits(8), .has_coverage(UVM_NO_COVERAGE));
    endfunction
  
    virtual function void build();
        NORP = uvm_reg_field::type_id::create(.name("NORP"), .parent(null), .contxt(get_full_name()));
        CRC_3D_OPTIONS_SUPPORTED = uvm_reg_field::type_id::create(.name("CRC_3D_OPTIONS_SUPPORTED"), .parent(null), .contxt(get_full_name()));
        _5V_DP_PWR_CAP = uvm_reg_field::type_id::create(.name("_5V_DP_PWR_CAP"), .parent(null), .contxt(get_full_name()));
        _12V_DP_PWR_CAP = uvm_reg_field::type_id::create(.name("_12V_DP_PWR_CAP"), .parent(null), .contxt(get_full_name()));
        _18V_DP_PWR_CAP = uvm_reg_field::type_id::create(.name("_18V_DP_PWR_CAP"), .parent(null), .contxt(get_full_name()));

        NORP.configure(
            .parent(this),
            .size(1),
            .lsb_pos(0),
            .access("RO"),
            .volatile(0),
            .reset(0),  // Correct Value
            .has_reset(1),
            .is_rand(1),
            .individually_accessible(0)
        );
        CRC_3D_OPTIONS_SUPPORTED.configure(  
            .parent(this),
            .size(1),
            .lsb_pos(1),
            .access("RO"),
            .volatile(0),
            .reset(0),
            .has_reset(1),
            .is_rand(1), 
            .individually_accessible(0)
        );        
        _5V_DP_PWR_CAP.configure(       
            .parent(this),
            .size(1),
            .lsb_pos(5),
            .access("RO"),
            .volatile(0),
            .reset(0),
            .has_reset(1),
            .is_rand(1),
            .individually_accessible(0)
        );        
        _12V_DP_PWR_CAP.configure(        
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
        _18V_DP_PWR_CAP.configure(        
            .parent(this),
            .size(1),
            .lsb_pos(7),
            .access("RO"),
            .volatile(0),
            .reset(0),
            .has_reset(1),
            .is_rand(1),
            .individually_accessible(0)
        );
    endfunction
endclass