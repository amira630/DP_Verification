class dp_source_ref extends uvm_scoreboard;
    `uvm_component_utils(dp_source_ref)

    // Input and output analysis ports for connecting to the scoreboard
    uvm_analysis_export #(dp_sink_sequence_item) sink_in_export;  // Receives transactions from dp_sink_monitor
    uvm_analysis_export #(dp_tl_sequence_item) tl_in_export;      // Receives transactions from dp_tl_monitor
    uvm_analysis_port #(dp_transaction) ref_model_out_port; // Sends expected transactions to the scoreboard

    // Transaction variables for output of Reference model
    dp_transaction expected_transaction;
    dp_sink_sequence_item sink_item;
    dp_tl_sequence_item tl_item;
    iso_op_code cs, ns; // Current and next state variables for the reference model
    bit ready, BS_flag, SR_flag, BE_flag, SS_flag, FS_flag, FE_flag, VB_ID_flag, MVID_flag, MAUD_flag; // Flags for ready and busy states
    int count_BF;
    // Constructor
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    // Build phase
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        sink_in_export = new("sink_in_export", this);
        tl_in_export = new("tl_in_export", this);
        ref_model_out_port = new("ref_model_out_port", this);
        expected_transaction = dp_transaction::type_id::create("expected_transaction", this);
        tl_item = dp_tl_sequence_item::type_id::create("tl_item");
        sink_item = dp_sink_sequence_item::type_id::create("sink_item");
        `uvm_info(get_type_name(), "Reference model build_phase completed", UVM_LOW)
    endfunction

