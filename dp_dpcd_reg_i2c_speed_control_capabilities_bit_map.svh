///////////////////////////////////////////////////////////////////////////////
// File:        dp_dpcd_reg_i2c_speed_control_capabilities_bit_map.svh
// Author:      Amira Atef
// Date:        20-3-2025
// Description: Definition of the I2C Speed Control Capabilities Bit Map register at address 0_00_0Ch
//              in the DP DPCD Receiver Capability Field.
///////////////////////////////////////////////////////////////////////////////

class dp_dpcd_reg_i2c_speed_control_capabilities_bit_map extends uvm_reg;
    `uvm_object_utils(dp_dpcd_reg_i2c_speed_control_capabilities_bit_map)

    rand uvm_reg_field I2C_SPEED_CONTROL_CAPABILITIES_BIT_MAP;

    function new(string name = "dp_dpcd_reg_i2c_speed_control_capabilities_bit_map");
        super.new(.name(name), .n_bits(8), .has_coverage(UVM_NO_COVERAGE));
    endfunction
  
    virtual function void build();
        I2C_SPEED_CONTROL_CAPABILITIES_BIT_MAP = uvm_reg_field::type_id::create(.name("I2C_SPEED_CONTROL_CAPABILITIES_BIT_MAP"), .parent(null), .contxt(get_full_name()));

        I2C_SPEED_CONTROL_CAPABILITIES_BIT_MAP.configure(
            .parent(this),
            .size(8),
            .lsb_pos(0),
            .access("RO"),
            .volatile(0),
            .reset(8'h08),  
            .has_reset(1),
            .is_rand(1),
            .individually_accessible(1)
        );
    endfunction
endclass