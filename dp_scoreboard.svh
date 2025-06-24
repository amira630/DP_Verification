class dp_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(dp_scoreboard)
    
    uvm_analysis_export #(dp_tl_sequence_item) sb_tl_export;
    uvm_analysis_export #(dp_sink_sequence_item) sb_sink_export;
    // uvm_analysis_export #(dp_ref_transaction) sb_ref_export;

    uvm_tlm_analysis_fifo #(dp_tl_sequence_item) sb_tl_fifo;
    uvm_tlm_analysis_fifo #(dp_sink_sequence_item) sb_sink_fifo;
    // uvm_tlm_analysis_fifo #(dp_ref_transaction) sb_ref_fifo;

    dp_tl_sequence_item tl_item;
    dp_sink_sequence_item sink_item;
    // dp_ref_transaction expected_transaction;

    virtual dp_ref_if ref_vif;
    
    int error_count = 0;
    int correct_count = 0;
    bit comp_pixels;
    logic [7:0] RED_8 [$];   logic [15:0] RED_16 [$];
    logic [7:0] GREEN_8 [$]; logic [15:0] GREEN_16 [$];
    logic [7:0] BLUE_8 [$];  logic [15:0] BLUE_16 [$];
    bit [15:0] RED, GREEN, BLUE; // Variables to store pixel data
    logic [2:0] ISO_LC;
    logic [2:0] bpc;
    int count_comp0, count_comp1, count_comp2, count_comp3;
    logic [7:0] ISO_symbols_lane0, ISO_symbols_lane1, ISO_symbols_lane2, ISO_symbols_lane3;

    function new(string name = "dp_scoreboard", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        
        sb_tl_export = new("sb_tl_export", this);
        sb_sink_export = new("sb_sink_export", this);
        // sb_ref_export = new("sb_ref_export", this);

        sb_tl_fifo = new("sb_tl_fifo", this);
        sb_sink_fifo = new("sb_sink_fifo", this);
        // sb_ref_fifo = new("sb_ref_fifo", this);

        `uvm_info(get_type_name(), "Scoreboard build_phase completed", UVM_LOW)

    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        sb_tl_export.connect(sb_tl_fifo.analysis_export);
        sb_sink_export.connect(sb_sink_fifo.analysis_export);
        // sb_ref_export.connect(sb_ref_fifo.analysis_export);

        `uvm_info(get_type_name(), "Scoreboard connect_phase completed", UVM_LOW)
    endfunction

    task run_phase(uvm_phase phase);
        super.run_phase(phase);
        forever begin   
            // `uvm_info(get_type_name(), "Got tl_item from FIFO", UVM_LOW)
            // `uvm_info(get_type_name(), $sformatf("SPM_ISO_start = %b, MS_rst_n = %b", 
            //     tl_item.SPM_ISO_start, tl_item.MS_rst_n), UVM_LOW)
            if (sb_tl_fifo.try_get(tl_item)) begin
                if(tl_item.SPM_ISO_start && tl_item.MS_rst_n) begin
                    // `uvm_error(get_type_name(), $sformatf("WE ARE GETTING TL_ITEM"))
                    // `uvm_fatal(get_type_name(),"WE ARE GETTING TL_ITEM")
                    case (tl_item.SPM_Lane_Count)
                        3'b001: ISO_LC = 3'b001;
                        3'b010: ISO_LC = 3'b010;
                        3'b100: ISO_LC = 3'b100;
                        default: `uvm_info(get_type_name(), "Incorrect lane count", UVM_LOW)
                    endcase
                    if(tl_item.SPM_MSA_VLD) begin
                        bpc = tl_item.SPM_Full_MSA[183:181];
                    end    
                    else if(tl_item.MS_DE) begin
                        if(bpc == 3'b001) begin
                            // `uvm_info(get_type_name(), $sformatf("RED = %0h, GREEN = %0h, BLUE = %0h", tl_item.MS_Pixel_Data[7:0], tl_item.MS_Pixel_Data[15:8], tl_item.MS_Pixel_Data[23:16]), UVM_LOW)
                            // `uvm_fatal(get_type_name(),"WE ARE GETTING PIXEL DATA")
                            RED_8.push_back(tl_item.MS_Pixel_Data[7:0]);
                            GREEN_8.push_back(tl_item.MS_Pixel_Data[15:8]);
                            BLUE_8.push_back(tl_item.MS_Pixel_Data[23:16]);
                        end
                        else if (bpc == 3'b100) begin
                            `uvm_info(get_type_name(), $sformatf("RED = %0h, GREEN = %0h, BLUE = %0h", tl_item.MS_Pixel_Data[15:0], tl_item.MS_Pixel_Data[31:16], tl_item.MS_Pixel_Data[47:32]), UVM_LOW)
                            RED_16.push_back(tl_item.MS_Pixel_Data[15:0]);
                            GREEN_16.push_back(tl_item.MS_Pixel_Data[31:16]);
                            BLUE_16.push_back(tl_item.MS_Pixel_Data[47:32]);
                        end
                    end
                end
                // else begin
                //     RED_8.delete(); GREEN_8.delete(); BLUE_8.delete();
                //     RED_16.delete(); GREEN_16.delete(); BLUE_16.delete();
                //     ISO_LC = 3'b000;
                //     bpc = 3'b000;
                //     count_comp0 = 0; count_comp1 = 0; count_comp2 = 0; count_comp3 = 0;
                //     ISO_symbols_lane0 = 8'h00; ISO_symbols_lane1 = 8'h00; 
                //     ISO_symbols_lane2 = 8'h00; ISO_symbols_lane3 = 8'h00;
                // end
            end
            sb_sink_fifo.get(sink_item);
            if(sink_item.ISO_symbols_lane0 != 8'h00) begin
                // `uvm_info(get_type_name(), $sformatf("ISO_symbols_lane0 = %0h",sink_item.ISO_symbols_lane0), UVM_LOW)
            end
            if(sink_item.ISO_symbols_lane0 == BE && sink_item.Control_sym_flag_lane0) begin
                // `uvm_info(get_type_name(), "Inside BE to FS - should compare", UVM_LOW)
                comp_pixels = 1'b1; 
                continue;
            end
            else if (sink_item.ISO_symbols_lane0 == FS && sink_item.Control_sym_flag_lane0) begin
                comp_pixels = 1'b0; 
                // `uvm_info(get_type_name(), "Inside FS to FE - should not compare", UVM_LOW)
                continue;
            end
            else if (sink_item.ISO_symbols_lane0 == FE && sink_item.Control_sym_flag_lane0) begin
                comp_pixels = 1'b1;
                // `uvm_info(get_type_name(), "Inside FE to FS/BS - should compare", UVM_LOW)
                continue;
            end
            else if ((sink_item.ISO_symbols_lane0 == BS || sink_item.ISO_symbols_lane0 == SR)  && sink_item.Control_sym_flag_lane0) begin
                comp_pixels = 1'b0; 
                // `uvm_info(get_type_name(), "Inside BS to BE - should not compare", UVM_LOW)
                continue;
            end
            if (comp_pixels) begin
                // `uvm_info(get_type_name(), "Inside Compare condition", UVM_LOW)
                if (^sink_item.ISO_symbols_lane0 === 1'bx) begin
                    `uvm_warning(get_type_name(), "Actual ISO_symbols_lane0 is X, skipping this comparison")
                    continue;
                end
                else begin
                    compare_pixels();
                end
            end       

            `uvm_info("run_phase", tl_item.convert2string(), UVM_HIGH)
            `uvm_info("run_phase", sink_item.convert2string(), UVM_HIGH) 
        end
    endtask

    task compare_pixels();
        case (ISO_LC) 
            3'b001: begin
                // `uvm_error(get_type_name(), $sformatf("INSIDE LANE COUNT ONEEEEEEEEEEE"))
                pixels_symbols(count_comp0, RED, GREEN, BLUE, ISO_symbols_lane0); // Call pixels_symbols task to handle pixel transmission (valid data part of TU)
                if (ISO_symbols_lane0 !== sink_item.ISO_symbols_lane0) begin
                    `uvm_error(get_type_name(), $sformatf("Mismatch in ISO_symbols_lane0: expected=%0h, actual=%0h", ISO_symbols_lane0, sink_item.ISO_symbols_lane0))
                    // `uvm_fatal(get_type_name(),"Mismatch in ISO_symbols_lane0")
                    error_count++;
                end
                else begin
                    // `uvm_info(get_type_name(),  $sformatf("ISO_symbols_lane0 match: expected=%0h, actual=%0h", ISO_symbols_lane0, sink_item.ISO_symbols_lane0), UVM_LOW)
                    correct_count++;
                    // `uvm_fatal("SCOREBOARD", "ISO_symbols_lane0 match")
                end
            end
            3'b010: begin
                pixels_symbols(count_comp0, RED, GREEN, BLUE, ISO_symbols_lane0); // Call pixels_symbols task to handle pixel transmission (valid data part of TU)
                if (ISO_symbols_lane0 !== sink_item.ISO_symbols_lane0) begin
                    `uvm_error(get_type_name(), $sformatf("Mismatch in ISO_symbols_lane0: expected=%0h, actual=%0h", ISO_symbols_lane0, sink_item.ISO_symbols_lane0))
                    `uvm_fatal(get_type_name(),"Mismatch in ISO_symbols_lane0")
                    error_count++;
                end
                else begin
                    `uvm_info(get_type_name(), "ISO_symbols_lane0 match", UVM_LOW)
                    correct_count++;
                end
                pixels_symbols(count_comp1, RED, GREEN, BLUE, ISO_symbols_lane1); // Call pixels_symbols task to handle pixel transmission (valid data part of TU)
                if (ISO_symbols_lane1 !== sink_item.ISO_symbols_lane1) begin
                    `uvm_error(get_type_name(), $sformatf("Mismatch in ISO_symbols_lane1: expected=%0h, actual=%0h", ISO_symbols_lane1, sink_item.ISO_symbols_lane1))
                    `uvm_fatal(get_type_name(),"Mismatch in ISO_symbols_lane1")
                    error_count++;
                end
                else begin
                    `uvm_info(get_type_name(), "ISO_symbols_lane1 match", UVM_LOW)
                    correct_count++;
                end
            end
            3'b100: begin
                pixels_symbols(count_comp0, RED, GREEN, BLUE, ISO_symbols_lane0); // Call pixels_symbols task to handle pixel transmission (valid data part of TU)
                if (ISO_symbols_lane0 !== sink_item.ISO_symbols_lane0) begin
                    `uvm_error(get_type_name(), $sformatf("Mismatch in ISO_symbols_lane0: expected=%0h, actual=%0h", ISO_symbols_lane0, sink_item.ISO_symbols_lane0))
                    `uvm_fatal(get_type_name(),"Mismatch in ISO_symbols_lane0")
                    error_count++;
                end
                else begin
                    `uvm_info(get_type_name(), "ISO_symbols_lane0 match", UVM_LOW)
                    correct_count++;
                end
                pixels_symbols(count_comp1, RED, GREEN, BLUE, ISO_symbols_lane1); // Call pixels_symbols task to handle pixel transmission (valid data part of TU)
                if (ISO_symbols_lane1 !== sink_item.ISO_symbols_lane1) begin
                    `uvm_error(get_type_name(), $sformatf("Mismatch in ISO_symbols_lane1: expected=%0h, actual=%0h", ISO_symbols_lane1, sink_item.ISO_symbols_lane1))
                    `uvm_fatal(get_type_name(),"Mismatch in ISO_symbols_lane1")
                    error_count++;
                end
                else begin
                    `uvm_info(get_type_name(), "ISO_symbols_lane1 match", UVM_LOW)
                    correct_count++;
                end
                pixels_symbols(count_comp2, RED, GREEN, BLUE, ISO_symbols_lane2); // Call pixels_symbols task to handle pixel transmission (valid data part of TU)
                if (ISO_symbols_lane2 !== sink_item.ISO_symbols_lane2) begin
                    `uvm_error(get_type_name(), $sformatf("Mismatch in ISO_symbols_lane2: expected=%0h, actual=%0h", ISO_symbols_lane2, sink_item.ISO_symbols_lane2))
                    `uvm_fatal(get_type_name(),"Mismatch in ISO_symbols_lane2")
                    error_count++;
                end
                else begin
                    `uvm_info(get_type_name(), "ISO_symbols_lane2 match", UVM_LOW)
                    correct_count++;
                end
                pixels_symbols(count_comp3, RED, GREEN, BLUE, ISO_symbols_lane3); // Call pixels_symbols task to handle pixel transmission (valid data part of TU)
                if (ISO_symbols_lane3 !== sink_item.ISO_symbols_lane3) begin
                    `uvm_error(get_type_name(), $sformatf("Mismatch in ISO_symbols_lane3: expected=%0h, actual=%0h", ISO_symbols_lane3, sink_item.ISO_symbols_lane3))
                    `uvm_fatal(get_type_name(),"Mismatch in ISO_symbols_lane3")
                    error_count++;
                end
                else begin
                    `uvm_info(get_type_name(), "ISO_symbols_lane3 match", UVM_LOW)
                    correct_count++;
                end
            end
            // default: `uvm_info(get_type_name(), "No pixels yet", UVM_LOW)        
        endcase
    endtask

    task pixels_symbols(
        ref int count_comp,
        ref bit [15:0] RED, GREEN, BLUE,
        output logic [AUX_DATA_WIDTH-1:0] ISO_symbols_lanex
    ); 
        case (bpc)
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
    function void report_phase(uvm_phase phase);
        super.report_phase(phase);
        `uvm_info("report_phase", $sformatf("Total successful transactions: %d", correct_count), UVM_MEDIUM);
        `uvm_info("report_phase", $sformatf("Total failed transactions: %d", error_count), UVM_MEDIUM);
    endfunction
    
endclass