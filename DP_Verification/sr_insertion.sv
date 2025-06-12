//////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Block Name:  SR Isertion
//
// Author:      Mohamed Alaa
//
// Discription: The SR Insertion block plays a crucial role in maintaining data integrity by managing 
//              the periodic insertion of SR symbols within the transmitted stream. It continuously 
//              monitors and counts the number of BS symbols in the data stream. Once 512 BS symbols 
//              have been transmitted, the block replaces the 512th BS symbol with an SR (Scrambler Reset) symbol. 
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module sr_insertion 
(
  input wire       clk,                       // System clock
  input wire       rst_n,                     // Active low reset
  input wire       mux_control_sym_flag,      // Flag indicating control symbols
  input wire [7:0] mux_idle_stream_symbols,       // Input symbol stream
    
  output reg       iso_control_sym_flag,    // Output control symbol flag
  output reg [7:0] iso_symbols          // Output symbol stream with SR inserted
);

  // Symbol definitions
  localparam [7:0] BS = 8'b10111100;    // Blanking Start symbol              
  localparam [7:0] BF = 8'b10111101;    // Blanking Fill symbol               
  localparam [7:0] SR = 8'b00001111;    // Scrambler Reset symbol             

  // State definitions (Gray Code)
  typedef enum reg [3:0] 
  {    
    // State definitions for BS symbol sequence detection
    IDLE_STATE   = 4'b0000,         // IDLE STATE 
    BS1_DETECTED = 4'b0001,         // First BS detected
    BS2_DETECTED = 4'b0011,         // BF after BS detected
    BS3_DETECTED = 4'b0010,         // Second BF detected
    BS4_DETECTED = 4'b0110,         // Final BS detected, BS complete
    // State definitions for SR symbol insertion
    SR1_INSERT   = 4'b0111,         // Insert SR instead of BS
    SR2_INSERT   = 4'b0101,         // Insert BF
    SR3_INSERT   = 4'b1101,         // Insert BF 
    SR4_INSERT   = 4'b1111          // Insert SR instead of BS, then back to IDLE_STATE
  } state_t;    

  // Registers 
  state_t     current_state, next_state;
  reg [9:0]   bs_counter;                  // Counter for BS symbols (up to 512)
  reg         replace_with_sr;             // Flag to indicate SR replacement
  reg         bs_complete;                 // Flag to indicate complete BS detection

  reg [7:0]   iso_symbols_comb;
  reg         iso_control_sym_flag_comb;

  // State transiton & update bs_complete flag 
  always @(posedge clk or negedge rst_n) 
   begin
    if (!rst_n) 
     begin
      current_state <= IDLE_STATE;
      bs_complete   <= 1'b0;
     end 
    else 
     begin
      current_state <= next_state;      
      bs_complete   <= (current_state == BS4_DETECTED) ? 1'b1 : 1'b0;    // Set bs_complete flag when a full BS sequence is detected
     end
    end
    
  // Next state logic
  always @(*)
   begin
    case (current_state)
    IDLE_STATE: 
          begin
            if (mux_control_sym_flag && mux_idle_stream_symbols == BS) 
            begin
              if (replace_with_sr) 
              begin
                next_state = SR1_INSERT;
              end 
              else 
              begin
                next_state = BS1_DETECTED;
              end
            end
          end     
    BS1_DETECTED: 
          begin
            if (mux_control_sym_flag && mux_idle_stream_symbols == BF) 
            begin
                next_state = BS2_DETECTED;
            end 
            else 
            begin
                next_state = IDLE_STATE;         // Sequence broken, reset
            end
          end
    BS2_DETECTED: 
          begin
            if (mux_control_sym_flag && mux_idle_stream_symbols == BF) 
            begin
                next_state = BS3_DETECTED;
            end 
            else
            begin
                next_state = IDLE_STATE;         // Sequence broken, reset
            end
          end
    BS3_DETECTED: 
          begin
            if (mux_control_sym_flag && mux_idle_stream_symbols == BS) 
            begin
                next_state = BS4_DETECTED;       // BS sequence complete
            end 
            else 
            begin
                next_state = IDLE_STATE;         // Sequence broken, reset
            end
          end      
    BS4_DETECTED: 
          begin
                next_state = IDLE_STATE;         // Go back to IDLE after BS detected
          end
    SR1_INSERT: 
          begin
                next_state = SR2_INSERT;
          end
    SR2_INSERT: 
          begin
                next_state = SR3_INSERT;
          end    
    SR3_INSERT: 
          begin
                next_state = SR4_INSERT;
          end
    SR4_INSERT: 
          begin
                next_state = IDLE_STATE;
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
    iso_control_sym_flag_comb = mux_control_sym_flag;
    iso_symbols_comb      = mux_idle_stream_symbols;
    case (current_state)
    IDLE_STATE:
          begin 
            if ((next_state == SR1_INSERT) && (replace_with_sr))
            begin
                iso_symbols_comb      = SR;      // Replace first BS with SR
                iso_control_sym_flag_comb = 1'b1;
            end
            else 
            begin 
                iso_control_sym_flag_comb = mux_control_sym_flag;
                iso_symbols_comb      = mux_idle_stream_symbols;
            end
          end
    BS1_DETECTED:
          begin 
            iso_control_sym_flag_comb = mux_control_sym_flag;
            iso_symbols_comb      = mux_idle_stream_symbols;
          end
    BS2_DETECTED:
          begin 
            iso_control_sym_flag_comb = mux_control_sym_flag;
            iso_symbols_comb      = mux_idle_stream_symbols;
          end
    BS3_DETECTED:
          begin 
            iso_control_sym_flag_comb = mux_control_sym_flag;
            iso_symbols_comb      = mux_idle_stream_symbols;
          end
    BS4_DETECTED:
          begin 
            iso_control_sym_flag_comb = mux_control_sym_flag;
            iso_symbols_comb      = mux_idle_stream_symbols;
          end
    SR1_INSERT: 
          begin
            iso_symbols_comb      = BF;      
            iso_control_sym_flag_comb = 1'b1;
          end
    SR2_INSERT: 
          begin
            iso_symbols_comb      = BF;      
            iso_control_sym_flag_comb = 1'b1;
          end     
    SR3_INSERT: 
          begin
            iso_symbols_comb      = SR;      // Replace second BS with SR
            iso_control_sym_flag_comb = 1'b1;
          end            
    SR4_INSERT: 
          begin
            iso_control_sym_flag_comb = mux_control_sym_flag;
            iso_symbols_comb      = mux_idle_stream_symbols;
          end
    default: 
          begin
            iso_control_sym_flag_comb = mux_control_sym_flag;
            iso_symbols_comb      = mux_idle_stream_symbols;
          end
    endcase
   end

  // BS counter management
  always @(posedge clk or negedge rst_n) 
   begin
    if (!rst_n) 
     begin
      bs_counter      <= 10'd0;
      replace_with_sr <= 1'b0;
     end 
    else if (bs_complete) 
     begin
      // Increment counter when complete BS sequence detected
      if (bs_counter == 10'd510) 
       begin
        bs_counter      <= 10'd0;      // Reset counter after 512 BS symbols
        replace_with_sr <= 1'b1;       // Signal to replace next BS with SR
       end
      else
       begin
        bs_counter      <= bs_counter + 1'b1;
        replace_with_sr <= 1'b0;
       end
     end
    else if (current_state == SR4_INSERT)
     begin
      // Reset the replace flag after SR insertion is complete
      replace_with_sr   <= 1'b0;
     end
    end

 // Make the output signals sequential
 always @ (posedge clk or negedge rst_n)
  begin
  if(!rst_n)
   begin
    iso_symbols       <= 8'd0; 
    iso_control_sym_flag  <= 1'b0;  
   end
  else 
   begin	
    iso_symbols       <= iso_symbols_comb; 
    iso_control_sym_flag  <= iso_control_sym_flag_comb;    
   end 
  end 

endmodule