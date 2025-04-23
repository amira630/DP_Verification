///////////////////////////////////////////////////////////////////////////////
// File:        dp_dpcd_reg_dpcd_rev.svh
// Author:      Amira Atef
// Date:        20-3-2025
// Description: Definition of the DPCD_REV register at address 0_00_00h
//              in the DP DPCD Receiver Capability Field.
///////////////////////////////////////////////////////////////////////////////

class dp_dpcd_reg_dpcd_rev extends uvm_reg;
  `uvm_object_utils(dp_dpcd_reg_dpcd_rev)

  rand uvm_reg_field MINOR_REVISION_NUMBER;

  rand uvm_reg_field MAJOR_REVISION_NUMBER;

  function new(string name = "dp_dpcd_reg_dpcd_rev");
    super.new(.name(name), .n_bits(8), .has_coverage(UVM_NO_COVERAGE));
  endfunction

  virtual function void build();
    MINOR_REVISION_NUMBER = uvm_reg_field::type_id::create(.name("MINOR_REVISION_NUMBER"), .parent(null), .contxt(get_full_name()));
    MAJOR_REVISION_NUMBER = uvm_reg_field::type_id::create(.name("MAJOR_REVISION_NUMBER"), .parent(null), .contxt(get_full_name()));
    
    MINOR_REVISION_NUMBER.configure(
      .parent(this),
      .size(4),
      .lsb_pos(0),
      .access("RO"),
      .volatile(0),
      .reset(4'h4),    // Correct Value
      .has_reset(0),
      .is_rand(1),  
      .individually_accessible(0)
    );

    MAJOR_REVISION_NUMBER.configure(
      .parent(this),
      .size(4),
      .lsb_pos(4),
      .access("RO"),
      .volatile(0),
      .reset(4'h1), // Correct Value
      .has_reset(0),
      .is_rand(1),
      .individually_accessible(0)
    );
  endfunction
endclass