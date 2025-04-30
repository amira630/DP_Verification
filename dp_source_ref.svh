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
    bit ready; // for when ISO is ready to transition from IDLE to actual stream transmission
    bit BS_flag, SR_flag, BF_flag, MSA_done, FS_flag, FE_flag; // Flags for ready and busy states
    iso_idle_code cs_0, cs_1, cs_2, cs_3, ns_0, ns_1, ns_2, ns_3; // Current and next state variables for the IDLE pattern
    int counter_0, counter_SR_0, counter_1, counter_SR_1, counter_2, counter_SR_2, counter_3, counter_SR_3, count_MSA_0, count_MSA_1, count_MSA_2, count_MSA_3; // Reset MSA counters to initial values; // Counters for the number of symbols sent
    int count_VBLANK; // Counter for the number of VBLANK symbols sent
    
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
            generate_expected_transaction(tl_item, expected_transaction); // Generate expected transaction based on TL item
        end
        phase.drop_objection(this); // Drop objection when done
        `uvm_info(get_type_name(), "Reference model run_phase completed", UVM_LOW)
    endtask

    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////// NOTES ///////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////


    // Need to add something to let it know when it is ready to stop the IDLE transmission and start the actual stream transmission
    // .VBLANK stateقبل ما اروح لل IDLE stateلازم اعرف هقعد قد ايه في ال 
    // Need the HTOTAL_PERIOD and VBLANK_PERIOD in terms of clock cycles to be calculated in their own functions
    // Remaining for me is ACTIVE state

    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////// NOTES ///////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////

    // This function is basically an FSM for what is the expected output of the DP source Main Lanes and Control Signals during ISO Services
    function void generate_expected_transaction( 
        input dp_tl_sequence_item tl_item,      // Transaction from dp_tl_monitor
        output dp_transaction expected_transaction // Generated expected transaction
    );
        if (tl_item.LT_Pass) begin // Check if link remained trained
            fork
                begin
                    case (cs)
                        ISO_IDLE: begin
                            ISO_IDLE_PATTERN(tl_item, expected_transaction); // Call ISO_IDLE function to handle IDLE state
                            counter_SR_0 = 0;
                            cs_0 = ISO_SR; 
                            if(tl_item.ISO_LC == 2'b01) begin
                                    counter_SR_1 = 0;
                                    cs_1 = ISO_SR; 
                            end
                            else if (tl_item.ISO_LC == 2'b11) begin
                                    counter_SR_1 = 0; counter_SR_2 = 0; counter_SR_3 = 0;
                                    cs_1 = ISO_SR; cs_2 = ISO_SR; cs_3 = ISO_SR;
                            end
                            if (tl_item.SPM_ISO_start) begin
                                ns = ISO_VBLANK; // Transition to VBLANK state
                            end else begin
                                ns = ISO_IDLE; // Stay in IDLE state
                            end
                        end 
                        ISO_VBLANK: begin
                            ISO_VBLANK_PATTERN(tl_item, expected_transaction); // Call VBLANK function to handle VBLANK state
                            MSA_done = 1'b0; // Reset MSA_done flag after sending VBLANK symbols for the current video frame
                            count_MSA_0 = 0; count_MSA_1 = 0; count_MSA_2 = 0; count_MSA_3 = 0;
                            if (tl_item.SPM_ISO_start) begin
                                ns = ISO_HBLANK; // Transition to HBLANK state
                            end else begin
                                ns = ISO_IDLE; // ransition to IDLE state
                            end
                        end 
                        ISO_HBLANK:
                        ISO_ACTIVE: begin
                            ISO_
                            if (tl_item.SPM_ISO_start) begin
                                ns = ISO_HBLANK; // Transition to HBLANK state
                            end else begin
                                ns = ISO_IDLE; // ransition to IDLE state
                            end
                        end
                        default:
                            // Default case to handle unexpected states
                            `uvm_fatal("ISO_STATE_ERROR", "Invalid state in ISO operation")
                    endcase
                end

                begin 
                    if(~tl_item.rst_n) begin
                        cs = ISO_IDLE; // Reset state to ISO_IDLE
                        cs_0 = ISO_SR; cs_1 = ISO_SR; cs_2 = ISO_SR; cs_3 = ISO_SR; 
                        counter_0 = 0; counter_SR_0 = 0; // Reset state and counters to initial values
                        counter_1 = 0; counter_SR_1 = 0; // Reset state and counters to initial values
                        counter_2 = 0; counter_SR_2 = 0; // Reset state and counters to initial values
                        counter_3 = 0; counter_SR_3 = 0; // Reset state and counters to initial values
                        count_MSA_0 = 0; // Reset MSA counters to initial values
                    end else begin
                        cs = ns; // Update current state to next state
                    end
                end
            join
        end // Link training has failed and all ISO signals are don't cares and we need to retrain the link
        else begin
            expected_transaction.ISO_symbols_lane0 ='bx;
            expected_transaction.ISO_symbols_lane1 ='bx;
            expected_transaction.ISO_symbols_lane2 ='bx;
            expected_transaction.ISO_symbols_lane3 ='bx;
            expected_transaction.Control_sym_flag_lane0 ='bx;
            expected_transaction.Control_sym_flag_lane1 ='bx;
            expected_transaction.Control_sym_flag_lane2 ='bx;
            expected_transaction.Control_sym_flag_lane3 ='bx;
            ref_model_out_port.write(expected_transaction);
        end
    endfunction

    // This function sends the idle pattern on all 4 lanes 
    function void ISO_IDLE_PATTERN(input dp_tl_sequence_item tl_item, output dp_transaction expected_transaction);
        while(!ready) begin
            if (!tl_item.rst_n) begin
                cs_0 = ISO_SR; cs_1 = ISO_SR; cs_2 = ISO_SR; cs_3 = ISO_SR; 
                counter_0 = 0; counter_SR_0 = 0; // Reset state and counters to initial values
                counter_1 = 0; counter_SR_1 = 0; // Reset state and counters to initial values
                counter_2 = 0; counter_SR_2 = 0; // Reset state and counters to initial values
                counter_3 = 0; counter_SR_3 = 0; // Reset state and counters to initial values
                break; // Exit the loop if reset is active, link training no longer valid so ISO signals are don't cares
            end
            else begin
                cs_0 = ns_0; // Update current state to next state
                cs_1 = ns_1; // Update current state to next state
                cs_2 = ns_2; // Update current state to next state
                cs_3 = ns_3; // Update current state to next state
            end
            IDLE_PATTERN(tl_item, counter_SR_0, counter_0, cs_0, ns_0, expected_transaction.ISO_symbols_lane0, expected_transaction.Control_sym_flag_lane0); // Call IDLE_PATTERN function to handle IDLE state
            IDLE_PATTERN(tl_item, counter_SR_1, counter_1, cs_1, ns_1, expected_transaction.ISO_symbols_lane1, expected_transaction.Control_sym_flag_lane1); // Call IDLE_PATTERN function to handle IDLE state
            IDLE_PATTERN(tl_item, counter_SR_2, counter_2, cs_2, ns_2, expected_transaction.ISO_symbols_lane2, expected_transaction.Control_sym_flag_lane2); // Call IDLE_PATTERN function to handle IDLE state
            IDLE_PATTERN(tl_item, counter_SR_3, counter_3, cs_3, ns_3, expected_transaction.ISO_symbols_lane3, expected_transaction.Control_sym_flag_lane3); // Call IDLE_PATTERN function to handle IDLE state
            // Send the expected transaction to the scoreboard
            ref_model_out_port.write(expected_transaction);
        end             
    endfunction

    // This function creates the IDLE pattern to be sent on each lane
    function void IDLE_PATTERN(
        input dp_tl_sequence_item tl_item, 
        ref int counter_SR, counter, // Counters for the number of symbols sent
        ref iso_idle_code cs, ns, // Current and next state variables for the IDLE pattern
        output logic [AUX_DATA_WIDTH-1:0] ISO_symbols_lanex,
        output logic Control_sym_flag_lanex
    );
        case (cs)
            ISO_SR: begin // Start with sending SR symbol instead of BS symbol
                Control_sym_flag_lanex = 1'b1;
                ISO_symbols_lanex = SR;
                counter_SR = 0; // Reset counter after sending SR symbols
                SR_flag = 1'b1; // Set SR_flag to indicate that a SR symbol has been sent
                if(BF_flag) begin // if BF has been sent twice
                    ns = ISO_VB_ID; // Transition to VB_ID state
                    counter++; // Increment the counter for the number of symbols sent
                end
                else
                    ns = ISO_BF; // Transition to BF state
            end
            ISO_BS: begin // Send BS symbol 
                Control_sym_flag_lanex = 1'b1;
                ISO_symbols_lanex = BS;
                BS_flag = 1'b1; // Set BS_flag to indicate that a BS symbol has been sent
                if(BF_flag) begin // if BF has been sent twice
                    counter_SR++; // To make sure after every 512 BS Control Link Symbol sequences one gets replaced by a SR symbol sequence
                    counter++; // Increment the counter for the number of symbols sent
                    ns = ISO_VB_ID; // Transition to VB_ID state
                end
                else
                    ns = ISO_BF; // Transition to BF state
            end
            ISO_BF: begin
                Control_sym_flag_lanex = 1'b1;
                ISO_symbols_lanex = BF;
                if(!BF_flag) begin
                    ns = ISO_BF; // Transition to VB_ID state
                    BF_flag= 1'b1;
                end
                else begin
                    if(SR_flag) begin // If this Control symbol sequnce is SR go back and end it with an SR symbol
                        ns = ISO_SR; // Transition to VB_ID state
                    end
                    else if (BS_flag) begin // If this Control symbol sequnce is BS go back and end it with an BS symbol
                        ns = ISO_BS; // Reset count_SR after sending BS and BF symbols
                    end
                end
            end
            ISO_VB_ID:begin
                Control_sym_flag_lanex = 1'b0;
                ISO_symbols_lanex = 8'bx000_1000; // No Video or audio or active video stream this is VB-ID for an IDLE pattern
                counter++; // Increment the counter for the number of symbols sent
                ns = ISO_MVID; // Transition to MVID state
                BF_flag = 1'b0; // Reset BF_flag after sending VB_ID symbols
                BS_flag = 1'b0; // Reset BS_flag after sending VB_ID symbols
                SR_flag = 1'b0; // Reset SR_flag after sending VB_ID symbols
            end
            ISO_MVID:begin
                Control_sym_flag_lanex = 1'b0;
                ISO_symbols_lanex = 'bx;
                counter++; // Increment the counter for the number of symbols sent
                ns = ISO_MAUD; // Transition to MAUD state
            end
            ISO_MAUD:begin
                Control_sym_flag_lanex = 1'b0;
                ISO_symbols_lanex = 'bx;
                counter++; // Increment the counter for the number of symbols sent
                ns = ISO_DUMMY; // Transition to IDLE state
            end
            ISO_DUMMY:begin
                Control_sym_flag_lanex = 1'b0;
                ISO_symbols_lanex = 8'b0; // Dummy symbol for IDLE state
                counter++; // Increment the counter for the number of symbols sent
                if(counter<8188) begin
                    ns = ISO_DUMMY; // Stay in IDLE state
                end
                else begin
                    counter = 0;
                    if(counter_SR == 512) begin
                        ns = ISO_SR; // Transition to SR state
                    end
                    else
                        ns = ISO_BS; // Transition to BS state
                end
            end
            default: `uvm_fatal("ISO_STATE_ERROR", "Invalid state in ISO operation")
        endcase
    endfunction

    function void ISO_VBLANK_PATTERN(input dp_tl_sequence_item tl_item, output dp_transaction expected_transaction);
        case(tl_item.ISO_LC) // according to the actvie lane count, send VBlank on all active lanes and remain with IDLE pattern on inactive lanes
            2'b00: begin // // Data transmission on 1 lane
                while(count_VBLANK < VBLANK_PERIOD) begin
                    if (!tl_item.rst_n) begin
                        cs_0 = ISO_SR; cs_1 = ISO_SR; cs_2 = ISO_SR; cs_3 = ISO_SR; 
                        counter_0 = 0; counter_SR_0 = 0; // Reset state and counters to initial values
                        counter_1 = 0; counter_SR_1 = 0; // Reset state and counters to initial values
                        counter_2 = 0; counter_SR_2 = 0; // Reset state and counters to initial values
                        counter_3 = 0; counter_SR_3 = 0; // Reset state and counters to initial values
                        count_MSA_0 = 0; // Reset MSA counters to initial values
                        break; // Exit the loop if reset is active
                    end
                    else begin
                        cs_0 = ns_0; // Update current state to next state
                        cs_1 = ns_1; // Update current state to next state
                        cs_2 = ns_2; // Update current state to next state
                        cs_3 = ns_3; // Update current state to next state
                    end
                    send_vblank_symbols(tl_item, counter_SR_0, counter_0, count_MSA_0, cs_0, ns_0, tl_item.ISO_LC, 2'd0, expected_transaction.ISO_symbols_lane0, expected_transaction.Control_sym_flag_lane0); // Call VBLANK_PATTERN function to handle VBLANK state
                    IDLE_PATTERN(tl_item, counter_SR_1, counter_1, cs_1, ns_1, expected_transaction.ISO_symbols_lane1, expected_transaction.Control_sym_flag_lane1); // Call IDLE_PATTERN function to handle IDLE state
                    IDLE_PATTERN(tl_item, counter_SR_2, counter_2, cs_2, ns_2, expected_transaction.ISO_symbols_lane2, expected_transaction.Control_sym_flag_lane2); // Call IDLE_PATTERN function to handle IDLE state
                    IDLE_PATTERN(tl_item, counter_SR_3, counter_3, cs_3, ns_3, expected_transaction.ISO_symbols_lane3, expected_transaction.Control_sym_flag_lane3); // Call IDLE_PATTERN function to handle IDLE state
                    
                    count_VBLANK++; // Increment the VBLANK counter
                    // Send the expected transaction to the scoreboard
                    ref_model_out_port.write(expected_transaction); // Not SURE if this is correct
                end  
            end
            2'b01: begin // // Data transmission on 2 lanes
                while(count_VBLANK < VBLANK_PERIOD) begin
                    if (!tl_item.rst_n) begin
                        cs_0 = ISO_IDLE; cs_1 = ISO_IDLE; cs_2 = ISO_IDLE; cs_3 = ISO_IDLE; 
                        counter_0 = 0; counter_SR_0 = 0; // Reset state and counters to initial values
                        counter_1 = 0; counter_SR_1 = 0; // Reset state and counters to initial values
                        counter_2 = 0; counter_SR_2 = 0; // Reset state and counters to initial values
                        counter_3 = 0; counter_SR_3 = 0; // Reset state and counters to initial values
                        count_MSA_0 = 0; count_MSA_1 = 0; // Reset MSA counters to initial values
                        break; // Exit the loop if reset is active
                    end
                    else begin
                        cs_0 = ns_0; // Update current state to next state
                        cs_1 = ns_1; // Update current state to next state
                        cs_2 = ns_2; // Update current state to next state
                        cs_3 = ns_3; // Update current state to next state
                    end
                    send_vblank_symbols(tl_item, counter_SR_0, counter_0, cs_0, count_MSA_0, ns_0, tl_item.ISO_LC, 2'd0, expected_transaction.ISO_symbols_lane0, expected_transaction.Control_sym_flag_lane0); // Call VBLANK_PATTERN function to handle VBLANK state
                    send_vblank_symbols(tl_item, counter_SR_1, counter_1, cs_1, count_MSA_1, ns_1, tl_item.ISO_LC, 2'd1, expected_transaction.ISO_symbols_lane1, expected_transaction.Control_sym_flag_lane1); // Call VBLANK_PATTERN function to handle VBLANK state
                    IDLE_PATTERN(tl_item, counter_SR_2, counter_2, cs_2, ns_2, expected_transaction.ISO_symbols_lane2, expected_transaction.Control_sym_flag_lane2); // Call IDLE_PATTERN function to handle IDLE state
                    IDLE_PATTERN(tl_item, counter_SR_3, counter_3, cs_3, ns_3, expected_transaction.ISO_symbols_lane3, expected_transaction.Control_sym_flag_lane3); // Call IDLE_PATTERN function to handle IDLE state
                    
                    count_VBLANK++; // Increment the VBLANK counter
                    // Send the expected transaction to the scoreboard
                    ref_model_out_port.write(expected_transaction); // Not SURE if this is correct
                end             
            end
            2'b11: begin // Data transmission on 4 lanes
                while(count_VBLANK < VBLANK_PERIOD) begin
                    // SEND VBLANK pattern to all lanes
                    if (!tl_item.rst_n) begin
                        cs_0 = ISO_IDLE; cs_1 = ISO_IDLE; cs_2 = ISO_IDLE; cs_3 = ISO_IDLE; 
                        counter_0 = 0; counter_SR_0 = 0; // Reset state and counters to initial values
                        counter_1 = 0; counter_SR_1 = 0; // Reset state and counters to initial values
                        counter_2 = 0; counter_SR_2 = 0; // Reset state and counters to initial values
                        counter_3 = 0; counter_SR_3 = 0; // Reset state and counters to initial values
                        count_MSA_0 = 0; count_MSA_1 = 0; count_MSA_2 = 0; count_MSA_3 = 0; // Reset MSA counters to initial values
                        break; // Exit the loop if reset is active
                    end
                    else begin
                        cs_0 = ns_0; // Update current state to next state
                        cs_1 = ns_1; // Update current state to next state
                        cs_2 = ns_2; // Update current state to next state
                        cs_3 = ns_3; // Update current state to next state
                    end
                    send_vblank_symbols(tl_item, counter_SR_0, counter_0, count_MSA_0, cs_0, ns_0, tl_item.ISO_LC, 2'd0, expected_transaction.ISO_symbols_lane0, expected_transaction.Control_sym_flag_lane0); // Call VBLANK_PATTERN function to handle VBLANK state
                    send_vblank_symbols(tl_item, counter_SR_1, counter_1, count_MSA_1, cs_1, ns_1, tl_item.ISO_LC, 2'd1, expected_transaction.ISO_symbols_lane1, expected_transaction.Control_sym_flag_lane1); // Call VBLANK_PATTERN function to handle VBLANK state
                    send_vblank_symbols(tl_item, counter_SR_2, counter_2, count_MSA_2, cs_2, ns_2, tl_item.ISO_LC, 2'd2, expected_transaction.ISO_symbols_lane2, expected_transaction.Control_sym_flag_lane2); // Call VBLANK_PATTERN function to handle VBLANK state
                    send_vblank_symbols(tl_item, counter_SR_3, counter_3, count_MSA_3, cs_3, ns_3, tl_item.ISO_LC, 2'd3, expected_transaction.ISO_symbols_lane3, expected_transaction.Control_sym_flag_lane3); // Call VBLANK_PATTERN function to handle VBLANK state
                    count_VBLANK++; // Increment the VBLANK counter
                    // Send the expected transaction to the scoreboard
                    ref_model_out_port.write(expected_transaction);
                end             
            end
            default:    // Default case to handle unexpected states
                `uvm_fatal("ISO_LANE_NUM_ERROR", "Invalid lane number in ISO operation! Lane Count cannot be 3!")
        endcase
    endfunction

    function void send_vblank_symbols(
        input dp_tl_sequence_item tl_item,
        ref int counter_SR, counter, count_MSA, // Counters for the number of symbols sent
        ref iso_idle_code cs, ns, // Current and next state variables for the IDLE pattern
        input bit [1:0] lane_num, 
        input bit [1:0] lane_id,
        output logic [AUX_DATA_WIDTH-1:0] ISO_symbols_lanex,
        output logic Control_sym_flag_lanex
    );
        int count_lc; // to count which round of VB-ID, Mvid adn Maud is this 
        case (cs)
            ISO_SR: begin
                Control_sym_flag_lanex = 1'b1;
                ISO_symbols_lanex = SR;
                counter_SR = 0; // Reset counter after sending SR symbols
                SR_flag = 1'b1;
                if(BF_flag) begin
                    ns = ISO_VB_ID; // Transition to VB_ID state
                    counter++; // Increment the counter for the number of symbols sent
                end
                else
                    ns = ISO_BF; // Transition to BF state
            end
            ISO_BS: begin
                Control_sym_flag_lanex = 1'b1;
                ISO_symbols_lanex = BS;
                BS_flag = 1'b1;
                if(BF_flag) begin
                    counter_SR++;
                    counter++; // Increment the counter for the number of symbols sent
                    ns = ISO_VB_ID; // Transition to VB_ID state
                end
                else
                    ns = ISO_BF; // Transition to BF state
            end
            ISO_BF: begin
                Control_sym_flag_lanex = 1'b1;
                ISO_symbols_lanex = BF;
                if(!BF_flag) begin
                    ns = ISO_BF; // Transition to VB_ID state
                    BF_flag= 1'b1;
                end
                else begin
                    if(SR_flag) begin
                        ns = ISO_SR; // Transition to VB_ID state
                    end
                    else if (BS_flag) begin
                        ns = ISO_BS; // Reset count_SR after sending BS and BF symbols
                    end
                end
            end
            ISO_VB_ID:begin
                Control_sym_flag_lanex = 1'b0;
                ISO_symbols_lanex = 8'bx000_1000;  //lessa hashof ha5aleha kaaaaaam
                counter++; // Increment the counter for the number of symbols sent
                ns = ISO_MVID; // Transition to MVID state
                BF_flag = 1'b0; // Reset BF_flag after sending VB_ID symbols
                BS_flag = 1'b0; // Reset BS_flag after sending VB_ID symbols
                SR_flag = 1'b0; // Reset SR_flag after sending VB_ID symbols
            end
            ISO_MVID:begin
                Control_sym_flag_lanex = 1'b0;
                ISO_symbols_lanex = 8'h00;
                counter++; // Increment the counter for the number of symbols sent
                ns = ISO_MAUD; // Transition to MAUD state
            end
            ISO_MAUD:begin
                Control_sym_flag_lanex = 1'b0;
                ISO_symbols_lanex = 8'h00;
                counter++; // Increment the counter for the number of symbols sent
                
                if((lane_num== 2'b00 && count_lc < 4) || (lane_num== 2'b01 && count_lc < 2)) begin // if not done with iterations repeat
                    ns = ISO_VB_ID; // Rpeat from VB-ID
                    count_lc++; // Increment
                end
                else begin
                    count_lc= 0;
                    if(MSA_done) begin
                        ns = ISO_MSA; // Transition to MSA state
                    end
                    else begin
                        ns = ISO_DUMMY; // Transition to dummy state
                    end
                end  
            end
            ISO_DUMMY:begin
                Control_sym_flag_lanex = 1'b0;
                ISO_symbols_lanex = 'b0; // Dummy symbol for IDLE state
                counter++; // Increment the counter for the number of symbols sent
                if(counter<HTOTAL_PERIOD) begin
                    ns = ISO_DUMMY; // Stay in IDLE state
                end
                else begin
                    counter = 0;
                    if(counter_SR == 512) begin
                        ns = ISO_SR; // Transition to SR state
                    end
                    else
                        ns = ISO_BS; // Transition to BS state
                end
            end
            ISO_MSA:begin
                counter++; // Increment the counter for the number of symbols sent
                if(count_MSA== 0 || count_MSA== 1) begin
                    ISO_symbols_lanex = SS;
                    Control_sym_flag_lanex = 1'b1;
                    ns = ISO_MSA; // Stay in MSA state
                    count_MSA++; // Increment the counter for the number of symbols sent
                end
                else if((lane_num== 2'b11 && count_MSA < 11) || (lane_num== 2'b01 && count_MSA < 20) || (lane_num== 2'b00 && count_MSA < 38)) begin // how much time needed for MSA transmission depending on lane count
                    Control_sym_flag_lanex = 1'b0;
                    MSA_symbols(tl_item, lane_num, lane_id, count_MSA-2, ISO_symbols_lanex); // Call MSA_symbols function to handle MSA state
                    count_MSA++; // Increment the counter for the number of symbols sent
                    ns = ISO_MSA; // Stay in MSA state
                end
                else begin
                    Control_sym_flag_lanex = 1'b1;
                    ISO_symbols_lanex = SE; 
                    count_MSA= 0;
                    MSA_done = 1'b1;
                    if(counter<HTOTAL_PERIOD) begin 
                        ns = ISO_DUMMY; // Stay in IDLE state
                    end
                    else begin
                        if(counter_SR == 512) begin
                            ns = ISO_SR; // Transition to SR state
                        end
                        else
                            ns = ISO_BS; // Transition to BS state
                    end
                end
            end
            default: `uvm_fatal("ISO_STATE_ERROR", "Invalid state in ISO operation in VBLANK_PATTERN function")
        endcase
    endfunction

    // This function is used specifically to transmit MSA symbols across each active lane
    function void MSA_symbols(
        input dp_tl_sequence_item tl_item,
        input bit [1:0] lane_num, // lane count
        input bit [1:0] lane_id, // lane number
        ref int count_MSA,
        output logic [AUX_DATA_WIDTH-1:0] ISO_symbols_lanex
    );
        bit [1:0] round_num; // Round number for MSA symbols
        if(count_MSA<9)
            round_num = 2'b00; // Round number 1 for lane 0, lane 1, lane 2, lane 3
        else if(count_MSA<18)
            round_num = 2'b01; // Round number 2 for lane 0, lane 1
        else if(count_MSA<27)
            round_num = 2'b10; // Round number 3 for lane 0
        else if(count_MSA<36)
            round_num = 2'b11; // Round number 4 for lane 0

        case(round_num)
            2'b00: begin // Round 1 for lane 0, lane 1, lane 2, lane 3
                case(lane_id)
                    2'b00: begin // lane0
                        case(count_MSA)
                            'd0: ISO_symbols_lanex = tl_item.Mvid[23:16]; // MSA symbol for lane 0, count 0
                            'd1: ISO_symbols_lanex = tl_item.Mvid[15:8]; // MSA symbol for lane 0, count 1
                            'd2: ISO_symbols_lanex = tl_item.Mvid[7:0]; // MSA symbol for lane 0, count 2
                            'd3: ISO_symbols_lanex = tl_item.HTotal[15:8]; // MSA symbol for lane 0, count 3
                            'd4: ISO_symbols_lanex = tl_item.HTotal[7:0]; // MSA symbol for lane 0, count 4
                            'd5: ISO_symbols_lanex = tl_item.VTotal[15:8]; // MSA symbol for lane 0, count 5
                            'd6: ISO_symbols_lanex = tl_item.VTotal[7:0]; // MSA symbol for lane 0, count 6
                            'd7: ISO_symbols_lanex = {tl_item.HSP, tl_item.HSW[14:8]}; // MSA symbol for lane 0, count 7
                            'd8: ISO_symbols_lanex = tl_item.HSW[7:0]; // MSA symbol for lane 0, count 8
                            default: `uvm_fatal("MSA_SYMBOLS_ERROR", "Invalid count_MSA in MSA_symbols function")
                        endcase
                    end
                    2'b01: begin // lane1
                        case(count_MSA)
                            'd0: ISO_symbols_lanex = tl_item.Mvid[23:16];                   // MSA symbol for lane 1, count 0
                            'd1: ISO_symbols_lanex = tl_item.Mvid[15:8];                    // MSA symbol for lane 1, count 1
                            'd2: ISO_symbols_lanex = tl_item.Mvid[7:0];                     // MSA symbol for lane 2, count 2
                            'd3: ISO_symbols_lanex = tl_item.HStart[15:8];                  // MSA symbol for lane 1, count 3
                            'd4: ISO_symbols_lanex = tl_item.HStart[7:0];                   // MSA symbol for lane 1, count 4
                            'd5: ISO_symbols_lanex = tl_item.VStart[15:8];                  // MSA symbol for lane 1, count 5
                            'd6: ISO_symbols_lanex = tl_item.VStart[7:0];                   // MSA symbol for lane 1, count 6
                            'd7: ISO_symbols_lanex = {tl_item.VSP, tl_item.VSW[14:8]};      // MSA symbol for lane 1, count 7
                            'd8: ISO_symbols_lanex = tl_item.VSW[7:0];                      // MSA symbol for lane 1, count 8
                            default: `uvm_fatal("MSA_SYMBOLS_ERROR", "Invalid count_MSA in MSA_symbols function")
                        endcase
                    end
                    2'b10: begin // lane2
                        case(count_MSA)
                            'd0: ISO_symbols_lanex = tl_item.Mvid[23:16];       // MSA symbol for lane 2, count 0
                            'd1: ISO_symbols_lanex = tl_item.Mvid[15:8];        // MSA symbol for lane 2, count 1
                            'd2: ISO_symbols_lanex = tl_item.Mvid[7:0];         // MSA symbol for lane 2, count 2
                            'd3: ISO_symbols_lanex = tl_item.HWidth[15:8];      // MSA symbol for lane 2, count 3
                            'd4: ISO_symbols_lanex = tl_item.HWidth[7:0];       // MSA symbol for lane 2, count 4
                            'd5: ISO_symbols_lanex = tl_item.VHeight[15:8];     // MSA symbol for lane 2, count 5
                            'd6: ISO_symbols_lanex = tl_item.VHeight[7:0];      // MSA symbol for lane 2, count 6
                            'd7: ISO_symbols_lanex = 8'h00;                     // MSA symbol for lane 2, count 7
                            'd8: ISO_symbols_lanex = 8'h00;                     // MSA symbol for lane 2, count 8
                            default: `uvm_fatal("MSA_SYMBOLS_ERROR", "Invalid count_MSA in MSA_symbols function")
                        endcase
                    end
                    2'b11: begin // lane3
                        case(count_MSA)
                            'd0: ISO_symbols_lanex = tl_item.Mvid[23:16];   // MSA symbol for lane 3, count 3
                            'd1: ISO_symbols_lanex = tl_item.Mvid[15:8];    // MSA symbol for lane 3, count 1
                            'd2: ISO_symbols_lanex = tl_item.Mvid[7:0];     // MSA symbol for lane 3, count 2
                            'd3: ISO_symbols_lanex = tl_item.Nvid[23:16];   // MSA symbol for lane 3, count 3
                            'd4: ISO_symbols_lanex = tl_item.Nvid[15:8];    // MSA symbol for lane 3, count 4
                            'd5: ISO_symbols_lanex = tl_item.Nvid[7:0];     // MSA symbol for lane 3, count 5
                            'd6: ISO_symbols_lanex = tl_item.MISC0;         // MSA symbol for lane 3, count 6
                            'd7: ISO_symbols_lanex = tl_item.MISC1;         // MSA symbol for lane 3, count 7
                            'd8: ISO_symbols_lanex = 8'h00;     	        // MSA symbol for lane 3, count 8
                            default: `uvm_fatal("MSA_SYMBOLS_ERROR", "Invalid count_MSA in MSA_symbols function")
                        endcase
                    end
                endcase
            end
            2'b01: begin // Round 2 for lane 0, lane 1
                case(lane_id) 
                    2'b00: begin // lane0
                        if(lane_num==2'b01) begin // if lane count is 2
                            case(count_MSA-9)
                                'd0: ISO_symbols_lanex = tl_item.Mvid[23:16]; // MSA symbol for lane 0, count 0
                                'd1: ISO_symbols_lanex = tl_item.Mvid[15:8]; // MSA symbol for lane 0, count 1
                                'd2: ISO_symbols_lanex = tl_item.Mvid[7:0]; // MSA symbol for lane 0, count 2
                                'd3: ISO_symbols_lanex = tl_item.HWidth[15:8]; // MSA symbol for lane 0, count 3
                                'd4: ISO_symbols_lanex = tl_item.HWidth[7:0]; // MSA symbol for lane 0, count 4
                                'd5: ISO_symbols_lanex = tl_item.VHeight[15:8]; // MSA symbol for lane 0, count 5
                                'd6: ISO_symbols_lanex = tl_item.VHeight[7:0]; // MSA symbol for lane 0, count 6
                                'd7: ISO_symbols_lanex = 8'h00; // MSA symbol for lane 0, count 7
                                'd8: ISO_symbols_lanex = 8'h00; // MSA symbol for lane 0, count 8
                                default: `uvm_fatal("MSA_SYMBOLS_ERROR", "Invalid count_MSA in MSA_symbols function")
                            endcase
                        end 
                        else begin  // if lane count is 4
                            case(count_MSA-9)
                                'd0: ISO_symbols_lanex = tl_item.Mvid[23:16]; // MSA symbol for lane 0, count 0
                                'd1: ISO_symbols_lanex = tl_item.Mvid[15:8]; // MSA symbol for lane 0, count 1
                                'd2: ISO_symbols_lanex = tl_item.Mvid[7:0]; // MSA symbol for lane 0, count 2
                                'd3: ISO_symbols_lanex = tl_item.HStart[15:8]; // MSA symbol for lane 0, count 3
                                'd4: ISO_symbols_lanex = tl_item.HStart[7:0]; // MSA symbol for lane 0, count 4
                                'd5: ISO_symbols_lanex = tl_item.VStart[15:8]; // MSA symbol for lane 0, count 5
                                'd6: ISO_symbols_lanex = tl_item.VStart[7:0]; // MSA symbol for lane 0, count 6
                                'd7: ISO_symbols_lanex = {tl_item.VSP, tl_item.VSW[14:8]}; // MSA symbol for lane 0, count 7
                                'd8: ISO_symbols_lanex = tl_item.VSW[7:0]; // MSA symbol for lane 0, count 8
                                default: `uvm_fatal("MSA_SYMBOLS_ERROR", "Invalid count_MSA in MSA_symbols function")
                            endcase
                        end
                    end
                    2'b01: begin // lane1
                        case(count_MSA-9)
                                'd0: ISO_symbols_lanex = tl_item.Mvid[23:16]; // MSA symbol for lane 0, count 0
                                'd1: ISO_symbols_lanex = tl_item.Mvid[15:8]; // MSA symbol for lane 0, count 1
                                'd2: ISO_symbols_lanex = tl_item.Mvid[7:0]; // MSA symbol for lane 0, count 2
                                'd3: ISO_symbols_lanex = tl_item.Nvid[23:16]; // MSA symbol for lane 0, count 3
                                'd4: ISO_symbols_lanex = tl_item.Nvid[15:8]; // MSA symbol for lane 0, count 4
                                'd5: ISO_symbols_lanex = tl_item.Nvid[7:0]; // MSA symbol for lane 0, count 5
                                'd6: ISO_symbols_lanex = tl_item.MISC0; // MSA symbol for lane 0, count 6
                                'd7: ISO_symbols_lanex = tl_item.MISC1; // MSA symbol for lane 0, count 7
                                'd8: ISO_symbols_lanex = 8'h00; // MSA symbol for lane 0, count 8
                                default: `uvm_fatal("MSA_SYMBOLS_ERROR", "Invalid count_MSA in MSA_symbols function")
                            default: `uvm_fatal("MSA_SYMBOLS_ERROR", "Invalid count_MSA in MSA_symbols function")
                        endcase
                    end
                    default: `uvm_fatal("MSA_SYMBOLS_ERROR", "Invalid lane_id in MSA_symbols function")
                endcase
            end
            2'b10: begin // Round 3 for lane 0
                case(count_MSA-18)
                    'd0: ISO_symbols_lanex = tl_item.Mvid[23:16]; // MSA symbol for lane 0, count 0
                    'd1: ISO_symbols_lanex = tl_item.Mvid[15:8]; // MSA symbol for lane 0, count 1
                    'd2: ISO_symbols_lanex = tl_item.Mvid[7:0]; // MSA symbol for lane 0, count 2
                    'd3: ISO_symbols_lanex = tl_item.HWidth[15:8]; // MSA symbol for lane 0, count 3
                    'd4: ISO_symbols_lanex = tl_item.HWidth[7:0]; // MSA symbol for lane 0, count 4
                    'd5: ISO_symbols_lanex = tl_item.VHeight[15:8]; // MSA symbol for lane 0, count 5
                    'd6: ISO_symbols_lanex = tl_item.VHeight[7:0]; // MSA symbol for lane 0, count 6
                    'd7: ISO_symbols_lanex = 8'h00; // MSA symbol for lane 0, count 7
                    'd8: ISO_symbols_lanex = 8'h00; // MSA symbol for lane 0, count 8
                    default: `uvm_fatal("MSA_SYMBOLS_ERROR", "Invalid count_MSA in MSA_symbols function")
                endcase
            end
            2'b11: begin // Round 4 for lane 0
                case(count_MSA-27)
                    'd0: ISO_symbols_lanex = tl_item.Mvid[23:16]; // MSA symbol for lane 0, count 0
                    'd1: ISO_symbols_lanex = tl_item.Mvid[15:8]; // MSA symbol for lane 0, count 1
                    'd2: ISO_symbols_lanex = tl_item.Mvid[7:0]; // MSA symbol for lane 0, count 2
                    'd3: ISO_symbols_lanex = tl_item.Nvid[23:16]; // MSA symbol for lane 0, count 3
                    'd4: ISO_symbols_lanex = tl_item.Nvid[15:8]; // MSA symbol for lane 0, count 4
                    'd5: ISO_symbols_lanex = tl_item.Nvid[7:0]; // MSA symbol for lane 0, count 5
                    'd6: ISO_symbols_lanex = tl_item.MISC0; // MSA symbol for lane 0, count 6
                    'd7: ISO_symbols_lanex = tl_item.MISC1; // MSA symbol for lane 0, count 7
                    'd8: ISO_symbols_lanex = 8'h00; // MSA symbol for lane 0, count 8
                    default: `uvm_fatal("MSA_SYMBOLS_ERROR", "Invalid count_MSA in MSA_symbols function")
                endcase
            end
        endcase
    endfunction
endclass