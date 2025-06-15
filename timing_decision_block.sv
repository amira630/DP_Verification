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
    input  wire        clk,                   // clock signal
    input  wire        rst_n,                 // reset signal
    input  wire        ms_de,                 // main stream data enable
    input  wire [9:0]  ms_stm_bw,             // main stream bandwidth
    input  wire        ms_stm_bw_valid,       // main stream bandwidth valid
    input  wire        ms_vsync,              // main stream vertical sync
    input  wire        ms_hsync,              // main stream horizontal sync
    input  wire        spm_iso_start,         // start of isolation mode
    input  wire [2:0]  spm_lane_count,        // number of data lanes
    input  wire [15:0] spm_lane_bw,           // lane bandwidth
    input  wire [15:0] htotal,                // total horizontal pixels
    input  wire [15:0] hwidth,                // active horizontal width
    input  wire [15:0] vtotal,                // total vertical pixels
    input  wire [15:0] vheight,               // active vertical height
    input  wire [7:0]  misc0,                 // provide colormitry information as color depth and pixel format bpc   
    input  wire [7:0]  misc1,                 // additional miscellaneous data
    input  wire        spm_msa_vld,           // main stream attributes valid
    input  wire        h_sync_polarity,       // horizontal sync polarity
    input  wire        v_sync_polarity,       // vertical sync polarity

    //=========================
    // output ports
    //=========================
    output reg         td_vld_data,            // valid data flag 
    output reg         td_scheduler_start,     // scheduler start signal
    output reg  [1:0]  td_lane_count,          // output lane count
    output reg  [13:0] td_h_blank_ctr,         // horizontal blanking counter
    output reg  [15:0] td_h_active_ctr,        // horizontal active counter
    output reg  [9:0]  td_v_blank_ctr,         // vertical blanking counter
    output reg  [12:0] td_v_active_ctr,        // vertical active counter
    output reg  [5:0]  td_tu_vld_data_size,    // timing unit valid data size
    output reg  [5:0]  td_tu_stuffed_data_size,// timing unit stuffed data size
    output wire        td_hsync,               // output horizontal sync
    output wire        td_vsync,               // output vertical sync
    output wire        td_de,                  // output data enable
    output reg  [15:0] td_tu_alternate_up,    // timing unit alternate up
    output reg  [15:0] td_tu_alternate_down,  // timing unit alternate down
    output reg  [15:0] td_h_total_ctr,         // total horizontal counter
    output reg         td_hsync_polarity,      // horizontal sync polarity
    output reg         td_vsync_polarity,      // vertical sync polarity
    output reg  [8:0]  td_misc0_1,             // extracted from spm_msa representing bits per component
    output reg  [15:0] total_stuffing_req_reg
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



    // Define the variables used in the to calculate hwidth module number of lanes 
    reg [15:0] mod_lc_hwidth;        // Modulo result of hwidth_sync and spm_lane_count_sync
    //reg [15:0] div_lc_hwidth;        // Division result of hwidth_sync and spm_lane_count_sync
    //reg [15:0] mul_lc_hwidth;        // Multiplication result of div_lc_hwidth and spm_lane_count_sync

    reg        mod_flag_dn;          // Flag to indicate modulo operation is done
    reg [4:0]  mod_pipeline_counter; // Pipeline counter for tracking stages

    // Hactive equivalent calculation registers
    reg  [15:0] hactive_mod_result;        // Result of division for HActive calculation
    reg  [15:0] hactive_width_equivalent;  // equivalent horizontal width

    // Hactive period calculation registers
    reg  [15:0] hactive_stage1_result;    // Result of hactive_width_equivalent * BPC
    reg  [15:0] hactive_stage2_result;    // Result of stage1 * symbols_per_pixel
    reg  [15:0] hactive_stage3_result;    // Result of symbol_bit_size * SPM_Lane_Count
    reg  [15:0] hactive_stage4_result;    // Result of division (stage2_result / stage3_result)
    reg  [15:0] hactive_stage5_result;    // Final result of division
    reg         hactive_valid;            // Valid flag for hactive calculation
    reg  [6:0]  hactive_pipeline_counter; // Pipeline counter for tracking stages
    
    // Hblank equivalent period calculation registers
    reg  [19:0] hblank_stage1_result;    // Result of (HTotal - HWidth) * SPM_Lane_BW
    reg  [13:0] hblank_width_equivalent; // blankibg period calculation 
    reg         hblank_valid;            // Valid flag for hblank calculation
    reg  [6:0]  hblank_pipeline_counter; // Pipeline counter for tracking stages



    // Horizontal total period calculation registers
    reg [23:0] htotal_calculate_stage1; // Total horizontal period counter
    reg [15:0] htotal_calculate; // Final total horizontal period counter
    reg [6:0] htotal_pipeline_counter; // Pipeline counter for tracking stages
    reg       htotal_valid; // Valid flag for htotal calculation



    // Vertical blanking period calculation registers
    reg  [9:0]  vblank;       // vertical blanking period counter
    reg         vblank_valid; // valid flag for vblank calculation
    

    // Intermediate registers (pipeline stages) for stuffing period calculation
    reg  [31:0] stage1_total_bits;
    reg  [31:0] stage2_total_symbols;
    reg  [31:0] stage3_symbols_per_lane;
    reg  [31:0] stage4_symbols_per_TU;
    reg  [63:0] stage5_mult_result;
    wire [63:0] stage6_scaled_valid_symbols;
    reg  [63:0] stage7_scaled_valid_symbols; // Scaled valid symbols for stuffing period calculation
    reg  [15:0] valid_symbols_integer;
    reg  [15:0] valid_symbols_fraction;
    reg  [15:0] valid_symbols_fraction_scaled;
    reg  [15:0] first_decimal;
    reg  [15:0] second_decimal;
    reg  [15:0] rounded_first_decimal;
    reg  [9:0]  stuffing_pipeline_counter;
    reg         stuffing_valid;



    // Intermediate registers for calculating up and down transitions
    reg [63:0] tu_number ;    // number of transfer units inside active period
    reg [19:0] total_stuffing_req ;//total stuffing required in active period
    reg [19:0] total_stuffing_stage1 ;
    reg [19:0] total_stuffing_stage2 ;
    reg [19:0] tu_alternate_down_stage1 ;
    reg [19:0] tu_alternate_down_stage2 ;
    reg [15:0] tu_alternate_down ; // total number of times to alternate down in active period
    reg [15:0] tu_alternate_up ;  // total number of times to alternate up in active period
    reg [9:0]  alternate_counter; // counter to count number of cycles the calculation for up and down transition is done
    reg        alternate_valid; // valid flag indicating that the up and down transition calculation is done


   // shift registers for hsync, vsync, de and spm_iso_start to delay these signals until th data counters are valid
    reg [403:0] hsync_shift_reg;
    reg [403:0] vsync_shift_reg;
    reg [403:0] de_shift_reg;
    reg [403:0] spm_iso_start_shift_reg;


    
    // synchronized variables to save the inputs from stream and link policy makers
    reg  [2:0]  spm_lane_count_sync;
    reg  [15:0] spm_lane_bw_sync;
    reg         spm_lane_info_saved;    // flag to indicate that lane information is saved
    reg  [15:0] htotal_sync;
    reg  [15:0] hwidth_sync;
    reg  [15:0] vtotal_sync;
    reg  [15:0] vheight_sync;
    reg  [8:0]  misc0_1_sync;
    reg  [9:0]  ms_stm_bw_sync;          // synchronized main stream bandwidth
    reg         ms_stm_bw_saved;         // flag to indicate if main stream bandwidth is saved
    reg         video_params_saved_flag; // flag to indicate video parameters are saved
    reg         all_saved_flag;          // flag to indicate that all data input are being saved 


    //===============================================================================
    // division module for hactive period calculation
    //===============================================================================

    // first division module number 1 for hactive calculation
    reg         div_start1;
    reg         div_done1;

    // second division module number 2 for hactive calculation
    reg         div_start2;
    reg         div_done2;
    

    // division module number 3 for hactive period calculation
    reg         div_start3;
    reg         div_done3;
    wire [15:0] lane_count;


    // fourth division module number 4 for hblank calculation
    reg         div_start4;
    reg         div_done4;
    wire [19:0] ms_stm_bw4;// ms_stm_bw4 is the bandwidth of the stream policy maker in 20 bits so it can be input to the divisor module number 4

   
    // fifth division module number 5 for htotal period calculation
    reg         div_start5;
    reg         div_done5;
    wire [23:0] ms_stm_bw5;  // ms_stm_bw5 is the bandwidth of the stream policy maker in 16 bits so it can be input to the divisor module number 5

    // sixth division module number 6 for stuffing period calculation
    reg         div_start6; // Start signal for the division operation in stage 6
    reg         div_done6;  // Done signal for the division operation in stage 6
    reg [31:0]  symbol_bit_size6; // symbol bit size in bits (8 bits) (8/10 encoding)   

    // seventh division module number 7 for stuffing period calculation
    reg         div_done7; // Done signal for the division operation in stage 7
    reg [31:0]  spm_lane_count7 ; // lane count in 32 bits so it can be input to the divisor module number 7

    // division module number 8 for stuffing period calculation
    reg         div_start8;
    reg         div_done8;
    wire [63:0] spm_bw ;

    // division module number 9 for alterante up and down calculation 
    reg         div_done9; // Done signal for the division operation in stage 9
    reg         div_start9;

    // tenth division module number 10 for alternate up and down calculation
    reg         div_start10; // Start signal for the division operation in stage 10
    reg         div_done10;  // Done signal for the division operation in stage 10
    wire [19:0] ms_stm_bw10; // ms_stm_bw10 is the bandwidth of the stream policy maker in 20 bits so it can be input to the divisor module number 10

    // eleventh division module number 11 for hwidth module lane count calculation
    reg div_start11; // Start signal for the division operation in stage 11
    reg div_done11; // Done signal for the division operation in stage 11



    assign lane_count       = spm_lane_count_sync; // lane count in 16 bits so it can be input to the divisor module 
    assign spm_bw           = spm_lane_bw_sync;    // lane bandwidth in 64 bits so it can be input to the divisor module
    assign ms_stm_bw4       = ms_stm_bw_sync;      //  ms_stm_bw4 is the bandwidth of the stream policy maker in 20 bits so it can be input to the divisor module
    assign ms_stm_bw5       = ms_stm_bw_sync;      // ms_stm_bw5 is the bandwidth of the stream policy maker in 16 bits so it can be input to the divisor module
    assign symbol_bit_size6 = symbol_bit_size;     // symbol bi size in 32 bits so it can be input to the divisor module
    assign spm_lane_count7  = spm_lane_count_sync; // lane count in 32 bits so it can be input to the divisor module number 7
    assign ms_stm_bw10      = ms_stm_bw_sync;      // ms_stm_bw10 is the bandwidth of the stream policy maker in 20 bits so it can be input to the divisor module number 10


 // first Divider module for hactive period calculation
    Divider 
    #
    (
        .WIDTH(16)
    ) 
    divider_hactive_inst1 
    (
        .clk(clk),
        .rst(rst_n),
        .dividend(hwidth_sync),
        .divisor(lane_count),
        .start(div_start1),
        //.quotient(hactive_mod_result),
        .remainder(hactive_mod_result),
        .done(div_done1)
    );
    
    Divider 
    #
    (
        .WIDTH(16)
    ) 
    divider_hactive_inst2 
    (
        .clk(clk),
        .rst(rst_n),
        .dividend(hactive_stage2_result),
        .divisor(symbol_bit_size),
        .start(div_start2),
        .quotient(hactive_stage3_result),
        //.remainder(),
        .done(div_done2)
    );

   

    Divider 
    #
    (
        .WIDTH(16)
    ) 
    divider_hactive_inst3 
    (
        .clk(clk),
        .rst(rst_n),
        .dividend(hactive_stage3_result),
        .divisor(lane_count),
        .start(div_start3),
        .quotient(hactive_stage4_result),
        //.remainder(),
        .done(div_done3)
    );



    Divider
    #
    (
        .WIDTH(20)
    )
    divider_hactive_inst4 
    (
        .clk(clk),
        .rst(rst_n),
        .dividend(hblank_stage1_result),
        .divisor(ms_stm_bw4),
        .start(div_start4),
        .quotient(hblank_width_equivalent),
        //.remainder(),
        .done(div_done4)
    );

 
    Divider
    #
    (
        .WIDTH(24)
    )
    divider_hactive_inst5 
    (
        .clk(clk),
        .rst(rst_n),
        .dividend(htotal_calculate_stage1),
        .divisor(ms_stm_bw5),
        .start(div_start5),
        .quotient(htotal_calculate),
        //.remainder(),
        .done(div_done5)
    );

    Divider
    #
    (
        .WIDTH(32)
    )
    divider_stuffing_inst6 
    (
        .clk(clk),
        .rst(rst_n),
        .dividend(stage1_total_bits),
        .divisor(symbol_bit_size6),
        .start(div_start6),
        .quotient(stage2_total_symbols),
        //.remainder(),
        .done(div_done6)
    );

    Divider
    #
    (
        .WIDTH(32)
    )
    divider_stuffing_inst7 
    (
        .clk(clk),
        .rst(rst_n),
        .dividend(stage2_total_symbols),
        .divisor(spm_lane_count7),
        .start(div_done6),
        .quotient(stage3_symbols_per_lane),
        //.remainder(),
        .done(div_done7)
    );


    Divider
    #
    (
        .WIDTH(64)
    ) 
    divider_stuffing_inst8 
    (
        .clk(clk),
        .rst(rst_n),
        .dividend(stage5_mult_result),
        .divisor(spm_bw),
        .start(div_start8),
        .quotient(stage6_scaled_valid_symbols),
        //.remainder(),
        .done(div_done8)
    ); 

    Divider
    #
    (
        .WIDTH(64)
    )
    divider_stuffing_inst9 
    (
        .clk(clk),
        .rst(rst_n),
        .dividend(stage7_scaled_valid_symbols),
        .divisor(stage6_scaled_valid_symbols),
        .start(div_start9),
        .quotient(tu_number),
        //.remainder(),
        .done(div_done9)
    );

    Divider
    #
    (
        .WIDTH(20)
    )
    divider_alternate_inst10
    (
        .clk(clk),
        .rst(rst_n),
        .dividend(total_stuffing_stage1),
        .divisor(ms_stm_bw10),
        .start(div_start10),
        .quotient(total_stuffing_stage2),
        //.remainder(),
        .done(div_done10)
    );

    Divider 
    #
    (
        .WIDTH(16)
    ) 
    divider_hwidth_inst11 
    (
        .clk(clk),
        .rst(rst_n),
        .dividend(hwidth_sync),
        .divisor(lane_count),
        .start(div_start11),
        //.quotient(div_lc_hwidth),
        .remainder(mod_lc_hwidth),
        .done(div_done11)
    );

    //===============================================================================
    // making sure all data has been saved before processing
    //===============================================================================

    always_comb begin
        all_saved_flag = (video_params_saved_flag && ms_stm_bw_saved && spm_lane_info_saved);
    end

    //=======================================================================================
    // always block for synchronization and saving the inputs (MSA) from stream policy maker
    //=======================================================================================
        always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
        begin
            htotal_sync            <= 16'b0;
            hwidth_sync            <= 16'b0;
            vtotal_sync            <= 16'b0;
            vheight_sync           <= 16'b0;
            misc0_1_sync           <= 9'b0;
            video_params_saved_flag<= 1'b0;
        end 
        else 
        if (spm_msa_vld)
        begin
            htotal_sync            <= htotal;
            hwidth_sync            <= hwidth;
            vtotal_sync            <= vtotal;
            vheight_sync           <= vheight;
            misc0_1_sync           <= {misc1[7:6], misc0[7:1]};
            video_params_saved_flag<= 1'b1;
        end
        else
        if(spm_iso_start == 1'b0)
        begin
            video_params_saved_flag        <= 1'b0;
            htotal_sync                    <= 16'b0;
            hwidth_sync                    <= 16'b0;
            vtotal_sync                    <= 16'b0;
            vheight_sync                   <= 16'b0;
            misc0_1_sync                   <= 9'b0;

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
            ms_stm_bw_sync  <= ms_stm_bw;
            ms_stm_bw_saved <= 1'b1;
        end
        else
        if (spm_iso_start == 1'b0)
        begin
            ms_stm_bw_saved <= 1'b0;
            ms_stm_bw_sync  <= 10'b0;
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
            spm_lane_info_saved <= 1'b0; // flag to indicate that lane information is saved
        end 
        else 
        if (spm_iso_start_pulse) 
        begin
            spm_lane_bw_sync    <= spm_lane_bw;
            spm_lane_count_sync <= spm_lane_count;
            spm_lane_info_saved <= 1'b1; // flag to indicate that lane information is saved
        end
        else 
        if(spm_iso_start == 1'b0)
        begin
            spm_lane_info_saved <= 1'b0; // reset the flag if spm_iso_start is not high
            spm_lane_bw_sync    <= 16'b0;
            spm_lane_count_sync <= 3'b0;
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
    if (all_saved_flag == 1'b1) begin
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
    end 
    else 
    begin
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
        //mod_lc_hwidth        <= 16'b0;
        //div_lc_hwidth        <= 16'b0;
        //mul_lc_hwidth        <= 16'b0;
        mod_flag_dn          <= 1'b0;
        mod_pipeline_counter <= 5'b0;
        div_start11          <= 1'b0; // Reset division start signal
    end 
    else 
    if (all_saved_flag == 1'b1) // every time we use data input we check if its saved at first or not
    begin
        //div_lc_hwidth       <= hwidth_sync / spm_lane_count_sync;
        if(mod_pipeline_counter == 1)
        begin
            div_start11         <= 1'b1 ; // Start the division operation
        end
        else
        begin
            div_start11 <= 1'b0; // Stop the division operation
        end
        if (mod_pipeline_counter <= 25)
        begin
            mod_pipeline_counter <= mod_pipeline_counter + 1;
        end
        // Valid flag (high when result is ready)
        mod_flag_dn         <= (mod_pipeline_counter == 25);
    end 
    else 
    if (spm_iso_start == 1'b0) 
    begin
        //mod_lc_hwidth        <= 16'b0;
        //div_lc_hwidth        <= 16'b0;
        //mul_lc_hwidth        <= 16'b0;
        mod_pipeline_counter <= 5'b0;
    end
end

// calculate x_value based on bpc
// x_value is used to adjust the final result of hactive  calculation
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) 
    begin
        x_value <= 0;
    end 
    else 
    if (mod_flag_dn == 1'b1) 
    begin
        if (mod_lc_hwidth == 0) 
        begin
            x_value <= 0;
        end 
        else 
        begin
            case (bpc)
                16'd8:    x_value <= 3;
                16'd16:   x_value <= 6;
                default:  x_value <= 0;
            endcase
        end
    end 
    else
    if (spm_iso_start == 1'b0)
    begin
        x_value <= 0;
    end
end
//==============================================================================
// ** 1) Calculating Horizontal Active Period Counter **
//==============================================================================

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) 
    begin
        // Reset hblank equivalent calculation
        //hactive_mod_result        <= 16'b0;
        hactive_width_equivalent  <= 16'b0;

        // Reset hactive period calculation
        hactive_stage1_result     <= 16'b0;
        hactive_stage2_result     <= 16'b0;
        //hactive_stage3_result     <= 16'b0;
        //hactive_stage4_result     <= 16'b0;
        hactive_stage5_result     <= 16'b0;

        // Reset pipeline counter and valid flag
        hactive_valid             <= 1'b0;
        hactive_pipeline_counter  <= 7'b0;
        div_start3                <= 1'b0;
        div_start1                <= 1'b0; // Reset division start signal
        div_start2                <= 1'b0; // Reset division start signal
    end 
    else 
    if(all_saved_flag == 1'b1)    
    begin
        // ** 1) hactive equivalent calculation **

        // Stage 1: Division (HWidth / SPM_Lane_count)
        //hactive_mod_result       <= hwidth_sync / spm_lane_count_sync; 
        if(hactive_pipeline_counter == 0)
        begin
            div_start1 <= 1'b1; // Start the division operation
        end
        else
        begin
            div_start1 <= 1'b0; // Stop the division operation
        end

        if(div_done1 == 1'b1)
        begin
            // Stage 2: Multiplication (uses result from previous cycle) Hactive_width_Equivalent
            hactive_width_equivalent <= hwidth_sync - hactive_mod_result;
        end
        // ** 2) hactive period calculation **

        // Stage 1: 
        hactive_stage1_result   <= hactive_width_equivalent ;

        // Stage 2: Multiplication with number of bits per pixel
        hactive_stage2_result   <= hactive_stage1_result * bpp;

        // Stage 3: division (hactive_stage2_result / symbol_bit_size)
        //hactive_stage3_result   <= hactive_stage2_result / symbol_bit_size ;
        if(hactive_pipeline_counter == 25)
        begin
            div_start2 <= 1'b1; // Start the division operation
        end
        else
        begin
            div_start2 <= 1'b0; // Stop the division operation
        end
        

        if(hactive_pipeline_counter == 50)
        begin
            div_start3 <= 1'b1;
        end
        else
        begin
            div_start3 <= 1'b0;
        end
        // Stage 4: Division (hactive_stage3_result / SPM_Lane_Count)
        if(div_done3 == 1'b1)
        begin
            hactive_stage5_result <= hactive_stage4_result + x_value;
        end

        // -----------------------------------------------------------------
        // track the pipeline stages to determine when the result is valid
        //------------------------------------------------------------------
        // hactive_pipeline_counter is used to track the stages of the pipeline
        // pipeline tracker
        if (hactive_pipeline_counter <= 80)
        begin
            hactive_pipeline_counter <= hactive_pipeline_counter + 1;
        end
        // Valid flag (high when result is ready)
        hactive_valid <= (hactive_pipeline_counter == 80);
    end
    else
    begin
        // Reset hactive equivalent calculation
        //hactive_mod_result        <= 16'b0;
        hactive_width_equivalent  <= 16'b0;

        // Reset hactive period calculation
        hactive_stage1_result     <= 16'b0;
        hactive_stage2_result     <= 16'b0;
        //hactive_stage3_result     <= 16'b0;
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
        //hblank_width_equivalent   <= 0;

        // Reset hblank period calculation
        hblank_stage1_result      <= 0;

        // Reset pipeline counter and valid flag
        hblank_valid              <= 0;
        hblank_pipeline_counter   <= 0;
        div_start4                <= 0; // Reset division start signal
    end 
    else 
    if(all_saved_flag == 1'b1)
    begin
        // ** 1) hblank equivalent calculation **

        // Stage 1: 
        hblank_stage1_result <= (htotal_sync - hwidth_sync) * spm_lane_bw_sync;
        // Stage 2: 
        if(hblank_pipeline_counter == 5)
        begin
            div_start4 <= 1'b1; // Start the division operation
        end
        else
        begin
            div_start4 <= 1'b0; // Stop the division operation
        end
        //hblank_width_equivalent <= hblank_stage1_result / ms_stm_bw_sync;
        // -----------------------------------------------------------------
        // track the pipeline stages to determine when the result is valid
        //------------------------------------------------------------------
        // pipeline_counter is used to track the stages of the pipeline
        // pipeline tracker 
        if (hblank_pipeline_counter <= 10)
        begin
            hblank_pipeline_counter <= hblank_pipeline_counter + 1;
        end
        // Valid flag (high when result is ready)
        hblank_valid <= (div_done4 == 1'b1);
    end
    else
    begin
        // Reset hblank equivalent calculation
        //hblank_width_equivalent   <= 0;
        hblank_stage1_result      <= 0;
        // Reset pipeline counter and valid flag
        hblank_valid              <= 0;
        hblank_pipeline_counter   <= 0;
        div_start4                <= 0; // Reset division start signal
    end
end

//==============================================================================
// ** 3) Calculating total Horizontal Period (Blank + Active)**
//==============================================================================


always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) 
    begin
        // Reset horizontal total counter
        //htotal_calculate <= 16'b0;
        htotal_calculate_stage1  <= 24'b0;
        div_start5               <= 1'b0; // Reset division start signal
        htotal_pipeline_counter  <= 0; // Reset pipeline counter
        htotal_valid             <= 0; // Reset valid flag
    end 
    else 
    if (all_saved_flag == 1'b1) 
    begin
        // Calculate total horizontal period (HTotal = HActive + HBlank)
        htotal_calculate_stage1 <=  htotal_sync * spm_lane_bw_sync;
        //htotal_calculate        <=  htotal_calculate_stage1 / ms_stm_bw_sync ;
        if (htotal_pipeline_counter == 5)
        begin
            div_start5 <= 1'b1; // Start the division operation
        end
        else
        begin
            div_start5 <= 1'b0; // Stop the division operation
        end

        if(htotal_pipeline_counter < 20)
        begin
            htotal_pipeline_counter <= htotal_pipeline_counter + 1;
        end
        // Valid flag (high when result is ready)
        htotal_valid <= ( div_done5 == 1'b1);

    end
    else
    begin
        // Reset horizontal total counter
        htotal_calculate_stage1  <= 24'b0;
        div_start5               <= 1'b0; // Reset division start signal
        htotal_pipeline_counter  <= 0; // Reset pipeline counter
        htotal_valid             <= 0; // Reset valid flag
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
    if (all_saved_flag == 1'b1)
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
            //stage2_total_symbols          <= 0;
            //stage3_symbols_per_lane       <= 0;
            stage4_symbols_per_TU         <= 0;
            stage5_mult_result            <= 0;
            //stage6_scaled_valid_symbols   <= 0;
            valid_symbols_integer         <= 0;
            valid_symbols_fraction        <= 0;
            //valid_symbols_fraction_scaled <= 0;
            stuffing_pipeline_counter     <= 0;
            stuffing_valid                <= 0;
            //first_decimal                 <= 0;
            //second_decimal                <= 0;
            //rounded_first_decimal         <= 0;
            div_start8                    <= 0;
        end 
        else
        if(all_saved_flag == 1'b1) 
        begin
            // Stage 1: bits/sec = pixel_clock × bpp
            stage1_total_bits <= ms_stm_bw_sync * bpp;

            // Stage 2: symbols/sec (8b/10b encoding → divide by 8)
            //stage2_total_symbols <= stage1_total_bits / symbol_bit_size;
            if(stuffing_pipeline_counter == 4)
            begin
                div_start6 <= 1'b1; // Start the division operation
            end
            else
            begin
                div_start6 <= 1'b0; // Stop the division operation
            end
            
            // Stage 3: symbols per lane = total_symbols / lanes
            
            //stage3_symbols_per_lane <= stage2_total_symbols / spm_lane_count_sync;

            // Stage 4: Fixed-point shift TU size → TU × 2^N
            if(div_done7 == 1'b1)
            begin
                stage4_symbols_per_TU <= stage3_symbols_per_lane * TU_SIZE ;
            end

            // Stage 5: Multiply TU_shifted × symbols_per_lane
            stage5_mult_result <= stage4_symbols_per_TU << FP_PRECISION;

            // Stage 6: Divide by link symbol rate
            if(stuffing_pipeline_counter == 80)
            begin
                div_start8 <= 1'b1; // Start the division operation
            end
            else
            begin
                div_start8 <= 1'b0; // Stop the division operation
            end
            //stage6_scaled_valid_symbols <= stage5_mult_result / spm_lane_bw_sync;

            // Stage 7: Extract integer and fractional parts
            if(div_done8 == 1'b1)
            begin
                valid_symbols_integer         <= stage6_scaled_valid_symbols >> FP_PRECISION;
                valid_symbols_fraction        <= stage6_scaled_valid_symbols[FP_PRECISION-1:0];
            end
            // Stage 8: Scale fractional part to two decimal points
            //valid_symbols_fraction_scaled <= (valid_symbols_fraction * 100) >> FP_PRECISION; // to get two digits after decimal point

            // Stage 9: Extract first and second decimal digits
            //first_decimal                 <= valid_symbols_fraction_scaled / FP_PRECISION;
            //second_decimal                <= valid_symbols_fraction_scaled - (first_decimal * FP_PRECISION); 
            // calculating up and down transition on integer part
            /*if (second_decimal == 5 || second_decimal == 6 || second_decimal == 7 || second_decimal == 8 || second_decimal == 9) 
            begin
                rounded_first_decimal <= first_decimal + 1;
            end
            else
            begin
                rounded_first_decimal <= first_decimal;
            end*/

            // Pipeline valid flag
            if (stuffing_pipeline_counter <= 200)
            begin
                stuffing_pipeline_counter <= stuffing_pipeline_counter + 1;
            end
            // Valid flag (high when result is ready)
            if(stuffing_pipeline_counter == 200)
            begin
                stuffing_valid <= 1'b1; // Set valid flag when pipeline is ready
            end
        end
        else
        begin       
            // Reset all pipeline stages
            stage1_total_bits             <= 0;
            //stage2_total_symbols          <= 0;
            //stage3_symbols_per_lane       <= 0;
            stage4_symbols_per_TU         <= 0;
            stage5_mult_result            <= 0;
            //stage6_scaled_valid_symbols   <= 0;
            valid_symbols_integer         <= 0;
            valid_symbols_fraction        <= 0;
            //valid_symbols_fraction_scaled <= 0;
            //first_decimal                 <= 0;
            //second_decimal                <= 0;
            //rounded_first_decimal         <= 0;
            // Reset pipeline counter and valid flag
            stuffing_pipeline_counter     <= 0;
            stuffing_valid                <= 0;
            div_start8                    <= 0; // Reset division start signal
        end
    end



//===========================================================================
// calculating the up and down transition on the integer part
//===========================================================================

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
        begin
            // Reset up and down transition registers
            tu_alternate_up             <= 0;
            tu_alternate_down           <= 0;
            alternate_valid             <= 0;
            alternate_counter           <= 0;
            tu_alternate_down_stage1    <= 0;
            tu_alternate_down_stage2    <= 0;
            total_stuffing_req          <= 0;
            total_stuffing_stage1       <= 0;
            //total_stuffing_stage2       <= 0;
            //tu_number                   <= 0; 
            stage7_scaled_valid_symbols <= 0;
            div_start9                  <= 0; // Reset division start signal
        end 
        else
        if(stuffing_valid == 1'b1) 
        begin
            stage7_scaled_valid_symbols <= hactive_stage5_result << FP_PRECISION ; // Shift left to scale by 2^N
            //tu_number                   <= (stage7_scaled_valid_symbols / stage6_scaled_valid_symbols)  ;
            // Calculate total stuffing required
            total_stuffing_stage1       <= hwidth_sync * spm_lane_bw_sync ;
            //total_stuffing_stage2     <= total_stuffing_stage1 / (ms_stm_bw_sync) ;

            if(alternate_counter == 6'd3)
            begin
                div_start9  <= 1'b1; // Start the division operation
                div_start10 <= 1'b1; // Start the division operation
            end
            else
            begin
                div_start9  <= 1'b0; // Stop the division operation
                div_start10 <= 1'b0; // Stop the division operation
            end
            if(div_done10 == 1'b1)
            begin
                total_stuffing_req    <= total_stuffing_stage2 - hactive_stage5_result ;
            end
            // total stuffing required % transfer unit number 
            if(tu_number != 0)
            begin
                tu_alternate_down_stage1           <= total_stuffing_req + tu_number  ; 
                tu_alternate_down_stage2           <= (TU_SIZE - valid_symbols_integer)*tu_number;
                tu_alternate_down                  <=  tu_alternate_down_stage1 - tu_alternate_down_stage2 ; // calculating alternating down number of times 
                // calculating alternating up number of times 
                tu_alternate_up                    <= tu_number - tu_alternate_down ;
            end
            else    
            begin
                tu_alternate_down           <= 0;
                tu_alternate_up             <= 0;
                tu_alternate_down_stage1    <= 0;
                tu_alternate_down_stage2    <= 0;
            end
            
            // Valid flag for alternate up and down transition
            if (alternate_counter <= 75)
            begin
                alternate_counter <= alternate_counter + 1;
            end
            alternate_valid <= (alternate_counter == 75); // Set valid flag when pipeline is ready
        end
        else
        begin
            // Reset up and down transition registers
            tu_alternate_up             <= 0;
            tu_alternate_down           <= 0;
            alternate_valid             <= 0;
            alternate_counter           <= 0;
            tu_alternate_down_stage1    <= 0;
            tu_alternate_down_stage2    <= 0;
            total_stuffing_req          <= 0;
            total_stuffing_stage1       <= 0;
            //total_stuffing_stage2       <= 0;
            //tu_number                   <= 0; 
            stage7_scaled_valid_symbols <= 0;
            div_start9                  <= 0; // Reset division start signal
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
        total_stuffing_req_reg  <= 0;
    end 
    else 
    begin
        if (alternate_valid == 1'b1) 
        begin
            td_h_active_ctr         <= hactive_stage5_result;
            td_h_blank_ctr          <= hblank_width_equivalent+1;
            td_v_blank_ctr          <= vblank;
            td_v_active_ctr         <= vheight_sync;
            td_tu_vld_data_size     <= valid_symbols_integer;
            td_tu_stuffed_data_size <= TU_SIZE - valid_symbols_integer;
            td_tu_alternate_down    <= tu_alternate_down;
            td_tu_alternate_up      <= tu_alternate_up;
            td_lane_count           <= spm_lane_count_sync - 1'd1;
            td_h_total_ctr          <= htotal_calculate;
            //td_h_total_ctr          <= 16'd17820;
            // Assigning hsync and vsync polarities
            td_hsync_polarity       <= h_sync_polarity;
            td_vsync_polarity       <= v_sync_polarity;
            td_misc0_1              <= misc0_1_sync;
            td_vld_data             <= 1'b1;
            total_stuffing_req_reg  <= total_stuffing_req;
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
            total_stuffing_req_reg  <= 0;
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