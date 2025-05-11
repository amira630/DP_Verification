/////////////////////////////////////////////////////////////////////////////////////////////////////
// Block Name:  IDLE Pattern
//
// Author:      Mohamed Alaa
//
// Discription: This block generates idle symbol patterns when no active video, audio, HBlank, or VBlack 
//              is being transmitted. Each pattern includes BS, VB-ID, Mvid, and Maud symbols, followed by 
//              dummy symbols, all set to zero. This pattern repeats every 8192 symbols.  
/////////////////////////////////////////////////////////////////////////////////////////////////////

module idle_pattern 
(
  input wire       clk,                    // System clock
  input wire       rst_n,                  // Active low reset
  input wire       sched_idle_en,    // Enable signal from scheduler
    
  output reg [7:0] idle_symbols,           // 8-bit output for idle symbols
  output reg       idle_control_sym_flag,  // Flag for BS symbols
  output reg       idle_activate_en  // Flag for scheduler about switching availability
);

  // Symbol definitions
  localparam [7:0] BS    = 8'b10111100;    // Blanking Start            
  localparam [7:0] BF    = 8'b10111101;    // Blanking Fill
  localparam [7:0] VB_ID = 8'b10011000;    // VB-ID symbol
  localparam [7:0] MVID  = 8'b00000000;    // Mvid symbol  (all zeros)
  localparam [7:0] MAUD  = 8'b00000000;    // Maud symbol  (all zeros)
  localparam [7:0] DUMMY = 8'b00000000;    // Dummy symbol (all zeros)
    
  // States for the pattern generation (Gray Code)
  typedef enum reg [3:0] 
  {
    IDLE_STATE  = 4'b0000,     // IDLE STATE                    
    BS1         = 4'b0001,     // First BS symbol  (BS)
    BS2         = 4'b0011,     // Second BS symbol (BF)
    BS3         = 4'b0010,     // Third BS symbol  (BF)
    BS4         = 4'b0110,     // Fourth BS symbol (BS)
    VB_ID_STATE = 4'b0111,     // VB-ID symbol
    MVID_STATE  = 4'b0101,     // Mvid symbol
    MAUD_STATE  = 4'b1101,     // Maud symbol
    DUMMY_STATE = 4'b1111      // Dummy symbols
  } state_t;
    
  // Registers for state and counter management
  state_t     current_state, next_state;
  reg [12:0]  symbol_counter;              // Counter for 8192 symbols (2^13 = 8192)
  reg         last_dummy_symbol;           // Flag for the last dummy symbol before BS
  
  reg [7:0]   idle_symbols_comb;
  reg         idle_control_sym_flag_comb;
  reg         idle_activate_en_comb;

  // State and counter management
  always @(posedge clk or negedge rst_n)
   begin
    if (!rst_n) 
     begin
      current_state       <= IDLE_STATE;
      symbol_counter      <= 13'd0;
      last_dummy_symbol   <= 1'b0;
     end 
     else if (sched_idle_en) 
     begin
      current_state       <= next_state; 
      // Update symbol counter
      if (symbol_counter == 13'd8191)
       begin
        symbol_counter    <= 13'd0;
        last_dummy_symbol <= 1'b0;
       end 
      else
       begin
        if (current_state == IDLE_STATE)  // Start the Counter at 0 and end at 8191 (8192 total symbols transmitted)
         begin
          symbol_counter    <= 13'd0;
         end
        else
         begin
          symbol_counter    <= symbol_counter + 1'b1;
          last_dummy_symbol <= (symbol_counter == 13'd8190) ? 1'b1 : 1'b0;
         end
       end
      end 
      else
       begin
        current_state     <= IDLE_STATE;
        symbol_counter    <= 13'd0;
        last_dummy_symbol <= 1'b0;
       end
   end
    
  // Next state logic
  always @(*) 
   begin
    case (current_state)
    IDLE_STATE: 
          begin
            if (sched_idle_en)
            begin
              next_state = BS1;
            end
            else
            begin
              next_state = IDLE_STATE;
            end
          end
    BS1: 
          begin    
              next_state = BS2;
          end
    BS2:
          begin    
              next_state = BS3;
          end
    BS3:
          begin    
              next_state = BS4;
          end
    BS4:
          begin    
              next_state = VB_ID_STATE;
          end
    VB_ID_STATE:
          begin    
              next_state = MVID_STATE;
          end
    MVID_STATE:
          begin    
              next_state = MAUD_STATE;
          end    
    MAUD_STATE:
          begin    
              next_state = DUMMY_STATE;
          end
    DUMMY_STATE: 
          begin
            if (last_dummy_symbol)
            begin
              next_state = BS1;
            end 
            else 
            begin
              next_state = DUMMY_STATE;
            end
          end
    default: 
          begin    
              next_state = BS1;
          end
    endcase
    end
    
  // Output logic
  always @(*)
   begin
    idle_symbols_comb           = 8'd0;
    idle_control_sym_flag_comb  = 1'b0;
    idle_activate_en_comb = 1'b0;
    case (current_state)
    IDLE_STATE:
          begin 
            idle_symbols_comb           = 8'd0;
            idle_control_sym_flag_comb  = 1'b0;
            idle_activate_en_comb = 1'b0;  // Deasserted during BS symbols
          end
    BS1:
          begin 
            idle_symbols_comb           = BS;
            idle_control_sym_flag_comb  = 1'b1;
            idle_activate_en_comb = 1'b0;  // Deasserted during BS symbols
          end
    BS2:
          begin
            idle_symbols_comb           = BF;
            idle_control_sym_flag_comb  = 1'b1;
            idle_activate_en_comb = 1'b0;  // Deasserted during BS symbols
          end
    BS3: 
          begin
            idle_symbols_comb           = BF;
            idle_control_sym_flag_comb  = 1'b1;
            idle_activate_en_comb = 1'b0;  // Deasserted during BS symbols
          end
    BS4: 
          begin
            idle_symbols_comb           = BS;
            idle_control_sym_flag_comb  = 1'b1;
            idle_activate_en_comb = 1'b1;  // Asserted for the last BS Symbol
          end
    VB_ID_STATE:
          begin
            idle_symbols_comb           = VB_ID;
            idle_control_sym_flag_comb  = 1'b0;
            idle_activate_en_comb = 1'b1;  // Asserted for normal operation
          end
    MVID_STATE:
          begin
            idle_symbols_comb           = MVID;
            idle_control_sym_flag_comb  = 1'b0;
            idle_activate_en_comb = 1'b1;  // Asserted for normal operation
          end
    MAUD_STATE:
          begin
            idle_symbols_comb           = MAUD;
            idle_control_sym_flag_comb  = 1'b0;
            idle_activate_en_comb = 1'b1;  // Asserted for normal operation
          end
    DUMMY_STATE:
          begin
            idle_symbols_comb           = DUMMY;
            idle_control_sym_flag_comb  = 1'b0;
            idle_activate_en_comb = last_dummy_symbol ? 1'b0 : 1'b1;  // Deasserted on last dummy symbol
          end
    default:
          begin
            idle_symbols_comb           = 8'd0;
            idle_control_sym_flag_comb  = 1'b0;
            idle_activate_en_comb = 1'b0;
          end
     endcase
    end

 // Make the output signals sequential
 always @ (posedge clk or negedge rst_n)
  begin
  if(!rst_n)
   begin
    idle_symbols           <= 8'd0; 
    idle_control_sym_flag  <= 1'b0;
    idle_activate_en <= 'b0;   
   end
  else 
   begin	
    idle_symbols           <= idle_symbols_comb;
    idle_control_sym_flag  <= idle_control_sym_flag_comb;
    idle_activate_en <= idle_activate_en_comb;  
   end 
  end 

endmodule