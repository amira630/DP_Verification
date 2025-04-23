///////////////////////////////////////////////////////////////////////////////
// File:        dp_reg_sequence.svh
// Author:      Amira Atef
// Date:        22-03-2025
// Description: Sequence for configuring the DP Source
///////////////////////////////////////////////////////////////////////////////
class dp_reg_sequence extends uvm_reg_sequence(dp_sink_base_sequence);  
  `uvm_object_utils(dp_reg_sequence)

  dp_dpcd_reg_block reg_block;
  
  function new(string name = "dp_reg_sequence");
    super.new(name);
  endfunction
  
  virtual task body();
    uvm_status_e status;
    uvm_reg_data_t data;
    
    //reg_block.CTRL.write(status, 32'h00000202);
    
    //reg_block.CTRL.OFFSET.set(2);
    //reg_block.CTRL.SIZE.set(2);
    
    // writes in the value and then the desired value
    void'(reg_block.RECEIVER_CAPABILITY_FIELD.MAX_LANE_COUNT.MAX_LANE_COUNT.randomize());
    
    // geneates a write transaction based on the randomized desired values and updates the mirror value
    reg_block.RECEIVER_CAPABILITY_FIELD.MAX_LANE_COUNT.MAX_LANE_COUNT.update(status);
    
    reg_block.RECEIVER_CAPABILITY_FIELD.MAX_LANE_COUNT.MAX_LANE_COUNT.read(status, data);
  endtask
  
endclass



// class reg_access_sequence extends uvm_reg_sequence;
//   // Register model - will be set by the test
//   my_reg_block reg_model;
  
//   // Control flags for which test sections to execute
//   bit do_basic_access = 1;
//   bit do_register_files = 1;
//   bit do_mem_access = 1;
//   bit do_built_in_tests = 1;
  
//   // Random values to write
//   rand bit[31:0] ctrl_value;
//   rand bit[31:0] data_values[4];
  
//   // Constraints to make random values more interesting
//   constraint value_constraints {
//     ctrl_value inside {[1:255]};
//     foreach(data_values[i]) {
//       data_values[i] != 0;
//     }
//   }
  
//   `uvm_object_utils(reg_access_sequence)
  
//   function new(string name = "reg_access_sequence");
//     super.new(name);
//   endfunction
  
//   virtual task body();
//     uvm_status_e status;
//     uvm_reg_data_t read_data;
    
//     if (reg_model == null) begin
//       `uvm_fatal("REG_SEQ", "Register model handle is null")
//       return;
//     end
    
//     `uvm_info("REG_SEQ", "Starting register access sequence", UVM_MEDIUM)
    
//     //------------------------------------------
//     // 1. Basic register access tests
//     //------------------------------------------
//     if (do_basic_access) begin
//       `uvm_info("REG_SEQ", "Performing basic register access tests", UVM_MEDIUM)
      
//       // Write to control register
//       `uvm_info("REG_SEQ", $sformatf("Writing control value 0x%0h", ctrl_value), UVM_MEDIUM)
//       reg_model.top_control.write(status, ctrl_value);
//       if (status != UVM_IS_OK) 
//         `uvm_error("REG_SEQ", "Write to top_control failed")
      
//       // Read back and verify
//       reg_model.top_control.read(status, read_data);
//       if (status != UVM_IS_OK) 
//         `uvm_error("REG_SEQ", "Read from top_control failed")
      
//       if (read_data != ctrl_value) 
//         `uvm_error("REG_SEQ", $sformatf("Control read data mismatch: Expected 0x%0h, Got 0x%0h", 
//                                         ctrl_value, read_data))
//       else
//         `uvm_info("REG_SEQ", $sformatf("Control read data match: 0x%0h", read_data), UVM_MEDIUM)
      
//       // Read status register
//       reg_model.top_status.read(status, read_data);
//       if (status != UVM_IS_OK) 
//         `uvm_error("REG_SEQ", "Read from top_status failed")
      
//       `uvm_info("REG_SEQ", $sformatf("Status register value: 0x%0h", read_data), UVM_MEDIUM)
//     end
    
//     //------------------------------------------
//     // 2. Register file access tests
//     //------------------------------------------
//     if (do_register_files) begin
//       `uvm_info("REG_SEQ", "Performing register file access tests", UVM_MEDIUM)
      
//       // Register File A tests
//       `uvm_info("REG_SEQ", "Testing Register File A", UVM_MEDIUM)
      
//       // Write to control register in regfile_a
//       reg_model.regfile_a.rf_control.write(status, 'hA5);
//       if (status != UVM_IS_OK) 
//         `uvm_error("REG_SEQ", "Write to regfile_a.rf_control failed")
      
//       // Read back and verify
//       reg_model.regfile_a.rf_control.read(status, read_data);
//       if (read_data != 'hA5) 
//         `uvm_error("REG_SEQ", $sformatf("RegFile A control read data mismatch: Expected 0xA5, Got 0x%0h", read_data))
      
//       // Write and read from data registers in regfile_a
//       foreach(reg_model.regfile_a.rf_data[i]) begin
//         `uvm_info("REG_SEQ", $sformatf("Testing regfile_a.rf_data[%0d]", i), UVM_MEDIUM)
        
