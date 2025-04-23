///////////////////////////////////////////////////////////////////////////////
// File:        dp_dpcd_reg_predictor.svh
// Author:      Amira Atef
// Date:        22-03-2025
// Description: Custom register predcitor to filter out accesses with errors
//              and to verify that the response of the access is the expected
//              one.
///////////////////////////////////////////////////////////////////////////////
class dp_dpcd_reg_predictor#(type BUSTYPE = uvm_sequence_item) extends uvm_reg_predictor#(.BUSTYPE(BUSTYPE));

    `uvm_component_param_utils(dp_dpcd_reg_predictor#(BUSTYPE))

    function new(string name = "dp_dpcd_reg_predictor", uvm_component null);
        super.new(name, parent);
    endfunction

    //Getter for the expected reponse
    protected virtual function uvm_status_e get_exp_response(uvm_reg_bus_op operation);
        uvm_reg register;

        register = map.get_reg_by_offset(operation.addr, (operation.kind == UVM_READ));

        //Any access to a location on which no register is mapped must reutrn AUX_DEFER
        if(register == null) begin
            `uvm_warning("DPCD_PREDICTOR", $sformatf("Register at address 0x%0h is RESERVED", addr));
            return UVM_NOT_OK;
        end

        //Any write access to a full read-only register must return an APB error.
        if(operation.kind == UVM_WRITE) begin
            uvm_reg_map_info info = map.get_reg_map_info(register);

            if(info.rights == "RO") begin
                `uvm_warning("DPCD_PREDICTOR", $sformatf("Write access to a full read-only register"));
                return UVM_NOT_OK;
            end
        end
        `uvm_info("DPCD_PREDICTOR", $sformatf("All OK"));
        return UVM_IS_OK;
    endfunction

    virtual function void write(BUSTYPE tr);
        uvm_reg_bus_op operation;

        adapter.bus2reg(tr, operation);

        uvm_status_e exp_response = get_exp_response(operation);
        //// not entirely sure yet
        if(exp_response.status != operation.status) begin
            uvm_error("DUT_ERROR", $sformatf("Mismatch detected for the AUX_CH operation status - expected: %0s, received: %0s on access: %0s - reason: %0s",
                exp_response.status.name(), operation.status.name(), tr.convert2string(), exp_response.info))
        end

        if(operation.status == UVM_IS_OK) begin
            super.write(tr);
        end
    endfunction
    
endclass