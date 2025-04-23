///////////////////////////////////////////////////////////////////////////////
// File:        dp_dpcd_reg_8b10b_training_aux_rd_interval.svh
// Author:      Amira Atef
// Date:        20-3-2025
// Description: Definition of the 8b10b_TRAINING_AUX_RD_INTERVAL register at address 0_00_0Eh
//              in the DP DPCD Receiver Capability Field.
///////////////////////////////////////////////////////////////////////////////

class dp_dpcd_reg_8b10b_training_aux_rd_interval extends uvm_reg;
    `uvm_object_utils(dp_dpcd_reg_8b10b_training_aux_rd_interval)

    rand uvm_reg_field TRAINING_AUX_RD_INTERVAL;
    rand uvm_reg_field EXTENDED_RECEIVER_CAPABILITY_FIELD_PRESENT;

    function new(string name = "dp_dpcd_reg_8b10b_training_aux_rd_interval");
        super.new(.name(name), .n_bits(8), .has_coverage(UVM_NO_COVERAGE));
    endfunction
  
    virtual function void build();
        TRAINING_AUX_RD_INTERVAL = uvm_reg_field::type_id::create(.name("TRAINING_AUX_RD_INTERVAL"), .parent(null), .contxt(get_full_name()));
        EXTENDED_RECEIVER_CAPABILITY_FIELD_PRESENT = uvm_reg_field::type_id::create(.name("EXTENDED_RECEIVER_CAPABILITY_FIELD_PRESENT"), .parent(null), .contxt(get_full_name()));

        TRAINING_AUX_RD_INTERVAL.configure(
            .parent(this),
            .size(7),
            .lsb_pos(0),
            .access("RO"),
            .volatile(0),
            .reset(7'h00),  
            .has_reset(1),
            .is_rand(1),
            .individually_accessible(0)
        );

        EXTENDED_RECEIVER_CAPABILITY_FIELD_PRESENT.configure(
            .parent(this),
            .size(1),
            .lsb_pos(7),
            .access("RO"),
            .volatile(0),
            .reset(1),      // Correct Value
            .has_reset(1),
            .is_rand(1),
            .individually_accessible(0)
        );
    endfunction
endclass