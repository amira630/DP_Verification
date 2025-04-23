///////////////////////////////////////////////////////////////////////////////
// File:        dp_dpcd_reg_number_of_audio_endpoints.svh
// Author:      Amira Atef
// Date:        20-3-2025
// Description: Definition of the NUMBER_OF_AUDIO_ENDPOINTS register at address 0_00_22h
//              in the DP DPCD Receiver Capability Field.
///////////////////////////////////////////////////////////////////////////////

class dp_dpcd_reg_number_of_audio_endpoints extends uvm_reg;
    `uvm_object_utils(dp_dpcd_reg_number_of_audio_endpoints)

    rand uvm_reg_field NUMBER_OF_AUDIO_ENDPOINTS;

    function new(string name = "dp_dpcd_reg_number_of_audio_endpoints");
        super.new(.name(name), .n_bits(8), .has_coverage(UVM_NO_COVERAGE));
    endfunction
  
    virtual function void build();
        NUMBER_OF_AUDIO_ENDPOINTS = uvm_reg_field::type_id::create(.name("NUMBER_OF_AUDIO_ENDPOINTS"), .parent(null), .contxt(get_full_name()));

        NUMBER_OF_AUDIO_ENDPOINTS.configure(
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
    endfunction
endclass