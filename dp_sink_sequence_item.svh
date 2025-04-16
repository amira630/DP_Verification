class dp_sink_sequence_item extends uvm_sequence_item;
    `uvm_object_utils(dp_sink_sequence_item);

    rand bit HPD_Signal;
    
    bit START_STOP;
    bit [7:0] AUX_IN_OUT[$];             

// Reply Command Signal 
    rand i2c_aux_reply_cmd_e i2c_reply_cmd;
    rand native_aux_reply_cmd_e native_reply_cmd;

// Output Signals across from DUT to the PHY Layer
    logic [1:0] CR_ADJ_LC, CR_PHY_Instruct, EQ_ADJ_LC, EQ_PHY_Instruct;
    logic [7:0] CR_ADJ_BW, EQ_ADJ_BW;

// AUX fields moved from base_sequence
    logic [3:0] command;
    logic [19:0] address;
    logic [7:0] length;
    logic [7:0] data[$];  // Variable length data

// Flags
    bit is_reply;

// constraints
    constraint valid_i2c_aux_reply_cmd_c {
        //i2c_reply_cmd != RESERVED;  // Avoid using RESERVED value
    }

    constraint valid_native_aux_reply_cmd_c {
        //native_reply_cmd != RESERVED;  // Avoid using RESERVED value
    }

    function new(string name = "dp_sink_sequence_item");
        super.new(name);
    endfunction //new()

    // Copy the values from the virtual interface to the sequence item
    // This function is used to initialize the sequence item with values from the DUT
    // It is called by the driver to get the current state of the DUT
    // and store it in the sequence item for later use
    function void copy_from_vif(virtual dp_sink_if vif);
        this.HPD_Signal = vif.HPD_Signal;
        this.AUX_START_STOP = vif.AUX_START_STOP;
        this.PHY_START_STOP = vif.PHY_START_STOP;
        this.AUX_IN_OUT = vif.AUX_IN_OUT;
        this.CR_ADJ_LC = vif.CR_ADJ_LC;
        this.CR_PHY_Instruct = vif.CR_PHY_Instruct;
        this.EQ_ADJ_LC = vif.EQ_ADJ_LC;
        this.EQ_PHY_Instruct = vif.EQ_PHY_Instruct;
        this.CR_ADJ_BW = vif.CR_ADJ_BW;
        this.EQ_ADJ_BW = vif.EQ_ADJ_BW;
    endfunction    

    function string convert2string();
        string aux_data = "";
        string data_str = "";

        foreach(AUX_IN_OUT[i]) begin
            aux_data = {aux_data, $sformatf("AUX_IN_OUT[%0d]=%0h ", i, AUX_IN_OUT[i])};
        end

        foreach(data[i]) begin
            data_str = {data_str, $sformatf("data[%0d]=%0h ", i, data[i])};
        end
        
        return $sformatf("%s HPD_Signal = %0b, CMD = %0s, AUX_IN_OUT = %0b, START_STOP = %0b, CR_ADJ_LC = %0b, CR_ADJ_BW = %0b, CR_PHY_Instruct = %0b, EQ_ADJ_BW = %0b, EQ_ADJ_LC = %0b, EQ_PHY_Instruct = %0b AUX_COMMAND = %0h, AUX_ADDRESS = %0h, AUX_LENGTH = %0h, AUX_DATA = %s", super.convert2string(),HPD_Signal, command, AUX_IN_OUT, START_STOP, CR_ADJ_LC, CR_ADJ_BW, CR_PHY_Instruct, EQ_ADJ_BW, EQ_ADJ_LC, EQ_PHY_Instruct, command, address, length, data_str);
    endfunction
    
endclass //dp_sink_sequence_item extends superClass