///////////////////////////////////////////////////////////////////////////////
// File:        dp_reg_sequence.svh
// Author:      Amira Atef
// Date:        22-03-2025
// Description: Sequence for configuring the DP Source
///////////////////////////////////////////////////////////////////////////////
  class dp_reg_sequence extends uvm_reg_sequence;
    
    dp_dpcd_reg_block reg_block;

    `uvm_object_utils(dp_reg_sequence)
    
    function new(string name = "dp_reg_sequence");
      super.new(name);
    endfunction
    
    virtual task body();
      uvm_status_e status;
      uvm_reg_data_t data;
      
      //reg_block.CTRL.write(status, 32'h00000202);
      
      //reg_block.CTRL.OFFSET.set(2);
      //reg_block.CTRL.SIZE.set(2);
      
      void'(reg_block.RECEIVER_CAPABILITY_FIELD.MAX_LANE_COUNT.randomize());
      
      reg_block.RECEIVER_CAPABILITY_FIELD.MAX_LANE_COUNT.update(status);
      
      reg_block.RECEIVER_CAPABILITY_FIELD.MAX_LANE_COUNT.read(status, data);
      
    endtask
    
  endclass