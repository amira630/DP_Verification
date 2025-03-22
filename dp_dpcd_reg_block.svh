///////////////////////////////////////////////////////////////////////////////
// File:        dp_dpcd_reg_block.svh
// Author:      Amira Atef
// Date:        22-03-2025
// Description: DPCD Register block
///////////////////////////////////////////////////////////////////////////////
  class dp_dpcd_reg_block extends uvm_reg_block;    
    `uvm_object_utils(dp_dpcd_reg_block)

    // Declaring the DPCD Register Fields of type register file
    rand dp_dpcd_reg_file_receiver_capability RECEIVER_CAPABILITY_FIELD;

    function new(string name = "dp_dpcd_reg_block");
      super.new(name, UVM_NO_COVERAGE);
    endfunction
    
    virtual function void build();
        // Create and initialize the default register map
        default_map = create_map(
            .name("dpcd_map"),
            .base_addr(20'h0_00_00),
            .n_bytes(1),
            .endian(UVM_LITTLE_ENDIAN),
            .byte_addressing(1)
        );

        // Create Register Files  
        RECEIVER_CAPABILITY_FIELD= dp_dpcd_reg_file_receiver_capability::type_id::create(.name("RECEIVER_CAPABILITY_FIELD"),.parent(null),.contxt(get_full_name()));

        // Configure Register Files
        RECEIVER_CAPABILITY_FIELD.configure(this, null, "");

        // Build Register Files
        RECEIVER_CAPABILITY_FIELD.build();

        // Map the registers inside the register files
        RECEIVER_CAPABILITY_FIELD.map(this.default_map, 20'h0_00_00);
    endfunction
  endclass