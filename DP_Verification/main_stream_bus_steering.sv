//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Block Name:  Main Stream Bus Steering
//
// Author:      Mohamed Alaa
//
// Discription: The block is responsible for mapping the main video pixel data to match the selected video format, 
//              ensuring proper alignment with the color space, bit depth, and transmission configuration. It 
//              processes the pixel data based on the chosen format, whether RGB or YCbCr 4:4:4, and the specified 
//              bits per component (8-ppc or 16-ppc). Additionally, it utilizes the provided number of active lanes—
//              determined by the link training process—to distribute the video data accordingly for transmission. 
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module main_stream_bus_steering 
(
  input wire        clk,
  input wire        rst_n,
  input wire        sched_steering_en,
  input wire        td_vld_data,    
  input wire [1:0]  td_lane_count,
  input wire [8:0]  td_misc0_1,
  input wire [95:0] fifo_pixel_data,
  input wire        rd_data_valid,
  input wire        fifo_almost_empty,

  output reg        mbs_empty_regs,
  output reg [7:0]  main_steered_lane0,
  output reg [7:0]  main_steered_lane1,
  output reg [7:0]  main_steered_lane2,
  output reg [7:0]  main_steered_lane3
);

  // Symbol definitions
  localparam [7:0] IDLE_SYMBOL = 8'b00000000;
  localparam [8:0] RGB_8BPC    = 9'b000010000;                  
  localparam [8:0] RGB_16BPC   = 9'b001000000;                   
  localparam [8:0] YCBCR_8BPC  = 9'b000010110;    
  localparam [8:0] YCBCR_16BPC = 9'b001000110;              

  // Internal Regs
  reg  [1:0]  lane_count_reg;
  reg  [8:0]  misc_reg;
  reg  [7:0]  empty_regs;
//  reg         empty_reg_file;
  reg  [47:0] reg_file [7:0];              // Register File: 8 registers, each 48-bit

  reg         write_index_inc;

reg test;
reg test2;

reg tt;
reg tf;
reg tw;

  reg         read_enable;
  reg  [2:0]  read_index;
  reg  [1:0]  read_counter;

  // Pulse generation registers
  wire       [3:0] empty_count;
  reg        [2:0] pulse_counter;
  reg        [2:0] pulse_counter_comb;  
  reg        [2:0] next_pulse_counter;
  reg        [2:0] old_pulse_counter;
  reg              eigth_regs_empty;
  reg              four_regs_empty;
  reg              two_regs_empty;
 // reg              one_reg_empty;
  reg  [3:0] write_index;
  reg  [3:0] write_index_stored;  

  reg  [7:0]  main_steered_lane0_comb;
  reg  [7:0]  main_steered_lane1_comb;
  reg  [7:0]  main_steered_lane2_comb;
  reg  [7:0]  main_steered_lane3_comb;

  // State definitions (Gray Code)  
