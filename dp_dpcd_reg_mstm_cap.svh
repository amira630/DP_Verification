///////////////////////////////////////////////////////////////////////////////
// File:        dp_dpcd_reg_mstm_cap.svh
// Author:      Amira Atef
// Date:        20-3-2025
// Description: Definition of the MSTM_CAP register at address 0_00_21h
//              in the DP DPCD Receiver Capability Field.
///////////////////////////////////////////////////////////////////////////////

class dp_dpcd_reg_mstm_cap extends uvm_reg;
    `uvm_object_utils(dp_dpcd_reg_mstm_cap)

    rand uvm_reg_field MST_CAP;
    
    rand uvm_reg_field SINGLE_STREAM_SIDEBAND_MSG_SUPPORT;

    rand uvm_reg_field DOWN_REP_UP_REQ_RESPONSE_TIME;

    rand uvm_reg_field CEC_TUNNELING_CAP;

    function new(string name = "dp_dpcd_reg_mstm_cap");
        super.new(.name(name), .n_bits(8), .has_coverage(UVM_NO_COVERAGE));
    endfunction
  
    virtual function void build();
        MST_CAP = uvm_reg_field::type_id::create(.name("MST_CAP"), .parent(null), .contxt(get_full_name()));
        SINGLE_STREAM_SIDEBAND_MSG_SUPPORT = uvm_reg_field::type_id::create(.name("SINGLE_STREAM_SIDEBAND_MSG_SUPPORT"), .parent(null), .contxt(get_full_name()));
        DOWN_REP_UP_REQ_RESPONSE_TIME = uvm_reg_field::type_id::create(.name("DOWN_REP_UP_REQ_RESPONSE_TIME"), .parent(null), .contxt(get_full_name()));
        CEC_TUNNELING_CAP = uvm_reg_field::type_id::create(.name("CEC_TUNNELING_CAP"), .parent(null), .contxt(get_full_name()));
        
        MST_CAP.configure(
            .parent(this),
            .size(1),
            .lsb_pos(0),
            .access("RO"),
            .volatile(0),
            .reset(0),    // Correct Value 
            .has_reset(1),
            .is_rand(1),
            .individually_accessible(0)
        );

        SINGLE_STREAM_SIDEBAND_MSG_SUPPORT.configure(
            .parent(this),
            .size(1),
            .lsb_pos(1),
            .access("RO"),
            .volatile(0),
            .reset(0),      // Correct Value
            .has_reset(1),
            .is_rand(1),
            .individually_accessible(0)
        );

        DOWN_REP_UP_REQ_RESPONSE_TIME.configure(
            .parent(this),
            .size(3),
            .lsb_pos(2),
            .access("RO"),
            .volatile(0),
            .reset(3'b000),      // Correct Value
            .has_reset(1),
            .is_rand(1),
            .individually_accessible(0)
        );

        CEC_TUNNELING_CAP.configure(
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
    endfunction
endclass