///////////////////////////////////////////////////////////////////////////////
// File:        dp_aux_reg_adapter.svh
// Author:      Amira Atef
// Date:        22-03-2025
// Description: Transaction adapter for the AUX protocol
///////////////////////////////////////////////////////////////////////////////  
class dp_aux_reg_adapter extends uvm_reg_adapter;

    `uvm_object_utils(dp_aux_reg_adapter)

    function new(string name = "dp_aux_reg_adapter");
        super.new(name);  
    endfunction

    virtual function void bus2reg(uvm_sequence_item bus_item, ref uvm_reg_bus_op rw);
        dp_sink_sequence_item item_mon;
        dp_sink_sequence_item item_drv;

        // Down casting of bus_item (parent) onto item_mon (child) i.e. item_mon = bus_item;
        if($cast(item_mon, bus_item)) begin
            rw.kind   = item_mon.command[2:0] == 3'b001? UVM_READ : UVM_WRITE;
            ///// loop??? //////
            rw.addr   = item_mon.address; // under development
            rw.data   = item_mon.data; //under development
            ///// loop??? //////
            rw.status = item_mon.native_aux_reply_cmd == AUX_ACK ? UVM_IS_OK : UVM_NOT_OK;    // not sure
                                                                //UVM_IS_OK     Operation completed successfully
                                                                //UVM_NOT_OK     Operation completed with error        
        end
        else if($cast(item_drv, bus_item)) begin
            rw.kind   = item_mon.command[2:0] == 3'b001? UVM_READ : UVM_WRITE;
            rw.addr   = item_drv.address;
            rw.data   = item_drv.data;
            rw.status = item_drv.native_aux_reply_cmd == AUX_ACK ? UVM_IS_OK : UVM_NOT_OK;
        end
        else begin
            `uvm_fatal("ALGORITHM_ISSUE", $sformatf("Class not supported: %0s", bus_item.get_type_name()))
        end
        
    endfunction

    virtual function uvm_sequence_item reg2bus(const ref uvm_reg_bus_op rw);
        dp_sink_sequence_item item = dp_sink_sequence_item::type_id::create("item");

        void'(item.randomize() with {
            /// Not entirely sure
            if (rw.kind == UVM_READ)
                item.native_aux_reply_cmd  == (rw.status == UVM_IS_OK) ?  AUX_ACK: AUX_DEFER;
            else
                item.native_aux_reply_cmd  == (rw.status == UVM_IS_OK) ?  AUX_ACK: AUX_NACK; // not sure
            item.data == rw.data;
            item.address == rw.addr;
        });

        return item;
    endfunction

endclass