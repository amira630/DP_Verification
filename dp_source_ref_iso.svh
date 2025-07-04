import uvm_pkg::*;
    `include "uvm_macros.svh"
import test_parameters_pkg::*;
import dp_transactions_pkg::*;
class dp_source_ref_iso extends uvm_component;
    `uvm_component_utils(dp_source_ref_iso)

    // Input and output analysis ports for connecting to the scoreboard
    // uvm_analysis_export #(dp_sink_sequence_item) sink_in_export;  // Receives transactions from dp_sink_monitor
    uvm_analysis_export #(dp_tl_sequence_item) tl_in_export;      // Receives transactions from dp_tl_monitor
    uvm_analysis_port #(dp_ref_transaction) ref_model_out_port; // Sends expected transactions to the scoreboard

    uvm_tlm_analysis_fifo #(dp_tl_sequence_item) ref_tl_fifo;
    // dummy_tl_sink dummy_sink;

    // Transaction variables for output of Reference model
    dp_ref_transaction expected_transaction;
    dp_tl_sequence_item tl_item;

    virtual dp_ref_if ref_vif;
    
    iso_op_code cs; // Current and next state variables for the reference model
    iso_idle_code cs_0, cs_1, cs_2, cs_3; // Current and next state variables for the IDLE pattern
    iso_TU_code cs_0_TU, cs_1_TU, cs_2_TU, cs_3_TU; // Current and next state variables for the Transfer Unit

    bit ready; // for when ISO is ready to transition from IDLE to actual stream transmission
    bit BF_flag, MSA_done, FS_flag, FE_flag, calc_flag, entered; // Flags for ready and busy states
    bit BS_flag_0, BS_flag_1, BS_flag_2, BS_flag_3, SR_flag_0, SR_flag_1, SR_flag_2, SR_flag_3, BF_flag_0, BF_flag_1, BF_flag_2, BF_flag_3;

    int counter_i, counter_0, counter_SR_0, counter_1, counter_SR_1, counter_2, counter_SR_2, counter_3, counter_SR_3, count_MSA_0, count_MSA_1, count_MSA_2, count_MSA_3; // Reset MSA counters to initial values; // Counters for the number of symbols sent
    int count_VBLANK, count_HBLANK_ACTIVE, count_HACTIVE; // Counter for the number of VBLANK  and HBLANK symbols sent
    
    logic [7:0] RED_8 [$];   logic [15:0] RED_16 [$];
    logic [7:0] GREEN_8 [$]; logic [15:0] GREEN_16 [$];
    logic [7:0] BLUE_8 [$];  logic [15:0] BLUE_16 [$];

    bit [15:0] RED, GREEN, BLUE; // Variables to store pixel data
    bit [2:0] ISO_LC;

    // Pixel clock and link parameters
    logic [23:0] Mvid_q[$];        // Replaces logic [23:0] Mvid
    logic [23:0] Nvid_q[$];        // Replaces logic [23:0] Nvid

    // Timing parameters
    logic [15:0] HTotal_q[$];
    logic [15:0] VTotal_q[$];
    logic [15:0] HStart_q[$];
    logic [15:0] VStart_q[$];
    logic [15:0] HWidth_q[$];
    logic [15:0] VHeight_q[$];

    // Sync polarities
    logic HSP_q[$];               // Replaces logic HSP
    logic VSP_q[$];               // Replaces logic VSP

    // Sync widths
    logic [14:0] HSW_q[$];
    logic [14:0] VSW_q[$];

    // Miscellaneous
    logic [7:0] MISC0_q[$];
    logic [7:0] MISC1_q[$];

    ////////// Variables to store Timing Parameters //////////////////
    logic [15:0] hactive_period;
    logic [15:0] hblank_period;
    logic [15:0] vblank_period;
    logic [15:0] htotal_period;
    logic [15:0] valid_symbols_integer;
    logic [15:0] valid_symbols_fraction;
    logic [3:0] tu_alternate_up;
    logic [3:0] tu_alternate_down;
    logic alternate_valid;
    
    // Constructor
    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    // Build phase
    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        // sink_in_export = new("sink_in_export", this);
        `uvm_info(get_type_name(), "build_phase reached", UVM_LOW)
        tl_in_export = new("tl_in_export", this);
        ref_model_out_port = new("ref_model_out_port", this);
        expected_transaction = dp_ref_transaction::type_id::create("expected_transaction", this);
        tl_item = dp_tl_sequence_item::type_id::create("tl_item");
        // sink_item = dp_sink_sequence_item::type_id::create("sink_item");
        // dummy_sink = dummy_tl_sink::type_id::create("dummy_sink", this);
        ref_tl_fifo = new("ref_tl_fifo", this);
        `uvm_info(get_type_name(), "Reference model build_phase completed", UVM_LOW)
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        tl_in_export.connect(ref_tl_fifo.analysis_export);

        `uvm_info(get_type_name(), "Ref model connect_phase completed", UVM_LOW)
    endfunction

    bit RESET, in_ISO, delay;
// Run phase
    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        phase.raise_objection(this); // Raise objection to keep the simulation running
        
        // Reference model logic to generate expected transactions
        // This is a placeholder for the actual reference model logic
        `uvm_info(get_type_name(), "Reference model run_phase started", UVM_MEDIUM)


        // counter_i++; // Increment the counter for the number of symbols sent
        forever begin
            fork
                begin
                    // Wait for the next transaction
                    ref_tl_fifo.get(tl_item);
                    `uvm_info(get_type_name(), $sformatf("Got TL item from FIFO: %s", tl_item.convert2string()), UVM_HIGH)
                    // `uvm_info(get_type_name(), "Got TL item from FIFO", UVM_MEDIUM)
                    if (!tl_item.MS_rst_n) begin
                        RESET = 1;
                        entered = 0;
                        delay = 0;
                    end
                    else if(tl_item.SPM_ISO_start) begin
                        ISO_LC = tl_item.SPM_Lane_Count;
                        in_ISO = 1;
                        RESET = 0;
                        entered = 1;
                        if(tl_item.MS_DE) begin
                            case(MISC0_q[0][7:5])
                                3'b001: begin // 8bpc
                                    RED_8.push_back(tl_item.MS_Pixel_Data[7:0]);
                                    GREEN_8.push_back(tl_item.MS_Pixel_Data[15:8]);
                                    BLUE_8.push_back(tl_item.MS_Pixel_Data[23:16]);
                                end
                                3'b100: begin // 16bpc
                                    RED_16.push_back(tl_item.MS_Pixel_Data[15:0]);
                                    GREEN_16.push_back(tl_item.MS_Pixel_Data[31:16]);
                                    BLUE_16.push_back(tl_item.MS_Pixel_Data[47:32]);
                                end
                            endcase
                        end
                        else if (tl_item.SPM_MSA_VLD) begin
                            Mvid_q.push_back(tl_item.SPM_Full_MSA[23:0]);
                            Nvid_q.push_back(tl_item.SPM_Full_MSA[47:24]);
                            HTotal_q.push_back(tl_item.SPM_Full_MSA[63:48]);
                            VTotal_q.push_back(tl_item.SPM_Full_MSA[79:64]);
                            HStart_q.push_back(tl_item.SPM_Full_MSA[95:80]);
                            VStart_q.push_back(tl_item.SPM_Full_MSA[111:96]);
                            HSP_q.push_back(tl_item.SPM_Full_MSA[112]);
                            HSW_q.push_back(tl_item.SPM_Full_MSA[127:113]);
                            VSP_q.push_back(tl_item.SPM_Full_MSA[128]);
                            VSW_q.push_back(tl_item.SPM_Full_MSA[143:129]);
                            HWidth_q.push_back(tl_item.SPM_Full_MSA[159:144]);
                            VHeight_q.push_back(tl_item.SPM_Full_MSA[175:160]);
                            MISC0_q.push_back(tl_item.SPM_Full_MSA[183:176]);
                            MISC1_q.push_back(tl_item.SPM_Full_MSA[191:184]);
                            calculate_timing_parameters(hactive_period, hblank_period, vblank_period, htotal_period, valid_symbols_integer, valid_symbols_fraction, tu_alternate_up, tu_alternate_down, alternate_valid);
                            // Mvid_q.delete(0); Nvid_q.delete(0); HTotal_q.delete(0); VTotal_q.delete(0); HStart_q.delete(0);
                            // VStart_q.delete(0); HSP_q.delete(0); HSW_q.delete(0); VSP_q.delete(0); VSW_q.delete(0);
                            // HWidth_q.delete(0); VHeight_q.delete(0); MISC0_q.delete(0); MISC1_q.delete(0);
                            `uvm_info(get_type_name(), "Calculated timing parameters for expected transaction", UVM_LOW)
                        end
                    end
                    else begin
                        in_ISO = 0;
                        delay = 0;
                        RESET = 0;
                    end
                end
                begin
                    if(RESET) begin // Reset
                        `uvm_info(get_type_name(), "Reset — initializing internal state", UVM_HIGH)
                        expected_transaction.ISO_symbols_lane0 ='b0;
                        expected_transaction.ISO_symbols_lane1 ='b0;
                        expected_transaction.ISO_symbols_lane2 ='b0;
                        expected_transaction.ISO_symbols_lane3 ='b0;
                        expected_transaction.Control_sym_flag_lane0 ='b0;
                        expected_transaction.Control_sym_flag_lane1 ='b0;
                        expected_transaction.Control_sym_flag_lane2 ='b0;
                        expected_transaction.Control_sym_flag_lane3 ='b0;
                        expected_transaction.WFULL = 1'b0; // Reset WFULL flag
                        cs = ISO_IDLE; // Reset state to ISO_IDLE
                        cs_0 = ISO_SR; cs_1 = ISO_SR; cs_2 = ISO_SR; cs_3 = ISO_SR; 
                        cs_0_TU = ISO_TU_PIXELS; cs_1_TU = ISO_TU_PIXELS; cs_2_TU = ISO_TU_PIXELS; cs_3_TU = ISO_TU_PIXELS;
                        counter_0 = 0; counter_SR_0 = 0; // Reset state and counters to initial values
                        counter_1 = 0; counter_SR_1 = 0; // Reset state and counters to initial values
                        counter_2 = 0; counter_SR_2 = 0; // Reset state and counters to initial values
                        counter_3 = 0; counter_SR_3 = 0; // Reset state and counters to initial values
                        count_MSA_0 = 0; count_MSA_1 = 0; count_MSA_2 = 0; count_MSA_3 = 0; // Reset MSA counters to initial values
                        count_VBLANK = 0; count_HBLANK_ACTIVE =0; count_HACTIVE =0; // Reset VBLANK and HBLANK counters to initial values
                        RED_8.delete(); RED_16.delete(); GREEN_8.delete(); GREEN_16.delete(); BLUE_8.delete(); BLUE_8.delete(); // Clear the pixel queue
                        Mvid_q.delete(); Nvid_q.delete(); HTotal_q.delete(); VTotal_q.delete(); HStart_q.delete();
                        VStart_q.delete(); HSP_q.delete(); HSW_q.delete(); VSP_q.delete(); VSW_q.delete();
                        HWidth_q.delete(); VHeight_q.delete(); MISC0_q.delete(); MISC1_q.delete();
                        `uvm_info(get_type_name(), "Allocated expected_transaction object", UVM_HIGH)
                        ref_vif.ref_expected_ISO_symbols_lane0 = expected_transaction.ISO_symbols_lane0;
                        ref_vif.ref_expected_ISO_symbols_lane1 = expected_transaction.ISO_symbols_lane1;
                        ref_vif.ref_expected_ISO_symbols_lane2 = expected_transaction.ISO_symbols_lane2;
                        ref_vif.ref_expected_ISO_symbols_lane3 = expected_transaction.ISO_symbols_lane3;

                        ref_vif.ref_expected_Control_sym_flag_lane0 = expected_transaction.Control_sym_flag_lane0;
                        ref_vif.ref_expected_Control_sym_flag_lane1 = expected_transaction.Control_sym_flag_lane1;
                        ref_vif.ref_expected_Control_sym_flag_lane2 = expected_transaction.Control_sym_flag_lane2;
                        ref_vif.ref_expected_Control_sym_flag_lane3 = expected_transaction.Control_sym_flag_lane3;
                        send_expected_to_scoreboard();
                    end
                    else if (in_ISO) begin // if reset is off and LT is passed
                        // `uvm_info(get_type_name(), $sformatf("VBlank value %0d", vblank_period), UVM_LOW)
                        if(!delay) begin
                            delay = 1;
                            repeat(4) begin
                                ref_vif.ref_expected_ISO_symbols_lane0 = expected_transaction.ISO_symbols_lane0;
                                ref_vif.ref_expected_ISO_symbols_lane1 = expected_transaction.ISO_symbols_lane1;
                                ref_vif.ref_expected_ISO_symbols_lane2 = expected_transaction.ISO_symbols_lane2;
                                ref_vif.ref_expected_ISO_symbols_lane3 = expected_transaction.ISO_symbols_lane3;

                                ref_vif.ref_expected_Control_sym_flag_lane0 = expected_transaction.Control_sym_flag_lane0;
                                ref_vif.ref_expected_Control_sym_flag_lane1 = expected_transaction.Control_sym_flag_lane1;
                                ref_vif.ref_expected_Control_sym_flag_lane2 = expected_transaction.Control_sym_flag_lane2;
                                ref_vif.ref_expected_Control_sym_flag_lane3 = expected_transaction.Control_sym_flag_lane3;
                                send_expected_to_scoreboard();
                            end
                        end
                        `uvm_info(get_type_name(), "Calling generate_expected_transaction()", UVM_LOW)
                        generate_expected_transaction(); // Generate expected transaction based on TL item
                        // if(!RESET && !in_ISO) begin
                        //     IDLE_PATTERN(SR_flag_0, BS_flag_0, BF_flag_0, counter_SR_0, counter_0, cs_0, expected_transaction.ISO_symbols_lane0, expected_transaction.Control_sym_flag_lane0); // Call IDLE_PATTERN task to handle IDLE state
                        //     IDLE_PATTERN(SR_flag_1, BS_flag_1, BF_flag_1, counter_SR_1, counter_1, cs_1, expected_transaction.ISO_symbols_lane1, expected_transaction.Control_sym_flag_lane1); // Call IDLE_PATTERN task to handle IDLE state
                        //     IDLE_PATTERN(SR_flag_2, BS_flag_2, BF_flag_2, counter_SR_2, counter_2, cs_2, expected_transaction.ISO_symbols_lane2, expected_transaction.Control_sym_flag_lane2); // Call IDLE_PATTERN task to handle IDLE state
                        //     IDLE_PATTERN(SR_flag_3, BS_flag_3, BF_flag_3, counter_SR_3, counter_3, cs_3, expected_transaction.ISO_symbols_lane3, expected_transaction.Control_sym_flag_lane3); // Call IDLE_PATTERN task to handle IDLE state
                        //     counter_i = 0;
                        //     send_expected_to_scoreboard();
                        // end
                    end
                    else if (!entered || RESET) begin
                        `uvm_info(get_type_name(), "LT not passed", UVM_HIGH)
                        expected_transaction.ISO_symbols_lane0 ='b0;
                        expected_transaction.ISO_symbols_lane1 ='b0;
                        expected_transaction.ISO_symbols_lane2 ='b0;
                        expected_transaction.ISO_symbols_lane3 ='b0;
                        expected_transaction.Control_sym_flag_lane0 ='b0;
                        expected_transaction.Control_sym_flag_lane1 ='b0;
                        expected_transaction.Control_sym_flag_lane2 ='b0;
                        expected_transaction.Control_sym_flag_lane3 ='b0;
                        if(!tl_item.MS_rst_n)
                            expected_transaction.WFULL = 1'b0; // Reset WFULL flag
                        calc_flag = 0;
                        cs = ISO_IDLE; // Reset state to ISO_IDLE
                        cs_0 = ISO_SR; cs_1 = ISO_SR; cs_2 = ISO_SR; cs_3 = ISO_SR; 
                        cs_0_TU = ISO_TU_PIXELS; cs_1_TU = ISO_TU_PIXELS; cs_2_TU = ISO_TU_PIXELS; cs_3_TU = ISO_TU_PIXELS;
                        counter_0 = 0; counter_SR_0 = 0; // Reset state and counters to initial values
                        counter_1 = 0; counter_SR_1 = 0; // Reset state and counters to initial values
                        counter_2 = 0; counter_SR_2 = 0; // Reset state and counters to initial values
                        counter_3 = 0; counter_SR_3 = 0; // Reset state and counters to initial values
                        count_MSA_0 = 0; count_MSA_1 = 0; count_MSA_2 = 0; count_MSA_3 = 0; // Reset MSA counters to initial values
                        count_VBLANK = 0; count_HBLANK_ACTIVE =0; count_HACTIVE =0; // Reset VBLANK and HBLANK counters to initial values
                        RED_8.delete(); RED_16.delete(); GREEN_8.delete(); GREEN_16.delete(); BLUE_8.delete(); BLUE_8.delete(); // Clear the pixel queue
                        Mvid_q.delete(); Nvid_q.delete(); HTotal_q.delete(); VTotal_q.delete(); HStart_q.delete();
                        VStart_q.delete(); HSP_q.delete(); HSW_q.delete(); VSP_q.delete(); VSW_q.delete();
                        HWidth_q.delete(); VHeight_q.delete(); MISC0_q.delete(); MISC1_q.delete();
                        `uvm_info(get_type_name(), "Allocated expected_transaction object", UVM_HIGH)
                        ref_vif.ref_expected_ISO_symbols_lane0 = expected_transaction.ISO_symbols_lane0;
                        ref_vif.ref_expected_ISO_symbols_lane1 = expected_transaction.ISO_symbols_lane1;
                        ref_vif.ref_expected_ISO_symbols_lane2 = expected_transaction.ISO_symbols_lane2;
                        ref_vif.ref_expected_ISO_symbols_lane3 = expected_transaction.ISO_symbols_lane3;

                        ref_vif.ref_expected_Control_sym_flag_lane0 = expected_transaction.Control_sym_flag_lane0;
                        ref_vif.ref_expected_Control_sym_flag_lane1 = expected_transaction.Control_sym_flag_lane1;
                        ref_vif.ref_expected_Control_sym_flag_lane2 = expected_transaction.Control_sym_flag_lane2;
                        ref_vif.ref_expected_Control_sym_flag_lane3 = expected_transaction.Control_sym_flag_lane3;
                        send_expected_to_scoreboard();               
                    end
                    else if(entered && !in_ISO) begin
                        IDLE_PATTERN(SR_flag_0, BS_flag_0, BF_flag_0, counter_SR_0, counter_0, cs_0, expected_transaction.ISO_symbols_lane0, expected_transaction.Control_sym_flag_lane0); // Call IDLE_PATTERN task to handle IDLE state
                        IDLE_PATTERN(SR_flag_1, BS_flag_1, BF_flag_1, counter_SR_1, counter_1, cs_1, expected_transaction.ISO_symbols_lane1, expected_transaction.Control_sym_flag_lane1); // Call IDLE_PATTERN task to handle IDLE state
                        IDLE_PATTERN(SR_flag_2, BS_flag_2, BF_flag_2, counter_SR_2, counter_2, cs_2, expected_transaction.ISO_symbols_lane2, expected_transaction.Control_sym_flag_lane2); // Call IDLE_PATTERN task to handle IDLE state
                        IDLE_PATTERN(SR_flag_3, BS_flag_3, BF_flag_3, counter_SR_3, counter_3, cs_3, expected_transaction.ISO_symbols_lane3, expected_transaction.Control_sym_flag_lane3); // Call IDLE_PATTERN task to handle IDLE state
                        counter_i = 0;
                        send_expected_to_scoreboard();
                    end
                end
            join
        end
        phase.drop_objection(this); // Drop objection when done
        `uvm_info(get_type_name(), "Reference model run_phase completed", UVM_LOW)
    endtask

    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////// NOTES ///////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////


    // Need to add something to let it know when it is ready to stop the IDLE transmission and start the actual stream transmission
    // .VBLANK stateقبل ما اروح لل IDLE stateلازم اعرف هقعد قد ايه في ال 
    // need to know how many clocks till we stop idle pattern
    // need to know if idle patterns need inter-lane skewing// NO INTER LANE SKEWING
    // This task creates the IDLE pattern to be sent on each lane

    ////////////////////////////////////////////////////////////////////////////////
    ////////////////////////////////// NOTES ///////////////////////////////////////
    ////////////////////////////////////////////////////////////////////////////////

    // This task is basically an FSM for what is the expected output of the DP source Main Lanes and Control Signals during ISO Services
    task generate_expected_transaction();
        case (cs)
            ISO_IDLE: begin
                ISO_IDLE_PATTERN(); // Call ISO_IDLE task to handle IDLE state
                counter_i = 0; // Reset counter after sending IDLE state for the current video
                cs = ISO_VBLANK; // Transition to VBLANK state
                cs_0_TU = ISO_TU_PIXELS; cs_1_TU = ISO_TU_PIXELS; cs_2_TU = ISO_TU_PIXELS; cs_3_TU = ISO_TU_PIXELS;
                //Optional
                counter_0 = 0; // about to start a new video
                cs_0 = ISO_BS; 
                if(ISO_LC == 3'b010) begin
                    counter_1 = 0;
                    cs_1 = ISO_BS; 
                end
                else if (ISO_LC == 3'b100) begin
                    counter_1 = 0; counter_2 = 0; counter_3 = 0;
                    cs_1 = ISO_BS; cs_2 = ISO_BS; cs_3 = ISO_BS;
                end
            end 
            ISO_VBLANK: begin
                `uvm_info(get_type_name(), $sformatf("INSIDE VVVVVVVVVVVVVVVVBLANK"), UVM_MEDIUM)
                ISO_VBLANK_PATTERN(); // Call VBLANK task to handle VBLANK state
                cs = ISO_HBLANK; // Transition to HBLANK state
                MSA_done = 1'b0; // Reset MSA_done flag after sending VBLANK symbols for the current video frame
                count_MSA_0 = 0; count_MSA_1 = 0; count_MSA_2 = 0; count_MSA_3 = 0;
                count_VBLANK =0; // Reset VBLANK counter after sending VBLANK symbols for the current video frame
            end 
            ISO_HBLANK: begin
                `uvm_info(get_type_name(), $sformatf("INSIDE HHHHHHHHHHHHHHHHBLANK"), UVM_MEDIUM)
                ISO_HBLANK_PATTERN(); // Call HBLANK task to handle HBLANK state
                cs = ISO_ACTIVE;
            end 
            ISO_ACTIVE: begin
                ISO_ACTIVE_PATTERN(); // Call ACTIVE task to handle ACTIVE state
                count_HBLANK_ACTIVE++;
                count_HACTIVE = 0;
                if(count_HBLANK_ACTIVE < VHeight_q[0])    // If all lines are done, go back to VBLANK state
                    cs = ISO_HBLANK; // Transition to HBLANK state
                else if(RED_8.size() != 0 || GREEN_8.size() != 0 || BLUE_8.size() != 0 || RED_16.size() != 0 || GREEN_16.size() != 0 || BLUE_16.size() != 0) begin // Start a new frame
                    cs = ISO_VBLANK; // Transition to VBLANK state
                    count_HBLANK_ACTIVE = 0;
                    // empty queues
                    Mvid_q.delete(0); Nvid_q.delete(0); HTotal_q.delete(0); VTotal_q.delete(0); HStart_q.delete(0);
                    VStart_q.delete(0); HSP_q.delete(0); HSW_q.delete(0); VSP_q.delete(0); VSW_q.delete(0);
                    HWidth_q.delete(0); VHeight_q.delete(0); MISC0_q.delete(0); MISC1_q.delete(0);
                end 
                else begin
                    cs = ISO_IDLE;
                    // empty queues
                    if ((Mvid_q.size() > 0)) begin
                        Mvid_q.delete(0); Nvid_q.delete(0); HTotal_q.delete(0); VTotal_q.delete(0); HStart_q.delete(0);
                        VStart_q.delete(0); HSP_q.delete(0); HSW_q.delete(0); VSP_q.delete(0); VSW_q.delete(0);
                        HWidth_q.delete(0); VHeight_q.delete(0); MISC0_q.delete(0); MISC1_q.delete(0);
                    end
                end
            end
            default: begin
                // Default case to handle unexpected states
                `uvm_fatal("ISO_STATE_ERROR", "Invalid state in ISO operation")
            end
        endcase
    endtask

    // This task sends the idle pattern on all 4 lanes 
    task ISO_IDLE_PATTERN();
        while(!ready) begin
            if (!tl_item.MS_rst_n) begin
                entered = 0;
                break; // Exit the loop if reset is active or link training no longer valid so ISO signals are don't cares
            end
            expected_transaction.WFULL = 1'b0; // Reset WFULL flag
            IDLE_PATTERN(SR_flag_0, BS_flag_0, BF_flag_0, counter_SR_0, counter_0, cs_0, expected_transaction.ISO_symbols_lane0, expected_transaction.Control_sym_flag_lane0); // Call IDLE_PATTERN task to handle IDLE state
            IDLE_PATTERN(SR_flag_1, BS_flag_1, BF_flag_1, counter_SR_1, counter_1, cs_1, expected_transaction.ISO_symbols_lane1, expected_transaction.Control_sym_flag_lane1); // Call IDLE_PATTERN task to handle IDLE state
            IDLE_PATTERN(SR_flag_2, BS_flag_2, BF_flag_2, counter_SR_2, counter_2, cs_2, expected_transaction.ISO_symbols_lane2, expected_transaction.Control_sym_flag_lane2); // Call IDLE_PATTERN task to handle IDLE state
            IDLE_PATTERN(SR_flag_3, BS_flag_3, BF_flag_3, counter_SR_3, counter_3, cs_3, expected_transaction.ISO_symbols_lane3, expected_transaction.Control_sym_flag_lane3); // Call IDLE_PATTERN task to handle IDLE state
            // Send the expected transaction to the scoreboard
            `uvm_info(get_type_name(), "Allocated expected_transaction object", UVM_MEDIUM)
            ref_vif.ref_expected_ISO_symbols_lane0 = expected_transaction.ISO_symbols_lane0;
            ref_vif.ref_expected_ISO_symbols_lane1 = expected_transaction.ISO_symbols_lane1;
            ref_vif.ref_expected_ISO_symbols_lane2 = expected_transaction.ISO_symbols_lane2;
            ref_vif.ref_expected_ISO_symbols_lane3 = expected_transaction.ISO_symbols_lane3;

            ref_vif.ref_expected_Control_sym_flag_lane0 = expected_transaction.Control_sym_flag_lane0;
            ref_vif.ref_expected_Control_sym_flag_lane1 = expected_transaction.Control_sym_flag_lane1;
            ref_vif.ref_expected_Control_sym_flag_lane2 = expected_transaction.Control_sym_flag_lane2;
            ref_vif.ref_expected_Control_sym_flag_lane3 = expected_transaction.Control_sym_flag_lane3;
            send_expected_to_scoreboard();
            counter_i++; // Increment the counter for the number of symbols sent
            if(in_ISO && !RESET) begin
                if(counter_i < 408) begin // 408 Ls_clks need to go by for the IDLE pattern to stop sending
                    ready = 1'b0; // Not ready to stop IDLE pattern
                end
                else begin
                    ready = 1'b1; // Ready to stop IDLE pattern
                end
            end
            else begin
                counter_i = 0; // because there is no video stream to countdown to.
                ready = 1'b0; // Not ready to stop IDLE pattern
            end
            `uvm_info(get_type_name(), $sformatf("STILL INSIDE IDLE: Counter_i = 0x%0d",  counter_i), UVM_MEDIUM)
        end             
    endtask

    task IDLE_PATTERN(
        ref bit SR_flag, BS_flag, BF_flag, 
        ref int counter_SR, counter, // Counters for the number of symbols sent
        ref iso_idle_code cs, // Current and next state variables for the IDLE pattern
        output logic [AUX_DATA_WIDTH-1:0] ISO_symbols_lanex,
        output logic Control_sym_flag_lanex
    );
        case (cs)
            ISO_SR: begin // Start with sending SR symbol instead of BS symbol
                `uvm_info(get_type_name(), $sformatf("INSIDE SR STATE - IDLE"), UVM_MEDIUM)
                Control_sym_flag_lanex = 1'b1;
                ISO_symbols_lanex = SR;
                counter_SR = 0; // Reset counter after sending SR symbols
                SR_flag = 1'b1; // Set SR_flag to indicate that a SR symbol has been sent
                if(BF_flag) begin // if BF has been sent twice
                    cs = ISO_VB_ID; // Transition to VB_ID state
                    counter++; // Increment the counter for the number of symbols sent
                end
                else
                    cs = ISO_BF; // Transition to BF state
            end
            ISO_BS: begin // Send BS symbol 
                `uvm_info(get_type_name(), $sformatf("INSIDE BS STATE - IDLE"), UVM_MEDIUM)
                Control_sym_flag_lanex = 1'b1;
                ISO_symbols_lanex = BS;
                BS_flag = 1'b1; // Set BS_flag to indicate that a BS symbol has been sent
                if(BF_flag) begin // if BF has been sent twice
                    counter_SR++; // To make sure after every 511 BS Control Link Symbol sequences one gets replaced by a SR symbol sequence
                    counter++; // Increment the counter for the number of symbols sent
                    cs = ISO_VB_ID; // Transition to VB_ID state
                end
                else
                    cs = ISO_BF; // Transition to BF state
            end
            ISO_BF: begin
                `uvm_info(get_type_name(), $sformatf("INSIDE BF STATE - IDLE"), UVM_MEDIUM)
                Control_sym_flag_lanex = 1'b1;
                ISO_symbols_lanex = BF;
                if(!BF_flag) begin
                    cs = ISO_BF; // Transition to ISO_BF state
                    BF_flag= 1'b1;
                end
                else begin
                    if(SR_flag) begin // If this Control symbol sequnce is SR go back and end it with an SR symbol
                        cs = ISO_SR; // Transition to ISO_SR state
                    end
                    else if (BS_flag) begin // If this Control symbol sequnce is BS go back and end it with an BS symbol
                        cs = ISO_BS; // Reset count_SR after sending BS and BF symbols
                    end
                end
            end
            ISO_VB_ID:begin
                `uvm_info(get_type_name(), $sformatf("INSIDE VB-ID STATE - IDLE"), UVM_MEDIUM)
                Control_sym_flag_lanex = 1'b0;
                ISO_symbols_lanex = 8'b0_000_1000; // No Video or audio or active video stream this is VB-ID for an IDLE pattern
                counter++; // Increment the counter for the number of symbols sent
                cs = ISO_MVID; // Transition to MVID state
                BF_flag = 1'b0; // Reset BF_flag after sending VB_ID symbols
                BS_flag = 1'b0; // Reset BS_flag after sending VB_ID symbols
                SR_flag = 1'b0; // Reset SR_flag after sending VB_ID symbols
            end
            ISO_MVID:begin
                `uvm_info(get_type_name(), $sformatf("INSIDE Mvid STATE - IDLE"), UVM_MEDIUM)
                Control_sym_flag_lanex = 1'b0;
                ISO_symbols_lanex = 'b0;
                counter++; // Increment the counter for the number of symbols sent
                cs = ISO_MAUD; // Transition to MAUD state
            end
            ISO_MAUD:begin
                `uvm_info(get_type_name(), $sformatf("INSIDE Maud STATE - IDLE"), UVM_MEDIUM)
                Control_sym_flag_lanex = 1'b0;
                ISO_symbols_lanex = 'b0;
                counter++; // Increment the counter for the number of symbols sent
                cs = ISO_DUMMY; // Transition to IDLE state
            end
            ISO_DUMMY:begin
                `uvm_info(get_type_name(), $sformatf("INSIDE DUMMY STATE - IDLE"), UVM_MEDIUM)
                Control_sym_flag_lanex = 1'b0;
                ISO_symbols_lanex = 8'b0; // Dummy symbol for IDLE state
                if(counter<8189) begin
                    cs = ISO_DUMMY; // Stay in IDLE state
                    counter++; // Increment the counter for the number of symbols sent
                    `uvm_info(get_type_name(), $sformatf("INSIDE DUMMY AGAINNNNNNN: Counter = 0x%0d",  counter), UVM_MEDIUM)
                end
                else begin
                    counter = 0;
                    if(counter_SR == 511) begin
                        cs = ISO_SR; // Transition to SR state
                    end
                    else begin
                        `uvm_info(get_type_name(), "ENTER BS AGAINNNNNNN", UVM_MEDIUM)
                        cs = ISO_BS; // Transition to BS state
                    end
                end
            end
            default: `uvm_fatal("ISO_STATE_ERROR", "Invalid state in ISO operation")
        endcase
    endtask

    task ISO_VBLANK_PATTERN();
        repeat(VTotal_q[0] - VHeight_q[0]) begin
            `uvm_info(get_type_name(), $sformatf("INSIDE the OUTER REPEAT, vblank_period = %0h", vblank_period), UVM_MEDIUM)
            repeat (HTotal_q[0]) begin
                `uvm_info(get_type_name(), $sformatf("INSIDE the INNER REPEAT, htotal_period = %0h", htotal_period), UVM_MEDIUM)
                if (RESET) begin
                    break; // Exit the loop if reset is active
                end
                else begin
                    `uvm_info(get_type_name(), $sformatf("INSIDE VBLANK OUTSIDE CASEEEEEEEEEE"), UVM_MEDIUM)
                    case(ISO_LC) // according to the actvie lane count, send VBlank on all active lanes and remain with IDLE pattern on inactive lanes
                        3'b001: begin // // Data transmission on 1 lane
                            send_vblank_symbols(SR_flag_0, BS_flag_0, BF_flag_0, counter_SR_0, counter_0, count_MSA_0, cs_0, ISO_LC, 2'd0, expected_transaction.ISO_symbols_lane0, expected_transaction.Control_sym_flag_lane0); // Call VBLANK_PATTERN task to handle VBLANK state
                            IDLE_PATTERN(SR_flag_1, BS_flag_1, BF_flag_1, counter_SR_1, counter_1, cs_1, expected_transaction.ISO_symbols_lane1, expected_transaction.Control_sym_flag_lane1); // Call IDLE_PATTERN task to handle IDLE state
                            IDLE_PATTERN(SR_flag_2, BS_flag_2, BF_flag_2, counter_SR_2, counter_2, cs_2, expected_transaction.ISO_symbols_lane2, expected_transaction.Control_sym_flag_lane2); // Call IDLE_PATTERN task to handle IDLE state
                            IDLE_PATTERN(SR_flag_3, BS_flag_3, BF_flag_3, counter_SR_3, counter_3, cs_3, expected_transaction.ISO_symbols_lane3, expected_transaction.Control_sym_flag_lane3); // Call IDLE_PATTERN task to handle IDLE state 
                        end
                        3'b010: begin // // Data transmission on 2 lanes
                            send_vblank_symbols(SR_flag_0, BS_flag_0, BF_flag_0, counter_SR_0, counter_0, count_MSA_0, cs_0, ISO_LC, 2'd0, expected_transaction.ISO_symbols_lane0, expected_transaction.Control_sym_flag_lane0); // Call VBLANK_PATTERN task to handle VBLANK state
                            send_vblank_symbols(SR_flag_1, BS_flag_1, BF_flag_1, counter_SR_1, counter_1, count_MSA_1, cs_1, ISO_LC, 2'd1, expected_transaction.ISO_symbols_lane1, expected_transaction.Control_sym_flag_lane1); // Call VBLANK_PATTERN task to handle VBLANK state
                            IDLE_PATTERN(SR_flag_2, BS_flag_2, BF_flag_2, counter_SR_2, counter_2, cs_2, expected_transaction.ISO_symbols_lane2, expected_transaction.Control_sym_flag_lane2); // Call IDLE_PATTERN task to handle IDLE state
                            IDLE_PATTERN(SR_flag_3, BS_flag_3, BF_flag_3, counter_SR_3, counter_3, cs_3, expected_transaction.ISO_symbols_lane3, expected_transaction.Control_sym_flag_lane3); // Call IDLE_PATTERN task to handle IDLE state            
                        end
                        3'b100: begin // Data transmission on 4 lanes
                            send_vblank_symbols(SR_flag_0, BS_flag_0, BF_flag_0, counter_SR_0, counter_0, count_MSA_0, cs_0, ISO_LC, 2'd0, expected_transaction.ISO_symbols_lane0, expected_transaction.Control_sym_flag_lane0); // Call VBLANK_PATTERN task to handle VBLANK state
                            send_vblank_symbols(SR_flag_1, BS_flag_1, BF_flag_1, counter_SR_1, counter_1, count_MSA_1, cs_1, ISO_LC, 2'd1, expected_transaction.ISO_symbols_lane1, expected_transaction.Control_sym_flag_lane1); // Call VBLANK_PATTERN task to handle VBLANK state
                            send_vblank_symbols(SR_flag_2, BS_flag_2, BF_flag_2, counter_SR_2, counter_2, count_MSA_2, cs_2, ISO_LC, 2'd2, expected_transaction.ISO_symbols_lane2, expected_transaction.Control_sym_flag_lane2); // Call VBLANK_PATTERN task to handle VBLANK state
                            send_vblank_symbols(SR_flag_3, BS_flag_3, BF_flag_3, counter_SR_3, counter_3, count_MSA_3, cs_3, ISO_LC, 2'd3, expected_transaction.ISO_symbols_lane3, expected_transaction.Control_sym_flag_lane3); // Call VBLANK_PATTERN task to handle VBLANK state           
                        end
                        default:    // Default case to handle unexpected states
                            `uvm_fatal("ISO_LANE_NUM_ERROR", "Invalid lane number in ISO operation! Lane Count cannot be 3!")
                    endcase
                end
                // Send the expected transaction to the scoreboard
                `uvm_info(get_type_name(), "Allocated expected_transaction object", UVM_MEDIUM)
                ref_vif.ref_expected_ISO_symbols_lane0 = expected_transaction.ISO_symbols_lane0;
                ref_vif.ref_expected_ISO_symbols_lane1 = expected_transaction.ISO_symbols_lane1;
                ref_vif.ref_expected_ISO_symbols_lane2 = expected_transaction.ISO_symbols_lane2;
                ref_vif.ref_expected_ISO_symbols_lane3 = expected_transaction.ISO_symbols_lane3;

                ref_vif.ref_expected_Control_sym_flag_lane0 = expected_transaction.Control_sym_flag_lane0;
                ref_vif.ref_expected_Control_sym_flag_lane1 = expected_transaction.Control_sym_flag_lane1;
                ref_vif.ref_expected_Control_sym_flag_lane2 = expected_transaction.Control_sym_flag_lane2;
                ref_vif.ref_expected_Control_sym_flag_lane3 = expected_transaction.Control_sym_flag_lane3;
                send_expected_to_scoreboard();
            end 
            if (RESET) begin
                break; // Exit the loop if reset is active
            end
        end
    endtask

    task send_vblank_symbols(
        ref bit SR_flag, BS_flag, BF_flag,
        ref int counter_SR, counter, count_MSA, // Counters for the number of symbols sent
        ref iso_idle_code cs, // Current and next state variables for the IDLE pattern
        input bit [2:0] lane_num, 
        input bit [1:0] lane_id,
        output logic [AUX_DATA_WIDTH-1:0] ISO_symbols_lanex,
        output logic Control_sym_flag_lanex
    );
        int count_lc; // to count which round of VB-ID, Mvid adn Maud is this 
        case (cs)
            ISO_SR: begin
                `uvm_info(get_type_name(), $sformatf("INSIDE SR STATE - VBLANK"), UVM_MEDIUM)
                Control_sym_flag_lanex = 1'b1;
                ISO_symbols_lanex = SR;
                counter_SR = 0; // Reset counter after sending SR symbols
                SR_flag = 1'b1;
                if(BF_flag) begin
                    cs = ISO_VB_ID; // Transition to VB_ID state
                    counter++; // Increment the counter for the number of symbols sent
                end
                else
                    cs = ISO_BF; // Transition to BF state
            end
            ISO_BS: begin
                `uvm_info(get_type_name(), $sformatf("INSIDE BS STATE - VBLANK"), UVM_MEDIUM)
                Control_sym_flag_lanex = 1'b1;
                ISO_symbols_lanex = BS;
                BS_flag = 1'b1;
                if(BF_flag) begin
                    counter_SR++;
                    counter++; // Increment the counter for the number of symbols sent
                    cs = ISO_VB_ID; // Transition to VB_ID state
                end
                else
                    cs = ISO_BF; // Transition to BF state
            end
            ISO_BF: begin
                `uvm_info(get_type_name(), $sformatf("INSIDE BF STATE - VBLANK"), UVM_MEDIUM)
                Control_sym_flag_lanex = 1'b1;
                ISO_symbols_lanex = BF;
                if(!BF_flag) begin
                    cs = ISO_BF; // Transition to VB_ID state
                    BF_flag= 1'b1;
                end
                else begin
                    if(SR_flag) begin
                        cs = ISO_SR; // Transition to VB_ID state
                    end
                    else if (BS_flag) begin
                        cs = ISO_BS; // Reset count_SR after sending BS and BF symbols
                    end
                end
            end
            ISO_VB_ID:begin
                `uvm_info(get_type_name(), $sformatf("INSIDE VB-ID STATE - VBLANK"), UVM_MEDIUM)
                Control_sym_flag_lanex = 1'b0;
                ISO_symbols_lanex = 8'b0000_0001; 
                counter++; // Increment the counter for the number of symbols sent
                cs = ISO_MVID; // Transition to MVID state
                BF_flag = 1'b0; // Reset BF_flag after sending VB_ID symbols
                BS_flag = 1'b0; // Reset BS_flag after sending VB_ID symbols
                SR_flag = 1'b0; // Reset SR_flag after sending VB_ID symbols
            end
            ISO_MVID:begin
                `uvm_info(get_type_name(), $sformatf("INSIDE Mvid STATE - VBLANK"), UVM_MEDIUM)
                Control_sym_flag_lanex = 1'b0;
                ISO_symbols_lanex = 8'h00;
                counter++; // Increment the counter for the number of symbols sent
                cs = ISO_MAUD; // Transition to MAUD state
            end
            ISO_MAUD:begin
                `uvm_info(get_type_name(), $sformatf("INSIDE Maud STATE - VBLANK"), UVM_MEDIUM)
                Control_sym_flag_lanex = 1'b0;
                ISO_symbols_lanex = 8'h00;
                counter++; // Increment the counter for the number of symbols sent
                
                if((lane_num== 3'b001 && count_lc < 4) || (lane_num== 3'b010 && count_lc < 2)) begin // if not done with iterations repeat
                    cs = ISO_VB_ID; // Rpeat from VB-ID
                    count_lc++; // Increment
                end
                else begin
                    count_lc= 0;
                    if(MSA_done) begin
                        cs = ISO_MSA; // Transition to MSA state
                    end
                    else begin
                        cs = ISO_DUMMY; // Transition to dummy state
                    end
                end  
            end
            ISO_DUMMY:begin
                `uvm_info(get_type_name(), $sformatf("INSIDE DUMMY STATE - VBLANK"), UVM_MEDIUM)
                Control_sym_flag_lanex = 1'b0;
                ISO_symbols_lanex = 'b0; // Dummy symbol for IDLE state
                if(counter < htotal_period-3) begin
                    cs = ISO_DUMMY; // Stay in IDLE state
                    counter++; // Increment the counter for the number of symbols sent
                end
                else begin
                    counter = 0;
                    count_VBLANK++; // Increment the VBLANK counter, the line is finished
                    if(counter_SR == 511) begin
                        cs = ISO_SR; // Transition to SR state
                    end
                    else
                        cs = ISO_BS; // Transition to BS state
                end
            end
            ISO_MSA:begin
                `uvm_info(get_type_name(), $sformatf("INSIDE MSA STATE - VBLANK"), UVM_MEDIUM)
                if(count_MSA== 0 || count_MSA== 1) begin
                    ISO_symbols_lanex = SS;
                    Control_sym_flag_lanex = 1'b1;
                    cs = ISO_MSA; // Stay in MSA state
                    count_MSA++; // Increment the counter for the number of symbols sent
                    counter++; // Increment the counter for the number of symbols sent
                end
                else if((lane_num== 3'b100 && count_MSA < 11) || (lane_num== 3'b010 && count_MSA < 20) || (lane_num== 3'b001 && count_MSA < 38)) begin // how much time needed for MSA transmission depending on lane count
                    Control_sym_flag_lanex = 1'b0;
                    count_MSA = count_MSA-2;
                    MSA_symbols(lane_num, lane_id, count_MSA, ISO_symbols_lanex); // Call MSA_symbols task to handle MSA state
                    count_MSA = count_MSA+2;
                    count_MSA++; // Increment the counter for the number of symbols sent
                    counter++; // Increment the counter for the number of symbols sent
                    cs = ISO_MSA; // Stay in MSA state
                end
                else begin
                    Control_sym_flag_lanex = 1'b1;
                    ISO_symbols_lanex = SE; 
                    count_MSA= 0;
                    MSA_done = 1'b1;
                    if(counter < htotal_period) begin 
                        cs = ISO_DUMMY; // Go to dummy state
                        counter++; // Increment the counter for the number of symbols sent
                    end
                    else begin
                        counter = 0;
                        count_VBLANK++; // Increment the VBLANK counter, the line is finished
                        if(counter_SR == 511) begin
                            cs = ISO_SR; // Transition to SR state
                        end
                        else
                            cs = ISO_BS; // Transition to BS state
                    end
                end
            end
            default: `uvm_fatal("ISO_STATE_ERROR", "Invalid state in ISO operation in VBLANK_PATTERN task")
        endcase
    endtask

    // This task is used specifically to transmit MSA symbols across each active lane
    task MSA_symbols(
        input bit [2:0] lane_num, // lane count
        input bit [1:0] lane_id, // lane number
        ref int count_MSA,
        output logic [AUX_DATA_WIDTH-1:0] ISO_symbols_lanex
    );
        bit [1:0] round_num; // Round number for MSA symbols
        if(count_MSA < 9)
            round_num = 2'b00; // Round number 1 for lane 0, lane 1, lane 2, lane 3
        else if(count_MSA < 18)
            round_num = 2'b01; // Round number 2 for lane 0, lane 1
        else if(count_MSA < 27)
            round_num = 2'b10; // Round number 3 for lane 0
        else if(count_MSA < 36)
            round_num = 2'b11; // Round number 4 for lane 0
        case(round_num)
            2'b00: begin // Round 1 for lane 0, lane 1, lane 2, lane 3
                case(lane_id)
                    2'b00: begin // lane0
                        case(count_MSA)
                            'd0: ISO_symbols_lanex = Mvid_q[0][23:16]; // MSA symbol for lane 0, count 0
                            'd1: ISO_symbols_lanex = Mvid_q[0][15:8]; // MSA symbol for lane 0, count 1
                            'd2: ISO_symbols_lanex = Mvid_q[0][7:0]; // MSA symbol for lane 0, count 2
                            'd3: ISO_symbols_lanex = HTotal_q[0][15:8]; // MSA symbol for lane 0, count 3
                            'd4: ISO_symbols_lanex = HTotal_q[0][7:0]; // MSA symbol for lane 0, count 4
                            'd5: ISO_symbols_lanex = VTotal_q[0][15:8]; // MSA symbol for lane 0, count 5
                            'd6: ISO_symbols_lanex = VTotal_q[0][7:0]; // MSA symbol for lane 0, count 6
                            'd7: ISO_symbols_lanex = {HSP_q[0], HSW_q[0][14:8]}; // MSA symbol for lane 0, count 7
                            'd8: ISO_symbols_lanex = HSW_q[0][7:0]; // MSA symbol for lane 0, count 8
                            default: `uvm_fatal("MSA_SYMBOLS_ERROR", "Invalid count_MSA in MSA_symbols task")
                        endcase
                    end
                    2'b01: begin // lane1
                        case(count_MSA)
                            'd0: ISO_symbols_lanex = Mvid_q[0][23:16];                   // MSA symbol for lane 1, count 0
                            'd1: ISO_symbols_lanex = Mvid_q[0][15:8];                    // MSA symbol for lane 1, count 1
                            'd2: ISO_symbols_lanex = Mvid_q[0][7:0];                     // MSA symbol for lane 2, count 2
                            'd3: ISO_symbols_lanex = HStart_q[0][15:8];                  // MSA symbol for lane 1, count 3
                            'd4: ISO_symbols_lanex = HStart_q[0][7:0];                   // MSA symbol for lane 1, count 4
                            'd5: ISO_symbols_lanex = VStart_q[0][15:8];                  // MSA symbol for lane 1, count 5
                            'd6: ISO_symbols_lanex = VStart_q[0][7:0];                   // MSA symbol for lane 1, count 6
                            'd7: ISO_symbols_lanex = {VSP_q[0], VSW_q[0][14:8]};      // MSA symbol for lane 1, count 7
                            'd8: ISO_symbols_lanex = VSW_q[0][7:0];                      // MSA symbol for lane 1, count 8
                            default: `uvm_fatal("MSA_SYMBOLS_ERROR", "Invalid count_MSA in MSA_symbols task")
                        endcase
                    end
                    2'b10: begin // lane2
                        case(count_MSA)
                            'd0: ISO_symbols_lanex = Mvid_q[0][23:16];       // MSA symbol for lane 2, count 0
                            'd1: ISO_symbols_lanex = Mvid_q[0][15:8];        // MSA symbol for lane 2, count 1
                            'd2: ISO_symbols_lanex = Mvid_q[0][7:0];         // MSA symbol for lane 2, count 2
                            'd3: ISO_symbols_lanex = HWidth_q[0][15:8];      // MSA symbol for lane 2, count 3
                            'd4: ISO_symbols_lanex = HWidth_q[0][7:0];       // MSA symbol for lane 2, count 4
                            'd5: ISO_symbols_lanex = VHeight_q[0][15:8];     // MSA symbol for lane 2, count 5
                            'd6: ISO_symbols_lanex = VHeight_q[0][7:0];      // MSA symbol for lane 2, count 6
                            'd7: ISO_symbols_lanex = 8'h00;                     // MSA symbol for lane 2, count 7
                            'd8: ISO_symbols_lanex = 8'h00;                     // MSA symbol for lane 2, count 8
                            default: `uvm_fatal("MSA_SYMBOLS_ERROR", "Invalid count_MSA in MSA_symbols task")
                        endcase
                    end
                    2'b11: begin // lane3
                        case(count_MSA)
                            'd0: ISO_symbols_lanex = Mvid_q[0][23:16];   // MSA symbol for lane 3, count 3
                            'd1: ISO_symbols_lanex = Mvid_q[0][15:8];    // MSA symbol for lane 3, count 1
                            'd2: ISO_symbols_lanex = Mvid_q[0][7:0];     // MSA symbol for lane 3, count 2
                            'd3: ISO_symbols_lanex = Nvid_q[0][23:16];   // MSA symbol for lane 3, count 3
                            'd4: ISO_symbols_lanex = Nvid_q[0][15:8];    // MSA symbol for lane 3, count 4
                            'd5: ISO_symbols_lanex = Nvid_q[0][7:0];     // MSA symbol for lane 3, count 5
                            'd6: ISO_symbols_lanex = MISC0_q[0];         // MSA symbol for lane 3, count 6
                            'd7: ISO_symbols_lanex = MISC1_q[0];         // MSA symbol for lane 3, count 7
                            'd8: ISO_symbols_lanex = 8'h00;     	        // MSA symbol for lane 3, count 8
                            default: `uvm_fatal("MSA_SYMBOLS_ERROR", "Invalid count_MSA in MSA_symbols task")
                        endcase
                    end
                endcase
            end
            2'b01: begin // Round 2 for lane 0, lane 1
                case(lane_id) 
                    2'b00: begin // lane0
                        if(lane_num==3'b010) begin // if lane count is 2
                            case(count_MSA-9)
                                'd0: ISO_symbols_lanex = Mvid_q[0][23:16]; // MSA symbol for lane 0, count 0
                                'd1: ISO_symbols_lanex = Mvid_q[0][15:8]; // MSA symbol for lane 0, count 1
                                'd2: ISO_symbols_lanex = Mvid_q[0][7:0]; // MSA symbol for lane 0, count 2
                                'd3: ISO_symbols_lanex = HWidth_q[0][15:8]; // MSA symbol for lane 0, count 3
                                'd4: ISO_symbols_lanex = HWidth_q[0][7:0]; // MSA symbol for lane 0, count 4
                                'd5: ISO_symbols_lanex = VHeight_q[0][15:8]; // MSA symbol for lane 0, count 5
                                'd6: ISO_symbols_lanex = VHeight_q[0][7:0]; // MSA symbol for lane 0, count 6
                                'd7: ISO_symbols_lanex = 8'h00; // MSA symbol for lane 0, count 7
                                'd8: ISO_symbols_lanex = 8'h00; // MSA symbol for lane 0, count 8
                                default: `uvm_fatal("MSA_SYMBOLS_ERROR", "Invalid count_MSA in MSA_symbols task")
                            endcase
                        end 
                        else begin  // if lane count is 4
                            case(count_MSA-9)
                                'd0: ISO_symbols_lanex = Mvid_q[0][23:16]; // MSA symbol for lane 0, count 0
                                'd1: ISO_symbols_lanex = Mvid_q[0][15:8]; // MSA symbol for lane 0, count 1
                                'd2: ISO_symbols_lanex = Mvid_q[0][7:0]; // MSA symbol for lane 0, count 2
                                'd3: ISO_symbols_lanex = HStart_q[0][15:8]; // MSA symbol for lane 0, count 3
                                'd4: ISO_symbols_lanex = HStart_q[0][7:0]; // MSA symbol for lane 0, count 4
                                'd5: ISO_symbols_lanex = VStart_q[0][15:8]; // MSA symbol for lane 0, count 5
                                'd6: ISO_symbols_lanex = VStart_q[0][7:0]; // MSA symbol for lane 0, count 6
                                'd7: ISO_symbols_lanex = {VSP_q[0], VSW_q[0][14:8]}; // MSA symbol for lane 0, count 7
                                'd8: ISO_symbols_lanex = VSW_q[0][7:0]; // MSA symbol for lane 0, count 8
                                default: `uvm_fatal("MSA_SYMBOLS_ERROR", "Invalid count_MSA in MSA_symbols task")
                            endcase
                        end
                    end
                    2'b01: begin // lane1
                        case(count_MSA-9)
                                'd0: ISO_symbols_lanex = Mvid_q[0][23:16]; // MSA symbol for lane 0, count 0
                                'd1: ISO_symbols_lanex = Mvid_q[0][15:8]; // MSA symbol for lane 0, count 1
                                'd2: ISO_symbols_lanex = Mvid_q[0][7:0]; // MSA symbol for lane 0, count 2
                                'd3: ISO_symbols_lanex = Nvid_q[0][23:16]; // MSA symbol for lane 0, count 3
                                'd4: ISO_symbols_lanex = Nvid_q[0][15:8]; // MSA symbol for lane 0, count 4
                                'd5: ISO_symbols_lanex = Nvid_q[0][7:0]; // MSA symbol for lane 0, count 5
                                'd6: ISO_symbols_lanex = MISC0_q[0]; // MSA symbol for lane 0, count 6
                                'd7: ISO_symbols_lanex = MISC1_q[0]; // MSA symbol for lane 0, count 7
                                'd8: ISO_symbols_lanex = 8'h00; // MSA symbol for lane 0, count 8
                                default: `uvm_fatal("MSA_SYMBOLS_ERROR", "Invalid count_MSA in MSA_symbols task")
                        endcase
                    end
                    default: `uvm_fatal("MSA_SYMBOLS_ERROR", "Invalid lane_id in MSA_symbols task")
                endcase
            end
            2'b10: begin // Round 3 for lane 0
                case(count_MSA-18)
                    'd0: ISO_symbols_lanex = Mvid_q[0][23:16]; // MSA symbol for lane 0, count 0
                    'd1: ISO_symbols_lanex = Mvid_q[0][15:8]; // MSA symbol for lane 0, count 1
                    'd2: ISO_symbols_lanex = Mvid_q[0][7:0]; // MSA symbol for lane 0, count 2
                    'd3: ISO_symbols_lanex = HWidth_q[0][15:8]; // MSA symbol for lane 0, count 3
                    'd4: ISO_symbols_lanex = HWidth_q[0][7:0]; // MSA symbol for lane 0, count 4
                    'd5: ISO_symbols_lanex = VHeight_q[0][15:8]; // MSA symbol for lane 0, count 5
                    'd6: ISO_symbols_lanex = VHeight_q[0][7:0]; // MSA symbol for lane 0, count 6
                    'd7: ISO_symbols_lanex = 8'h00; // MSA symbol for lane 0, count 7
                    'd8: ISO_symbols_lanex = 8'h00; // MSA symbol for lane 0, count 8
                    default: `uvm_fatal("MSA_SYMBOLS_ERROR", "Invalid count_MSA in MSA_symbols task")
                endcase
            end
            2'b11: begin // Round 4 for lane 0
                case(count_MSA-27)
                    'd0: ISO_symbols_lanex = Mvid_q[0][23:16]; // MSA symbol for lane 0, count 0
                    'd1: ISO_symbols_lanex = Mvid_q[0][15:8]; // MSA symbol for lane 0, count 1
                    'd2: ISO_symbols_lanex = Mvid_q[0][7:0]; // MSA symbol for lane 0, count 2
                    'd3: ISO_symbols_lanex = Nvid_q[0][23:16]; // MSA symbol for lane 0, count 3
                    'd4: ISO_symbols_lanex = Nvid_q[0][15:8]; // MSA symbol for lane 0, count 4
                    'd5: ISO_symbols_lanex = Nvid_q[0][7:0]; // MSA symbol for lane 0, count 5
                    'd6: ISO_symbols_lanex = MISC0_q[0]; // MSA symbol for lane 0, count 6
                    'd7: ISO_symbols_lanex = MISC1_q[0]; // MSA symbol for lane 0, count 7
                    'd8: ISO_symbols_lanex = 8'h00; // MSA symbol for lane 0, count 8
                    default: `uvm_fatal("MSA_SYMBOLS_ERROR", "Invalid count_MSA in MSA_symbols task")
                endcase
            end
        endcase
    endtask

    // Note : Maybe make the while loop internal to each case statement and remove the while loop from Outside the case statement
    // This task creates the HBLANK pattern to be sent on each lane
    // This task is similar to the ISO_VBLANK_PATTERN task but Without sending MSA symbols and instead 
    // continuously sending the DUMMY pattern until the beginning of the Hactive period
    task ISO_HBLANK_PATTERN();
        while (counter_0 < hblank_period) begin
            if (RESET) begin
                break; // Exit the loop if reset is active
            end
            else begin
                case(ISO_LC) // according to the actvie lane count, send HBLANK on all active lanes and remain with IDLE pattern on inactive lanes
                    3'b001: begin // // Data transmission on 1 lane
                            send_hblank_symbols(SR_flag_0, BS_flag_0, BF_flag_0, counter_SR_0, counter_0, cs_0, ISO_LC, 2'd0, expected_transaction.ISO_symbols_lane0, expected_transaction.Control_sym_flag_lane0); // Call VBLANK_PATTERN task to handle VBLANK state
                            IDLE_PATTERN(SR_flag_1, BS_flag_1, BF_flag_1, counter_SR_1, counter_1, cs_1, expected_transaction.ISO_symbols_lane1, expected_transaction.Control_sym_flag_lane1); // Call IDLE_PATTERN task to handle IDLE state
                            IDLE_PATTERN(SR_flag_2, BS_flag_2, BF_flag_2, counter_SR_2, counter_2, cs_2, expected_transaction.ISO_symbols_lane2, expected_transaction.Control_sym_flag_lane2); // Call IDLE_PATTERN task to handle IDLE state
                            IDLE_PATTERN(SR_flag_3, BS_flag_3, BF_flag_3, counter_SR_3, counter_3, cs_3, expected_transaction.ISO_symbols_lane3, expected_transaction.Control_sym_flag_lane3); // Call IDLE_PATTERN task to handle IDLE state
                        end  

                    3'b010: begin // // Data transmission on 2 lanes
                            send_hblank_symbols(SR_flag_0, BS_flag_0, BF_flag_0, counter_SR_0, counter_0, cs_0, ISO_LC, 2'd0, expected_transaction.ISO_symbols_lane0, expected_transaction.Control_sym_flag_lane0); // Call VBLANK_PATTERN task to handle VBLANK state
                            send_hblank_symbols(SR_flag_1, BS_flag_1, BF_flag_1, counter_SR_1, counter_1, cs_1, ISO_LC, 2'd1, expected_transaction.ISO_symbols_lane1, expected_transaction.Control_sym_flag_lane1); // Call VBLANK_PATTERN task to handle VBLANK state
                            IDLE_PATTERN(SR_flag_2, BS_flag_2, BF_flag_2, counter_SR_2, counter_2, cs_2, expected_transaction.ISO_symbols_lane2, expected_transaction.Control_sym_flag_lane2); // Call IDLE_PATTERN task to handle IDLE state
                            IDLE_PATTERN(SR_flag_3, BS_flag_3, BF_flag_3, counter_SR_3, counter_3, cs_3, expected_transaction.ISO_symbols_lane3, expected_transaction.Control_sym_flag_lane3); // Call IDLE_PATTERN task to handle IDLE state
                        end             

                    3'b100: begin // Data transmission on 4 lanes
                        // SEND VBLANK pattern to all lanes
                        send_hblank_symbols(SR_flag_0, BS_flag_0, BF_flag_0, counter_SR_0, counter_0, cs_0, ISO_LC, 2'd0, expected_transaction.ISO_symbols_lane0, expected_transaction.Control_sym_flag_lane0); // Call VBLANK_PATTERN task to handle VBLANK state
                        send_hblank_symbols(SR_flag_1, BS_flag_1, BF_flag_1, counter_SR_1, counter_1, cs_1, ISO_LC, 2'd1, expected_transaction.ISO_symbols_lane1, expected_transaction.Control_sym_flag_lane1); // Call VBLANK_PATTERN task to handle VBLANK state
                        send_hblank_symbols(SR_flag_2, BS_flag_2, BF_flag_2, counter_SR_2, counter_2, cs_2, ISO_LC, 2'd2, expected_transaction.ISO_symbols_lane2, expected_transaction.Control_sym_flag_lane2); // Call VBLANK_PATTERN task to handle VBLANK state
                        send_hblank_symbols(SR_flag_3, BS_flag_3, BF_flag_3, counter_SR_3, counter_3, cs_3, ISO_LC, 2'd3, expected_transaction.ISO_symbols_lane3, expected_transaction.Control_sym_flag_lane3); // Call VBLANK_PATTERN task to handle VBLANK state
                    end             

                    default:    // Default case to handle unexpected states
                        `uvm_fatal("ISO_LANE_NUM_ERROR", "Invalid lane number in ISO operation! Lane Count cannot be 3!")
                endcase
            end
            // Send the expected transaction to the scoreboard
            `uvm_info(get_type_name(), "Allocated expected_transaction object", UVM_MEDIUM)
            ref_vif.ref_expected_ISO_symbols_lane0 = expected_transaction.ISO_symbols_lane0;
            ref_vif.ref_expected_ISO_symbols_lane1 = expected_transaction.ISO_symbols_lane1;
            ref_vif.ref_expected_ISO_symbols_lane2 = expected_transaction.ISO_symbols_lane2;
            ref_vif.ref_expected_ISO_symbols_lane3 = expected_transaction.ISO_symbols_lane3;

            ref_vif.ref_expected_Control_sym_flag_lane0 = expected_transaction.Control_sym_flag_lane0;
            ref_vif.ref_expected_Control_sym_flag_lane1 = expected_transaction.Control_sym_flag_lane1;
            ref_vif.ref_expected_Control_sym_flag_lane2 = expected_transaction.Control_sym_flag_lane2;
            ref_vif.ref_expected_Control_sym_flag_lane3 = expected_transaction.Control_sym_flag_lane3;
            send_expected_to_scoreboard();
        end
        // Clear Counters and flags for the next iteration
        counter_0 = 0;
        if(ISO_LC == 3'b010) begin
            counter_1 = 0;
        end
        else if (ISO_LC == 3'b100) begin
            counter_1 = 0;
            counter_2 = 0;
            counter_3 = 0;
        end
    endtask

    // This task creates the HBLANK pattern to be sent on each lane
    task send_hblank_symbols(
        ref bit SR_flag, BS_flag, BF_flag,
        ref int counter_SR, counter, // Counters for the number of symbols sent
        ref iso_idle_code cs, // Current and next state variables for the IDLE pattern
        input bit [2:0] lane_num, 
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
                    cs = ISO_VB_ID; // Transition to VB_ID state
                    counter++; // Increment the counter for the number of symbols sent
                end
                else begin
                    cs = ISO_BF; // Transition to BF state
                end
            end

            ISO_BS: begin
                Control_sym_flag_lanex = 1'b1;
                ISO_symbols_lanex = BS;
                BS_flag = 1'b1;
                if(BF_flag) begin
                    counter_SR++;
                    counter++; // Increment the counter for the number of symbols sent
                    cs = ISO_VB_ID; // Transition to VB_ID state
                end
                else
                    cs = ISO_BF; // Transition to BF state
            end
            ISO_BF: begin
                Control_sym_flag_lanex = 1'b1;
                ISO_symbols_lanex = BF;
                if(!BF_flag) begin
                    cs = ISO_BF; // Transition to VB_ID state
                    BF_flag= 1'b1;
                end
                else begin
                    if(SR_flag) begin
                        cs = ISO_SR; // Transition to VB_ID state
                    end
                    else if (BS_flag) begin
                        cs = ISO_BS; // Reset count_SR after sending BS and BF symbols
                    end
                end
            end
            ISO_VB_ID:begin
                Control_sym_flag_lanex = 1'b0;
                ISO_symbols_lanex = 8'b0000_0000;
                counter++; // Increment the counter for the number of symbols sent
                cs = ISO_MVID; // Transition to MVID state
                BF_flag = 1'b0; // Reset BF_flag after sending VB_ID symbols
                BS_flag = 1'b0; // Reset BS_flag after sending VB_ID symbols
                SR_flag = 1'b0; // Reset SR_flag after sending VB_ID symbols
            end
            ISO_MVID:begin
                Control_sym_flag_lanex = 1'b0;
                ISO_symbols_lanex = 8'h00;
                counter++; // Increment the counter for the number of symbols sent
                cs = ISO_MAUD; // Transition to MAUD state
            end
            ISO_MAUD:begin
                Control_sym_flag_lanex = 1'b0;
                ISO_symbols_lanex = 8'h00;
                counter++; // Increment the counter for the number of symbols sent
                
                if((lane_num== 3'b001 && count_lc < 4) || (lane_num== 3'b010 && count_lc < 2)) begin // if not done with iterations repeat
                    cs = ISO_VB_ID; // Rpeat from VB-ID
                    count_lc++; // Increment
                end
                else begin
                    count_lc= 0;
                    cs = ISO_DUMMY; // Transition to dummy state
                end  
            end
            ISO_DUMMY:begin
                if(counter<hblank_period-1-3) begin
                    Control_sym_flag_lanex = 1'b0;
                    ISO_symbols_lanex = 'b0; // Dummy symbol for IDLE state
                    cs = ISO_DUMMY; // Stay in IDLE state
                end
                else begin
                    Control_sym_flag_lanex = 1'b1;
                    ISO_symbols_lanex = BE; // Dummy symbol for IDLE state
                    if(counter_SR == 511) begin
                            cs = ISO_SR; // Transition to SR state
                        end
                        else begin
                            cs = ISO_BS; // Transition to BS state
                        end
                end
                counter++; // Increment the counter for the number of symbols sent  
            end
           
            default: `uvm_fatal("ISO_STATE_ERROR", "Invalid state in ISO operation in VBLANK_PATTERN task")
        endcase
    endtask

    task ISO_ACTIVE_PATTERN();
        
        int count_data_0, count_data_1, count_data_2, count_data_3; // Counters for the number of symbols sent
        bit ceil_flag_0, floor_flag_0, ceil_flag_1, floor_flag_1, ceil_flag_2, floor_flag_2, ceil_flag_3, floor_flag_3; // Flags for the up and down states
        int count_TU_0, count_TU_1, count_TU_2, count_TU_3; // Counters for the number of symbols sent 
        int remaining_symbols_0 = hactive_period;
        int remaining_symbols_1 = hactive_period; 
        int remaining_symbols_2 = hactive_period; 
        int remaining_symbols_3 = hactive_period;
        int count_comp_0, count_comp_1, count_comp_2, count_comp_3;

        ceil_flag_0 =1; ceil_flag_1 =1; ceil_flag_2 =1; ceil_flag_3 =1; // Initialize the up flags to 1
        
        while(count_HACTIVE < hactive_period) begin
            if (RESET) begin
                count_data_0 = 0; count_data_1 = 0; count_data_2 = 0; count_data_3= 0;
                count_TU_0 = 0; count_TU_1 = 0; count_TU_2 = 0; count_TU_3 = 0; // Reset state and counters to initial values
                remaining_symbols_0 = 0; remaining_symbols_1 = 0; remaining_symbols_2 = 0; remaining_symbols_3 = 0; // Reset remaining symbols to initial values    
                count_comp_0 = 0; count_comp_1 = 0; count_comp_2 = 0; count_comp_3 = 0;
                break; // Exit the loop if reset is active
            end
            else begin
                case(ISO_LC) // according to the actvie lane count, send VBlank on all active lanes and remain with IDLE pattern on inactive lanes
                    3'b001: begin // // Data transmission on 1 lane    
                        send_hactive_symbols(counter_0, count_TU_0, count_data_0, remaining_symbols_0, count_comp_0, ceil_flag_0, floor_flag_0, cs_0_TU, ISO_LC, 2'd0, expected_transaction.ISO_symbols_lane0, expected_transaction.Control_sym_flag_lane0); // Call HACTIVE_PATTERN task to handle HACTIVE state
                        IDLE_PATTERN(SR_flag_1, BS_flag_1, BF_flag_1, counter_SR_1, counter_1, cs_1, expected_transaction.ISO_symbols_lane1, expected_transaction.Control_sym_flag_lane1); // Call IDLE_PATTERN task to handle IDLE state
                        IDLE_PATTERN(SR_flag_2, BS_flag_2, BF_flag_2, counter_SR_2, counter_2, cs_2, expected_transaction.ISO_symbols_lane2, expected_transaction.Control_sym_flag_lane2); // Call IDLE_PATTERN task to handle IDLE state
                        IDLE_PATTERN(SR_flag_3, BS_flag_3, BF_flag_3, counter_SR_3, counter_3, cs_3, expected_transaction.ISO_symbols_lane3, expected_transaction.Control_sym_flag_lane3); // Call IDLE_PATTERN task to handle IDLE state
                    end
                    3'b010: begin // // Data transmission on 2 lanes
                        send_hactive_symbols(counter_0, count_TU_0, count_data_0, remaining_symbols_0, count_comp_0, ceil_flag_0, floor_flag_0, cs_0_TU, ISO_LC, 2'd0, expected_transaction.ISO_symbols_lane0, expected_transaction.Control_sym_flag_lane0); // Call HACTIVE_PATTERN task to handle HACTIVE state
                        send_hactive_symbols(counter_1, count_TU_1, count_data_1, remaining_symbols_1, count_comp_1, ceil_flag_1, floor_flag_1, cs_1_TU, ISO_LC, 2'd1, expected_transaction.ISO_symbols_lane1, expected_transaction.Control_sym_flag_lane1); // Call HACTIVE_PATTERN task to handle HACTIVE state
                        IDLE_PATTERN(SR_flag_2, BS_flag_2, BF_flag_2, counter_SR_2, counter_2, cs_2, expected_transaction.ISO_symbols_lane2, expected_transaction.Control_sym_flag_lane2); // Call IDLE_PATTERN task to handle IDLE state
                        IDLE_PATTERN(SR_flag_3, BS_flag_3, BF_flag_3, counter_SR_3, counter_3, cs_3, expected_transaction.ISO_symbols_lane3, expected_transaction.Control_sym_flag_lane3); // Call IDLE_PATTERN task to handle IDLE state          
                    end
                    3'b100: begin // Data transmission on 4 lanes
                        // SEND VBLANK pattern to all lanes
                        send_hactive_symbols(counter_0, count_data_0, count_TU_0, remaining_symbols_0, count_comp_0, ceil_flag_0, floor_flag_0, cs_0_TU, ISO_LC, 2'd0, expected_transaction.ISO_symbols_lane0, expected_transaction.Control_sym_flag_lane0); // Call HACTIVE_PATTERN task to handle HACTIVE state
                        send_hactive_symbols(counter_1, count_data_1, count_TU_1, remaining_symbols_1, count_comp_1, ceil_flag_1, floor_flag_1, cs_1_TU, ISO_LC, 2'd1, expected_transaction.ISO_symbols_lane1, expected_transaction.Control_sym_flag_lane1); // Call HACTIVE_PATTERN task to handle HACTIVE state
                        send_hactive_symbols(counter_2, count_data_2, count_TU_2, remaining_symbols_2, count_comp_2, ceil_flag_2, floor_flag_2, cs_2_TU, ISO_LC, 2'd2, expected_transaction.ISO_symbols_lane2, expected_transaction.Control_sym_flag_lane2); // Call HACTIVE_PATTERN task to handle HACTIVE state
                        send_hactive_symbols(counter_3, count_data_3, count_TU_3, remaining_symbols_3, count_comp_3, ceil_flag_3, floor_flag_3, cs_3_TU, ISO_LC, 2'd3, expected_transaction.ISO_symbols_lane3, expected_transaction.Control_sym_flag_lane3); // Call HACTIVE_PATTERN task to handle HACTIVE state 
                    end
                    default:    // Default case to handle unexpected states
                        `uvm_fatal("ISO_LANE_NUM_ERROR", "Invalid lane number in ISO operation! Lane Count cannot be 3!")
                endcase
                count_HACTIVE++; // Increment the HACTIVE counter
            end
            // Send the expected transaction to the scoreboard
            `uvm_info(get_type_name(), "Allocated expected_transaction object", UVM_MEDIUM)
            ref_vif.ref_expected_ISO_symbols_lane0 = expected_transaction.ISO_symbols_lane0;
            ref_vif.ref_expected_ISO_symbols_lane1 = expected_transaction.ISO_symbols_lane1;
            ref_vif.ref_expected_ISO_symbols_lane2 = expected_transaction.ISO_symbols_lane2;
            ref_vif.ref_expected_ISO_symbols_lane3 = expected_transaction.ISO_symbols_lane3;

            ref_vif.ref_expected_Control_sym_flag_lane0 = expected_transaction.Control_sym_flag_lane0;
            ref_vif.ref_expected_Control_sym_flag_lane1 = expected_transaction.Control_sym_flag_lane1;
            ref_vif.ref_expected_Control_sym_flag_lane2 = expected_transaction.Control_sym_flag_lane2;
            ref_vif.ref_expected_Control_sym_flag_lane3 = expected_transaction.Control_sym_flag_lane3;
            send_expected_to_scoreboard();
        end    
    endtask
    
    // assumed that there must be at least 1 stuffing symbol in each TU.
    // did not account for the possibilty that not enough pixels were sent to fill up the active region
    task send_hactive_symbols (
        ref int counter, count_TU, count_data, remaining_symbols, count_comp, // Counts the number of symbols sent in a single TU
        ref bit ceil_flag, floor_flag, // Flags for the up and down values
        ref iso_TU_code cs, // Current and next state variables for the IDLE pattern
        input bit [2:0] lane_num, // lane count
        input bit [1:0] lane_id,  // lane number
        output logic [AUX_DATA_WIDTH-1:0] ISO_symbols_lanex,
        output logic Control_sym_flag_lanex
    );
        int stuff_num_ceil; 
        int stuff_num_floor = 64 - valid_symbols_integer;
        //int remaining_symbols; // Remaining symbols to be sent in the current line
        if(tu_alternate_up == 0) begin
            ceil_flag = 1'b0;
            floor_flag = 1'b1; // Set floor_flag to 1 to indicate the down symbols
        end
        else begin
            stuff_num_ceil = 64 - (valid_symbols_integer+1); 
        end
        case (cs) 
            ISO_TU_PIXELS:begin
                Control_sym_flag_lanex = 1'b0;
                
                pixels_symbols(count_comp, RED, GREEN, BLUE, ISO_symbols_lanex); // Call pixels_symbols task to handle pixel transmission (valid data part of TU)
                
                if(remaining_symbols > 64) begin // If i still have space for more than 1 TU, which means I can have a full TU + a truncated TU
                    if(ceil_flag && (count_data < tu_alternate_up)) begin
                        count_data++;
                        cs = ISO_TU_PIXELS; // Stay in TU_PIXELS state
                    end 
                    else if(ceil_flag) begin
                        ceil_flag = 1'b0; // Reset ceil_flag after sending the up symbols
                        floor_flag = 1'b1; // Set floor_flag to 1 to indicate the down symbols
                        count_data = 0; // Reset count_data after sending the up symbols
                        if(stuff_num_ceil == 1) begin
                            cs = ISO_TU_FE; // Transition to FE state
                        end
                        else begin
                            cs = ISO_TU_FS; // Transition to FS state
                        end
                    end
                    if(floor_flag && (count_data < tu_alternate_down)) begin
                        count_data++;
                        cs = ISO_TU_PIXELS; // Stay in TU_PIXELS state
                    end 
                    else if(floor_flag) begin
                        ceil_flag = 1'b1; // Set floor_flag to 1 to indicate the up symbols
                        floor_flag = 1'b0; // Reset floor_flag after sending the down symbols
                        count_data = 0; // Reset count_data after sending the down symbols
                        if(stuff_num_floor == 1) begin
                            cs = ISO_TU_FE; // Transition to FE state
                        end
                        else begin
                            cs = ISO_TU_FS; // Transition to FS state
                        end
                    end 
                    count_TU++; // Increment the counter for the number of symbols sent in 1 TU
                    counter++; 
                end
                else if(counter < hactive_period) begin
                    cs = ISO_TU_PIXELS; // Stay in TU_PIXELS state
                    counter++; 
                end
                else begin
                    counter = 0;
                    count_TU = 0;
                end 
            end              

            ISO_TU_FS: begin
                Control_sym_flag_lanex = 1'b1;
                ISO_symbols_lanex = FS;
                counter++;
                count_TU++;   
                if(ceil_flag) begin
                    if(stuff_num_ceil == 2) begin
                        cs = ISO_TU_FE; // Transition to FE state
                    end
                    else begin
                        cs = ISO_TU_DUMMY; // Stay in TU_DUMMY state
                    end
                end
                else if(floor_flag) begin
                    if(stuff_num_floor == 2) begin
                        cs = ISO_TU_FE; // Transition to FE state
                    end
                    else begin
                        cs = ISO_TU_DUMMY; // Transition to TU_DUMMY state
                    end
                end
            end

            ISO_TU_FE: begin
                Control_sym_flag_lanex = 1'b1;
                ISO_symbols_lanex = FE;
                remaining_symbols = hactive_period - counter; // Remaining symbols to be sent in the current line
                counter++; 
                count_TU = 0; // Reset count_TU after sending the last symbol inside a TU
                cs = ISO_TU_PIXELS; // Transition to TU state
            end

            ISO_TU_DUMMY:begin
                Control_sym_flag_lanex = 1'b0;
                ISO_symbols_lanex = 'b0; // Dummy symbol for IDLE state
                if(count_TU <63) begin
                    cs = ISO_TU_DUMMY; // Stay in DUMMY state  
                end
                else begin
                    cs = ISO_TU_FE; // Transition to FE state
                end
                count_TU++; // Increment the counter for the number of symbols sent inside the TU
                counter++; // Increment the counter for the number of symbols sent
            end
            default: `uvm_fatal("ISO_STATE_ERROR", "Invalid state in ISO operation in VBLANK_PATTERN task")
        endcase
    endtask

    task pixels_symbols(
        ref int count_comp,
        ref bit [15:0] RED, GREEN, BLUE,
        output logic [AUX_DATA_WIDTH-1:0] ISO_symbols_lanex
    ); 
        case (MISC0_q[0][7:5])
            3'b001: begin // 8bpc     
                case(count_comp) 
                    'd0: ISO_symbols_lanex = RED_8.pop_front();
                    'd1: ISO_symbols_lanex = GREEN_8.pop_front();
                    'd2: ISO_symbols_lanex = BLUE_8.pop_front();
                    default: `uvm_fatal("PIXELS_SYMBOLS_ERROR", "Invalid count_comp in pixels_symbols task")
                endcase
                count_comp++;
                if(count_comp == 3)
                    count_comp = 0;
            end
            3'b100: begin // 16bpc
                case(count_comp) 
                    'd0: begin
                        RED = RED_16.pop_front();
                        ISO_symbols_lanex = RED[15:8];
                    end 
                    'd1: begin
                        ISO_symbols_lanex = RED[7:0];
                    end
                    'd2: begin
                        GREEN = GREEN_16.pop_front();
                        ISO_symbols_lanex = GREEN[15:8];
                    end
                    'd3: begin
                        ISO_symbols_lanex = GREEN[7:0];
                    end
                    'd4: begin
                        BLUE = BLUE_16.pop_front();
                        ISO_symbols_lanex = BLUE[15:8];
                    end
                    'd5: begin
                        ISO_symbols_lanex = BLUE[7:0];
                    end
                    default: `uvm_fatal("PIXELS_SYMBOLS_ERROR", "Invalid count_comp in pixels_symbols task")
                endcase
                count_comp++;
                if(count_comp == 6)
                    count_comp = 0;
            end
            default: `uvm_fatal("PIXELS_SYMBOLS_ERROR", "Invalid MISC0[7:5] in pixels_symbols task")
        endcase
    endtask

       // This task calculates the timing parameters for the ISO operation
    task calculate_timing_parameters(
        output logic [15:0] hactive_period,
        output logic [15:0] hblank_period,
        output logic [15:0] vblank_period,
        output logic [15:0] htotal_period, // not sure if this is correct
        output logic [15:0] valid_symbols_integer,
        output logic [15:0] valid_symbols_fraction,
        output logic [3:0] tu_alternate_up,
        output logic [3:0] tu_alternate_down,
        output logic alternate_valid
    );  
        // Define the parameters for the calculations
        logic [15:0] hwidth;
        logic [15:0] htotal;
        logic [15:0] vtotal;
        logic [15:0] vheight;
        logic [2:0]  spm_lane_count;
        logic [15:0] spm_lane_bw;
        logic [15:0] bpc;
        logic [15:0] symbols_per_pixel;
        logic [15:0] symbol_bit_size; // always 8 bits
        int TU_SIZE = 64; // always 64 symbols
        logic [15:0] x_value; // empirical correction factor either 3 or 6 depending on bpc (8 or 16)

        // Internal registers for intermediate calculations
        logic [15:0] HACTIVE_EQUIVALENT_WIDTH, HACTIVE_TOTAL_BITS;
        logic [15:0] HACTIVE_TOTAL_SYMBOLS, HACTIVE_TOTAL_SYMBOLS_BITS, HACTIVE_FINAL_PERIOD;
        logic [15:0] HBLANK_EQUIVALENT_WIDTH, HBLANK_TOTAL_BITS;
        logic [15:0] HBLANK_TOTAL_SYMBOLS, HBLANK_TOTAL_SYMBOLS_BITS, HBLANK_FINAL_PERIOD;
        logic [63:0] TOTAL_BITS_PER_SECOND;
        logic [31:0] TOTAL_SYMBOLS_PER_SECOND, SYMBOLS_PER_LANE, SYMBOLS_PER_TU;
        logic [63:0] SCALED_VALID_SYMBOLS;
        logic [15:0] FRACTIONAL_PART_SCALED, FIRST_DECIMAL, SECOND_DECIMAL, ROUNDED_FIRST_DECIMAL;

        // Wait for the next transaction
        // ref_tl_fifo.get(tl_item); 
        `uvm_info(get_type_name(), $sformatf("Got TL item from FIFO: %s", tl_item.convert2string()), UVM_HIGH)

        // Extract the parameters from the transaction item
        htotal = HTotal_q[0];
        vtotal = VTotal_q[0];
        hwidth = HWidth_q[0];
        vheight = VHeight_q[0];
        spm_lane_count = tl_item.SPM_Lane_Count;
        // not sure here
        spm_lane_bw = tl_item.SPM_Lane_BW;
        symbol_bit_size = 16'h0008; // 8 bits
        if (MISC0_q[0][7:5] == 3'b001) begin
            bpc = 16'h0008; // 8 bits per component
        end 
        if (MISC0_q[0][7:5] == 3'b100) begin
            bpc = 16'h0010; // 16 bits per component
        end 
        if (bpc == 16'h0008) begin // 8 bits per component
            symbols_per_pixel = 16'h0003; // 3 symbols per pixel for 8 bpc
            x_value = 16'h0003; // x = 3 for 8 bpc
        end
        if (bpc == 16'h0010) begin // 16 bits per component
            symbols_per_pixel = 16'h0006; // 6 symbols per pixel for 16 bpc
            x_value = 16'h0006; // x = 6 for 16 bpc
        end
    
        // Reset logic
        if (!tl_item.MS_rst_n) begin
            hactive_period = 0;
            hblank_period = 0;
            vblank_period = 0;
            valid_symbols_integer = 0;
            valid_symbols_fraction = 0;
            tu_alternate_up = 0;
            tu_alternate_down = 0;
            alternate_valid = 0;
        end 
        else begin
    
            //////////////////////////////////////////
            // Horizontal Active Period Calculation //
            //////////////////////////////////////////
            
            // HwidthEquivalent = Hwidth - (Hwidth % spm_lane_count)
            // Hactive = (HwidthEquivalent) * bpc * symbols_per_pixel) / (symbol_bit_size * spm_lane_count) + x_value
            
            // Step 1: Calculate the equivalent horizontal active width
            // What it does? Rounds hwidth down to the nearest multiple of spm_lane_count.
            HACTIVE_EQUIVALENT_WIDTH = hwidth - (hwidth % spm_lane_count);
            
            // Step 2: Multiply the equivalent width by bits per component (BPC) 
            HACTIVE_TOTAL_BITS = HACTIVE_EQUIVALENT_WIDTH * bpc;
            
            // Step 3: Multiply the result by the number of symbols per pixel
            HACTIVE_TOTAL_SYMBOLS_BITS = HACTIVE_TOTAL_BITS * symbols_per_pixel;
            
            // Step 4: Divide the result by the symbol bit size
            HACTIVE_TOTAL_SYMBOLS = HACTIVE_TOTAL_SYMBOLS / symbol_bit_size;
            
            // Step 5: Divide the result by the lane count and add the offset (x_value)
            // Why? These symbols are sent in parallel over multiple lanes → divide by spm_lane_count.
            // Why add x_value? It's an empirical correction factor:
            // x = 3 for 8 bpc
            // x = 6 for 16 bpc
            // Accounts for framing overhead or internal padding.
            HACTIVE_FINAL_PERIOD = (HACTIVE_TOTAL_SYMBOLS / spm_lane_count) + x_value;
            
            // Step 6: Assign the final result to the horizontal active period
            hactive_period = HACTIVE_FINAL_PERIOD;
            
            ///////////////////////////////////////////
            ///////////////////////////////////////////
            ///////////////////////////////////////////


            ////////////////////////////////////////////
            // Horizontal Blanking Period Calculation //
            ////////////////////////////////////////////

            // HblankWidthEquivalent = (htotal - hwidth) - ((htotal - hwidth) % spm_lane_count)
            // Hblank = (HblankWidthEquivalent * bpc * symbols_per_pixel) / (symbol_bit_size * spm_lane_count) + x_value

            // Step 1: Calculate the equivalent horizontal blanking width
            HBLANK_EQUIVALENT_WIDTH = (htotal - hwidth) - ((htotal - hwidth) % spm_lane_count);
            
            // Step 2: Multiply the equivalent width by bits per component (BPC)
            HBLANK_TOTAL_BITS = HBLANK_EQUIVALENT_WIDTH * bpc;
            
            // Step 3: Multiply the result by the number of symbols per pixel
            HBLANK_TOTAL_SYMBOLS_BITS = HBLANK_TOTAL_BITS * symbols_per_pixel;
            
            // Step 4: Divide the result by the symbol bit size
            HBLANK_TOTAL_SYMBOLS = HBLANK_TOTAL_SYMBOLS / symbol_bit_size;
            
            // Step 5: Divide the result by the lane count and add the offset (x_value)
            HBLANK_FINAL_PERIOD = (HBLANK_TOTAL_SYMBOLS / spm_lane_count) + x_value;
            
            // Step 6: Assign the final result to the horizontal blanking period
            hblank_period = HBLANK_FINAL_PERIOD;
            
            ///////////////////////////////////////////
            /// Horizontal Total Period Calculation ///
            ///////////////////////////////////////////
            
            htotal_period = hblank_period + hactive_period; // In symbols

            //////////////////////////////////////////
            // Vertical Blanking Period Calculation //
            //////////////////////////////////////////

            vblank_period = vtotal - vheight; // In lines
              
            ///////////////////////////////////////////
            ///////////////////////////////////////////
            ///////////////////////////////////////////
    

            ///////////////////////////////////////////////////
            // Valid and Stuffing Data Size in Transfer Unit //
            ///////////////////////////////////////////////////
    
            // Step 1: Calculate Total Bits per Second
            TOTAL_BITS_PER_SECOND = spm_lane_bw * bpc;
    
            // Step 2: Calculate Total Symbols per Second
            TOTAL_SYMBOLS_PER_SECOND = TOTAL_BITS_PER_SECOND / symbol_bit_size;
    
            // Step 3: Calculate Symbols per Lane
            SYMBOLS_PER_LANE = TOTAL_SYMBOLS_PER_SECOND / spm_lane_count;
    
            // Step 4: Calculate Symbols per Transfer Unit (TU)
            SYMBOLS_PER_TU = SYMBOLS_PER_LANE * TU_SIZE;
    
            // Step 5: Calculate Scaled Valid Symbols (Fixed-point precision)
            SCALED_VALID_SYMBOLS = (SYMBOLS_PER_TU << 10) / spm_lane_bw;
    
            // Step 6: Extract Integer and Fractional Parts
            valid_symbols_integer = SCALED_VALID_SYMBOLS >> 10;
            valid_symbols_fraction = SCALED_VALID_SYMBOLS[9:0];
    
            // Step 7: Scale Fractional Part for Rounding
            FRACTIONAL_PART_SCALED = (valid_symbols_fraction * 100) >> 10;
    
            // Step 8: Extract First and Second Decimal Digits
            FIRST_DECIMAL = FRACTIONAL_PART_SCALED / 10;
            SECOND_DECIMAL = FRACTIONAL_PART_SCALED % 10;
    
            // Step 9: Perform Rounding
            if (SECOND_DECIMAL >= 5) begin
                ROUNDED_FIRST_DECIMAL = FIRST_DECIMAL + 1;
            end else begin
                ROUNDED_FIRST_DECIMAL = FIRST_DECIMAL;
            end
    
            // Step 10: Determine Alternate Up and Down Transition
            case (ROUNDED_FIRST_DECIMAL)
                16'd0: begin tu_alternate_up = 4'h0; tu_alternate_down = 4'h1; alternate_valid = 1'b1; end
                16'd1: begin tu_alternate_up = 4'h1; tu_alternate_down = 4'h9; alternate_valid = 1'b1; end
                16'd2: begin tu_alternate_up = 4'h1; tu_alternate_down = 4'h4; alternate_valid = 1'b1; end
                16'd3: begin tu_alternate_up = 4'h3; tu_alternate_down = 4'h7; alternate_valid = 1'b1; end
                16'd4: begin tu_alternate_up = 4'h2; tu_alternate_down = 4'h3; alternate_valid = 1'b1; end
                16'd5: begin tu_alternate_up = 4'h1; tu_alternate_down = 4'h1; alternate_valid = 1'b1; end
                16'd6: begin tu_alternate_up = 4'h3; tu_alternate_down = 4'h2; alternate_valid = 1'b1; end
                16'd7: begin tu_alternate_up = 4'h7; tu_alternate_down = 4'h3; alternate_valid = 1'b1; end
                16'd8: begin tu_alternate_up = 4'h4; tu_alternate_down = 4'h1; alternate_valid = 1'b1; end
                16'd9: begin tu_alternate_up = 4'h9; tu_alternate_down = 4'h1; alternate_valid = 1'b1; end
                default: begin tu_alternate_up = 4'h0; tu_alternate_down = 4'h0; alternate_valid = 1'b0; end
            endcase
               
            ///////////////////////////////////////////
            ///////////////////////////////////////////
            ///////////////////////////////////////////
        end
    endtask

    task send_expected_to_scoreboard();
        dp_ref_transaction tx_copy;
        tx_copy = dp_ref_transaction::type_id::create($sformatf("tx_copy_%0d", $time));
        void'($cast(tx_copy, expected_transaction.clone()));
        ref_model_out_port.write(tx_copy);
    endtask
endclass