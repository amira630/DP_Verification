class dp_sink_sequence_item extends uvm_sequence_item;
    `uvm_object_utils(dp_sink_sequence_item);

    rand bit hpd_signal;
    rand bit start_stop;

    bit [7:0] aux_in_out[$];             

// Reply Command Signal 
    rand i2c_aux_reply_cmd_e i2c_aux_reply_cmd;

// Output Signals across from DUT to the PHY Layer
    logic [1:0] cr_adj_lc, cr_phy_instruct, eq_adj_lc, eq_phy_instruct;
    logic [7:0] cr_adj_bw, eq_adj_bw;

// AUX fields moved from base_sequence
    logic [3:0] command;
    logic [19:0] address;
    logic [7:0] length;
    logic [7:0] data[$];  // Variable length data

// constraints
    constraint valid_i2c_aux_reply_cmd_c {
        i2c_aux_reply_cmd != RESERVED;  // Avoid using RESERVED value
    }

    function new(string name = "dp_sink_sequence_item");
        super.new(name);
    endfunction //new()

    function string convert2string();
        string aux_data = "";
        string data_str = "";

        foreach(aux_in_out[i]) begin
            aux_data = {aux_data, $sformatf("aux_in_out[%0d]=%0h ", i, aux_in_out[i])};
        end

        foreach(data[i]) begin
            data_str = {data_str, $sformatf("data[%0d]=%0h ", i, data[i])};
        end
        
        return $sformatf("%s HPD_Signal = %0b, CMD = %0s, AUX_IN_OUT = %0b, START_STOP = %0b, CR_ADJ_LC = %0b, CR_ADJ_BW = %0b, CR_PHY_Instruct = %0b,
        EQ_ADJ_BW = %0b, EQ_ADJ_LC = %0b, EQ_PHY_Instruct = %0b AUX_COMMAND = %0h, AUX_ADDRESS = %0h, AUX_LENGTH = %0h, AUX_DATA = %s", super.convert2string(),
        hpd_signal, i2c_aux_reply_cmd.name(), aux_in_out, start_stop, cr_adj_lc, cr_adj_bw, cr_phy_instruct, eq_adj_bw, eq_adj_lc, eq_phy_instruct, command, address, length, data_str);
    endfunction
    
endclass //dp_sink_sequence_item extends superClass