// Run phase
    task run_phase(uvm_phase phase);
        phase.raise_objection(this); // Raise objection to keep the simulation running
        super.run_phase(phase);
        // Reference model logic to generate expected transactions
        // This is a placeholder for the actual reference model logic
        forever begin
            expected_transaction = dp_transaction::type_id::create("expected_transaction");
            generate_expected_transaction(tl_item, sink_item, expected_transaction); // Generate expected transaction based on sink and TL items
        end
        phase.drop_objection(this); // Drop objection when done
        `uvm_info(get_type_name(), "Reference model run_phase completed", UVM_LOW)
    endtask

    function void generate_expected_transaction(
        input dp_tl_sequence_item tl_item,      // Transaction from dp_tl_monitor
        input dp_sink_sequence_item sink_item,  // Transaction from dp_sink_monitor
        output dp_transaction expected_transaction // Generated expected transaction
    );
        if (tl_item.SPM_ISO_start) begin
            fork
                begin
                    case (cs)
                        ISO_IDLE: ISO_IDLE(tl_item, expected_transaction); // Call ISO_IDLE function to handle IDLE state
                        ISO_VBLANK:
                        ISO_HBLANK:
                        ISO_ACTIVE:
                        default:
                            // Default case to handle unexpected states
                            `uvm_fatal("ISO_STATE_ERROR", "Invalid state in ISO operation")
                    endcase
                end

                begin 
                    if(~tl_item.rst_n) begin
                        cs = ISO_IDLE; // Reset state to ISO_IDLE
                    end else begin
                        cs = ns; // Update current state to next state
                    end
                end
            join
        end
        else begin
            expected_transaction.ISO_symbols_lane0 ='bx;
            expected_transaction.ISO_symbols_lane1 ='bx;
            expected_transaction.ISO_symbols_lane2 ='bx;
            expected_transaction.ISO_symbols_lane3 ='bx;
            expected_transaction.Control_sym_flag_lane0 ='bx;
            expected_transaction.Control_sym_flag_lane1 ='bx;
            expected_transaction.Control_sym_flag_lane2 ='bx;
            expected_transaction.Control_sym_flag_lane3 ='bx;
        end
    endfunction

    function void ISO_IDLE(input dp_tl_sequence_item tl_item, output dp_transaction expected_transaction);
        int counter_SR = 0; // Counter for the number of symbols sent
        int counter = 0; // Counter for the number of BF symbols sent
        while(!ready) begin
            expected_transaction.Control_sym_flag_lane0 = 1'b1;
            expected_transaction.Control_sym_flag_lane1 = 1'b1;
            expected_transaction.Control_sym_flag_lane2 = 1'b1;
            expected_transaction.Control_sym_flag_lane3 = 1'b1;
            counter_SR++;
            counter++; // Increment the counter for the number of symbols sent
            if(!SR_flag || (counter_SR==513 || counter_SR == 1)) begin
                expected_transaction.ISO_symbols_lane0 = SR;
                expected_transaction.ISO_symbols_lane1 = SR;
                expected_transaction.ISO_symbols_lane2 = SR;
                expected_transaction.ISO_symbols_lane3 = SR;
                SR_flag = 1'b1;
                BS_flag = 1'b1;
                if(counter_SR == 513) begin
                    counter_SR = 0; // Reset counter after sending SR symbols
                    SR_flag = 1'b0;
                end
                continue; // Continue to the next iteration
            end
            else if(!BS_flag) begin
                expected_transaction.ISO_symbols_lane0 = BS;
                expected_transaction.ISO_symbols_lane1 = BS;
                expected_transaction.ISO_symbols_lane2 = BS;
                expected_transaction.ISO_symbols_lane3 = BS;
                BS_flag = 1'b1;
                continue; // Continue to the next iteration
            end
            else if(count_BF <2) begin
                expected_transaction.ISO_symbols_lane0 = BF;
                expected_transaction.ISO_symbols_lane1 = BF;
                expected_transaction.ISO_symbols_lane2 = BF;
                expected_transaction.ISO_symbols_lane3 = BF;
                count_BF++;
                if(count_BF == 2) begin
                    if(SR_flag)
                        SR_flag = 0; // Reset count_SR after sending BF symbols
                    else if (BS_flag)
                        BS_flag = 0; // Reset count_SR after sending BS and BF symbols
                end
                continue; // Continue to the next iteration
            end
            else if(!VB_ID_flag) begin
                expected_transaction.ISO_symbols_lane0 = 8'bx000_1000;
                expected_transaction.ISO_symbols_lane1 = 8'bx000_1000;
                expected_transaction.ISO_symbols_lane2 = 8'bx000_1000;
                expected_transaction.ISO_symbols_lane3 = 8'bx000_1000;
                VB_ID_flag = 1'b1;
                expected_transaction.Control_sym_flag_lane0 = 1'b0;
                expected_transaction.Control_sym_flag_lane1 = 1'b0;
                expected_transaction.Control_sym_flag_lane2 = 1'b0;
                expected_transaction.Control_sym_flag_lane3 = 1'b0;
                continue; // Continue to the next iteration
            end
            else if(!MVID_flag) begin
                expected_transaction.ISO_symbols_lane0 = 'bx;
                expected_transaction.ISO_symbols_lane1 = 'bx;
                expected_transaction.ISO_symbols_lane2 = 'bx;
                expected_transaction.ISO_symbols_lane3 = 'bx;
                MVID_flag = 1'b1;
                expected_transaction.Control_sym_flag_lane0 = 1'b0;
                expected_transaction.Control_sym_flag_lane1 = 1'b0;
                expected_transaction.Control_sym_flag_lane2 = 1'b0;
                expected_transaction.Control_sym_flag_lane3 = 1'b0;
                continue; // Continue to the next iteration    
            end
            else if(!MAUD_flag) begin
                expected_transaction.ISO_symbols_lane0 = 'bx;
                expected_transaction.ISO_symbols_lane1 = 'bx;
                expected_transaction.ISO_symbols_lane2 = 'bx;
                expected_transaction.ISO_symbols_lane3 = 'bx;
                MAUD_flag = 1'b1;
                expected_transaction.Control_sym_flag_lane0 = 1'b0;
                expected_transaction.Control_sym_flag_lane1 = 1'b0;
                expected_transaction.Control_sym_flag_lane2 = 1'b0;
                expected_transaction.Control_sym_flag_lane3 = 1'b0;
                continue; // Continue to the next iteration    
            end
        end 
    endfunction
endclass