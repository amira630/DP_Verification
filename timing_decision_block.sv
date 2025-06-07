//==============================================================================
//  module: timing decision block
//  description: this module processes input signals related to video timing 
//  and generates control signals for synchronization, data validation, and 
//  active/blanking intervals.
//  author:  mohammed tersawy
//==============================================================================

module timing_decision_block
(
    //=========================
    // input ports
    //=========================
    input  wire        clk,                // clock signal
    input  wire        rst_n,              // reset signal
    input  wire        ms_de,              // main stream data enable
    input  wire [9:0]  ms_stm_bw,          // main stream bandwidth
    input  wire        ms_stm_bw_valid,    // main stream bandwidth valid
    input  wire        ms_vsync,           // main stream vertical sync
    input  wire        ms_hsync,           // main stream horizontal sync
    input  wire        spm_iso_start,      // start of isolation mode
    input  wire [2:0]  spm_lane_count,     // number of data lanes
    input  wire [15:0] spm_lane_bw,        // lane bandwidth
    input  wire [15:0] htotal,             // total horizontal pixels
    input  wire [15:0] hwidth,             // active horizontal width
    input  wire [15:0] vtotal,             // total vertical pixels
    input  wire [15:0] vheight,            // active vertical height
    input  wire [7:0]  misc0,              // provide colormitry information as color depth and pixel format bpc   
    input  wire [7:0]  misc1,              // additional miscellaneous data
    input  wire        spm_msa_vld,        // main stream attributes valid
    input  wire        h_sync_polarity,    // horizontal sync polarity
    input  wire        v_sync_polarity,    // vertical sync polarity

    //=========================
    // output ports
    //=========================
    output reg         td_vld_data,        // valid data flag 
    output reg         td_scheduler_start, // scheduler start signal
    output reg  [1:0]  td_lane_count,      // output lane count
    output reg  [13:0] td_h_blank_ctr,     // horizontal blanking counter
    output reg  [15:0] td_h_active_ctr,    // horizontal active counter
    output reg  [9:0]  td_v_blank_ctr,     // vertical blanking counter
    output reg  [12:0] td_v_active_ctr,    // vertical active counter
    output reg  [5:0]  td_tu_vld_data_size,// timing unit valid data size
    output reg  [5:0]  td_tu_stuffed_data_size,// timing unit stuffed data size
    output wire        td_hsync,            // output horizontal sync
    output wire        td_vsync,            // output vertical sync
    output wire        td_de,               // output data enable
    output reg  [3:0]  td_tu_alternate_up,  // timing unit alternate up
    output reg  [3:0]  td_tu_alternate_down,// timing unit alternate down
    output reg  [15:0] td_h_total_ctr,      // total horizontal counter
    output reg         td_hsync_polarity,   // horizontal sync polarity
    output reg         td_vsync_polarity,   // vertical sync polarity
    output reg  [8:0]  td_misc0_1           // extractedfrom spm_msa representing bits per component
);

    //=============================
    // local parameters
    //=============================
    localparam int TU_SIZE            = 64;          // symbols
    localparam int FP_PRECISION       = 10;          // fixed-point (2^10 = 1024)

    //=============================
    // local variables
    //=============================
    reg  [15:0] bpp;                     // bits per pixel (24 or 48)
    reg  [15:0] bpc;                     // bits per component (8 or 16)
    reg  [15:0] symbols_per_pixel;       // number of symbols per pixel (3 symbols per pixel)
    reg  [15:0] symbol_bit_size;         // symbol size in bits (8 bits) (8/10 encoding)
    reg  [15:0] x_value;                 // adjustment factor based on bpc
    wire        spm_iso_start_pulse;     // pulse signal for spm_iso_start
    reg         spm_iso_start_d;         // delayed spm_iso_start
    reg         saving_flag;             // flag to indicate saving of video parameters
    reg  [9:0]  ms_stm_bw_sync;          // synchronized main stream bandwidth
    reg         ms_stm_bw_saved;         // flag to indicate if main stream bandwidth is saved


    // Define the variables used in the to calculate hwidth module number of lanes 
    reg [15:0] mod_lc_hwidth; // Modulo result of hwidth_sync and spm_lane_count_sync
    reg [15:0] div_lc_hwidth; // Division result of hwidth_sync and spm_lane_count_sync
    reg [15:0] mul_lc_hwidth; // Multiplication result of div_lc_hwidth and spm_lane_count_sync
    reg        mod_flag_dn;   // Flag to indicate modulo operation is done
    reg [3:0]  mod_pipeline_counter; // Pipeline counter for tracking stages

    // Hactive equivalent calculation registers
    reg  [15:0] hactive_div_result;       // Result of division for HActive calculation
    reg  [15:0] hactive_width_equivalent;  // equivalent horizontal width

    // Hactive period calculation registers
    reg  [15:0] hactive_stage1_result;    // Result of hactive_width_equivalent * BPC
    reg  [15:0] hactive_stage2_result;    // Result of stage1 * symbols_per_pixel
    reg  [15:0] hactive_stage3_result;    // Result of symbol_bit_size * SPM_Lane_Count
    reg  [15:0] hactive_stage4_result;    // Result of division (stage2_result / stage3_result)
    reg  [15:0] hactive_stage5_result;    // Final result of division
    reg         hactive_valid;            // Valid flag for hactive calculation
    reg  [6:0]  hactive_pipeline_counter; // Pipeline counter for tracking stages
    
    // Hblank equivalent calculation registers
    reg  [13:0] hblank_div_result;       // Result of division for HBlank calculation
    reg  [13:0] hblank_width_equivalent; // equivalent horizontal blanking width

    // Hbalnk period calculation registers
    reg  [13:0] hblank_stage1_result;    // Result of hblank_width_equivalent * BPC
    reg  [13:0] hblank_stage2_result;    // Result of stage1 * symbols_per_pixel
    reg  [13:0] hblank_stage3_result;    // Result of symbol_bit_size * SPM_Lane_Count
    reg  [13:0] hblank_stage4_result;    // Result of division (stage2_result / stage3_result)
    reg  [13:0] hblank_stage5_result;    // Final result of division
    reg         hblank_valid;            // Valid flag for hblank calculation
    reg  [6:0]  hblank_pipeline_counter; // Pipeline counter for tracking stages

    // Vertical blanking period calculation registers
    reg  [9:0]  vblank;       // vertical blanking period counter
    reg         vblank_valid; // valid flag for vblank calculation


    // Intermediate registers (pipeline stages) for stuffing period calculation
    reg [31:0] stage1_total_bits;
    reg [31:0] stage2_total_symbols;
    reg [31:0] stage3_symbols_per_lane;
    reg [31:0] stage4_symbols_per_TU;
    reg [63:0] stage5_mult_result;
    wire [63:0] stage6_scaled_valid_symbols;
    reg [15:0] valid_symbols_integer;
    reg [15:0] valid_symbols_fraction;
    reg [15:0] valid_symbols_fraction_scaled;
    reg [15:0] first_decimal;
    reg [15:0] second_decimal;
    reg [15:0] rounded_first_decimal;
    reg [6:0]  stuffing_pipeline_counter;
    reg        stuffing_valid;
    reg        alternate_valid; // valid flag for alternate up and down transition
    reg [3:0]  tu_alternate_up;
    reg [3:0]  tu_alternate_down;

   // shift registers for hsync, vsync, de and spm_iso_start to delay these signals until th data counters are valid
    reg [403:0] hsync_shift_reg;
    reg [403:0] vsync_shift_reg;
    reg [403:0] de_shift_reg;
    reg [403:0] spm_iso_start_shift_reg;

   // divider internal signals 

    //=============================
    // synchronized variables
    //=============================
    reg  [2:0]  spm_lane_count_sync;
    reg  [15:0] spm_lane_bw_sync;
    reg  [15:0] htotal_sync;
    reg  [15:0] hwidth_sync;
    reg  [15:0] vtotal_sync;
    reg  [15:0] vheight_sync;
    reg  [8:0]  misc0_1_sync;
    //===============================================================================
    // division module for stuffing period calculation
    //===============================================================================
    reg         div_start;
    reg         div_done;
    wire  [63:0] spm_bw ;


    assign spm_bw = spm_lane_bw_sync; // lane bandwidth in 64 bits 
    Divider divider_inst 
    (
        .clk(clk),
        .rst(rst_n),
        .dividend(stage5_mult_result),
        .divisor(spm_bw),
        .start(div_start),
        .quotient(stage6_scaled_valid_symbols),
        //.remainder(),
        .done(div_done)
    ); 

    //===============================================================================
    // division module for hactive period calculation
    //===============================================================================
    reg div_start_hactive;
    reg div_done_hactive;
    wire [15:0] lane_count;
    assign lane_count = spm_lane_count_sync; // lane count in 16 bits

    Divider 
    #
    (
        .WIDTH(16)
    ) 
    divider_hactive_inst 
    (
        .clk(clk),
        .rst(rst_n),
        .dividend(hactive_stage3_result),
        .divisor(lane_count),
        .start(div_start_hactive),
        .quotient(hactive_stage4_result),
        //.remainder(),
        .done(div_done_hactive)
    );

    //===============================================================================
    // division module for hblank period calculation
    //===============================================================================
    reg div_start_hblank;
    reg div_done_hblank;

    Divider 
    #
    (
        .WIDTH(14)
    ) 
    divider_hblank_inst 
    (
        .clk(clk),
        .rst(rst_n),
        .dividend(hblank_stage3_result),
        .divisor(lane_count),
        .start(div_start_hblank),
        .quotient(hblank_stage4_result),
        //.remainder(),
        .done(div_done_hblank)
    );

    //=======================================================================================
    // always block for synchronization and saving the inputs (MSA) from stream policy maker
    //=======================================================================================
        always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
        begin
            htotal_sync         <= 16'b0;
            hwidth_sync         <= 16'b0;
            vtotal_sync         <= 16'b0;
            vheight_sync        <= 16'b0;
            misc0_1_sync        <= 9'b0;
            saving_flag         <= 1'b0;
        end 
        else 
        if (spm_msa_vld)
        begin
            htotal_sync         <= htotal;
            hwidth_sync         <= hwidth;
            vtotal_sync         <= vtotal;
            vheight_sync        <= vheight;
            misc0_1_sync        <= {misc1[7:6] , misc0[7:1]};
            saving_flag         <= 1'b1;
        end
        else
        if(spm_iso_start == 1'b0)
        begin
            saving_flag         <= 1'b0;
        end
    end
    //==================================================================
    // saving source stream bandwidth from stream policy maker
    //==================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
        begin
            ms_stm_bw_sync  <= 10'b0;
            ms_stm_bw_saved <= 1'b0;
        end 
        else 
        if (ms_stm_bw_valid) 
        begin
            ms_stm_bw_sync <= ms_stm_bw;
            ms_stm_bw_saved <= 1'b1;
        end
        else
        if (spm_iso_start == 1'b0)
        begin
            ms_stm_bw_saved <= 1'b0;
        end 
    end



    //==============================================================================
    // always block for generating pulse signal for spm_iso_start
    //==============================================================================
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
        begin
            spm_iso_start_d <= 1'b0;
        end 
        else 
        begin
            spm_iso_start_d <= spm_iso_start;
        end
    end

    // checking on posedgedge of spm_iso_start to save bandwidth and lane count
    //  generate a pulse signal of spm_iso_start
    assign spm_iso_start_pulse = spm_iso_start & ~spm_iso_start_d; 


    //=========================================================================
    // always block for saving bandwidth and lane count from link policy maker 
    //=========================================================================

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
        begin
            spm_lane_bw_sync    <= 16'b0;
            spm_lane_count_sync <= 3'b0;
        end 
        else 
        if (spm_iso_start_pulse) 
        begin
            spm_lane_bw_sync    <= spm_lane_bw;
            spm_lane_count_sync <= spm_lane_count;
        end
    end
    
//==============================================================================
// definning color format (RGB or YCbCr) and bpc (number of bits per component)
//==============================================================================
always_comb begin
    // default values
    bpc               = 16'd0;
    symbols_per_pixel = 16'd0;
    symbol_bit_size   = 16'd0;
    bpp               = 16'd0; 
    if (saving_flag == 1'b1) begin
        case (misc0_1_sync)
            9'b000010000: // RGB 8 bpc
            begin
                bpc               = 16'd8;
                symbols_per_pixel = 16'd3;
                symbol_bit_size   = 16'd8;
                bpp               = 16'd24; // bits per pixel
            end
            9'b001000000: // RGB 16 bpc
            begin
                bpc               = 16'd16;
                symbols_per_pixel = 16'd6;
                symbol_bit_size   = 16'd8;
                bpp               = 16'd48; // bits per pixel
            end
            9'b000010110: // YCbCr 4:4:4 8 bpc
            begin
                bpc               = 16'd8;
                symbols_per_pixel = 16'd3;
                symbol_bit_size   = 16'd8;
                bpp               = 16'd24;
            end
            9'b001000110: // YCbCr 4:4:4 16 bpc
            begin
                bpc               = 16'd16;
                symbols_per_pixel = 16'd6;
                symbol_bit_size   = 16'd8;
                bpp               = 16'd48; // bits per pixel
            end
            default:
            begin
                bpc               = 16'd10;
                symbols_per_pixel = 16'd3;
                symbol_bit_size   = 16'd8;
                bpp               = 16'd30; // bits per pixel
            end
        endcase
    end else begin
        bpc               = 16'd0;
        symbols_per_pixel = 16'd0;
        symbol_bit_size   = 16'd0;
        bpp               = 16'd0;
    end
end
// calculating hwidth module number of lanes
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) 
    begin
        mod_lc_hwidth        <= 16'b0;
        div_lc_hwidth        <= 16'b0;
        mul_lc_hwidth        <= 16'b0;
        mod_flag_dn          <= 1'b0;
        mod_pipeline_counter <= 4'b0;
    end 
    else 
    if (saving_flag == 1'b1) 
    begin
        div_lc_hwidth       <= hwidth_sync / spm_lane_count_sync;
        mul_lc_hwidth       <= div_lc_hwidth * spm_lane_count_sync; 
        mod_lc_hwidth       <= hwidth_sync - mul_lc_hwidth;
        if (mod_pipeline_counter < 4)
        begin
            mod_pipeline_counter <= mod_pipeline_counter + 1;
        end
        // Valid flag (high when result is ready)
        mod_flag_dn         <= (mod_pipeline_counter == 3);
    end 
    else 
    if (spm_iso_start == 1'b0) 
    begin
        mod_lc_hwidth        <= 16'b0;
        div_lc_hwidth        <= 16'b0;
        mul_lc_hwidth        <= 16'b0;
        mod_flag_dn          <= 1'b0;
        mod_pipeline_counter <= 4'b0;
    end
end

// calculate x_value based on bpc
// x_value is used to adjust the final result of hactive and hblank calculations
always_comb begin
    if (mod_flag_dn == 1'b1) 
    begin
        if (mod_lc_hwidth == 0) 
        begin
            x_value = 0;
        end 
        else 
        begin
            case (bpc)
                16'd8:
                begin  
                    x_value = 3;
                end
                16'd16:
                begin
                    x_value = 6;
                end
                default:
                begin
                    x_value = 0;
                end
            endcase
        end
    end 
    else 
    begin
        x_value = 0;
    end
end
//==============================================================================
// ** 1)Calculating Horizontal Active Period Counter **
//==============================================================================

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) 
    begin
        // Reset hblank equivalent calculation
        hactive_div_result        <= 16'b0;
        hactive_width_equivalent  <= 16'b0;

        // Reset hactive period calculation
        hactive_stage1_result     <= 16'b0;
        hactive_stage2_result     <= 16'b0;
        hactive_stage3_result     <= 16'b0;
        //hactive_stage4_result     <= 16'b0;
        hactive_stage5_result     <= 16'b0;

        // Reset pipeline counter and valid flag
        hactive_valid             <= 1'b0;
        hactive_pipeline_counter  <= 7'b0;
    end 
    else 
    if(saving_flag == 1'b1)    
    begin
        // ** 1) hblank equivalent calculation **

        // Stage 1: Division (HWidth / SPM_Lane_BW)
        hactive_div_result       <= hwidth_sync / spm_lane_count_sync; 

        // Stage 2: Multiplication (uses result from previous cycle) Hactive_width_Equivalent
        hactive_width_equivalent <= spm_lane_count_sync * hactive_div_result;

        // ** 2) hactive period calculation **

        // Stage 1: Multiplication (hactive_width_equivalent * BPC)
        hactive_stage1_result <= hactive_width_equivalent * bpc;

        // Stage 2: Multiplication with symbols_per_pixel
        hactive_stage2_result <= hactive_stage1_result * symbols_per_pixel;

        // Stage 3: Multiplication with SPM_Lane_Count
        hactive_stage3_result <= hactive_stage2_result / symbol_bit_size ;

        if(hactive_pipeline_counter == 10)
        begin
            div_start_hactive <= 1'b1;
        end
        else
        begin
            div_start_hactive <= 1'b0;
        end
        if(div_done_hactive == 1'b1)
        begin
            // Stage 4: Division (stage2_result / stage3_result)
            hactive_stage5_result <= hactive_stage4_result + x_value;
        end

        // -----------------------------------------------------------------
        // track the pipeline stages to determine when the result is valid
        //------------------------------------------------------------------
        // hactive_pipeline_counter is used to track the stages of the pipeline
        // pipeline tracker
        if (hactive_pipeline_counter <= 28)
        begin
            hactive_pipeline_counter <= hactive_pipeline_counter + 1;
        end
        // Valid flag (high when result is ready)
        hactive_valid <= (hactive_pipeline_counter == 28);
    end
    else
    begin
        // Reset hactive equivalent calculation
        hactive_div_result        <= 16'b0;
        hactive_width_equivalent  <= 16'b0;

        // Reset hactive period calculation
        hactive_stage1_result     <= 16'b0;
        hactive_stage2_result     <= 16'b0;
        hactive_stage3_result     <= 16'b0;
        //hactive_stage4_result  <= 16'b0;
        hactive_stage5_result     <= 16'b0;

        // Reset pipeline counter and valid flag
        hactive_valid             <= 1'b0;
        hactive_pipeline_counter  <= 7'b0;
    end
end

//==============================================================================
// ** 2) Calculating Horizontal Blanking Period Counter **
//==============================================================================

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) 
    begin
        // Reset hblank equivalent calculation
        hblank_div_result         <= 14'b0;
        hblank_width_equivalent   <= 14'b0;

        // Reset hblank period calculation
        hblank_stage1_result      <= 14'b0;
        hblank_stage2_result      <= 14'b0;
        hblank_stage3_result      <= 14'b0;
        //hblank_stage4_result      <= 14'b0;
        hblank_stage5_result      <= 14'b0;

        // Reset pipeline counter and valid flag
        hblank_valid              <= 1'b0;
        hblank_pipeline_counter   <= 7'b0;
        div_start_hactive         <= 1'b0;
    end 
    else 
    if(saving_flag == 1'b1)
    begin
        // ** 1) hblank equivalent calculation **

        // Stage 1: Division ((HTotal - hwidth) / SPM_Lane_BW)
       hblank_div_result       <= (htotal_sync - hwidth_sync) / spm_lane_count_sync;

        // Stage 2: Multiplication (uses result from previous cycle) (HBlank_Equivalent * SPM_Lane_Count)
     
        hblank_width_equivalent     <= spm_lane_count_sync * hblank_div_result;
      
        // ** 2) hblank period calculation **

        // Stage 1: Multiplication (hblank_width_equivalent * BPC)
        hblank_stage1_result    <= hblank_width_equivalent * bpc;

        // Stage 2: Multiplication with symbols_per_pixel
        hblank_stage2_result    <= hblank_stage1_result * symbols_per_pixel;

        // Stage 3: Multiplication with SPM_Lane_Count
        hblank_stage3_result    <=  hblank_stage2_result / symbol_bit_size ;


        // Stage 4: Division (stage2_result / stage3_result)
        if(hblank_pipeline_counter == 8)
        begin
            div_start_hblank <= 1'b1;
        end
        else
        begin
            div_start_hblank <= 1'b0;
        end

        //hblank_stage4_result    <= (hblank_stage3_result / spm_lane_count_sync) + x_value;

        if(div_done_hblank == 1'b1)
        begin
            hblank_stage5_result    <= hblank_stage4_result + x_value;
        end

        // -----------------------------------------------------------------
        // track the pipeline stages to determine when the result is valid
        //------------------------------------------------------------------
        // pipeline_counter is used to track the stages of the pipeline
        // pipeline tracker 
        if (hblank_pipeline_counter <= 25)
        begin
            hblank_pipeline_counter <= hblank_pipeline_counter + 1;
        end
        // Valid flag (high when result is ready)
        hblank_valid <= (hblank_pipeline_counter == 25);
    end
    else
    begin
        // Reset hblank equivalent calculation
        hblank_div_result         <= 14'b0;
        hblank_width_equivalent   <= 14'b0;

        // Reset hblank period calculation
        hblank_stage1_result      <= 14'b0;
        hblank_stage2_result      <= 14'b0;
        hblank_stage3_result      <= 14'b0;
        //hblank_stage4_result      <= 14'b0;
        hblank_stage5_result      <= 14'b0;

        // Reset pipeline counter and valid flag
        hblank_valid              <= 1'b0;
        hblank_pipeline_counter   <= 7'b0;
    end
end


//==============================================================================
// ** Calculating Vertical Blanking Period Counter **
//==============================================================================

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) 
    begin
        // Reset vertical blanking period calculation
        vblank       <= 0;
        vblank_valid <= 0;
    end 
    else 
    if (saving_flag == 1'b1 )
    begin
        // Calculate vertical blanking period (VBlank = VTotal - VHeight)
        vblank       <= vtotal_sync - vheight_sync;

        // Set valid flag when VBlank is calculated
        vblank_valid <= 1'b1;
    end
    else
    begin
        // Reset vertical blanking period calculation
        vblank       <= 0;
        vblank_valid <= 0;
    end
end

//==============================================================================
// ** calculating valid and stuffing data size in transfer unit **
//==============================================================================

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
        begin
            // Reset all pipeline stages
            stage1_total_bits             <= 0;
            stage2_total_symbols          <= 0;
            stage3_symbols_per_lane       <= 0;
            stage4_symbols_per_TU         <= 0;
            stage5_mult_result            <= 0;
        //    stage6_scaled_valid_symbols   <= 0;
            valid_symbols_integer         <= 0;
            valid_symbols_fraction        <= 0;
            valid_symbols_fraction_scaled <= 0;
            stuffing_pipeline_counter     <= 0;
            stuffing_valid                <= 0;
            first_decimal                 <= 0;
            second_decimal                <= 0;
            rounded_first_decimal         <= 0;
            div_start                     <= 0;
        end 
        else
        if(saving_flag == 1'b1 && ms_stm_bw_saved == 1'b1) 
        begin
            // Stage 1: bits/sec = pixel_clock × bpp
            stage1_total_bits <= ms_stm_bw_sync * bpp;

            // Stage 2: symbols/sec (8b/10b encoding → divide by 8)
            stage2_total_symbols <= stage1_total_bits / symbol_bit_size;

            // Stage 3: symbols per lane = total_symbols / lanes
            stage3_symbols_per_lane <= stage2_total_symbols / spm_lane_count_sync;

            // Stage 4: Fixed-point shift TU size → TU × 2^N
            stage4_symbols_per_TU <= stage3_symbols_per_lane * TU_SIZE ;

            // Stage 5: Multiply TU_shifted × symbols_per_lane
            stage5_mult_result <= stage4_symbols_per_TU << FP_PRECISION;

            // Stage 6: Divide by link symbol rate
            if(stuffing_pipeline_counter == 5)
            begin
                div_start <= 1'b1; // Start the division operation
            end
            else
            begin
                div_start <= 1'b0; // Stop the division operation
            end
            //stage6_scaled_valid_symbols <= stage5_mult_result / spm_lane_bw_sync;

            // Stage 7: Extract integer and fractional parts
            if(div_done == 1'b1)
            begin
                valid_symbols_integer         <= stage6_scaled_valid_symbols >> FP_PRECISION;
                valid_symbols_fraction        <= stage6_scaled_valid_symbols[FP_PRECISION-1:0];
            end
            // Stage 8: Scale fractional part to two decimal points
            valid_symbols_fraction_scaled <= (valid_symbols_fraction * 100) >> FP_PRECISION; // to get two digits after decimal point

            // Stage 9: Extract first and second decimal digits
            first_decimal                 <= valid_symbols_fraction_scaled / FP_PRECISION;
            second_decimal                <= valid_symbols_fraction_scaled - (first_decimal * FP_PRECISION); 
            // calculating up and down transition on integer part
            if (second_decimal == 5 || second_decimal == 6 || second_decimal == 7 || second_decimal == 8 || second_decimal == 9) 
            begin
                rounded_first_decimal <= first_decimal + 1;
            end
            else
            begin
                rounded_first_decimal <= first_decimal;
            end

            // Pipeline valid flag
            if (stuffing_pipeline_counter <= 100)
            begin
            stuffing_pipeline_counter <= stuffing_pipeline_counter + 1;
            end

            stuffing_valid <= (stuffing_pipeline_counter == 100);
        end
        else
        begin       
            // Reset all pipeline stages
            stage1_total_bits             <= 0;
            stage2_total_symbols          <= 0;
            stage3_symbols_per_lane       <= 0;
            stage4_symbols_per_TU         <= 0;
            stage5_mult_result            <= 0;
       //     stage6_scaled_valid_symbols   <= 0;
            valid_symbols_integer         <= 0;
            valid_symbols_fraction        <= 0;
            valid_symbols_fraction_scaled <= 0;
            first_decimal                 <= 0;
            second_decimal                <= 0;
            rounded_first_decimal         <= 0;
            // Reset pipeline counter and valid flag
            stuffing_pipeline_counter     <= 0;
            stuffing_valid                <= 0;

        end
    end


    // calculating the up and down transition on the integer part
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
        begin
            // Reset up and down transition registers
            tu_alternate_up   <= 0;
            tu_alternate_down <= 0;
            alternate_valid   <= 0;
        end 
        else
        if(stuffing_valid == 1'b1) 
        begin
            // Assign up and down transition values based on the first decimal digit
                case (rounded_first_decimal)
                16'd0: 
                begin 
                    tu_alternate_up   <= 4'd0; 
                    tu_alternate_down <= 4'd1; 
                    alternate_valid   <= 1'b1;
                end
                16'd1: 
                begin 
                    tu_alternate_up   <= 4'd1; 
                    tu_alternate_down <= 4'd9;
                    alternate_valid   <= 1'b1; 
                end
                16'd2: 
                begin 
                    tu_alternate_up   <= 4'd1; 
                    tu_alternate_down <= 4'd4; 
                    alternate_valid   <= 1'b1;
                end
                16'd3:
                begin 
                    tu_alternate_up   <= 4'd3; 
                    tu_alternate_down <= 4'd7;
                    alternate_valid   <= 1'b1; 
                end
                16'd4:
                begin 
                    tu_alternate_up   <= 4'd2; 
                    tu_alternate_down <= 4'd3; 
                    alternate_valid   <= 1'b1;
                end
                16'd5: 
                begin 
                    tu_alternate_up   <= 4'd1; 
                    tu_alternate_down <= 4'd1; 
                    alternate_valid   <= 1'b1;
                end
                16'd6: 
                begin 
                    tu_alternate_up   <= 4'd3; 
                    tu_alternate_down <= 4'd2; 
                    alternate_valid   <= 1'b1;
                end
                16'd7:
                begin 
                    tu_alternate_up   <= 4'd7; 
                    tu_alternate_down <= 4'd3; 
                    alternate_valid   <= 1'b1;
                end
                16'd8:
                begin 
                    tu_alternate_up   <= 4'd4; 
                    tu_alternate_down <= 4'd1; 
                    alternate_valid   <= 1'b1;
                end
                16'd9: 
                begin 
                    tu_alternate_up   <= 4'd9; 
                    tu_alternate_down <= 4'd1;
                    alternate_valid   <= 1'b1;
                end
                default: 
                begin 
                    tu_alternate_up   <= 4'd0; 
                    tu_alternate_down <= 4'd0; 
                    alternate_valid   <= 1'b0;
                end
            endcase
        end
        else
        begin
            // Reset up and down transition registers
            alternate_valid   <= 0;
        end
    end




//==============================================================================
// ** Generating Output Signals **
//==============================================================================

// Generate output signals
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) 
    begin
        td_h_active_ctr         <= 0;
        td_h_blank_ctr          <= 0;
        td_v_blank_ctr          <= 0;
        td_v_active_ctr         <= 0;
        td_tu_vld_data_size     <= 0;
        td_tu_stuffed_data_size <= 0;
        td_tu_alternate_down    <= 0;
        td_tu_alternate_up      <= 0;
        td_lane_count           <= 0;
        td_h_total_ctr          <= 0;
        td_hsync_polarity       <= 0;
        td_vsync_polarity       <= 0;
        td_misc0_1              <= 0;
        td_vld_data             <= 1'b0;
    end 
    else 
    begin
        if (alternate_valid == 1'b1) 
        begin
            td_h_active_ctr         <= hactive_stage5_result;
            td_h_blank_ctr          <= hblank_stage5_result;
            td_v_blank_ctr          <= vblank;
            td_v_active_ctr         <= vheight_sync;
            td_tu_vld_data_size     <= valid_symbols_integer;
            td_tu_stuffed_data_size <= TU_SIZE - valid_symbols_integer;
            td_tu_alternate_down    <= tu_alternate_down;
            td_tu_alternate_up      <= tu_alternate_up;
            td_lane_count           <= spm_lane_count_sync - 1'd1;
            td_h_total_ctr          <= hactive_stage5_result + hblank_stage5_result;
            td_hsync_polarity       <= h_sync_polarity;
            td_vsync_polarity       <= v_sync_polarity;
            td_misc0_1              <= misc0_1_sync;
            td_vld_data             <= 1'b1;
        end
        else 
        begin
            td_h_active_ctr         <= 0;
            td_h_blank_ctr          <= 0;
            td_v_blank_ctr          <= 0;
            td_v_active_ctr         <= 0;
            td_tu_vld_data_size     <= 0;
            td_tu_stuffed_data_size <= 0;
            td_tu_alternate_down    <= 0;
            td_tu_alternate_up      <= 0;
            td_lane_count           <= 0;
            td_h_total_ctr          <= 0;
            td_hsync_polarity       <= 0;
            td_vsync_polarity       <= 0;
            td_misc0_1              <= 0;
            td_vld_data             <= 1'b0;
        end
    end
end

//=========================================================
// ** Generating Delayed Signals **
//=========================================================

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
        begin
            hsync_shift_reg         <= 404'b0;
            vsync_shift_reg         <= 404'b0;
            de_shift_reg            <= 404'b0;
            spm_iso_start_shift_reg <= 404'b0;
        end
        else
        begin
            hsync_shift_reg         <= {hsync_shift_reg[402:0], ms_hsync};  // shift left and append new input
            vsync_shift_reg         <= {vsync_shift_reg[402:0], ms_vsync};  // shift left and append new input
            de_shift_reg            <= {de_shift_reg[402:0], ms_de};  // shift left and append new input
            spm_iso_start_shift_reg <= {spm_iso_start_shift_reg[402:0], spm_iso_start};  // shift left and append new input
        end
    end


    assign td_hsync           = hsync_shift_reg[403];  // delayed output
    assign td_vsync           = vsync_shift_reg[403];  // delayed output
    assign td_de              = de_shift_reg[403];  // delayed output
    assign td_scheduler_start = spm_iso_start_shift_reg[403];  // delayed output



    
endmodule