//         reg_model.regfile_a.rf_data[i].write(status, data_values[i]);
//         if (status != UVM_IS_OK) 
//           `uvm_error("REG_SEQ", $sformatf("Write to regfile_a.rf_data[%0d] failed", i))
        
//         reg_model.regfile_a.rf_data[i].read(status, read_data);
//         if (read_data != data_values[i]) 
//           `uvm_error("REG_SEQ", $sformatf("RegFile A data[%0d] mismatch: Expected 0x%0h, Got 0x%0h", 
//                                         i, data_values[i], read_data))
//       end
      
//       // Register File B tests (brief version)
//       `uvm_info("REG_SEQ", "Testing Register File B", UVM_MEDIUM)
//       reg_model.regfile_b.rf_control.write(status, 'h3C);
//       reg_model.regfile_b.rf_data[0].write(status, 'hDEADBEEF);
//     end
    
//     //------------------------------------------
//     // 3. Memory access tests
//     //------------------------------------------
//     if (do_mem_access) begin
//       bit[31:0] mem_data[$];
      
//       `uvm_info("REG_SEQ", "Performing memory access tests", UVM_MEDIUM)
      
//       // Generate test data and fill first 10 locations
//       mem_data = {32'h01234567, 32'h89ABCDEF, 32'hFEEDFACE, 32'hCAFEBABE, 
//                  32'hDEADBEEF, 32'h55AA55AA, 32'hA5A5A5A5, 32'h00FF00FF, 
//                  32'hF0F0F0F0, 32'h12345678};
                 
//       for (int i=0; i<10; i++) begin
//         reg_model.my_memory.write(status, i, mem_data[i]);
//         if (status != UVM_IS_OK) 
//           `uvm_error("REG_SEQ", $sformatf("Write to memory address %0d failed", i))
//       end
      
//       // Read back and verify a few locations
//       for (int i=0; i<5; i++) begin
//         reg_model.my_memory.read(status, i, read_data);
//         if (status != UVM_IS_OK) 
//           `uvm_error("REG_SEQ", $sformatf("Read from memory address %0d failed", i))
          
//         if (read_data != mem_data[i]) 
//           `uvm_error("REG_SEQ", $sformatf("Memory data mismatch at addr %0d: Expected 0x%0h, Got 0x%0h", 
//                                         i, mem_data[i], read_data))
//         else
//           `uvm_info("REG_SEQ", $sformatf("Memory data match at addr %0d: 0x%0h", i, read_data), UVM_HIGH)
//       end
      
//       // Test burst access if supported
//       if (reg_model.my_memory.supports_byte_enable_access()) begin
//         uvm_status_e burst_status[$];
//         uvm_reg_data_t burst_data[$];
        
//         `uvm_info("REG_SEQ", "Testing burst memory access", UVM_MEDIUM)
        
//         // Read multiple addresses at once
//         reg_model.my_memory.burst_read(status, 5, 4, burst_data, .parent(this));
        
//         for (int i=0; i<4; i++) begin
//           if (burst_data[i] != mem_data[i+5]) 
//             `uvm_error("REG_SEQ", $sformatf("Burst memory read mismatch at offset %0d", i))
//         end
//       end
//     end
    
//     //------------------------------------------
//     // 4. Built-in UVM register sequences
//     //------------------------------------------
//     if (do_built_in_tests) begin
//       `uvm_info("REG_SEQ", "Running built-in UVM register test sequences", UVM_MEDIUM)
      
//       // Initialize sequence and set target register model
//       uvm_reg_hw_reset_seq hw_reset_seq = uvm_reg_hw_reset_seq::type_id::create("hw_reset_seq");
//       hw_reset_seq.model = reg_model;
      
//       // Run the reset sequence
//       `uvm_info("REG_SEQ", "Starting hardware reset test sequence", UVM_MEDIUM)
//       hw_reset_seq.start(null);
      
//       // Create and run bit bash sequence on control register only
//       uvm_reg_bit_bash_seq bit_bash_seq = uvm_reg_bit_bash_seq::type_id::create("bit_bash_seq");
//       bit_bash_seq.model = reg_model;
//       bit_bash_seq.regs = new[1];
//       bit_bash_seq.regs[0] = reg_model.top_control;
      
//       `uvm_info("REG_SEQ", "Starting bit bash test sequence on top_control", UVM_MEDIUM)
//       bit_bash_seq.start(null);
//     end
    
//     `uvm_info("REG_SEQ", "Register access sequence completed", UVM_MEDIUM)
//   endtask
  
//   // Helper task to demonstrate mirror operations
//   task mirror_example();
//     uvm_status_e status;
    
//     // Mirror with read - updates the mirror value by reading from DUT
//     reg_model.top_control.mirror(status, UVM_CHECK);
    
//     // Example predicting a value (updates mirror only)
//     reg_model.top_control.predict('hFF);
    
//     // Mirror again - should find a mismatch with the actual hardware
//     reg_model.top_control.mirror(status, UVM_CHECK);
//   endtask
// endclass