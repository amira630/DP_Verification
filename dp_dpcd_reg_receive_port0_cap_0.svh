///////////////////////////////////////////////////////////////////////////////
// File:        dp_dpcd_reg_receive_port0_cap_0.svh
// Author:      Amira Atef
// Date:        20-3-2025
// Description: Definition of the RECEIVE_PORT0_CAP_0 register at address 0_00_08h
//              in the DP DPCD Receiver Capability Field.
///////////////////////////////////////////////////////////////////////////////

class dp_dpcd_reg_receive_port0_cap_0 extends uvm_reg;
    `uvm_object_utils(dp_dpcd_reg_receive_port0_cap_0)

    rand uvm_reg_field LOCAL_EDID_PRESENT;

    rand uvm_reg_field ASSOCIATED_TO_PRECEDING_PORT;

    rand uvm_reg_field HBLANK_EXPANSION_CAPABLE;

    rand uvm_reg_field BUFFER_SIZE_UNIT;

    rand uvm_reg_field BUFFER_SIZE_PER_PORT;

    rand uvm_reg_field HBLANK_REDUCTION_CAPABLE;

    function new(string name = "dp_dpcd_reg_receive_port0_cap_0");
        super.new(.name(name), .n_bits(8), .has_coverage(UVM_NO_COVERAGE));
    endfunction
  
    virtual function void build();
        LOCAL_EDID_PRESENT = uvm_reg_field::type_id::create(.name("LOCAL_EDID_PRESENT"), .parent(null), .contxt(get_full_name()));
        ASSOCIATED_TO_PRECEDING_PORT = uvm_reg_field::type_id::create(.name("ASSOCIATED_TO_PRECEDING_PORT"), .parent(null), .contxt(get_full_name()));
        HBLANK_EXPANSION_CAPABLE = uvm_reg_field::type_id::create(.name("HBLANK_EXPANSION_CAPABLE"), .parent(null), .contxt(get_full_name()));
        BUFFER_SIZE_UNIT = uvm_reg_field::type_id::create(.name("BUFFER_SIZE_UNIT"), .parent(null), .contxt(get_full_name()));
        BUFFER_SIZE_PER_PORT = uvm_reg_field::type_id::create(.name("BUFFER_SIZE_PER_PORT"), .parent(null), .contxt(get_full_name()));
        HBLANK_REDUCTION_CAPABLE = uvm_reg_field::type_id::create(.name("HBLANK_REDUCTION_CAPABLE"), .parent(null), .contxt(get_full_name()));

        LOCAL_EDID_PRESENT.configure(
            .parent(this),
            .size(1),
            .lsb_pos(1),
            .access("RO"),
            .volatile(0),
            .reset(1),  // Correct Value  
            .has_reset(1),
            .is_rand(1),
            .individually_accessible(0)
        );
        
        ASSOCIATED_TO_PRECEDING_PORT.configure(  
            .parent(this),
            .size(1),
            .lsb_pos(2),
            .access("RO"),
            .volatile(0),
            .reset(0),      // Correct Value
            .has_reset(1),
            .is_rand(1), 
            .individually_accessible(0)
        );    
        /////////// IDK MUST READ MORE /////////////
        HBLANK_EXPANSION_CAPABLE.configure(  
            .parent(this),
            .size(1),
            .lsb_pos(3),
            .access("RO"),
            .volatile(0),
            .reset(1),      // Correct Value
            .has_reset(1),
            .is_rand(1), 
            .individually_accessible(0)
        );  

        BUFFER_SIZE_UNIT.configure(  
            .parent(this),
            .size(1),
            .lsb_pos(4),
            .access("RO"),
            .volatile(0),
            .reset(1),      // Correct Value
            .has_reset(1),
            .is_rand(1), 
            .individually_accessible(0)
        ); 

        BUFFER_SIZE_PER_PORT.configure(  
            .parent(this),
            .size(1),
            .lsb_pos(5),
            .access("RO"),
            .volatile(0),
            .reset(1),      // Correct Value
            .has_reset(1),
            .is_rand(1), 
            .individually_accessible(0)
        ); 

        HBLANK_REDUCTION_CAPABLE.configure(  
            .parent(this),
            .size(1),
            .lsb_pos(6),
            .access("RO"),
            .volatile(0),
            .reset(0),      // Correct Value
            .has_reset(1),
            .is_rand(1), 
            .individually_accessible(0)
        ); 
    endfunction
endclass