typedef enum reg [6:0]
{
  IDLE_STATE                               = 7'b0000000, // IDLE

  // 8-bpc (4 Lanes)
  FIRST_LEVEL_RED_8BPC_4LANES              = 7'b0000001,
  FIRST_LEVEL_GREAN_8BPC_4LANES            = 7'b0000011,
  FIRST_LEVEL_BLUE_8BPC_4LANES             = 7'b0000010,
  SECOND_LEVEL_RED_8BPC_4LANES             = 7'b0000110,
  SECOND_LEVEL_GREAN_8BPC_4LANES           = 7'b0000111,
  SECOND_LEVEL_BLUE_8BPC_4LANES            = 7'b0000101,

  // 16-bpc (4 Lanes)
  FIRST_LEVEL_RED1_16BPC_4LANES            = 7'b0000100,
  FIRST_LEVEL_RED2_16BPC_4LANES            = 7'b0001100,
  FIRST_LEVEL_GREAN1_16BPC_4LANES          = 7'b0001101,
  FIRST_LEVEL_GREAN2_16BPC_4LANES          = 7'b0001111,
  FIRST_LEVEL_BLUE1_16BPC_4LANES           = 7'b0001110,
  FIRST_LEVEL_BLUE2_16BPC_4LANES           = 7'b0001010,
  SECOND_LEVEL_RED1_16BPC_4LANES           = 7'b0001011,
  SECOND_LEVEL_RED2_16BPC_4LANES           = 7'b0001001,
  SECOND_LEVEL_GREAN1_16BPC_4LANES         = 7'b0001000,
  SECOND_LEVEL_GREAN2_16BPC_4LANES         = 7'b0011000,
  SECOND_LEVEL_BLUE1_16BPC_4LANES          = 7'b0011001,
  SECOND_LEVEL_BLUE2_16BPC_4LANES          = 7'b0011011,

  // 8-bpc (2 Lanes)
  FIRST_LEVEL_RED_8BPC_2LANES_REG1_2       = 7'b0011010,
  FIRST_LEVEL_GREAN_8BPC_2LANES_REG1_2     = 7'b0011110,
  FIRST_LEVEL_BLUE_8BPC_2LANES_REG1_2      = 7'b0011111,
  FIRST_LEVEL_RED_8BPC_2LANES_REG3_4       = 7'b0011101,
  FIRST_LEVEL_GREAN_8BPC_2LANES_REG3_4     = 7'b0011100,
  FIRST_LEVEL_BLUE_8BPC_2LANES_REG3_4      = 7'b0010100,
  SECOND_LEVEL_RED_8BPC_2LANES_REG5_6      = 7'b0010101,
  SECOND_LEVEL_GREAN_8BPC_2LANES_REG5_6    = 7'b0010111,
  SECOND_LEVEL_BLUE_8BPC_2LANES_REG5_6     = 7'b0010110,
  SECOND_LEVEL_RED_8BPC_2LANES_REG7_8      = 7'b0010010,
  SECOND_LEVEL_GREAN_8BPC_2LANES_REG7_8    = 7'b0010011,
  SECOND_LEVEL_BLUE_8BPC_2LANES_REG7_8     = 7'b0010001,

  // 16-bpc (2 Lanes)
  FIRST_LEVEL_RED1_16BPC_2LANES_REG1_2     = 7'b0010000,
  FIRST_LEVEL_RED2_16BPC_2LANES_REG1_2     = 7'b0110000,
  FIRST_LEVEL_GREAN1_16BPC_2LANES_REG1_2   = 7'b0110001,
  FIRST_LEVEL_GREAN2_16BPC_2LANES_REG1_2   = 7'b0110011,
  FIRST_LEVEL_BLUE1_16BPC_2LANES_REG1_2    = 7'b0110010,
  FIRST_LEVEL_BLUE2_16BPC_2LANES_REG1_2    = 7'b0110110,
  FIRST_LEVEL_RED1_16BPC_2LANES_REG3_4     = 7'b0110111,
  FIRST_LEVEL_RED2_16BPC_2LANES_REG3_4     = 7'b0110101,
  FIRST_LEVEL_GREAN1_16BPC_2LANES_REG3_4   = 7'b0110100,
  FIRST_LEVEL_GREAN2_16BPC_2LANES_REG3_4   = 7'b0111100,
  FIRST_LEVEL_BLUE1_16BPC_2LANES_REG3_4    = 7'b0111101,
  FIRST_LEVEL_BLUE2_16BPC_2LANES_REG3_4    = 7'b0111111,
  SECOND_LEVEL_RED1_16BPC_2LANES_REG5_6    = 7'b0111110,
  SECOND_LEVEL_RED2_16BPC_2LANES_REG5_6    = 7'b0111010,
  SECOND_LEVEL_GREAN1_16BPC_2LANES_REG5_6  = 7'b0111011,
  SECOND_LEVEL_GREAN2_16BPC_2LANES_REG5_6  = 7'b0111001,
  SECOND_LEVEL_BLUE1_16BPC_2LANES_REG5_6   = 7'b0111000,
  SECOND_LEVEL_BLUE2_16BPC_2LANES_REG5_6   = 7'b0101000,
  SECOND_LEVEL_RED1_16BPC_2LANES_REG7_8    = 7'b0101001,
  SECOND_LEVEL_RED2_16BPC_2LANES_REG7_8    = 7'b0101011,
  SECOND_LEVEL_GREAN1_16BPC_2LANES_REG7_8  = 7'b0101010,
  SECOND_LEVEL_GREAN2_16BPC_2LANES_REG7_8  = 7'b0101110,
  SECOND_LEVEL_BLUE1_16BPC_2LANES_REG7_8   = 7'b0101111,
  SECOND_LEVEL_BLUE2_16BPC_2LANES_REG7_8   = 7'b0101101,

  // 8-bpc (1 Lane)
  FIRST_LEVEL_RED_8BPC_1LANE_REG1          = 7'b0101100,
  FIRST_LEVEL_GREAN_8BPC_1LANE_REG1        = 7'b0100100,
  FIRST_LEVEL_BLUE_8BPC_1LANE_REG1         = 7'b0100101,
  FIRST_LEVEL_RED_8BPC_1LANE_REG2          = 7'b0100111,
  FIRST_LEVEL_GREAN_8BPC_1LANE_REG2        = 7'b0100110,
  FIRST_LEVEL_BLUE_8BPC_1LANE_REG2         = 7'b0100010,
  FIRST_LEVEL_RED_8BPC_1LANE_REG3          = 7'b0100011,
  FIRST_LEVEL_GREAN_8BPC_1LANE_REG3        = 7'b0100001,
  FIRST_LEVEL_BLUE_8BPC_1LANE_REG3         = 7'b0100000,
  FIRST_LEVEL_RED_8BPC_1LANE_REG4          = 7'b1100000,
  FIRST_LEVEL_GREAN_8BPC_1LANE_REG4        = 7'b1100001,
  FIRST_LEVEL_BLUE_8BPC_1LANE_REG4         = 7'b1100011,
  SECOND_LEVEL_RED_8BPC_1LANE_REG5         = 7'b1100010,
  SECOND_LEVEL_GREAN_8BPC_1LANE_REG5       = 7'b1100110,
  SECOND_LEVEL_BLUE_8BPC_1LANE_REG5        = 7'b1100111,
  SECOND_LEVEL_RED_8BPC_1LANE_REG6         = 7'b1100101,
  SECOND_LEVEL_GREAN_8BPC_1LANE_REG6       = 7'b1100100,
  SECOND_LEVEL_BLUE_8BPC_1LANE_REG6        = 7'b1101100,
  SECOND_LEVEL_RED_8BPC_1LANE_REG7         = 7'b1101101,
  SECOND_LEVEL_GREAN_8BPC_1LANE_REG7       = 7'b1101111,
  SECOND_LEVEL_BLUE_8BPC_1LANE_REG7        = 7'b1101110,
  SECOND_LEVEL_RED_8BPC_1LANE_REG8         = 7'b1101010,
  SECOND_LEVEL_GREAN_8BPC_1LANE_REG8       = 7'b1101011,
  SECOND_LEVEL_BLUE_8BPC_1LANE_REG8        = 7'b1101001,

  // 16-bpc (1 Lane)
  FIRST_LEVEL_RED1_16BPC_1LANE_REG1        = 7'b1101000,
  FIRST_LEVEL_RED2_16BPC_1LANE_REG1        = 7'b1111000,
  FIRST_LEVEL_GREAN1_16BPC_1LANE_REG1      = 7'b1111001,
  FIRST_LEVEL_GREAN2_16BPC_1LANE_REG1      = 7'b1111011,
  FIRST_LEVEL_BLUE1_16BPC_1LANE_REG1       = 7'b1111010,
  FIRST_LEVEL_BLUE2_16BPC_1LANE_REG1       = 7'b1111110,
  FIRST_LEVEL_RED1_16BPC_1LANE_REG2        = 7'b1111111,
  FIRST_LEVEL_RED2_16BPC_1LANE_REG2        = 7'b1111101,
  FIRST_LEVEL_GREAN1_16BPC_1LANE_REG2      = 7'b1111100,
  FIRST_LEVEL_GREAN2_16BPC_1LANE_REG2      = 7'b1110100,
  FIRST_LEVEL_BLUE1_16BPC_1LANE_REG2       = 7'b1110101,
  FIRST_LEVEL_BLUE2_16BPC_1LANE_REG2       = 7'b1110111,
  FIRST_LEVEL_RED1_16BPC_1LANE_REG3        = 7'b1110110,
  FIRST_LEVEL_RED2_16BPC_1LANE_REG3        = 7'b1110010,
  FIRST_LEVEL_GREAN1_16BPC_1LANE_REG3      = 7'b1110011,
  FIRST_LEVEL_GREAN2_16BPC_1LANE_REG3      = 7'b1110001,
  FIRST_LEVEL_BLUE1_16BPC_1LANE_REG3       = 7'b1110000,
  FIRST_LEVEL_BLUE2_16BPC_1LANE_REG3       = 7'b1010000,
  FIRST_LEVEL_RED1_16BPC_1LANE_REG4        = 7'b1010001,
  FIRST_LEVEL_RED2_16BPC_1LANE_REG4        = 7'b1010011,
  FIRST_LEVEL_GREAN1_16BPC_1LANE_REG4      = 7'b1010010,
  FIRST_LEVEL_GREAN2_16BPC_1LANE_REG4      = 7'b1010110,
  FIRST_LEVEL_BLUE1_16BPC_1LANE_REG4       = 7'b1010101,
  FIRST_LEVEL_BLUE2_16BPC_1LANE_REG4       = 7'b1010100,
  SECOND_LEVEL_RED1_16BPC_1LANE_REG5       = 7'b1011100,
  SECOND_LEVEL_RED2_16BPC_1LANE_REG5       = 7'b1011101,
  SECOND_LEVEL_GREAN1_16BPC_1LANE_REG5     = 7'b1011111,
  SECOND_LEVEL_GREAN2_16BPC_1LANE_REG5     = 7'b1011110,
  SECOND_LEVEL_BLUE1_16BPC_1LANE_REG5      = 7'b1011010,
  SECOND_LEVEL_BLUE2_16BPC_1LANE_REG5      = 7'b1011011,
  SECOND_LEVEL_RED1_16BPC_1LANE_REG6       = 7'b1011001,
  SECOND_LEVEL_RED2_16BPC_1LANE_REG6       = 7'b1011000,
  SECOND_LEVEL_GREAN1_16BPC_1LANE_REG6     = 7'b1001000,
  SECOND_LEVEL_GREAN2_16BPC_1LANE_REG6     = 7'b1001001,
  SECOND_LEVEL_BLUE1_16BPC_1LANE_REG6      = 7'b1001011,
  SECOND_LEVEL_BLUE2_16BPC_1LANE_REG6      = 7'b1001010,
  SECOND_LEVEL_RED1_16BPC_1LANE_REG7       = 7'b1001110,
  SECOND_LEVEL_RED2_16BPC_1LANE_REG7       = 7'b1001111,
  SECOND_LEVEL_GREAN1_16BPC_1LANE_REG7     = 7'b1001101,
  SECOND_LEVEL_GREAN2_16BPC_1LANE_REG7     = 7'b1001100,
  SECOND_LEVEL_BLUE1_16BPC_1LANE_REG7      = 7'b1000100,
  SECOND_LEVEL_BLUE2_16BPC_1LANE_REG7      = 7'b1000101,
  SECOND_LEVEL_RED1_16BPC_1LANE_REG8       = 7'b1000111,
  SECOND_LEVEL_RED2_16BPC_1LANE_REG8       = 7'b1000110,
  SECOND_LEVEL_GREAN1_16BPC_1LANE_REG8     = 7'b1000010,
  SECOND_LEVEL_GREAN2_16BPC_1LANE_REG8     = 7'b1000011,
  SECOND_LEVEL_BLUE1_16BPC_1LANE_REG8      = 7'b1000001,
  SECOND_LEVEL_BLUE2_16BPC_1LANE_REG8      = 7'b1000000

} state_t;

  state_t current_state, next_state;

  // State transiton & update bs_complete flag 
  always @(posedge clk or negedge rst_n) 
   begin
    if (!rst_n) 
     begin
      current_state <= IDLE_STATE;
     end 
    else 
     begin
      current_state <= next_state;      
     end
    end
    
  // Next state logic
  always @(*)
   begin
    case (current_state)
    IDLE_STATE:
          begin
            if ((sched_steering_en) && (empty_count != 4'd8)) 
            begin
              if ((lane_count_reg == 2'b11) && ((misc_reg == RGB_8BPC) || (misc_reg == YCBCR_8BPC))) 
              begin
                next_state = FIRST_LEVEL_RED_8BPC_4LANES;
              end 
              else if ((lane_count_reg == 2'b11) && ((misc_reg == RGB_16BPC) || (misc_reg == YCBCR_16BPC)))
              begin
                next_state = FIRST_LEVEL_RED1_16BPC_4LANES;
              end
              else if ((lane_count_reg == 2'b01) && ((misc_reg == RGB_8BPC) || (misc_reg == YCBCR_8BPC)))
              begin
                next_state = FIRST_LEVEL_RED_8BPC_2LANES_REG1_2;
              end
              else if ((lane_count_reg == 2'b01) && ((misc_reg == RGB_16BPC) || (misc_reg == YCBCR_16BPC)))
              begin
                next_state = FIRST_LEVEL_RED1_16BPC_2LANES_REG1_2;
              end
              else if ((lane_count_reg == 2'b00) && ((misc_reg == RGB_8BPC) || (misc_reg == YCBCR_8BPC)))
              begin
                next_state = FIRST_LEVEL_RED_8BPC_1LANE_REG1;
              end
              else if ((lane_count_reg == 2'b00) && ((misc_reg == RGB_16BPC) || (misc_reg == YCBCR_16BPC)))
              begin
                next_state = FIRST_LEVEL_RED1_16BPC_1LANE_REG1;
              end
              else
              begin
                next_state = IDLE_STATE;
              end
            end
            else
            begin
                next_state = IDLE_STATE;    
            end
          end    
    // 8-bpc (4 Lanes) - (6 states) 
    FIRST_LEVEL_RED_8BPC_4LANES: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = FIRST_LEVEL_GREAN_8BPC_4LANES; 
            end
            else
            begin
                next_state = FIRST_LEVEL_RED_8BPC_4LANES; 
            end        
          end
    FIRST_LEVEL_GREAN_8BPC_4LANES: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = FIRST_LEVEL_BLUE_8BPC_4LANES; 
            end
            else
            begin
                next_state = FIRST_LEVEL_GREAN_8BPC_4LANES; 
            end          
          end
    FIRST_LEVEL_BLUE_8BPC_4LANES: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = SECOND_LEVEL_RED_8BPC_4LANES;       
            end 
            else 
            begin
                next_state = FIRST_LEVEL_BLUE_8BPC_4LANES;         
            end
          end      
    SECOND_LEVEL_RED_8BPC_4LANES: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = SECOND_LEVEL_GREAN_8BPC_4LANES;       
            end 
            else 
            begin
                next_state = SECOND_LEVEL_RED_8BPC_4LANES;         
            end
          end
    SECOND_LEVEL_GREAN_8BPC_4LANES: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = SECOND_LEVEL_BLUE_8BPC_4LANES;       
            end 
            else 
            begin
                next_state = SECOND_LEVEL_GREAN_8BPC_4LANES;        
            end
          end
    SECOND_LEVEL_BLUE_8BPC_4LANES: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = FIRST_LEVEL_RED_8BPC_4LANES;    
            end 
            else 
            begin
                next_state = SECOND_LEVEL_BLUE_8BPC_4LANES; 
            end
          end    
    // 16-bpc (4 Lanes) - (12 states)      
    FIRST_LEVEL_RED1_16BPC_4LANES: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = FIRST_LEVEL_RED2_16BPC_4LANES;      
            end 
            else 
            begin
                next_state = FIRST_LEVEL_RED1_16BPC_4LANES;       
            end
          end
    FIRST_LEVEL_RED2_16BPC_4LANES: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = FIRST_LEVEL_GREAN1_16BPC_4LANES;      
            end 
            else 
            begin
                next_state = FIRST_LEVEL_RED2_16BPC_4LANES;         
            end
          end
    FIRST_LEVEL_GREAN1_16BPC_4LANES: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = FIRST_LEVEL_GREAN2_16BPC_4LANES;      
            end 
            else 
            begin
                next_state = FIRST_LEVEL_GREAN1_16BPC_4LANES;         
            end
          end
    FIRST_LEVEL_GREAN2_16BPC_4LANES: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = FIRST_LEVEL_BLUE1_16BPC_4LANES;      
            end 
            else 
            begin
                next_state = FIRST_LEVEL_GREAN2_16BPC_4LANES;         
            end
          end
    FIRST_LEVEL_BLUE1_16BPC_4LANES: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = FIRST_LEVEL_BLUE2_16BPC_4LANES;      
            end 
            else 
            begin
                next_state = FIRST_LEVEL_BLUE1_16BPC_4LANES;         
            end
          end
    FIRST_LEVEL_BLUE2_16BPC_4LANES: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = SECOND_LEVEL_RED1_16BPC_4LANES;      
            end 
            else 
            begin
                next_state = FIRST_LEVEL_BLUE2_16BPC_4LANES;         
            end
          end
    SECOND_LEVEL_RED1_16BPC_4LANES: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = SECOND_LEVEL_RED2_16BPC_4LANES;      
            end 
            else 
            begin
                next_state = SECOND_LEVEL_RED1_16BPC_4LANES;       
            end
          end
    SECOND_LEVEL_RED2_16BPC_4LANES: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = SECOND_LEVEL_GREAN1_16BPC_4LANES;      
            end 
            else 
            begin
                next_state = SECOND_LEVEL_RED2_16BPC_4LANES;         
            end
          end
    SECOND_LEVEL_GREAN1_16BPC_4LANES: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = SECOND_LEVEL_GREAN2_16BPC_4LANES;      
            end 
            else 
            begin
                next_state = SECOND_LEVEL_GREAN1_16BPC_4LANES;         
            end
          end
    SECOND_LEVEL_GREAN2_16BPC_4LANES: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = SECOND_LEVEL_BLUE1_16BPC_4LANES;      
            end 
            else 
            begin
                next_state = SECOND_LEVEL_GREAN2_16BPC_4LANES;         
            end
          end
    SECOND_LEVEL_BLUE1_16BPC_4LANES: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = SECOND_LEVEL_BLUE2_16BPC_4LANES;      
            end 
            else 
            begin
                next_state = SECOND_LEVEL_BLUE1_16BPC_4LANES;         
            end
          end
    SECOND_LEVEL_BLUE2_16BPC_4LANES: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = FIRST_LEVEL_RED1_16BPC_4LANES;      
            end 
            else 
            begin
                next_state = SECOND_LEVEL_BLUE2_16BPC_4LANES;         
            end
          end
    // 8-bpc (2 Lanes) - (12 states)
    FIRST_LEVEL_RED_8BPC_2LANES_REG1_2: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = FIRST_LEVEL_GREAN_8BPC_2LANES_REG1_2;      
            end 
            else 
            begin
                next_state = FIRST_LEVEL_RED_8BPC_2LANES_REG1_2;       
            end
          end
    FIRST_LEVEL_GREAN_8BPC_2LANES_REG1_2: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = FIRST_LEVEL_BLUE_8BPC_2LANES_REG1_2;      
            end 
            else 
            begin
                next_state = FIRST_LEVEL_GREAN_8BPC_2LANES_REG1_2;         
            end
          end
    FIRST_LEVEL_BLUE_8BPC_2LANES_REG1_2: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = FIRST_LEVEL_RED_8BPC_2LANES_REG3_4;      
            end 
            else 
            begin
                next_state = FIRST_LEVEL_BLUE_8BPC_2LANES_REG1_2;         
            end
          end
    FIRST_LEVEL_RED_8BPC_2LANES_REG3_4: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = FIRST_LEVEL_GREAN_8BPC_2LANES_REG3_4;      
            end 
            else 
            begin
                next_state = FIRST_LEVEL_RED_8BPC_2LANES_REG3_4;         
            end
          end
    FIRST_LEVEL_GREAN_8BPC_2LANES_REG3_4: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = FIRST_LEVEL_BLUE_8BPC_2LANES_REG3_4;      
            end 
            else 
            begin
                next_state = FIRST_LEVEL_GREAN_8BPC_2LANES_REG3_4;         
            end
          end
    FIRST_LEVEL_BLUE_8BPC_2LANES_REG3_4: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = SECOND_LEVEL_RED_8BPC_2LANES_REG5_6;      
            end 
            else 
            begin
                next_state = FIRST_LEVEL_BLUE_8BPC_2LANES_REG3_4;         
            end
          end
    SECOND_LEVEL_RED_8BPC_2LANES_REG5_6: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = SECOND_LEVEL_GREAN_8BPC_2LANES_REG5_6;      
            end 
            else 
            begin
                next_state = SECOND_LEVEL_RED_8BPC_2LANES_REG5_6;       
            end
          end
    SECOND_LEVEL_GREAN_8BPC_2LANES_REG5_6: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = SECOND_LEVEL_BLUE_8BPC_2LANES_REG5_6;      
            end 
            else 
            begin
                next_state = SECOND_LEVEL_GREAN_8BPC_2LANES_REG5_6;         
            end
          end
    SECOND_LEVEL_BLUE_8BPC_2LANES_REG5_6: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = SECOND_LEVEL_RED_8BPC_2LANES_REG7_8;      
            end 
            else 
            begin
                next_state = SECOND_LEVEL_BLUE_8BPC_2LANES_REG5_6;         
            end
          end
    SECOND_LEVEL_RED_8BPC_2LANES_REG7_8: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = SECOND_LEVEL_GREAN_8BPC_2LANES_REG7_8;      
            end 
            else 
            begin
                next_state = SECOND_LEVEL_RED_8BPC_2LANES_REG7_8;         
            end
          end
    SECOND_LEVEL_GREAN_8BPC_2LANES_REG7_8: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = SECOND_LEVEL_BLUE_8BPC_2LANES_REG7_8;      
            end 
            else 
            begin
                next_state = SECOND_LEVEL_GREAN_8BPC_2LANES_REG7_8;         
            end
          end
    SECOND_LEVEL_BLUE_8BPC_2LANES_REG7_8: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = FIRST_LEVEL_RED_8BPC_2LANES_REG1_2;      
            end 
            else 
            begin
                next_state = SECOND_LEVEL_BLUE_8BPC_2LANES_REG7_8;         
            end
          end
    // 16-bpc (2 Lanes) - (24 states)
    FIRST_LEVEL_RED1_16BPC_2LANES_REG1_2: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = FIRST_LEVEL_RED2_16BPC_2LANES_REG1_2;      
            end 
            else 
            begin
                next_state = FIRST_LEVEL_RED1_16BPC_2LANES_REG1_2;       
            end
          end
    FIRST_LEVEL_RED2_16BPC_2LANES_REG1_2: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = FIRST_LEVEL_GREAN1_16BPC_2LANES_REG1_2;      
            end 
            else 
            begin
                next_state = FIRST_LEVEL_RED2_16BPC_2LANES_REG1_2;       
            end
          end
    FIRST_LEVEL_GREAN1_16BPC_2LANES_REG1_2: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = FIRST_LEVEL_GREAN2_16BPC_2LANES_REG1_2;      
            end 
            else 
            begin
                next_state = FIRST_LEVEL_GREAN1_16BPC_2LANES_REG1_2;         
            end
          end
    FIRST_LEVEL_GREAN2_16BPC_2LANES_REG1_2: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = FIRST_LEVEL_BLUE1_16BPC_2LANES_REG1_2;      
            end 
            else 
            begin
                next_state = FIRST_LEVEL_GREAN2_16BPC_2LANES_REG1_2;         
            end
          end
    FIRST_LEVEL_BLUE1_16BPC_2LANES_REG1_2: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = FIRST_LEVEL_BLUE2_16BPC_2LANES_REG1_2;      
            end 
            else 
            begin
                next_state = FIRST_LEVEL_BLUE1_16BPC_2LANES_REG1_2;         
            end
          end
    FIRST_LEVEL_BLUE2_16BPC_2LANES_REG1_2: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = FIRST_LEVEL_RED1_16BPC_2LANES_REG3_4;      
            end 
            else 
            begin
                next_state = FIRST_LEVEL_BLUE2_16BPC_2LANES_REG1_2;         
            end
          end
    FIRST_LEVEL_RED1_16BPC_2LANES_REG3_4: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = FIRST_LEVEL_RED2_16BPC_2LANES_REG3_4;      
            end 
            else 
            begin
                next_state = FIRST_LEVEL_RED1_16BPC_2LANES_REG3_4;         
            end
          end
    FIRST_LEVEL_RED2_16BPC_2LANES_REG3_4: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = FIRST_LEVEL_GREAN1_16BPC_2LANES_REG3_4;      
            end 
            else 
            begin
                next_state = FIRST_LEVEL_RED2_16BPC_2LANES_REG3_4;         
            end
          end
    FIRST_LEVEL_GREAN1_16BPC_2LANES_REG3_4: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = FIRST_LEVEL_GREAN2_16BPC_2LANES_REG3_4;      
            end 
            else 
            begin
                next_state = FIRST_LEVEL_GREAN1_16BPC_2LANES_REG3_4;         
            end
          end
    FIRST_LEVEL_GREAN2_16BPC_2LANES_REG3_4: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = FIRST_LEVEL_BLUE1_16BPC_2LANES_REG3_4;      
            end 
            else 
            begin
                next_state = FIRST_LEVEL_GREAN2_16BPC_2LANES_REG3_4;         
            end
          end
    FIRST_LEVEL_BLUE1_16BPC_2LANES_REG3_4: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = FIRST_LEVEL_BLUE2_16BPC_2LANES_REG3_4;      
            end 
            else 
            begin
                next_state = FIRST_LEVEL_BLUE1_16BPC_2LANES_REG3_4;         
            end
          end
    FIRST_LEVEL_BLUE2_16BPC_2LANES_REG3_4: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = SECOND_LEVEL_RED1_16BPC_2LANES_REG5_6;      
            end 
            else 
            begin
                next_state = FIRST_LEVEL_BLUE2_16BPC_2LANES_REG3_4;         
            end
          end
    SECOND_LEVEL_RED1_16BPC_2LANES_REG5_6: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = SECOND_LEVEL_RED2_16BPC_2LANES_REG5_6;      
            end 
            else 
            begin
                next_state = SECOND_LEVEL_RED1_16BPC_2LANES_REG5_6;       
            end
          end
    SECOND_LEVEL_RED2_16BPC_2LANES_REG5_6: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = SECOND_LEVEL_GREAN1_16BPC_2LANES_REG5_6;      
            end 
            else 
            begin
                next_state = SECOND_LEVEL_RED2_16BPC_2LANES_REG5_6;       
            end
          end
    SECOND_LEVEL_GREAN1_16BPC_2LANES_REG5_6: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = SECOND_LEVEL_GREAN2_16BPC_2LANES_REG5_6;      
            end 
            else 
            begin
                next_state = SECOND_LEVEL_GREAN1_16BPC_2LANES_REG5_6;         
            end
          end
    SECOND_LEVEL_GREAN2_16BPC_2LANES_REG5_6: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = SECOND_LEVEL_BLUE1_16BPC_2LANES_REG5_6;      
            end 
            else 
            begin
                next_state = SECOND_LEVEL_GREAN2_16BPC_2LANES_REG5_6;         
            end
          end
    SECOND_LEVEL_BLUE1_16BPC_2LANES_REG5_6: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = SECOND_LEVEL_BLUE2_16BPC_2LANES_REG5_6;      
            end 
            else 
            begin
                next_state = SECOND_LEVEL_BLUE1_16BPC_2LANES_REG5_6;         
            end
          end
    SECOND_LEVEL_BLUE2_16BPC_2LANES_REG5_6: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = SECOND_LEVEL_RED1_16BPC_2LANES_REG7_8;      
            end 
            else 
            begin
                next_state = SECOND_LEVEL_BLUE2_16BPC_2LANES_REG5_6;         
            end
          end
    SECOND_LEVEL_RED1_16BPC_2LANES_REG7_8: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = SECOND_LEVEL_RED2_16BPC_2LANES_REG7_8;      
            end 
            else 
            begin
                next_state = SECOND_LEVEL_RED1_16BPC_2LANES_REG7_8;         
            end
          end
    SECOND_LEVEL_RED2_16BPC_2LANES_REG7_8: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = SECOND_LEVEL_GREAN1_16BPC_2LANES_REG7_8;      
            end 
            else 
            begin
                next_state = SECOND_LEVEL_RED2_16BPC_2LANES_REG7_8;         
            end
          end
    SECOND_LEVEL_GREAN1_16BPC_2LANES_REG7_8: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = SECOND_LEVEL_GREAN2_16BPC_2LANES_REG7_8;      
            end 
            else 
            begin
                next_state = SECOND_LEVEL_GREAN1_16BPC_2LANES_REG7_8;         
            end
          end
    SECOND_LEVEL_GREAN2_16BPC_2LANES_REG7_8: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = SECOND_LEVEL_BLUE1_16BPC_2LANES_REG7_8;      
            end 
            else 
            begin
                next_state = SECOND_LEVEL_GREAN2_16BPC_2LANES_REG7_8;         
            end
          end
    SECOND_LEVEL_BLUE1_16BPC_2LANES_REG7_8: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = SECOND_LEVEL_BLUE2_16BPC_2LANES_REG7_8;      
            end 
            else 
            begin
                next_state = SECOND_LEVEL_BLUE1_16BPC_2LANES_REG7_8;         
            end
          end
    SECOND_LEVEL_BLUE2_16BPC_2LANES_REG7_8: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = FIRST_LEVEL_RED1_16BPC_2LANES_REG1_2;      
            end 
            else 
            begin
                next_state = SECOND_LEVEL_BLUE2_16BPC_2LANES_REG7_8;         
            end
          end
    // 8-bpc (1 Lane) - (24 states)
    FIRST_LEVEL_RED_8BPC_1LANE_REG1: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = FIRST_LEVEL_GREAN_8BPC_1LANE_REG1;      
            end 
            else 
            begin
                next_state = FIRST_LEVEL_RED_8BPC_1LANE_REG1;       
            end
          end
    FIRST_LEVEL_GREAN_8BPC_1LANE_REG1: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = FIRST_LEVEL_BLUE_8BPC_1LANE_REG1;      
            end 
            else 
            begin
                next_state = FIRST_LEVEL_GREAN_8BPC_1LANE_REG1;       
            end
          end
    FIRST_LEVEL_BLUE_8BPC_1LANE_REG1: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = FIRST_LEVEL_RED_8BPC_1LANE_REG2;      
            end 
            else 
            begin
                next_state = FIRST_LEVEL_BLUE_8BPC_1LANE_REG1;         
            end
          end
    FIRST_LEVEL_RED_8BPC_1LANE_REG2: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = FIRST_LEVEL_GREAN_8BPC_1LANE_REG2;      
            end 
            else 
            begin
                next_state = FIRST_LEVEL_RED_8BPC_1LANE_REG2;         
            end
          end
    FIRST_LEVEL_GREAN_8BPC_1LANE_REG2: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = FIRST_LEVEL_BLUE_8BPC_1LANE_REG2;      
            end 
            else 
            begin
                next_state = FIRST_LEVEL_GREAN_8BPC_1LANE_REG2;         
            end
          end
    FIRST_LEVEL_BLUE_8BPC_1LANE_REG2: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = FIRST_LEVEL_RED_8BPC_1LANE_REG3;      
            end 
            else 
            begin
                next_state = FIRST_LEVEL_BLUE_8BPC_1LANE_REG2;         
            end
          end
    FIRST_LEVEL_RED_8BPC_1LANE_REG3: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = FIRST_LEVEL_GREAN_8BPC_1LANE_REG3;      
            end 
            else 
            begin
                next_state = FIRST_LEVEL_RED_8BPC_1LANE_REG3;         
            end
          end
    FIRST_LEVEL_GREAN_8BPC_1LANE_REG3: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = FIRST_LEVEL_BLUE_8BPC_1LANE_REG3;      
            end 
            else 
            begin
                next_state = FIRST_LEVEL_GREAN_8BPC_1LANE_REG3;         
            end
          end
    FIRST_LEVEL_BLUE_8BPC_1LANE_REG3: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = FIRST_LEVEL_RED_8BPC_1LANE_REG4;      
            end 
            else 
            begin
                next_state = FIRST_LEVEL_BLUE_8BPC_1LANE_REG3;         
            end
          end
    FIRST_LEVEL_RED_8BPC_1LANE_REG4: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = FIRST_LEVEL_GREAN_8BPC_1LANE_REG4;      
            end 
            else 
            begin
                next_state = FIRST_LEVEL_RED_8BPC_1LANE_REG4;         
            end
          end
    FIRST_LEVEL_GREAN_8BPC_1LANE_REG4: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = FIRST_LEVEL_BLUE_8BPC_1LANE_REG4;      
            end 
            else 
            begin
                next_state = FIRST_LEVEL_GREAN_8BPC_1LANE_REG4;         
            end
          end
    FIRST_LEVEL_BLUE_8BPC_1LANE_REG4: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = SECOND_LEVEL_RED_8BPC_1LANE_REG5;      
            end 
            else 
            begin
                next_state = FIRST_LEVEL_BLUE_8BPC_1LANE_REG4;         
            end
          end
    SECOND_LEVEL_RED_8BPC_1LANE_REG5: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = SECOND_LEVEL_GREAN_8BPC_1LANE_REG5;      
            end 
            else 
            begin
                next_state = SECOND_LEVEL_RED_8BPC_1LANE_REG5;       
            end
          end
    SECOND_LEVEL_GREAN_8BPC_1LANE_REG5: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = SECOND_LEVEL_BLUE_8BPC_1LANE_REG5;      
            end 
            else 
            begin
                next_state = SECOND_LEVEL_GREAN_8BPC_1LANE_REG5;       
            end
          end
    SECOND_LEVEL_BLUE_8BPC_1LANE_REG5: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = SECOND_LEVEL_RED_8BPC_1LANE_REG6;      
            end 
            else 
            begin
                next_state = SECOND_LEVEL_BLUE_8BPC_1LANE_REG5;         
            end
          end
    SECOND_LEVEL_RED_8BPC_1LANE_REG6: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = SECOND_LEVEL_GREAN_8BPC_1LANE_REG6;      
            end 
            else 
            begin
                next_state = SECOND_LEVEL_RED_8BPC_1LANE_REG6;         
            end
          end
    SECOND_LEVEL_GREAN_8BPC_1LANE_REG6: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = SECOND_LEVEL_BLUE_8BPC_1LANE_REG6;      
            end 
            else 
            begin
                next_state = SECOND_LEVEL_GREAN_8BPC_1LANE_REG6;         
            end
          end
    SECOND_LEVEL_BLUE_8BPC_1LANE_REG6: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = SECOND_LEVEL_RED_8BPC_1LANE_REG7;      
            end 
            else 
            begin
                next_state = SECOND_LEVEL_BLUE_8BPC_1LANE_REG6;         
            end
          end
    SECOND_LEVEL_RED_8BPC_1LANE_REG7: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = SECOND_LEVEL_GREAN_8BPC_1LANE_REG7;      
            end 
            else 
            begin
                next_state = SECOND_LEVEL_RED_8BPC_1LANE_REG7;         
            end
          end
    SECOND_LEVEL_GREAN_8BPC_1LANE_REG7: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = SECOND_LEVEL_BLUE_8BPC_1LANE_REG7;      
            end 
            else 
            begin
                next_state = SECOND_LEVEL_GREAN_8BPC_1LANE_REG7;         
            end
          end
    SECOND_LEVEL_BLUE_8BPC_1LANE_REG7: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = SECOND_LEVEL_RED_8BPC_1LANE_REG8;      
            end 
            else 
            begin
                next_state = SECOND_LEVEL_BLUE_8BPC_1LANE_REG7;         
            end
          end
    SECOND_LEVEL_RED_8BPC_1LANE_REG8: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = SECOND_LEVEL_GREAN_8BPC_1LANE_REG8;      
            end 
            else 
            begin
                next_state = SECOND_LEVEL_RED_8BPC_1LANE_REG8;         
            end
          end
    SECOND_LEVEL_GREAN_8BPC_1LANE_REG8: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = SECOND_LEVEL_BLUE_8BPC_1LANE_REG8;      
            end 
            else 
            begin
                next_state = SECOND_LEVEL_GREAN_8BPC_1LANE_REG8;         
            end
          end
    SECOND_LEVEL_BLUE_8BPC_1LANE_REG8: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = FIRST_LEVEL_RED_8BPC_1LANE_REG1;      
            end 
            else 
            begin
                next_state = SECOND_LEVEL_BLUE_8BPC_1LANE_REG8;         
            end
          end
    // 16-bpc (1 Lanes) - (48 states) 
    FIRST_LEVEL_RED1_16BPC_1LANE_REG1: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = FIRST_LEVEL_RED2_16BPC_1LANE_REG1;      
            end 
            else 
            begin
                next_state = FIRST_LEVEL_RED1_16BPC_1LANE_REG1;       
            end
          end
    FIRST_LEVEL_RED2_16BPC_1LANE_REG1: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = FIRST_LEVEL_GREAN1_16BPC_1LANE_REG1;      
            end 
            else 
            begin
                next_state = FIRST_LEVEL_RED2_16BPC_1LANE_REG1;       
            end
          end
    FIRST_LEVEL_GREAN1_16BPC_1LANE_REG1: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = FIRST_LEVEL_GREAN2_16BPC_1LANE_REG1;      
            end 
            else 
            begin
                next_state = FIRST_LEVEL_GREAN1_16BPC_1LANE_REG1;       
            end
          end
    FIRST_LEVEL_GREAN2_16BPC_1LANE_REG1: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = FIRST_LEVEL_BLUE1_16BPC_1LANE_REG1;      
            end 
            else 
            begin
                next_state = FIRST_LEVEL_GREAN2_16BPC_1LANE_REG1;       
            end
          end
    FIRST_LEVEL_BLUE1_16BPC_1LANE_REG1: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = FIRST_LEVEL_BLUE2_16BPC_1LANE_REG1;      
            end 
            else 
            begin
                next_state = FIRST_LEVEL_BLUE1_16BPC_1LANE_REG1;         
            end
          end
    FIRST_LEVEL_BLUE2_16BPC_1LANE_REG1: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = FIRST_LEVEL_RED1_16BPC_1LANE_REG2;      
            end 
            else 
            begin
                next_state = FIRST_LEVEL_BLUE2_16BPC_1LANE_REG1;         
            end
          end
    FIRST_LEVEL_RED1_16BPC_1LANE_REG2: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = FIRST_LEVEL_RED2_16BPC_1LANE_REG2;      
            end 
            else 
            begin
                next_state = FIRST_LEVEL_RED1_16BPC_1LANE_REG2;         
            end
          end
    FIRST_LEVEL_RED2_16BPC_1LANE_REG2: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = FIRST_LEVEL_GREAN1_16BPC_1LANE_REG2;      
            end 
            else 
            begin
                next_state = FIRST_LEVEL_RED2_16BPC_1LANE_REG2;         
            end
          end
    FIRST_LEVEL_GREAN1_16BPC_1LANE_REG2: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = FIRST_LEVEL_GREAN2_16BPC_1LANE_REG2;      
            end 
            else 
            begin
                next_state = FIRST_LEVEL_GREAN1_16BPC_1LANE_REG2;         
            end
          end
    FIRST_LEVEL_GREAN2_16BPC_1LANE_REG2: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = FIRST_LEVEL_BLUE1_16BPC_1LANE_REG2;      
            end 
            else 
            begin
                next_state = FIRST_LEVEL_GREAN2_16BPC_1LANE_REG2;         
            end
          end
    FIRST_LEVEL_BLUE1_16BPC_1LANE_REG2: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = FIRST_LEVEL_BLUE2_16BPC_1LANE_REG2;      
            end 
            else 
            begin
                next_state = FIRST_LEVEL_BLUE1_16BPC_1LANE_REG2;         
            end
          end
    FIRST_LEVEL_BLUE2_16BPC_1LANE_REG2: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = FIRST_LEVEL_RED1_16BPC_1LANE_REG3;      
            end 
            else 
            begin
                next_state = FIRST_LEVEL_BLUE2_16BPC_1LANE_REG2;         
            end
          end
    FIRST_LEVEL_RED1_16BPC_1LANE_REG3: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = FIRST_LEVEL_RED2_16BPC_1LANE_REG3;      
            end 
            else 
            begin
                next_state = FIRST_LEVEL_RED1_16BPC_1LANE_REG3;         
            end
          end
    FIRST_LEVEL_RED2_16BPC_1LANE_REG3: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = FIRST_LEVEL_GREAN1_16BPC_1LANE_REG3;      
            end 
            else 
            begin
                next_state = FIRST_LEVEL_RED2_16BPC_1LANE_REG3;         
            end
          end
    FIRST_LEVEL_GREAN1_16BPC_1LANE_REG3: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = FIRST_LEVEL_GREAN2_16BPC_1LANE_REG3;      
            end 
            else 
            begin
                next_state = FIRST_LEVEL_GREAN1_16BPC_1LANE_REG3;         
            end
          end
    FIRST_LEVEL_GREAN2_16BPC_1LANE_REG3: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = FIRST_LEVEL_BLUE1_16BPC_1LANE_REG3;      
            end 
            else 
            begin
                next_state = FIRST_LEVEL_GREAN2_16BPC_1LANE_REG3;         
            end
          end
    FIRST_LEVEL_BLUE1_16BPC_1LANE_REG3: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = FIRST_LEVEL_BLUE2_16BPC_1LANE_REG3;      
            end 
            else 
            begin
                next_state = FIRST_LEVEL_BLUE1_16BPC_1LANE_REG3;         
            end
          end
    FIRST_LEVEL_BLUE2_16BPC_1LANE_REG3: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = FIRST_LEVEL_RED1_16BPC_1LANE_REG4;      
            end 
            else 
            begin
                next_state = FIRST_LEVEL_BLUE2_16BPC_1LANE_REG3;         
            end
          end
    FIRST_LEVEL_RED1_16BPC_1LANE_REG4: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = FIRST_LEVEL_RED2_16BPC_1LANE_REG4;      
            end 
            else 
            begin
                next_state = FIRST_LEVEL_RED1_16BPC_1LANE_REG4;         
            end
          end
    FIRST_LEVEL_RED2_16BPC_1LANE_REG4: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = FIRST_LEVEL_GREAN1_16BPC_1LANE_REG4;      
            end 
            else 
            begin
                next_state = FIRST_LEVEL_RED2_16BPC_1LANE_REG4;         
            end
          end
    FIRST_LEVEL_GREAN1_16BPC_1LANE_REG4: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = FIRST_LEVEL_GREAN2_16BPC_1LANE_REG4;      
            end 
            else 
            begin
                next_state = FIRST_LEVEL_GREAN1_16BPC_1LANE_REG4;         
            end
          end
    FIRST_LEVEL_GREAN2_16BPC_1LANE_REG4: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = FIRST_LEVEL_BLUE1_16BPC_1LANE_REG4;      
            end 
            else 
            begin
                next_state = FIRST_LEVEL_GREAN2_16BPC_1LANE_REG4;         
            end
          end
    FIRST_LEVEL_BLUE1_16BPC_1LANE_REG4: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = FIRST_LEVEL_BLUE2_16BPC_1LANE_REG4;      
            end 
            else 
            begin
                next_state = FIRST_LEVEL_BLUE1_16BPC_1LANE_REG4;         
            end
          end
    FIRST_LEVEL_BLUE2_16BPC_1LANE_REG4: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = SECOND_LEVEL_RED1_16BPC_1LANE_REG5;      
            end 
            else 
            begin
                next_state = FIRST_LEVEL_BLUE2_16BPC_1LANE_REG4;         
            end
          end
    SECOND_LEVEL_RED1_16BPC_1LANE_REG5: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = SECOND_LEVEL_RED2_16BPC_1LANE_REG5;      
            end 
            else 
            begin
                next_state = SECOND_LEVEL_RED1_16BPC_1LANE_REG5;       
            end
          end
    SECOND_LEVEL_RED2_16BPC_1LANE_REG5: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = SECOND_LEVEL_GREAN1_16BPC_1LANE_REG5;      
            end 
            else 
            begin
                next_state = SECOND_LEVEL_RED2_16BPC_1LANE_REG5;       
            end
          end
    SECOND_LEVEL_GREAN1_16BPC_1LANE_REG5: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = SECOND_LEVEL_GREAN2_16BPC_1LANE_REG5;      
            end 
            else 
            begin
                next_state = SECOND_LEVEL_GREAN1_16BPC_1LANE_REG5;       
            end
          end
    SECOND_LEVEL_GREAN2_16BPC_1LANE_REG5: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = SECOND_LEVEL_BLUE1_16BPC_1LANE_REG5;      
            end 
            else 
            begin
                next_state = SECOND_LEVEL_GREAN2_16BPC_1LANE_REG5;       
            end
          end
    SECOND_LEVEL_BLUE1_16BPC_1LANE_REG5: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = SECOND_LEVEL_BLUE2_16BPC_1LANE_REG5;      
            end 
            else 
            begin
                next_state = SECOND_LEVEL_BLUE1_16BPC_1LANE_REG5;         
            end
          end
    SECOND_LEVEL_BLUE2_16BPC_1LANE_REG5: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = SECOND_LEVEL_RED1_16BPC_1LANE_REG6;      
            end 
            else 
            begin
                next_state = SECOND_LEVEL_BLUE2_16BPC_1LANE_REG5;         
            end
          end
    SECOND_LEVEL_RED1_16BPC_1LANE_REG6: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = SECOND_LEVEL_RED2_16BPC_1LANE_REG6;      
            end 
            else 
            begin
                next_state = SECOND_LEVEL_RED1_16BPC_1LANE_REG6;         
            end
          end
    SECOND_LEVEL_RED2_16BPC_1LANE_REG6: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = SECOND_LEVEL_GREAN1_16BPC_1LANE_REG6;      
            end 
            else 
            begin
                next_state = SECOND_LEVEL_RED2_16BPC_1LANE_REG6;         
            end
          end
    SECOND_LEVEL_GREAN1_16BPC_1LANE_REG6: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = SECOND_LEVEL_GREAN2_16BPC_1LANE_REG6;      
            end 
            else 
            begin
                next_state = SECOND_LEVEL_GREAN1_16BPC_1LANE_REG6;         
            end
          end
    SECOND_LEVEL_GREAN2_16BPC_1LANE_REG6: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = SECOND_LEVEL_BLUE1_16BPC_1LANE_REG6;      
            end 
            else 
            begin
                next_state = SECOND_LEVEL_GREAN2_16BPC_1LANE_REG6;         
            end
          end
    SECOND_LEVEL_BLUE1_16BPC_1LANE_REG6: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = SECOND_LEVEL_BLUE2_16BPC_1LANE_REG6;      
            end 
            else 
            begin
                next_state = SECOND_LEVEL_BLUE1_16BPC_1LANE_REG6;         
            end
          end
    SECOND_LEVEL_BLUE2_16BPC_1LANE_REG6: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = SECOND_LEVEL_RED1_16BPC_1LANE_REG7;      
            end 
            else 
            begin
                next_state = SECOND_LEVEL_BLUE2_16BPC_1LANE_REG6;         
            end
          end
    SECOND_LEVEL_RED1_16BPC_1LANE_REG7: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = SECOND_LEVEL_RED2_16BPC_1LANE_REG7;      
            end 
            else 
            begin
                next_state = SECOND_LEVEL_RED1_16BPC_1LANE_REG7;         
            end
          end
    SECOND_LEVEL_RED2_16BPC_1LANE_REG7: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = SECOND_LEVEL_GREAN1_16BPC_1LANE_REG7;      
            end 
            else 
            begin
                next_state = SECOND_LEVEL_RED2_16BPC_1LANE_REG7;         
            end
          end
    SECOND_LEVEL_GREAN1_16BPC_1LANE_REG7: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = SECOND_LEVEL_GREAN2_16BPC_1LANE_REG7;      
            end 
            else 
            begin
                next_state = SECOND_LEVEL_GREAN1_16BPC_1LANE_REG7;         
            end
          end
    SECOND_LEVEL_GREAN2_16BPC_1LANE_REG7: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = SECOND_LEVEL_BLUE1_16BPC_1LANE_REG7;      
            end 
            else 
            begin
                next_state = SECOND_LEVEL_GREAN2_16BPC_1LANE_REG7;         
            end
          end
    SECOND_LEVEL_BLUE1_16BPC_1LANE_REG7: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = SECOND_LEVEL_BLUE2_16BPC_1LANE_REG7;      
            end 
            else 
            begin
                next_state = SECOND_LEVEL_BLUE1_16BPC_1LANE_REG7;         
            end
          end
    SECOND_LEVEL_BLUE2_16BPC_1LANE_REG7: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = SECOND_LEVEL_RED1_16BPC_1LANE_REG8;      
            end 
            else 
            begin
                next_state = SECOND_LEVEL_BLUE2_16BPC_1LANE_REG7;         
            end
          end
    SECOND_LEVEL_RED1_16BPC_1LANE_REG8: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = SECOND_LEVEL_RED2_16BPC_1LANE_REG8;      
            end 
            else 
            begin
                next_state = SECOND_LEVEL_RED1_16BPC_1LANE_REG8;         
            end
          end
    SECOND_LEVEL_RED2_16BPC_1LANE_REG8: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = SECOND_LEVEL_GREAN1_16BPC_1LANE_REG8;      
            end 
            else 
            begin
                next_state = SECOND_LEVEL_RED2_16BPC_1LANE_REG8;         
            end
          end
    SECOND_LEVEL_GREAN1_16BPC_1LANE_REG8: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = SECOND_LEVEL_GREAN2_16BPC_1LANE_REG8;      
            end 
            else 
            begin
                next_state = SECOND_LEVEL_GREAN1_16BPC_1LANE_REG8;         
            end
          end
    SECOND_LEVEL_GREAN2_16BPC_1LANE_REG8: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = SECOND_LEVEL_BLUE1_16BPC_1LANE_REG8;      
            end 
            else 
            begin
                next_state = SECOND_LEVEL_GREAN2_16BPC_1LANE_REG8;         
            end
          end
    SECOND_LEVEL_BLUE1_16BPC_1LANE_REG8: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = SECOND_LEVEL_BLUE2_16BPC_1LANE_REG8;      
            end 
            else 
            begin
                next_state = SECOND_LEVEL_BLUE1_16BPC_1LANE_REG8;         
            end
          end
    SECOND_LEVEL_BLUE2_16BPC_1LANE_REG8: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
                next_state = FIRST_LEVEL_RED1_16BPC_1LANE_REG1;      
            end 
            else 
            begin
                next_state = SECOND_LEVEL_BLUE2_16BPC_1LANE_REG8;         
            end
          end
    default: 
          begin
                next_state = IDLE_STATE;
          end
        endcase
    end
   
  // Output logic
  always @(*)        
   begin
    // Default: pass through the input signals
    main_steered_lane0_comb = 8'b0;
    main_steered_lane1_comb = 8'b0;
    main_steered_lane2_comb = 8'b0;
    main_steered_lane3_comb = 8'b0;
    read_enable             = 1'b0;
    read_index              = 3'd0;
    read_counter            = 2'b0;
    four_regs_empty         = 0;
    two_regs_empty          = 0;
    case (current_state)
    IDLE_STATE:
          begin 
            main_steered_lane0_comb = 8'b0;
            main_steered_lane1_comb = 8'b0;
            main_steered_lane2_comb = 8'b0;
            main_steered_lane3_comb = 8'b0;  
            four_regs_empty         = 1;
            two_regs_empty          = 1;        
          end
    // 8-bpc (4 Lanes) - (6 states) 
    FIRST_LEVEL_RED_8BPC_4LANES:
          begin 
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
            main_steered_lane0_comb = reg_file[0][7:0];
            main_steered_lane1_comb = reg_file[1][7:0];
            main_steered_lane2_comb = reg_file[2][7:0];
            main_steered_lane3_comb = reg_file[3][7:0]; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    FIRST_LEVEL_GREAN_8BPC_4LANES:
          begin 
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[0][15:8];
            main_steered_lane1_comb = reg_file[1][15:8];
            main_steered_lane2_comb = reg_file[2][15:8];
            main_steered_lane3_comb = reg_file[3][15:8]; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    FIRST_LEVEL_BLUE_8BPC_4LANES:
          begin 
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin 
            main_steered_lane0_comb = reg_file[0][23:16];
            main_steered_lane1_comb = reg_file[1][23:16];
            main_steered_lane2_comb = reg_file[2][23:16];
            main_steered_lane3_comb = reg_file[3][23:16];
            read_enable             = 1'b1;
            read_index              = 3'd0;
            read_counter            = 2'b11;

            four_regs_empty         = 1;
//            empty_regs              = 8'b0000_1111; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    SECOND_LEVEL_RED_8BPC_4LANES:
          begin 
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin
            main_steered_lane0_comb = reg_file[4][7:0];
            main_steered_lane1_comb = reg_file[5][7:0];
            main_steered_lane2_comb = reg_file[6][7:0];
            main_steered_lane3_comb = reg_file[7][7:0]; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    SECOND_LEVEL_GREAN_8BPC_4LANES: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[4][15:8];
            main_steered_lane1_comb = reg_file[5][15:8];
            main_steered_lane2_comb = reg_file[6][15:8];
            main_steered_lane3_comb = reg_file[7][15:8]; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    SECOND_LEVEL_BLUE_8BPC_4LANES: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[4][23:16];
            main_steered_lane1_comb = reg_file[5][23:16];
            main_steered_lane2_comb = reg_file[6][23:16];
            main_steered_lane3_comb = reg_file[7][23:16]; 
            read_enable             = 1'b1;
            read_index              = 3'd4;
            read_counter            = 2'b11;
            four_regs_empty         = 1;
//            empty_regs              = 8'b1111_0000;
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end  
    // 16-bpc (4 Lanes) - (12 states)      
    FIRST_LEVEL_RED1_16BPC_4LANES: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[0][7:0];
            main_steered_lane1_comb = reg_file[1][7:0];
            main_steered_lane2_comb = reg_file[2][7:0];
            main_steered_lane3_comb = reg_file[3][7:0]; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end    
    FIRST_LEVEL_RED2_16BPC_4LANES: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[0][15:8];
            main_steered_lane1_comb = reg_file[1][15:8];
            main_steered_lane2_comb = reg_file[2][15:8];
            main_steered_lane3_comb = reg_file[3][15:8]; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    FIRST_LEVEL_GREAN1_16BPC_4LANES: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[0][23:16];
            main_steered_lane1_comb = reg_file[1][23:16];
            main_steered_lane2_comb = reg_file[2][23:16];
            main_steered_lane3_comb = reg_file[3][23:16]; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    FIRST_LEVEL_GREAN2_16BPC_4LANES: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[0][31:24];
            main_steered_lane1_comb = reg_file[1][31:24];
            main_steered_lane2_comb = reg_file[2][31:24];
            main_steered_lane3_comb = reg_file[3][31:24]; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    FIRST_LEVEL_BLUE1_16BPC_4LANES: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[0][39:32];
            main_steered_lane1_comb = reg_file[1][39:32];
            main_steered_lane2_comb = reg_file[2][39:32];
            main_steered_lane3_comb = reg_file[3][39:32]; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    FIRST_LEVEL_BLUE2_16BPC_4LANES: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[0][47:40];
            main_steered_lane1_comb = reg_file[1][47:40];
            main_steered_lane2_comb = reg_file[2][47:40];
            main_steered_lane3_comb = reg_file[3][47:40]; 
            read_enable             = 1'b1;
            read_index              = 3'd0;
            read_counter            = 2'b11;
            four_regs_empty         = 1;
//            empty_regs              = 8'b0000_1111; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    SECOND_LEVEL_RED1_16BPC_4LANES: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[4][7:0];
            main_steered_lane1_comb = reg_file[5][7:0];
            main_steered_lane2_comb = reg_file[6][7:0];
            main_steered_lane3_comb = reg_file[7][7:0]; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end    
    SECOND_LEVEL_RED2_16BPC_4LANES: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[4][15:8];
            main_steered_lane1_comb = reg_file[5][15:8];
            main_steered_lane2_comb = reg_file[6][15:8];
            main_steered_lane3_comb = reg_file[7][15:8]; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    SECOND_LEVEL_GREAN1_16BPC_4LANES: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[4][23:16];
            main_steered_lane1_comb = reg_file[5][23:16];
            main_steered_lane2_comb = reg_file[6][23:16];
            main_steered_lane3_comb = reg_file[7][23:16]; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    SECOND_LEVEL_GREAN2_16BPC_4LANES: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[4][31:24];
            main_steered_lane1_comb = reg_file[5][31:24];
            main_steered_lane2_comb = reg_file[6][31:24];
            main_steered_lane3_comb = reg_file[7][31:24]; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    SECOND_LEVEL_BLUE1_16BPC_4LANES: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[4][39:32];
            main_steered_lane1_comb = reg_file[5][39:32];
            main_steered_lane2_comb = reg_file[6][39:32];
            main_steered_lane3_comb = reg_file[7][39:32]; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    SECOND_LEVEL_BLUE2_16BPC_4LANES: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[4][47:40];
            main_steered_lane1_comb = reg_file[5][47:40];
            main_steered_lane2_comb = reg_file[6][47:40];
            main_steered_lane3_comb = reg_file[7][47:40]; 
            read_enable             = 1'b1;
            read_index              = 3'd4;
            read_counter            = 2'b11;
            four_regs_empty         = 1;
//            empty_regs              = 8'b1111_0000; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    // 8-bpc (2 Lanes) - (12 states)
    FIRST_LEVEL_RED_8BPC_2LANES_REG1_2: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[0][7:0];
            main_steered_lane1_comb = reg_file[1][7:0];
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end    
    FIRST_LEVEL_GREAN_8BPC_2LANES_REG1_2: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[0][15:8];
            main_steered_lane1_comb = reg_file[1][15:8];
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    FIRST_LEVEL_BLUE_8BPC_2LANES_REG1_2: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[0][23:16];
            main_steered_lane1_comb = reg_file[1][23:16];
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            read_enable             = 1'b1;
            read_index              = 3'd0;
            read_counter            = 2'b01;

            two_regs_empty          = 1;
//            empty_regs              = 8'b0000_0011; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    FIRST_LEVEL_RED_8BPC_2LANES_REG3_4: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[2][7:0];
            main_steered_lane1_comb = reg_file[3][7:0];
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    FIRST_LEVEL_GREAN_8BPC_2LANES_REG3_4: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[2][15:8];
            main_steered_lane1_comb = reg_file[3][15:8];
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL;  
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    FIRST_LEVEL_BLUE_8BPC_2LANES_REG3_4: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[2][23:16];
            main_steered_lane1_comb = reg_file[3][23:16];
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            read_enable             = 1'b1;
            read_index              = 3'd2;
            read_counter            = 2'b01;

            two_regs_empty          = 1;
//            empty_regs              = 8'b0000_1100; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    SECOND_LEVEL_RED_8BPC_2LANES_REG5_6: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[4][7:0];
            main_steered_lane1_comb = reg_file[5][7:0];
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL;  
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end    
    SECOND_LEVEL_GREAN_8BPC_2LANES_REG5_6: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[4][15:8];
            main_steered_lane1_comb = reg_file[5][15:8];
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    SECOND_LEVEL_BLUE_8BPC_2LANES_REG5_6: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[4][23:16];
            main_steered_lane1_comb = reg_file[5][23:16];
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL;
            read_enable             = 1'b1;
            read_index              = 3'd4;
            read_counter            = 2'b01;

            two_regs_empty          = 1;
//            empty_regs              = 8'b0011_0000;  
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    SECOND_LEVEL_RED_8BPC_2LANES_REG7_8: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[6][7:0];
            main_steered_lane1_comb = reg_file[7][7:0];
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL;
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    SECOND_LEVEL_GREAN_8BPC_2LANES_REG7_8: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[6][15:8];
            main_steered_lane1_comb = reg_file[7][15:8];
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    SECOND_LEVEL_BLUE_8BPC_2LANES_REG7_8: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[6][23:16];
            main_steered_lane1_comb = reg_file[7][23:16];
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL;
            read_enable             = 1'b1;
            read_index              = 3'd6;
            read_counter            = 2'b01;

            two_regs_empty          = 1;
//            empty_regs              = 8'b1100_0000;  
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    // 16-bpc (2 Lanes) - (24 states)
    FIRST_LEVEL_RED1_16BPC_2LANES_REG1_2: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[0][7:0];
            main_steered_lane1_comb = reg_file[1][7:0];
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end    
    FIRST_LEVEL_RED2_16BPC_2LANES_REG1_2: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[0][15:8];
            main_steered_lane1_comb = reg_file[1][15:8];
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    FIRST_LEVEL_GREAN1_16BPC_2LANES_REG1_2: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[0][23:16];
            main_steered_lane1_comb = reg_file[1][23:16];
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    FIRST_LEVEL_GREAN2_16BPC_2LANES_REG1_2: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[0][31:24];
            main_steered_lane1_comb = reg_file[1][31:24];
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end    
    FIRST_LEVEL_BLUE1_16BPC_2LANES_REG1_2: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[0][39:31];
            main_steered_lane1_comb = reg_file[1][39:31];
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    FIRST_LEVEL_BLUE2_16BPC_2LANES_REG1_2: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[0][47:40];
            main_steered_lane1_comb = reg_file[1][47:40];
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            read_enable             = 1'b1;
            read_index              = 3'd0;
            read_counter            = 2'b01;

            two_regs_empty          = 1;
//            empty_regs              = 8'b0000_0011; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    FIRST_LEVEL_RED1_16BPC_2LANES_REG3_4: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[2][7:0];
            main_steered_lane1_comb = reg_file[3][7:0];
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    FIRST_LEVEL_RED2_16BPC_2LANES_REG3_4: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[2][15:8];
            main_steered_lane1_comb = reg_file[3][15:8];
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL;  
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    FIRST_LEVEL_GREAN1_16BPC_2LANES_REG3_4: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8)) 
            begin            
            main_steered_lane0_comb = reg_file[2][23:16];
            main_steered_lane1_comb = reg_file[3][23:16];
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    FIRST_LEVEL_GREAN2_16BPC_2LANES_REG3_4: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[2][31:24];
            main_steered_lane1_comb = reg_file[3][31:24];
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end    
    FIRST_LEVEL_BLUE1_16BPC_2LANES_REG3_4: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[2][39:31];
            main_steered_lane1_comb = reg_file[3][39:31];
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    FIRST_LEVEL_BLUE2_16BPC_2LANES_REG3_4: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[2][47:40];
            main_steered_lane1_comb = reg_file[3][47:40];
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            read_enable             = 1'b1;
            read_index              = 3'd2;
            read_counter            = 2'b01;

            two_regs_empty          = 1;
//            empty_regs              = 8'b0000_1100; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    SECOND_LEVEL_RED1_16BPC_2LANES_REG5_6: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[4][7:0];
            main_steered_lane1_comb = reg_file[5][7:0];
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL;  
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end    
    SECOND_LEVEL_RED2_16BPC_2LANES_REG5_6: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[4][15:8];
            main_steered_lane1_comb = reg_file[5][15:8];
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    SECOND_LEVEL_GREAN1_16BPC_2LANES_REG5_6: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[4][23:16];
            main_steered_lane1_comb = reg_file[5][23:16];
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    SECOND_LEVEL_GREAN2_16BPC_2LANES_REG5_6: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[4][31:24];
            main_steered_lane1_comb = reg_file[5][31:24];
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end    
    SECOND_LEVEL_BLUE1_16BPC_2LANES_REG5_6: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[4][39:31];
            main_steered_lane1_comb = reg_file[5][39:31];
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    SECOND_LEVEL_BLUE2_16BPC_2LANES_REG5_6: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[4][47:40];
            main_steered_lane1_comb = reg_file[5][47:40];
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL;
            read_enable             = 1'b1;
            read_index              = 3'd4;
            read_counter            = 2'b01;

            two_regs_empty          = 1;
//            empty_regs              = 8'b0011_0000;  
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    SECOND_LEVEL_RED1_16BPC_2LANES_REG7_8: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[6][7:0];
            main_steered_lane1_comb = reg_file[7][7:0];
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL;
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    SECOND_LEVEL_RED2_16BPC_2LANES_REG7_8: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[6][15:8];
            main_steered_lane1_comb = reg_file[7][15:8];
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    SECOND_LEVEL_GREAN1_16BPC_2LANES_REG7_8: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[6][23:16];
            main_steered_lane1_comb = reg_file[7][23:16];
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    SECOND_LEVEL_GREAN2_16BPC_2LANES_REG7_8: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[6][31:24];
            main_steered_lane1_comb = reg_file[7][31:24];
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end    
    SECOND_LEVEL_BLUE1_16BPC_2LANES_REG7_8: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[6][39:31];
            main_steered_lane1_comb = reg_file[7][39:31];
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    SECOND_LEVEL_BLUE2_16BPC_2LANES_REG7_8: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[6][47:40];
            main_steered_lane1_comb = reg_file[7][47:40];
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            read_enable             = 1'b1;
            read_index              = 3'd6;
            read_counter            = 2'b01;

            two_regs_empty          = 1;
//            empty_regs              = 8'b1100_0000; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end 
    // 8-bpc (1 Lane) - (24 states)
    FIRST_LEVEL_RED_8BPC_1LANE_REG1: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[0][7:0];
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end    
    FIRST_LEVEL_GREAN_8BPC_1LANE_REG1: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[0][15:8];
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    FIRST_LEVEL_BLUE_8BPC_1LANE_REG1: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[0][23:16];
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    FIRST_LEVEL_RED_8BPC_1LANE_REG2: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[1][7:0];
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end    
    FIRST_LEVEL_GREAN_8BPC_1LANE_REG2: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[1][15:8];
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    FIRST_LEVEL_BLUE_8BPC_1LANE_REG2: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[1][23:16];
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            read_enable             = 1'b1;
            read_index              = 3'd0;
            read_counter            = 2'b01;

            two_regs_empty          = 1;
//            empty_regs              = 8'b0000_0011; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    FIRST_LEVEL_RED_8BPC_1LANE_REG3: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[2][7:0];
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    FIRST_LEVEL_GREAN_8BPC_1LANE_REG3: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[2][15:8];
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL;  
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    FIRST_LEVEL_BLUE_8BPC_1LANE_REG3: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[2][23:16];
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    FIRST_LEVEL_RED_8BPC_1LANE_REG4: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[3][7:0];
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    FIRST_LEVEL_GREAN_8BPC_1LANE_REG4: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[3][15:8];
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL;  
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    FIRST_LEVEL_BLUE_8BPC_1LANE_REG4: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[3][23:16];
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            read_enable             = 1'b1;
            read_index              = 3'd2;
            read_counter            = 2'b01;

            two_regs_empty          = 1;
//            empty_regs              = 8'b0000_1100; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    SECOND_LEVEL_RED_8BPC_1LANE_REG5: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[4][7:0];
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL;  
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end    
    SECOND_LEVEL_GREAN_8BPC_1LANE_REG5: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[4][15:8];
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    SECOND_LEVEL_BLUE_8BPC_1LANE_REG5: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[4][23:16];
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    SECOND_LEVEL_RED_8BPC_1LANE_REG6: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[5][7:0];
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL;  
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end    
    SECOND_LEVEL_GREAN_8BPC_1LANE_REG6: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[5][15:8];
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    SECOND_LEVEL_BLUE_8BPC_1LANE_REG6: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[5][23:16];
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            read_enable             = 1'b1;
            read_index              = 3'd4;
            read_counter            = 2'b01;

            two_regs_empty          = 1;
//            empty_regs              = 8'b0011_0000; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    SECOND_LEVEL_RED_8BPC_1LANE_REG7: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[6][7:0];
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL;
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    SECOND_LEVEL_GREAN_8BPC_1LANE_REG7: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[6][15:8];
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    SECOND_LEVEL_BLUE_8BPC_1LANE_REG7: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[6][23:16];
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    SECOND_LEVEL_RED_8BPC_1LANE_REG8: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[7][7:0];
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL;
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    SECOND_LEVEL_GREAN_8BPC_1LANE_REG8: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[7][15:8];
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    SECOND_LEVEL_BLUE_8BPC_1LANE_REG8: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[7][23:16];
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL;
            read_enable             = 1'b1;
            read_index              = 3'd6;
            read_counter            = 2'b01;

            two_regs_empty          = 1;
//            empty_regs              = 8'b1100_0000;  
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    // 16-bpc (1 Lanes) - (48 states) 
    FIRST_LEVEL_RED1_16BPC_1LANE_REG1: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[0][7:0];
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end    
    FIRST_LEVEL_RED2_16BPC_1LANE_REG1: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[0][15:8];
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    FIRST_LEVEL_GREAN1_16BPC_1LANE_REG1: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[0][23:16];
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    FIRST_LEVEL_GREAN2_16BPC_1LANE_REG1: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[0][31:24];
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end    
    FIRST_LEVEL_BLUE1_16BPC_1LANE_REG1: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[0][39:31];
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    FIRST_LEVEL_BLUE2_16BPC_1LANE_REG1: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[0][47:40];
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    FIRST_LEVEL_RED1_16BPC_1LANE_REG2: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[1][7:0];
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    FIRST_LEVEL_RED2_16BPC_1LANE_REG2: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[1][15:8];
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL;  
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    FIRST_LEVEL_GREAN1_16BPC_1LANE_REG2: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8)) 
            begin            
            main_steered_lane0_comb = reg_file[1][23:16];
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    FIRST_LEVEL_GREAN2_16BPC_1LANE_REG2: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[1][31:24];
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end    
    FIRST_LEVEL_BLUE1_16BPC_1LANE_REG2: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[1][39:31];
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    FIRST_LEVEL_BLUE2_16BPC_1LANE_REG2: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[1][47:40];
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            read_enable             = 1'b1;
            read_index              = 3'd0;
            read_counter            = 2'b01;

            two_regs_empty          = 1;
//            empty_regs              = 8'b0000_0011;  
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    FIRST_LEVEL_RED1_16BPC_1LANE_REG3: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[2][7:0];
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL;  
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end    
    FIRST_LEVEL_RED2_16BPC_1LANE_REG3: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[2][15:8];
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    FIRST_LEVEL_GREAN1_16BPC_1LANE_REG3: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[2][23:16];
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    FIRST_LEVEL_GREAN2_16BPC_1LANE_REG3: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[2][31:24];
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end    
    FIRST_LEVEL_BLUE1_16BPC_1LANE_REG3: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[2][39:31];
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    FIRST_LEVEL_BLUE2_16BPC_1LANE_REG3: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[2][47:40];
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    FIRST_LEVEL_RED1_16BPC_1LANE_REG4: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[3][7:0];
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL;
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    FIRST_LEVEL_RED2_16BPC_1LANE_REG4: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[3][15:8];
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    FIRST_LEVEL_GREAN1_16BPC_1LANE_REG4: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[3][23:16];
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    FIRST_LEVEL_GREAN2_16BPC_1LANE_REG4: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[3][31:24];
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end    
    FIRST_LEVEL_BLUE1_16BPC_1LANE_REG4: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[3][39:31];
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    FIRST_LEVEL_BLUE2_16BPC_1LANE_REG4: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[3][47:40];
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            read_enable             = 1'b1;
            read_index              = 3'd2;
            read_counter            = 2'b01;

            two_regs_empty          = 1;
//            empty_regs              = 8'b0000_1100; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    SECOND_LEVEL_RED1_16BPC_1LANE_REG5: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[4][7:0];
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end    
    SECOND_LEVEL_RED2_16BPC_1LANE_REG5: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[4][15:8];
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    SECOND_LEVEL_GREAN1_16BPC_1LANE_REG5: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[4][23:16];
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    SECOND_LEVEL_GREAN2_16BPC_1LANE_REG5: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[4][31:24];
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end    
    SECOND_LEVEL_BLUE1_16BPC_1LANE_REG5: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[4][39:31];
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    SECOND_LEVEL_BLUE2_16BPC_1LANE_REG5: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[4][47:40];
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    SECOND_LEVEL_RED1_16BPC_1LANE_REG6:
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[5][7:0];
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    SECOND_LEVEL_RED2_16BPC_1LANE_REG6: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[5][15:8];
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL;  
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    SECOND_LEVEL_GREAN1_16BPC_1LANE_REG6: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8)) 
            begin            
            main_steered_lane0_comb = reg_file[5][23:16];
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    SECOND_LEVEL_GREAN2_16BPC_1LANE_REG6: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[5][31:24];
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end    
    SECOND_LEVEL_BLUE1_16BPC_1LANE_REG6: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[5][39:31];
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    SECOND_LEVEL_BLUE2_16BPC_1LANE_REG6: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[5][47:40];
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            read_enable             = 1'b1;
            read_index              = 3'd4;
            read_counter            = 2'b01;

            two_regs_empty          = 1;
//            empty_regs              = 8'b0011_0000; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    SECOND_LEVEL_RED1_16BPC_1LANE_REG7: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[6][7:0];
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL;  
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end    
    SECOND_LEVEL_RED2_16BPC_1LANE_REG7: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[6][15:8];
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    SECOND_LEVEL_GREAN1_16BPC_1LANE_REG7: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[6][23:16];
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    SECOND_LEVEL_GREAN2_16BPC_1LANE_REG7: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[6][31:24];
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end    
    SECOND_LEVEL_BLUE1_16BPC_1LANE_REG7: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[6][39:31];
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    SECOND_LEVEL_BLUE2_16BPC_1LANE_REG7: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[6][47:40];
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL;
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    SECOND_LEVEL_RED1_16BPC_1LANE_REG8: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[7][7:0];
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL;
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    SECOND_LEVEL_RED2_16BPC_1LANE_REG8: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[7][15:8];
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    SECOND_LEVEL_GREAN1_16BPC_1LANE_REG8: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[7][23:16];
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    SECOND_LEVEL_GREAN2_16BPC_1LANE_REG8: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[7][31:24];
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end    
    SECOND_LEVEL_BLUE1_16BPC_1LANE_REG8: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[7][39:31];
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    SECOND_LEVEL_BLUE2_16BPC_1LANE_REG8: 
          begin
            if ((sched_steering_en) && (empty_count != 4'd8))
            begin            
            main_steered_lane0_comb = reg_file[7][47:40];
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            read_enable             = 1'b1;
            read_index              = 3'd6;
            read_counter            = 2'b01;

            two_regs_empty          = 1;
//            empty_regs              = 8'b1100_0000; 
            end 
            else 
            begin
            main_steered_lane0_comb = IDLE_SYMBOL;
            main_steered_lane1_comb = IDLE_SYMBOL;
            main_steered_lane2_comb = IDLE_SYMBOL;
            main_steered_lane3_comb = IDLE_SYMBOL; 
            end
          end
    default: 
          begin 
            main_steered_lane0_comb = 8'b0;
            main_steered_lane1_comb = 8'b0;
            main_steered_lane2_comb = 8'b0;
            main_steered_lane3_comb = 8'b0; 
          end
    endcase
   end

  // Lane Count Save
  always @(posedge clk or negedge rst_n) 
   begin
    if (!rst_n) 
     begin
      lane_count_reg <= 2'b0;
      misc_reg       <= 9'b0;
     end 
    else if (td_vld_data) 
     begin
      lane_count_reg <= td_lane_count;
      misc_reg       <= td_misc0_1;
     end
    end

    assign empty_count = empty_regs[0] + empty_regs[1] + empty_regs[2] + empty_regs[3] +
                         empty_regs[4] + empty_regs[5] + empty_regs[6] + empty_regs[7];

/*
    // Handle "mbs_empty_regs" signal and index (Asserted 4 clk cycles when 8 bits of empty_regs, 2 clk cycles when 4 bits of empty_regs,
    // 1 clk cycle when 2 bits of empty_regs)
   always @(posedge clk or posedge rst_n) 
     begin
      if (!rst_n) 
       begin
        mbs_empty_regs <= 0;
        pulse_counter  <= 0;
       end 
      else 
       begin
        if (pulse_counter != 0 && !fifo_almost_empty && (empty_count != 0)) 
         begin
          // Still counting pulse duration
          mbs_empty_regs  <= 1;
          pulse_counter   <= pulse_counter - 1;
        //  write_index     <= write_index + 2;
        //  write_index_inc <= 1'b1;
         end 
        else 
         begin
          if (!fifo_almost_empty & (empty_count != 0))
          begin
           mbs_empty_regs <= 1;
          end
          else
          begin
           mbs_empty_regs <= 0; 
          end
          if (empty_count == 4'd2 && !fifo_almost_empty) 
           begin
            pulse_counter  <= 3'd0;
           /* if (empty_regs == 0000_0011)
            begin
              write_index <= -4'd2;
            end
            else if (empty_regs == 0000_1100)
            begin
              write_index <= 4'd0;
            end
            else if (empty_regs == 0011_0000)
            begin
              write_index <= 4'd2;
            end
            else if (empty_regs == 1100_0000)
            begin
              write_index <= 4'd4;
            end */
/*
           end 
          else if (empty_count == 4'd4 && !fifo_almost_empty) 
           begin
            pulse_counter  <= 3'd1;
            
            /*if (empty_regs == 0000_1111)
            begin
              write_index <= -4'd2;
            end
            else if (empty_regs == 1111_0000)
            begin
              write_index <= 4'd2;
            end */
      /*     end 
          else if (empty_count == 4'd8 && !fifo_almost_empty) 
            begin
             pulse_counter  <= 3'd3;
           //  write_index    <= -4'd2;
            end
            end
        end
    end
*/

/*
    always @(posedge clk or posedge rst_n) 
     begin
      if (!rst_n) 
       begin
        mbs_empty_regs <= 0;
        pulse_counter  <= 0;
       end 
      else 
       begin
        if (!fifo_almost_empty && (empty_count != 0)) 
         begin
//          pulse_counter   <= 1;
          if ((empty_count == 2) && (pulse_counter != 0))
          begin
            mbs_empty_regs  <= 1;
            pulse_counter   <= 0;
          end
          else if ((empty_count == 2) && pulse_counter == 0)
          begin
            mbs_empty_regs  <= 0;
            pulse_counter   <= 0;
          end
          else
          begin
            mbs_empty_regs  <= 1;
            pulse_counter   <= 1;
          end
         end 
        else 
         begin
          mbs_empty_regs  <= 0;
          pulse_counter   <= 1;
         end
        end
    end
*/

/*
    always @(*) 
     begin
      mbs_empty_regs = 0;
      pulse_counter  = 0;
      if (!rst_n) 
       begin
        mbs_empty_regs = 0;
        pulse_counter  = 0;
       end 
      else 
       begin
        if (!fifo_almost_empty && (empty_count != 0)) 
         begin
//          pulse_counter   = 1;
          if ((empty_count == 2) && (pulse_counter != 0))
          begin
            mbs_empty_regs  = 1;
            pulse_counter   = 1;
          end
   /*       else if ((empty_count == 2) && (pulse_counter == 0))
          begin
            mbs_empty_regs  = 0;
            pulse_counter   = 0;    //////////////
          end */
/*          else
          begin
            mbs_empty_regs  = 1;
            pulse_counter   = 1;
          end
         end 
        else 
         begin
          mbs_empty_regs  = 0;
          pulse_counter   = 1;
         end
        end
    end
*/


/////////////////////////////////////////////////////////////////////////
  always @(posedge clk or negedge rst_n) 
     begin
      if (!rst_n) 
       begin
        eigth_regs_empty  <= 0;
       end 
      else 
       begin
        if (empty_count == 4'd8)
        begin
          eigth_regs_empty  <= 1;
        end
        else
        begin
          eigth_regs_empty  <= 0;
        end
       end
     end


  always @(posedge clk or negedge rst_n) 
     begin
      if (!rst_n) 
       begin
        pulse_counter  <= 0;
       end 
      else 
       begin
        if ((!fifo_almost_empty) && (pulse_counter != 0)) 
         begin
          pulse_counter  <= pulse_counter - 1;
         end 
        else 
         begin
          if (eigth_regs_empty)
          begin
            pulse_counter   = 3'd4;
          end
/*          else if ((empty_count == 6))
          begin
            pulse_counter   = 3'd3;
          end */
          else if (four_regs_empty)
          begin
            pulse_counter   = 3'd2;
          end
          else if (two_regs_empty)
          begin
            pulse_counter   = 3'd1;
          end
/*          else /*if ((empty_count == 0))*/
       /*   begin
            pulse_counter   = 3'd0;            
          end*/
        end
    end
  end 
////////////////////////////////////////////////////////////////////////

/*
  always @(posedge clk or negedge rst_n) 
    begin
      if (!rst_n) 
       begin
        next_pulse_counter  <= 0;
       end 
      else 
       begin
        if ((!fifo_almost_empty) && (next_pulse_counter != 0) /*&& (next_pulse_counter != 0)*/   /*) 
     begin
          next_pulse_counter  <= next_pulse_counter - 1;
         end 
        else if (pulse_counter == 3'd4)
        begin
          next_pulse_counter  <= 3'd4;
        end
        else if (pulse_counter == 3'd3)
        begin
          next_pulse_counter  <= 3'd3;
        end
        else if (pulse_counter == 3'd2)
        begin
          next_pulse_counter  <= 3'd2;
        end
        else if (pulse_counter == 3'd1)
        begin
          next_pulse_counter  <= 3'd1;
        end
       end
    end
*/
/*
  always @(*) 
     begin
//      pulse_counter = 0;
      tt = 0;
      tf = 0;
      tw = 0;
      if (!rst_n) 
       begin
        pulse_counter = 0;
       end 
      else 
       begin
        old_pulse_counter = pulse_counter;
        tf = 1;
        if ((!fifo_almost_empty) && ((old_pulse_counter == 3'd4) || (old_pulse_counter == 3'd3) || (old_pulse_counter == 3'd2) || (old_pulse_counter == 3'd1))) 
         begin
            pulse_counter = next_pulse_counter;
            tt = 1;          
         end 
         else if (next_pulse_counter != 3'd0)
         begin
            pulse_counter = next_pulse_counter;          
         end
        else 
         begin
          tw = 1;
          if ((empty_count == 8))
          begin
            pulse_counter   = 3'd4;
          end
          else if ((empty_count == 6))
          begin
            pulse_counter   = 3'd3;
          end
          else if ((empty_count == 4))
          begin
            pulse_counter   = 3'd2;
          end
          else if ((empty_count == 2))
          begin
            pulse_counter   = 3'd1;
          end
          else if ((empty_count == 0))
          begin
            pulse_counter   = 3'd0;            
          end
        end
    end
  end
*/

/*
  always @(posedge clk or negedge rst_n) 
     begin
      if (!rst_n) 
       begin
        pulse_counter  <= 0;
       end 
      else 
       begin
        if ((!fifo_almost_empty) && (pulse_counter != 0)) 
         begin
          pulse_counter  <= pulse_counter - 1;
         end 
        else 
         begin
          if (pulse_counter_comb == 3'd0)
          begin
            pulse_counter  <= 3'd0;
          end
          else
          begin
            pulse_counter  <= pulse_counter_comb - 1;
          end
        end
    end
  end

  always @(*)
  begin
    if (!((!fifo_almost_empty) && (pulse_counter != 0)))
    begin
           if ((empty_count == 8))
          begin
            pulse_counter_comb   = 3'd4;
          end
/*          else if ((empty_count == 6))
          begin
            pulse_counter_comb   = 3'd3;
          end */
/*          else if (four_regs_empty)
          begin
            pulse_counter_comb   = 3'd2;
          end
          else if (two_regs_empty)
          begin
            pulse_counter_comb   = 3'd1;
          end
          else /*if ((empty_count == 0))*/
/*          begin
            pulse_counter_comb   = 3'd0;            
          end
    end
    else 
    begin
            pulse_counter_comb   = pulse_counter;        
    end
  end */

  always @(*)
  begin
    if ((!fifo_almost_empty) && (empty_count != 0) && ((pulse_counter != 0) || (pulse_counter_comb != 0)))
    begin
      mbs_empty_regs  = 1;
    end
    else
    begin
      mbs_empty_regs  = 0;
    end
  end





 /*
  // Update empty_reg_file flag
  always @(posedge clk or negedge rst_n) 
   begin
    if (!rst_n) 
     begin
      empty_reg_file <= 1'b0;
     end 
    else if (empty_count == 4'd8) 
     begin
      empty_reg_file <= 1'b1;
     end
    else
     begin
      empty_reg_file <= 1'b0;
     end 
    end
*/

/*
  // Update write_index flag
  always @(posedge clk or negedge rst_n) 
   begin
    if (!rst_n) 
     begin
      test        <= 1'b0;
      test2       <= 1'b0;
      write_index <= 4'b0;
     end 
/*    else if (rd_data_valid) 
     begin
      write_index <= write_index + 2;
      test        <= 1'b0;
      test2       <= 1'b0;
     end */
/*    else
    begin
          if (empty_count == 4'd2 /*&& !fifo_almost_empty*/   /*) */
/*           begin
            test        <= 1'b1;
            if (empty_regs == 8'b0000_0011)
            begin
              write_index <= 4'd0;
              test2       <= 1'b1;
            end
            else if (empty_regs == 8'b0000_1100)
            begin
              write_index <= 4'd2;
              test2       <= 1'b1;
            end
            else if (empty_regs == 8'b0011_0000)
            begin
              write_index <= 4'd4;
              test2       <= 1'b1;
            end
            else if (empty_regs == 8'b1100_0000)
            begin
              write_index <= 4'd6;
              test2       <= 1'b1;
            end 
           end 
          else if (empty_count == 4'd4 /*&& !fifo_almost_empty*/   /*) */
/*           begin
            test        <= 1'b1;
            if (empty_regs == 8'b0000_1111)
            begin
              write_index <= 4'd0;
              test2       <= 1'b1;
            end
            else if (empty_regs == 8'b0011_1100)
            begin
              write_index <= 4'd2;
              test2       <= 1'b1;
            end
            else if (empty_regs == 8'b1111_0000)
            begin
              write_index <= 4'd4;
              test2       <= 1'b1;
            end 
            else if (empty_regs == 8'b1100_0011)
            begin
              write_index <= 4'd6;
              test2       <= 1'b1;
            end 
           end 
           else if (empty_count == 4'd6 /*&& !fifo_almost_empty*/   /*) */
/*           begin
            test        <= 1'b1;
            if (empty_regs == 8'b0011_1111)
            begin
              write_index <= 4'd0;
              test2       <= 1'b1;
            end
            else if (empty_regs == 8'b1111_1100)
            begin
              write_index <= 4'd2;
              test2       <= 1'b1;
            end 
            else if (empty_regs == 8'b1111_0011)
            begin
              write_index <= 4'd4;
              test2       <= 1'b1;
            end
            else if (empty_regs == 8'b1100_1111)
            begin
              write_index <= 4'd6;
              test2       <= 1'b1;
            end
           end  
/*          else if (empty_count == 4'd8 && !fifo_almost_empty) 
            begin
              test          <= 1'b1;
             write_index    <= 4'd0;
            end */
/*     end 
    end
*/

  // Update write_index flag
  always @(*) 
   begin
      test        = 1'b0;
      test2       = 1'b0;
      write_index = 4'b0;    
    if (!rst_n) 
     begin
      test        = 1'b0;
      test2       = 1'b0;
      write_index = 4'b0;
     end 
    else
    begin
          if (empty_count == 4'd2 /*&& !fifo_almost_empty*/) 
           begin
            test        = 1'b1;
            if (empty_regs == 8'b0000_0011)
            begin
              write_index = 4'd0;
              test2       = 1'b1;
            end
            else if (empty_regs == 8'b0000_1100)
            begin
              write_index = 4'd2;
              test2       = 1'b1;
            end
            else if (empty_regs == 8'b0011_0000)
            begin
              write_index = 4'd4;
              test2       = 1'b1;
            end
            else if (empty_regs == 8'b1100_0000)
            begin
              write_index = 4'd6;
              test2       = 1'b1;
            end 
           end 
          else if (empty_count == 4'd4 /*&& !fifo_almost_empty*/) 
           begin
            test        = 1'b1;
            if (empty_regs == 8'b0000_1111)
            begin
              write_index = 4'd0;
              test2       = 1'b1;
            end
            else if (empty_regs == 8'b0011_1100)
            begin
              write_index = 4'd2;
              test2       = 1'b1;
            end
            else if (empty_regs == 8'b1111_0000)
            begin
              write_index = 4'd4;
              test2       = 1'b1;
            end 
            else if (empty_regs == 8'b1100_0011)
            begin
              write_index = 4'd6;
              test2       = 1'b1;
            end 
           end 
           else if (empty_count == 4'd6 /*&& !fifo_almost_empty*/) 
           begin
            test        = 1'b1;
            if (empty_regs == 8'b0011_1111)
            begin
              write_index = 4'd0;
              test2       = 1'b1;
            end
            else if (empty_regs == 8'b1111_1100)
            begin
              write_index = 4'd2;
              test2       = 1'b1;
            end 
            else if (empty_regs == 8'b1111_0011)
            begin
              write_index = 4'd4;
              test2       = 1'b1;
            end
            else if (empty_regs == 8'b1100_1111)
            begin
              write_index = 4'd6;
              test2       = 1'b1;
            end
           end  
          else if (empty_count == 4'd8 /*&& !fifo_almost_empty*/) 
            begin
              test          = 1'b1;
             write_index    = write_index_stored;
            end 
     end 
    end

 always @ (posedge clk or negedge rst_n)
  begin
  if(!rst_n)
   begin
    write_index_stored <= 8'b0;  
   end
  else 
   begin	   
    write_index_stored <= write_index;       
   end 
  end 


  // Update the register file and "empty_regs"
  always @(posedge clk or negedge rst_n) 
   begin
    if (!rst_n) 
     begin
      for (int i = 0; i < 8; i++) 
       begin
        reg_file[i] <= 48'd0;
       end
      empty_regs <= 8'b1111_1111;  // All empty on reset
     end 
    else if (rd_data_valid) 
     begin
      reg_file[write_index]         <= fifo_pixel_data[47:0];
      reg_file[write_index + 1]     <= fifo_pixel_data[95:48];
      empty_regs[write_index]       <= 1'b0;
      empty_regs[write_index + 1]   <= 1'b0;
     if (read_enable)
     begin
      if (read_counter == 2'b00)
      begin
        empty_regs[read_index]     <= 1'b1;        
      end
      else if (read_counter == 2'b01)
      begin
        empty_regs[read_index]     <= 1'b1;  
        empty_regs[read_index + 1] <= 1'b1;       
      end
      else if (read_counter == 2'b11)
      begin
        empty_regs[read_index]     <= 1'b1;  
        empty_regs[read_index + 1] <= 1'b1;   
        empty_regs[read_index + 2] <= 1'b1;  
        empty_regs[read_index + 3] <= 1'b1;  
      end
     end 
     end
     else if (read_enable)
     begin
      if (read_counter == 2'b00)
      begin
        empty_regs[read_index]     <= 1'b1;        
      end
      else if (read_counter == 2'b01)
      begin
        empty_regs[read_index]     <= 1'b1;  
        empty_regs[read_index + 1] <= 1'b1;       
      end
      else if (read_counter == 2'b11)
      begin
        empty_regs[read_index]     <= 1'b1;  
        empty_regs[read_index + 1] <= 1'b1;   
        empty_regs[read_index + 2] <= 1'b1;  
        empty_regs[read_index + 3] <= 1'b1;  
      end
     end 
   end

 // Make the output signals sequential
 always @ (posedge clk or negedge rst_n)
  begin
  if(!rst_n)
   begin
    main_steered_lane0 <= 8'b0;  
    main_steered_lane1 <= 8'b0; 
    main_steered_lane2 <= 8'b0; 
    main_steered_lane3 <= 8'b0; 
   end
  else 
   begin	   
    main_steered_lane0 <= main_steered_lane0_comb;    
    main_steered_lane1 <= main_steered_lane1_comb;    
    main_steered_lane2 <= main_steered_lane2_comb;    
    main_steered_lane3 <= main_steered_lane3_comb;    
   end 
  end 

endmodule