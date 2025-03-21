class dp_tl_native_write_req_aux_sequence extends dp_tl_base_sequence;
    `uvm_object_utils(dp_tl_native_write_req_aux_sequence);
    
    function new(string name = "dp_tl_native_write_req_aux_sequence");
        super.new(name);
    endfunction //new()
    
    virtual task body();
        native_write_req_aux();
    endtask
endclass