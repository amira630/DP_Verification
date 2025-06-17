interface dp_ref_if #(parameter AUX_DATA_WIDTH = 8) ();
    logic [AUX_DATA_WIDTH-1:0] expected_ISO_symbols_lane0, expected_ISO_symbols_lane1, expected_ISO_symbols_lane2, expected_ISO_symbols_lane3;
    logic                      expected_Control_sym_flag_lane0, expected_Control_sym_flag_lane1, expected_Control_sym_flag_lane2, expected_Control_sym_flag_lane3;
    logic [AUX_DATA_WIDTH-1:0] ref_expected_ISO_symbols_lane0, ref_expected_ISO_symbols_lane1, ref_expected_ISO_symbols_lane2, ref_expected_ISO_symbols_lane3;
    logic                      ref_expected_Control_sym_flag_lane0, ref_expected_Control_sym_flag_lane1, ref_expected_Control_sym_flag_lane2, ref_expected_Control_sym_flag_lane3;
endinterface