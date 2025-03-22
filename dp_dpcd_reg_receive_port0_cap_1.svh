///////////////////////////////////////////////////////////////////////////////
// File:        dp_dpcd_reg_receive_port0_cap_1.svh
// Author:      Amira Atef
// Date:        20-3-2025
// Description: Definition of the RECEIVE_PORT0_CAP_1 register at address 0_00_09h
//              in the DP DPCD Receiver Capability Field.
///////////////////////////////////////////////////////////////////////////////

class dp_dpcd_reg_receive_port0_cap_1 extends uvm_reg;
    `uvm_object_utils(dp_dpcd_reg_receive_port0_cap_1)

    rand uvm_reg_field BUFFER_SIZE;

    function new(string name = "dp_dpcd_reg_receive_port0_cap_1");
        super.new(.name(name), .n_bits(8), .has_coverage(UVM_NO_COVERAGE));
    endfunction
  
    virtual function void build();
        BUFFER_SIZE = uvm_reg_field::type_id::create(.name("BUFFER_SIZE"), .parent(null), .contxt(get_full_name()));

        /////////// IDK MUST READ MORE /////////////
        BUFFER_SIZE.configure(
            .parent(this),
            .size(8),
            .lsb_pos(0),
            .access("RO"),
            .volatile(0),
            .reset(8'h0F),  // IDK 
            .has_reset(1),
            .is_rand(1),
            .individually_accessible(1)
        );       
    endfunction
endclass