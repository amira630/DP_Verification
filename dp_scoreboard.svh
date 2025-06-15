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
            compare_transactions_ISO(tl_item, sink_item, expected_transaction);

            `uvm_info("run_phase", tl_item.convert2string(), UVM_MEDIUM)
            `uvm_info("run_phase", sink_item.convert2string(), UVM_MEDIUM) 
        end
    endtask

    virtual function void compare_transactions_ISO(
        dp_tl_sequence_item tl_item,
        dp_sink_sequence_item sink_item, 
        dp_ref_transaction expected_transaction
    );

        ///////////////////// ISO TRANSACTION COMPARISON /////////////////////
        
        if (expected_transaction.ISO_symbols_lane0 !== sink_item.ISO_symbols_lane0) begin
            `uvm_error(get_type_name(), $sformatf("Mismatch in ISO_symbols_lane0: expected=%0h, actual=%0h", expected_transaction.ISO_symbols_lane0, sink_item.ISO_symbols_lane0))
            error_count++;
        end
        else begin
            `uvm_info(get_type_name(), "ISO_symbols_lane0 match", UVM_MEDIUM)
            correct_count++;
            // `uvm_fatal("SCOREBOARD", "ISO_symbols_lane0 match")
        end

        if (expected_transaction.ISO_symbols_lane1 !== sink_item.ISO_symbols_lane1) begin
            `uvm_error(get_type_name(), $sformatf("Mismatch in ISO_symbols_lane1: expected=%0h, actual=%0h", expected_transaction.ISO_symbols_lane1, sink_item.ISO_symbols_lane1))
            error_count++;
        end
        else begin
            `uvm_info(get_type_name(), "ISO_symbols_lane1 match", UVM_MEDIUM)
            correct_count++;
            // `uvm_fatal("SCOREBOARD", "ISO_symbols_lane1 match")
        end

        if (expected_transaction.ISO_symbols_lane2 !== sink_item.ISO_symbols_lane2) begin
            `uvm_error(get_type_name(), $sformatf("Mismatch in ISO_symbols_lane2: expected=%0h, actual=%0h", expected_transaction.ISO_symbols_lane2, sink_item.ISO_symbols_lane2))
            error_count++;
        end
        else begin
            `uvm_info(get_type_name(), "ISO_symbols_lane2 match", UVM_MEDIUM)
            correct_count++;
            // `uvm_fatal("SCOREBOARD", "ISO_symbols_lane2 match")
        end

        if (expected_transaction.ISO_symbols_lane3 !== sink_item.ISO_symbols_lane3) begin
            `uvm_error(get_type_name(), $sformatf("Mismatch in ISO_symbols_lane3: expected=%0h, actual=%0h", expected_transaction.ISO_symbols_lane3, sink_item.ISO_symbols_lane3))
            error_count++;
        end
        else begin
            `uvm_info(get_type_name(), "ISO_symbols_lane3 match", UVM_MEDIUM)
            correct_count++;
            // `uvm_fatal("SCOREBOARD", "ISO_symbols_lane3 match")
        end

        if (expected_transaction.Control_sym_flag_lane0 !== sink_item.Control_sym_flag_lane0) begin
            `uvm_error(get_type_name(), $sformatf("Mismatch in Control_sym_flag_lane0: expected=%0h, actual=%0h", expected_transaction.Control_sym_flag_lane0, sink_item.Control_sym_flag_lane0))
            error_count++;
        end
        else begin
            `uvm_info(get_type_name(), "Control_sym_flag_lane0 match", UVM_MEDIUM)
            correct_count++;
            // `uvm_fatal("SCOREBOARD", "Control_sym_flag_lane0 match")
        end

        if (expected_transaction.Control_sym_flag_lane1 !== sink_item.Control_sym_flag_lane1) begin
            `uvm_error(get_type_name(), $sformatf("Mismatch in Control_sym_flag_lane1: expected=%0h, actual=%0h", expected_transaction.Control_sym_flag_lane1, sink_item.Control_sym_flag_lane1))
            error_count++;
        end
        else begin
            `uvm_info(get_type_name(), "Control_sym_flag_lane1 match", UVM_MEDIUM)
            correct_count++;
            // `uvm_fatal("SCOREBOARD", "Control_sym_flag_lane1 match")
        end

        if (expected_transaction.Control_sym_flag_lane2 !== sink_item.Control_sym_flag_lane2) begin
            `uvm_error(get_type_name(), $sformatf("Mismatch in Control_sym_flag_lane2: expected=%0h, actual=%0h", expected_transaction.Control_sym_flag_lane2, sink_item.Control_sym_flag_lane2))
            error_count++;
        end
        else begin
            `uvm_info(get_type_name(), "Control_sym_flag_lane2 match", UVM_MEDIUM)
            correct_count++;
            // `uvm_fatal("SCOREBOARD", "Control_sym_flag_lane2 match")
        end

        if (expected_transaction.Control_sym_flag_lane3 !== sink_item.Control_sym_flag_lane3) begin
            `uvm_error(get_type_name(), $sformatf("Mismatch in Control_sym_flag_lane3: expected=%0h, actual=%0h", expected_transaction.Control_sym_flag_lane3, sink_item.Control_sym_flag_lane3))
            error_count++;
        end
        else begin
            `uvm_info(get_type_name(), "Control_sym_flag_lane3 match", UVM_MEDIUM)
            correct_count++;
            // `uvm_fatal("SCOREBOARD", "Control_sym_flag_lane3 match")
        end

        if (expected_transaction.WFULL !== tl_item.WFULL) begin
            `uvm_error(get_type_name(), $sformatf("Mismatch in WFULL: expected=%0h, actual=%0h", expected_transaction.WFULL, tl_item.WFULL))
            error_count++;
        end
        else begin
            `uvm_info(get_type_name(), "WFULL match", UVM_MEDIUM)
            correct_count++;
            // `uvm_fatal("SCOREBOARD", "WFULL match")
        end
    endfunction

    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("report_phase", $sformatf("Total successful transactions: %d", correct_count), UVM_MEDIUM);
        `uvm_info("report_phase", $sformatf("Total failed transactions: %d", error_count), UVM_MEDIUM);
    endfunction
    
endclass