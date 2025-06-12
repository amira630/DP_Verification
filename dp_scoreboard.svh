class dp_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(dp_scoreboard)
    
    uvm_analysis_export #(dp_tl_sequence_item) sb_tl_export;
    uvm_analysis_export #(dp_sink_sequence_item) sb_sink_export;
    uvm_analysis_export #(dp_ref_transaction) sb_ref_export;

    uvm_tlm_analysis_fifo #(dp_tl_sequence_item) sb_tl_fifo;
    uvm_tlm_analysis_fifo #(dp_sink_sequence_item) sb_sink_fifo;
    uvm_tlm_analysis_fifo #(dp_ref_transaction) sb_ref_fifo;

    dp_tl_sequence_item tl_item;
    dp_sink_sequence_item sink_item;
    dp_ref_transaction expected_transaction;
    
    int error_count = 0;
    int correct_count = 0;

    function new(string name = "dp_scoreboard", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        sb_tl_export = new("sb_tl_export", this);
        sb_sink_export = new("sb_sink_export", this);
        sb_ref_export = new("sb_ref_export", this);

        sb_tl_fifo = new("sb_tl_fifo", this);
        sb_sink_fifo = new("sb_sink_fifo", this);
        sb_ref_fifo = new("sb_ref_fifo", this);

        `uvm_info(get_type_name(), "Scoreboard build_phase completed", UVM_LOW)

    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        sb_tl_export.connect(sb_tl_fifo.analysis_export);
        sb_sink_export.connect(sb_sink_fifo.analysis_export);
        sb_ref_export.connect(sb_ref_fifo.analysis_export);

        `uvm_info(get_type_name(), "Scoreboard connect_phase completed", UVM_LOW)
    endfunction

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        forever begin
            sb_tl_fifo.get(tl_item);
            sb_sink_fifo.get(sink_item);
            sb_ref_fifo.get(expected_transaction);

            // Compare the reference model output with the actual transactions
            compare_transactions(tl_item, sink_item, expected_transaction);

            `uvm_info("run_phase", tl_item.convert2string(), UVM_MEDIUM)
            `uvm_info("run_phase", sink_item.convert2string(), UVM_MEDIUM) 
        end
    endtask

    virtual function void compare_transactions(
        dp_tl_sequence_item tl_item, 
        dp_sink_sequence_item sink_item, 
        dp_ref_transaction expected_transaction
    );
        // STREAM POLICY MAKER (tl_item)
        if (expected_transaction.SPM_Reply_Data != tl_item.SPM_Reply_Data) begin
            `uvm_error(get_type_name(), $sformatf("Mismatch in SPM_Reply_Data: expected=%0h, actual=%0h", expected_transaction.SPM_Reply_Data, tl_item.SPM_Reply_Data))
            error_count++;
        end
        else begin
            `uvm_info(get_type_name(), "Transactions match", UVM_MEDIUM)
            correct_count++;
        end
        if (expected_transaction.SPM_Reply_ACK != tl_item.SPM_Reply_ACK) begin
            `uvm_error(get_type_name(), $sformatf("Mismatch in SPM_Reply_ACK: expected=%0b, actual=%0b", expected_transaction.SPM_Reply_ACK, tl_item.SPM_Reply_ACK))
            error_count++;
        end
        else begin
            `uvm_info(get_type_name(), "Transactions match", UVM_MEDIUM)
            correct_count++;
        end
        
        if (expected_transaction.SPM_Reply_ACK_VLD != tl_item.SPM_Reply_ACK_VLD) begin
            `uvm_error(get_type_name(), $sformatf("Mismatch in SPM_Reply_ACK_VLD: expected=%b, actual=%b", expected_transaction.SPM_Reply_ACK_VLD, tl_item.SPM_Reply_ACK_VLD))
            error_count++;
        end
        else begin
            `uvm_info(get_type_name(), "Transactions match", UVM_MEDIUM)
            correct_count++;
        end

        if (expected_transaction.SPM_Reply_Data_VLD != tl_item.SPM_Reply_Data_VLD) begin
            `uvm_error(get_type_name(), $sformatf("Mismatch in SPM_Reply_Data_VLD: expected=%b, actual=%b", expected_transaction.SPM_Reply_Data_VLD, tl_item.SPM_Reply_Data_VLD))
            error_count++;
        end
        else begin
            `uvm_info(get_type_name(), "Transactions match", UVM_MEDIUM)
            correct_count++;
        end

        if (expected_transaction.SPM_NATIVE_I2C != tl_item.SPM_NATIVE_I2C) begin
            `uvm_error(get_type_name(), $sformatf("Mismatch in SPM_NATIVE_I2C: expected=%b, actual=%b", expected_transaction.SPM_NATIVE_I2C, tl_item.SPM_NATIVE_I2C))
            error_count++;
        end
        else begin
            `uvm_info(get_type_name(), "Transactions match", UVM_MEDIUM)
            correct_count++;
        end

        if (expected_transaction.CTRL_I2C_Failed != tl_item.CTRL_I2C_Failed) begin
            `uvm_error(get_type_name(), $sformatf("Mismatch in CTRL_I2C_Failed: expected=%b, actual=%b", expected_transaction.CTRL_I2C_Failed, tl_item.CTRL_I2C_Failed))
            error_count++;
        end
        else begin
            `uvm_info(get_type_name(), "Transactions match", UVM_MEDIUM)
            correct_count++;
        end

        // LINK POLICY MAKER (tl_item)
        if (expected_transaction.LPM_Reply_Data != tl_item.LPM_Reply_Data) begin
            `uvm_error(get_type_name(), $sformatf("Mismatch in LPM_Reply_Data: expected=%0h, actual=%0h", expected_transaction.LPM_Reply_Data, tl_item.LPM_Reply_Data))
            error_count++;
        end
        else begin
            `uvm_info(get_type_name(), "Transactions match", UVM_MEDIUM)
            correct_count++;
        end

        if (expected_transaction.LPM_Reply_ACK != tl_item.LPM_Reply_ACK) begin
            `uvm_error(get_type_name(), $sformatf("Mismatch in LPM_Reply_ACK: expected=%0b, actual=%0b", expected_transaction.LPM_Reply_ACK, tl_item.LPM_Reply_ACK))
            error_count++;
        end
        else begin
            `uvm_info(get_type_name(), "Transactions match", UVM_MEDIUM)
            correct_count++;
        end

        if (expected_transaction.LPM_Reply_ACK_VLD != tl_item.LPM_Reply_ACK_VLD) begin
            `uvm_error(get_type_name(), $sformatf("Mismatch in LPM_Reply_ACK_VLD: expected=%b, actual=%b", expected_transaction.LPM_Reply_ACK_VLD, tl_item.LPM_Reply_ACK_VLD))
            error_count++;
        end
        else begin
            `uvm_info(get_type_name(), "Transactions match", UVM_MEDIUM)
            correct_count++;
        end

        if (expected_transaction.LPM_Reply_Data_VLD != tl_item.LPM_Reply_Data_VLD) begin
            `uvm_error(get_type_name(), $sformatf("Mismatch in LPM_Reply_Data_VLD: expected=%b, actual=%b", expected_transaction.LPM_Reply_Data_VLD, tl_item.LPM_Reply_Data_VLD))
            error_count++;
        end
        else begin
            `uvm_info(get_type_name(), "Transactions match", UVM_MEDIUM)
            correct_count++;
        end

        if (expected_transaction.HPD_Detect != tl_item.HPD_Detect) begin
            `uvm_error(get_type_name(), $sformatf("Mismatch in HPD_Detect: expected=%b, actual=%b", expected_transaction.HPD_Detect, tl_item.HPD_Detect))
            error_count++;
        end
        else begin
            `uvm_info(get_type_name(), "Transactions match", UVM_MEDIUM)
            correct_count++;
        end

        if (expected_transaction.HPD_IRQ != tl_item.HPD_IRQ) begin
            `uvm_error(get_type_name(), $sformatf("Mismatch in HPD_IRQ: expected=%b, actual=%b", expected_transaction.HPD_IRQ, tl_item.HPD_IRQ))
            error_count++;
        end
        else begin
            `uvm_info(get_type_name(), "Transactions match", UVM_MEDIUM)
            correct_count++;
        end

        if (expected_transaction.CTRL_Native_Failed != tl_item.CTRL_Native_Failed) begin
            `uvm_error(get_type_name(), $sformatf("Mismatch in CTRL_Native_Failed: expected=%b, actual=%b", expected_transaction.CTRL_Native_Failed, tl_item.CTRL_Native_Failed))
            error_count++;
        end
        else begin
            `uvm_info(get_type_name(), "Transactions match", UVM_MEDIUM)
            correct_count++;
        end

        if (expected_transaction.LPM_NATIVE_I2C != tl_item.LPM_NATIVE_I2C) begin
            `uvm_error(get_type_name(), $sformatf("Mismatch in LPM_NATIVE_I2C: expected=%b, actual=%b", expected_transaction.LPM_NATIVE_I2C, tl_item.LPM_NATIVE_I2C))
            error_count++;
        end
        else begin
            `uvm_info(get_type_name(), "Transactions match", UVM_MEDIUM)
            correct_count++;
        end

        // LINK TRAINING SIGNALS (tl_item)
        if (expected_transaction.EQ_Final_ADJ_BW != tl_item.EQ_Final_ADJ_BW) begin
            `uvm_error(get_type_name(), $sformatf("Mismatch in EQ_Final_ADJ_BW: expected=%0h, actual=%0h", expected_transaction.EQ_Final_ADJ_BW, tl_item.EQ_Final_ADJ_BW))
            error_count++;
        end
        else begin
            `uvm_info(get_type_name(), "Transactions match", UVM_MEDIUM)
            correct_count++;
        end

        if (expected_transaction.EQ_Final_ADJ_LC != tl_item.EQ_Final_ADJ_LC) begin
            `uvm_error(get_type_name(), $sformatf("Mismatch in EQ_Final_ADJ_LC: expected=%0b, actual=%0b", expected_transaction.EQ_Final_ADJ_LC, tl_item.EQ_Final_ADJ_LC))
            error_count++;
        end
        else begin
            `uvm_info(get_type_name(), "Transactions match", UVM_MEDIUM)
            correct_count++;
        end

        if (expected_transaction.FSM_CR_Failed != tl_item.FSM_CR_Failed) begin
            `uvm_error(get_type_name(), $sformatf("Mismatch in FSM_CR_Failed: expected=%b, actual=%b", expected_transaction.FSM_CR_Failed, tl_item.FSM_CR_Failed))
            error_count++;
        end
        else begin
            `uvm_info(get_type_name(), "Transactions match", UVM_MEDIUM)
            correct_count++;
        end

        if (expected_transaction.EQ_FSM_CR_Failed != tl_item.EQ_FSM_CR_Failed) begin
            `uvm_error(get_type_name(), $sformatf("Mismatch in EQ_FSM_CR_Failed: expected=%b, actual=%b", expected_transaction.EQ_FSM_CR_Failed, tl_item.EQ_FSM_CR_Failed))
            error_count++;
        end
        else begin
            `uvm_info(get_type_name(), "Transactions match", UVM_MEDIUM)
            correct_count++;
        end

        if (expected_transaction.EQ_LT_Failed != tl_item.EQ_LT_Failed) begin
            `uvm_error(get_type_name(), $sformatf("Mismatch in EQ_LT_Failed: expected=%b, actual=%b", expected_transaction.EQ_LT_Failed, tl_item.EQ_LT_Failed))
            error_count++;
        end
        else begin
            `uvm_info(get_type_name(), "Transactions match", UVM_MEDIUM)
            correct_count++;
        end

        if (expected_transaction.EQ_LT_Pass != tl_item.EQ_LT_Pass) begin
            `uvm_error(get_type_name(), $sformatf("Mismatch in EQ_LT_Pass: expected=%b, actual=%b", expected_transaction.EQ_LT_Pass, tl_item.EQ_LT_Pass))
            error_count++;
        end
        else begin
            `uvm_info(get_type_name(), "Transactions match", UVM_MEDIUM)
            correct_count++;
        end

        if (expected_transaction.CR_Completed != tl_item.CR_Completed) begin
            `uvm_error(get_type_name(), $sformatf("Mismatch in CR_Completed: expected=%b, actual=%b", expected_transaction.CR_Completed, tl_item.CR_Completed))
            error_count++;
        end
        else begin
            `uvm_info(get_type_name(), "Transactions match", UVM_MEDIUM)
            correct_count++;
        end

        // PHYSICAL LAYER (sink_item)
        if (expected_transaction.PHY_ADJ_BW != sink_item.PHY_ADJ_BW) begin
            `uvm_error(get_type_name(), $sformatf("Mismatch in PHY_ADJ_BW: expected=%0h, actual=%0h", expected_transaction.PHY_ADJ_BW, sink_item.PHY_ADJ_BW))
            error_count++;
        end
        else begin
            `uvm_info(get_type_name(), "Transactions match", UVM_MEDIUM)
            correct_count++;
        end

        if (expected_transaction.PHY_ADJ_LC != sink_item.PHY_ADJ_LC) begin
            `uvm_error(get_type_name(), $sformatf("Mismatch in PHY_ADJ_LC: expected=%0b, actual=%0b", expected_transaction.PHY_ADJ_LC, sink_item.PHY_ADJ_LC))
            error_count++;
        end
        else begin
            `uvm_info(get_type_name(), "Transactions match", UVM_MEDIUM)
            correct_count++;
        end

        if (expected_transaction.PHY_Instruct != sink_item.PHY_Instruct) begin
            `uvm_error(get_type_name(), $sformatf("Mismatch in PHY_Instruct: expected=%0b, actual=%0b", expected_transaction.PHY_Instruct, sink_item.PHY_Instruct))
            error_count++;
        end
        else begin
            `uvm_info(get_type_name(), "Transactions match", UVM_MEDIUM)
            correct_count++;
        end

        if (expected_transaction.AUX_START_STOP != sink_item.AUX_START_STOP) begin
            `uvm_error(get_type_name(), $sformatf("Mismatch in AUX_START_STOP: expected=%b, actual=%b", expected_transaction.AUX_START_STOP, sink_item.AUX_START_STOP))
            error_count++;
        end
        else begin
            `uvm_info(get_type_name(), "Transactions match", UVM_MEDIUM)
            correct_count++;
        end

        if (expected_transaction.PHY_Instruct_VLD != sink_item.PHY_Instruct_VLD) begin
            `uvm_error(get_type_name(), $sformatf("Mismatch in PHY_Instruct_VLD: expected=%b, actual=%b", expected_transaction.PHY_Instruct_VLD, sink_item.PHY_Instruct_VLD))
            error_count++;
        end
        else begin
            `uvm_info(get_type_name(), "Transactions match", UVM_MEDIUM)
            correct_count++;
        end

        if (expected_transaction.AUX_IN_OUT != sink_item.AUX_IN_OUT) begin
            `uvm_error(get_type_name(), $sformatf("Mismatch in AUX_IN_OUT: expected=%0h, actual=%0h", expected_transaction.AUX_IN_OUT, sink_item.AUX_IN_OUT))
            error_count++;
        end
        else begin
            `uvm_info(get_type_name(), "Transactions match", UVM_MEDIUM)
            correct_count++;
        end

        ///////////////////// ISO TRANSACTION COMPARISON /////////////////////
        
        if (expected_transaction.ISO_symbols_lane0 !== sink_item.ISO_symbols_lane0) begin
            `uvm_error(get_type_name(), $sformatf("Mismatch in ISO_symbols_lane0: expected=%0h, actual=%0h", expected_transaction.ISO_symbols_lane0, sink_item.ISO_symbols_lane0))
            error_count++;
        end
        else begin
            `uvm_info(get_type_name(), "Transactions match", UVM_MEDIUM)
            correct_count++;
        end

        if (expected_transaction.ISO_symbols_lane1 !== sink_item.ISO_symbols_lane1) begin
            `uvm_error(get_type_name(), $sformatf("Mismatch in ISO_symbols_lane1: expected=%0h, actual=%0h", expected_transaction.ISO_symbols_lane1, sink_item.ISO_symbols_lane1))
            error_count++;
        end
        else begin
            `uvm_info(get_type_name(), "Transactions match", UVM_MEDIUM)
            correct_count++;
        end

        if (expected_transaction.ISO_symbols_lane2 !== sink_item.ISO_symbols_lane2) begin
            `uvm_error(get_type_name(), $sformatf("Mismatch in ISO_symbols_lane2: expected=%0h, actual=%0h", expected_transaction.ISO_symbols_lane2, sink_item.ISO_symbols_lane2))
            error_count++;
        end
        else begin
            `uvm_info(get_type_name(), "Transactions match", UVM_MEDIUM)
            correct_count++;
        end

        if (expected_transaction.ISO_symbols_lane3 !== sink_item.ISO_symbols_lane3) begin
            `uvm_error(get_type_name(), $sformatf("Mismatch in ISO_symbols_lane3: expected=%0h, actual=%0h", expected_transaction.ISO_symbols_lane3, sink_item.ISO_symbols_lane3))
            error_count++;
        end
        else begin
            `uvm_info(get_type_name(), "Transactions match", UVM_MEDIUM)
            correct_count++;
        end

        if (expected_transaction.Control_sym_flag_lane0 !== sink_item.Control_sym_flag_lane0) begin
            `uvm_error(get_type_name(), $sformatf("Mismatch in Control_sym_flag_lane0: expected=%0h, actual=%0h", expected_transaction.Control_sym_flag_lane0, sink_item.Control_sym_flag_lane0))
            error_count++;
        end
        else begin
            `uvm_info(get_type_name(), "Transactions match", UVM_MEDIUM)
            correct_count++;
        end

        if (expected_transaction.Control_sym_flag_lane1 !== sink_item.Control_sym_flag_lane1) begin
            `uvm_error(get_type_name(), $sformatf("Mismatch in Control_sym_flag_lane1: expected=%0h, actual=%0h", expected_transaction.Control_sym_flag_lane1, sink_item.Control_sym_flag_lane1))
            error_count++;
        end
        else begin
            `uvm_info(get_type_name(), "Transactions match", UVM_MEDIUM)
            correct_count++;
        end

        if (expected_transaction.Control_sym_flag_lane2 !== sink_item.Control_sym_flag_lane2) begin
            `uvm_error(get_type_name(), $sformatf("Mismatch in Control_sym_flag_lane2: expected=%0h, actual=%0h", expected_transaction.Control_sym_flag_lane2, sink_item.Control_sym_flag_lane2))
            error_count++;
        end
        else begin
            `uvm_info(get_type_name(), "Transactions match", UVM_MEDIUM)
            correct_count++;
        end

        if (expected_transaction.Control_sym_flag_lane3 !== sink_item.Control_sym_flag_lane3) begin
            `uvm_error(get_type_name(), $sformatf("Mismatch in Control_sym_flag_lane3: expected=%0h, actual=%0h", expected_transaction.Control_sym_flag_lane3, sink_item.Control_sym_flag_lane3))
            error_count++;
        end
        else begin
            `uvm_info(get_type_name(), "Transactions match", UVM_MEDIUM)
            correct_count++;
        end

        if (expected_transaction.WFULL !== tl_item.WFULL) begin
            `uvm_error(get_type_name(), $sformatf("Mismatch in WFULL: expected=%0h, actual=%0h", expected_transaction.WFULL, tl_item.WFULL))
            error_count++;
        end
        else begin
            `uvm_info(get_type_name(), "Transactions match", UVM_MEDIUM)
            correct_count++;
        end
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("report_phase", $sformatf("Total successful transactions: %d", correct_count), UVM_MEDIUM);
        `uvm_info("report_phase", $sformatf("Total failed transactions: %d", error_count), UVM_MEDIUM);
    endfunction
    
endclass