///////////////////////////////////////////////////////////////////////////////
// File:        dp_dpcd_reg_adapter_cap.svh
// Author:      Amira Atef
// Date:        20-3-2025
// Description: Definition of the ADAPTER_CAP register at address 0_00_0Fh
//              in the DP DPCD Receiver Capability Field.
///////////////////////////////////////////////////////////////////////////////

class dp_dpcd_reg_adapter_cap extends uvm_reg;
    `uvm_object_utils(dp_dpcd_reg_adapter_cap)

    rand uvm_reg_field FORCE_LOAD_SENSE_CAP;
    
    rand uvm_reg_field ALTERNATE_I2C_PATTERN_CAP;

    function new(string name = "dp_dpcd_reg_adapter_cap");
        super.new(.name(name), .n_bits(8), .has_coverage(UVM_NO_COVERAGE));
    endfunction
  
    virtual function void build();
        FORCE_LOAD_SENSE_CAP = uvm_reg_field::type_id::create(.name("FORCE_LOAD_SENSE_CAP"), .parent(null), .contxt(get_full_name()));
        ALTERNATE_I2C_PATTERN_CAP = uvm_reg_field::type_id::create(.name("ALTERNATE_I2C_PATTERN_CAP"), .parent(null), .contxt(get_full_name()));

        FORCE_LOAD_SENSE_CAP.configure(
            .parent(this),
            .size(1),
            .lsb_pos(0),
            .access("RO"),
            .volatile(0),
            .reset(0),    // IDK  
            .has_reset(1),
            .is_rand(1),
            .individually_accessible(0)
        );

        ALTERNATE_I2C_PATTERN_CAP.configure(
            .parent(this),
            .size(1),
            .lsb_pos(1),
            .access("RO"),
            .volatile(0),
            .reset(0),      // IDK
            .has_reset(1),
            .is_rand(1),
            .individually_accessible(0)
        );
    endfunction
endclass