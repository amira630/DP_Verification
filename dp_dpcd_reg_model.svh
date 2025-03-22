///////////////////////////////////////////////////////////////////////////////
// File:        dp_dpcd_reg_block.svh
// Author:      Amira Atef
// Date:        22-03-2025
// Description: DPCD Register Model
///////////////////////////////////////////////////////////////////////////////
class dp_dpcd_reg_model extends uvm_component;
    `uvm_component_utils(dp_dpcd_reg_model)
    
    //Register block
    dp_dpcd_reg_block reg_block;

    function new(string name = "dp_dpcd_reg_model", uvm_component null);
        super.new(name, parent);  
    endfunction

    virtual function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        if(reg_block == null) begin
            reg_block = dp_dpcd_reg_block::type_id::create("reg_block", this);
            
            reg_block.build();
            reg_block.lock_model(); //to prevent any further modifications to the register model after the testbench has finished building it
        end
    endfunction

endclass