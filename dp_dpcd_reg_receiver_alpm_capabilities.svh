///////////////////////////////////////////////////////////////////////////////
// File:        dp_dpcd_reg_receiver_alpm_capabilities.svh
// Author:      Amira Atef
// Date:        20-3-2025
// Description: Definition of the RECEIVER_ALPM_CAPABILITIES register at address 0_00_2Eh
//              in the DP DPCD Receiver Capability Field.
///////////////////////////////////////////////////////////////////////////////

class dp_dpcd_reg_receiver_alpm_capabilities extends uvm_reg;
    `uvm_object_utils(dp_dpcd_reg_receiver_alpm_capabilities)

    rand uvm_reg_field AUX_WAKE_ALPM_CAP;     

    rand uvm_reg_field PM_STATE_2A_SUPPORT;  

    rand uvm_reg_field AUX_LESS_ALPM_CAP;      

    rand uvm_reg_field AUX_LESS_ALPM_ML_PHY_SLEEP_STATUS_SUPPORTED; 

    function new(string name = "dp_dpcd_reg_receiver_alpm_capabilities");
        super.new(.name(name), .n_bits(8), .has_coverage(UVM_NO_COVERAGE));
    endfunction
  
    virtual function void build();
        AUX_WAKE_ALPM_CAP = uvm_reg_field::type_id::create(.name("AUX_WAKE_ALPM_CAP"), .parent(null), .contxt(get_full_name()));
        PM_STATE_2A_SUPPORT = uvm_reg_field::type_id::create(.name("PM_STATE_2A_SUPPORT"), .parent(null), .contxt(get_full_name()));
        AUX_LESS_ALPM_CAP = uvm_reg_field::type_id::create(.name("AUX_LESS_ALPM_CAP"), .parent(null), .contxt(get_full_name()));
        AUX_LESS_ALPM_ML_PHY_SLEEP_STATUS_SUPPORTED = uvm_reg_field::type_id::create(.name("AUX_LESS_ALPM_ML_PHY_SLEEP_STATUS_SUPPORTED"), .parent(null), .contxt(get_full_name()));
 
        AUX_WAKE_ALPM_CAP.configure(
            .parent(this),
            .size(1),
            .lsb_pos(0),
            .access("RO"),
            .volatile(0),
            .reset(0),    // Correct Value 
            .has_reset(1),
            .is_rand(0),
            .individually_accessible(0)
        );

        PM_STATE_2A_SUPPORT.configure(
            .parent(this),
            .size(1),
            .lsb_pos(1),
            .access("RO"),
            .volatile(0),
            .reset(0),    // Correct Value 
            .has_reset(1),
            .is_rand(0),
            .individually_accessible(0)
        );

        AUX_LESS_ALPM_CAP.configure(
            .parent(this),
            .size(1),
            .lsb_pos(2),
            .access("RO"),
            .volatile(0),
            .reset(0),    // Correct Value 
            .has_reset(1),
            .is_rand(1),
            .individually_accessible(0)
        );

        AUX_LESS_ALPM_ML_PHY_SLEEP_STATUS_SUPPORTED.configure(
            .parent(this),
            .size(1),
            .lsb_pos(3),
            .access("RO"),
            .volatile(0),
            .reset(0),    // Correct Value 
            .has_reset(1),
            .is_rand(1),
            .individually_accessible(0)
        );
    endfunction
endclass