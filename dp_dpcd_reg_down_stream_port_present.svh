///////////////////////////////////////////////////////////////////////////////
// File:        dp_dpcd_reg_down_stream_port_present.svh
// Author:      Amira Atef
// Date:        20-3-2025
// Description: Definition of the DOWN_STREAM_PORT_PRESENT register at address 0_00_05h
//              in the DP DPCD Receiver Capability Field.
///////////////////////////////////////////////////////////////////////////////

class dp_dpcd_reg_down_stream_port_present extends uvm_reg;
    `uvm_object_utils(dp_dpcd_reg_down_stream_port_present)

    rand uvm_reg_field DFP_PRESENT;

    rand uvm_reg_field DFP_TYPE;

    rand uvm_reg_field FORMAT_CONVERSION;
    
    rand uvm_reg_field DETAILED_CAP_INFO_AVAILABLE;

    rand uvm_reg_field PCON;

    function new(string name = "dp_dpcd_reg_down_stream_port_present");
        super.new(.name(name), .n_bits(8), .has_coverage(UVM_NO_COVERAGE));
    endfunction
  
    virtual function void build();
        DFP_PRESENT = uvm_reg_field::type_id::create(.name("DFP_PRESENT"), .parent(null), .contxt(get_full_name()));
        DFP_TYPE = uvm_reg_field::type_id::create(.name("DFP_TYPE"), .parent(null), .contxt(get_full_name()));
        FORMAT_CONVERSION = uvm_reg_field::type_id::create(.name("FORMAT_CONVERSION"), .parent(null), .contxt(get_full_name()));
        DETAILED_CAP_INFO_AVAILABLE = uvm_reg_field::type_id::create(.name("DETAILED_CAP_INFO_AVAILABLE"), .parent(null), .contxt(get_full_name()));
        PCON = uvm_reg_field::type_id::create(.name("PCON"), .parent(null), .contxt(get_full_name()));

        DFP_PRESENT.configure(
            .parent(this),
            .size(1),
            .lsb_pos(0),
            .access("RO"),
            .volatile(0),
            .reset(0),  // Correct Value
            .has_reset(1),
            .is_rand(1),
            .individually_accessible(0)
        );
        DFP_TYPE.configure(  
            .parent(this),
            .size(2),
            .lsb_pos(1),
            .access("RO"),
            .volatile(0),
            .reset(2'b00),
            .has_reset(1),
            .is_rand(1), 
            .individually_accessible(0)
        );        
        FORMAT_CONVERSION.configure(       
            .parent(this),
            .size(1),
            .lsb_pos(3),
            .access("RO"),
            .volatile(0),
            .reset(0),
            .has_reset(1),
            .is_rand(1),
            .individually_accessible(0)
        );        
        DETAILED_CAP_INFO_AVAILABLE.configure(        
            .parent(this),
            .size(1),
            .lsb_pos(4),
            .access("RO"),
            .volatile(0),
            .reset(0),
            .has_reset(1),
            .is_rand(1),
            .individually_accessible(0)
        );
        PCON.configure(        
            .parent(this),
            .size(2),
            .lsb_pos(5),
            .access("RO"),
            .volatile(0),
            .reset(2'b00),
            .has_reset(1),
            .is_rand(1),
            .individually_accessible(0)
        );
    endfunction
endclass