/////////////////////////////////////////////////////////////////////////////////////////////////////
// Block Name:  CR ERR CHK
//
// Author:      Mohamed Alaa
//
// Discription: The CR_ERR_CHK block plays a crucial role in handling failures during the clock recovery phase 
//              of the link training. If the CR FSM block detects a failure in clock recovery, the CR_ERR_CHK block
//              is activated to analyze and adjust key parameters to improve the chances of successful recovery.  
/////////////////////////////////////////////////////////////////////////////////////////////////////

module cr_err_chk 
(
  ////////////////// Inputs //////////////////
  input  wire        clk,
  input  wire        rst_n,  
  // LPM
  input  wire        config_param_vld,                   
  input  wire [7:0]  link_bw_cr,
  input  wire [1:0]  link_lc_cr,
  input  wire [1:0]  max_vtg,
  // CR FSM
  input  wire        cr_chk_start,   
  input  wire [7:0]  adj_vtg,
  input  wire [7:0]  adj_pre, 
  input  wire        cr_completed,                       
  input  wire        fsm_cr_failed, 
  ////////////////// Outputs //////////////////
  // CR FSM
  output reg  [7:0]  new_bw_cr,
  output reg  [1:0]  new_lc_cr,  
  output reg         err_cr_failed, 
  output reg         drive_setting_flag,
  output reg         bw_flag, 
  output reg         lc_flag 
);
  
// State encoding (Gray Code)
typedef enum reg [2:0] {
  IDLE_STATE                = 3'b000,  
  CHK_VTG                   = 3'b001,  
  ADJUST_DRIVING_PARAMETERS = 3'b011,  
  CHK_RBR                   = 3'b010,  
  REDUCE_BW                 = 3'b110,  
  CHK_LC                    = 3'b111,  
  REDUCE_LC                 = 3'b101,  
  CR_FAILED                 = 3'b100   
} state_t;


// Internal Signals
state_t     current_state, next_state;

reg  [7:0]  max_vtg_reg;
reg  [7:0]  max_bw_reg;
reg  [1:0]  max_lc_reg;
reg  [7:0]  current_vtg_reg;
reg  [7:0]  current_pre_reg;
reg  [7:0]  previous_vtg_reg;
reg  [7:0]  previous_pre_reg;
reg  [7:0]  current_bw_reg;
reg  [1:0]  current_lc_reg;
reg  [7:0]  current_bw_comb;
reg  [1:0]  current_lc_comb;

reg  [3:0]  driving_counter;
reg  [2:0]  same_parameters_counter;

reg  [7:0]  new_bw_cr_comb;
reg  [1:0]  new_lc_cr_comb;  
reg         err_cr_failed_comb;
reg         drive_setting_flag_comb;
reg         bw_flag_comb; 
reg         lc_flag_comb;       


//state transiton 
always @ (posedge clk or negedge rst_n)
 begin
  if(!rst_n)
   begin
    current_state <= IDLE_STATE;
   end
  else
   begin
    current_state <= next_state;
   end
 end


// next state logic
always @ (*)
 begin
  case(current_state)
  IDLE_STATE: 
        begin
          if (cr_chk_start)
           begin
            next_state = CHK_VTG;
           end
          else
           begin
            next_state = IDLE_STATE; 
           end
				end			  							  			
  CHK_VTG: 
        begin
          if (current_lc_reg == 2'b11)
          begin 
           if ((driving_counter == 'd11) || (same_parameters_counter == 'd6) || (current_vtg_reg == max_vtg_reg))
            begin
             next_state = CHK_RBR;
            end
           else
            begin
             next_state = ADJUST_DRIVING_PARAMETERS;
            end
          end
          else if (current_lc_reg == 2'b01)
          begin 
           if ((driving_counter == 'd11) || (same_parameters_counter == 'd6) || (current_vtg_reg[3:0] == max_vtg_reg[3:0]))
            begin
             next_state = CHK_RBR;
            end
           else
            begin
             next_state = ADJUST_DRIVING_PARAMETERS;
            end
          end
          else
          begin
           if ((driving_counter == 'd11) || (same_parameters_counter == 'd6) || (current_vtg_reg[1:0] == max_vtg_reg[1:0]))
            begin
             next_state = CHK_RBR;
            end
           else
            begin
             next_state = ADJUST_DRIVING_PARAMETERS;
            end            
          end
        end		
  ADJUST_DRIVING_PARAMETERS: 
        begin
            next_state = IDLE_STATE;
        end	          
  CHK_RBR:
        begin
          if (current_bw_reg == 8'h06) // RBR
           begin
            next_state = CHK_LC;
           end
          else
           begin
            next_state = REDUCE_BW;
           end 	 					  
        end
  REDUCE_BW:
        begin
            next_state = IDLE_STATE;          
        end
  CHK_LC: 
        begin
          if (current_lc_reg == 2'b00)  // 1 Lane
           begin
            next_state = CR_FAILED;
           end
          else
           begin
            next_state = REDUCE_LC;
           end 
        end
  REDUCE_LC:
        begin 
            next_state = IDLE_STATE;           
        end
  CR_FAILED:
        begin 
            next_state = IDLE_STATE;    
        end         
  default: 
        begin
            next_state = IDLE_STATE; 
        end	
  endcase                 	   
 end 


// output logic
always @ (*)
 begin
   new_bw_cr_comb          <=  'b0;
   new_lc_cr_comb          <=  'b0;
   err_cr_failed_comb      <= 1'b0;
   drive_setting_flag_comb <= 1'b0;
   bw_flag_comb            <= 1'b0; 
   lc_flag_comb            <= 1'b0;
   current_bw_comb         <=  'b0;
   current_lc_comb         <=  'b0;
  case(current_state)
  IDLE_STATE:
        begin
          new_bw_cr_comb          <=  'b0;
          new_lc_cr_comb          <=  'b0;
          err_cr_failed_comb      <= 1'b0;
          drive_setting_flag_comb <= 1'b0;
          bw_flag_comb            <= 1'b0; 
          lc_flag_comb            <= 1'b0;
          current_bw_comb         <=  'b0;
          current_lc_comb         <=  'b0;
				end			  							  			
  CHK_VTG: 
        begin
          err_cr_failed_comb      <= 1'b0;
          drive_setting_flag_comb <= 1'b0;
          bw_flag_comb            <= 1'b0; 
          lc_flag_comb            <= 1'b0;     					   	  
        end
  ADJUST_DRIVING_PARAMETERS: 
        begin  
          drive_setting_flag_comb <= 1'b1; 
        end		
  CHK_RBR: 
        begin
          err_cr_failed_comb      <= 1'b0;
          drive_setting_flag_comb <= 1'b0;
          bw_flag_comb            <= 1'b0; 
          lc_flag_comb            <= 1'b0;    					   	  
        end				
  REDUCE_BW: 
        begin
          bw_flag_comb            <= 1'b1; 
          if (current_bw_reg == 8'h1E)               // HBR3
           begin
             new_bw_cr_comb       <= 8'h14;
             current_bw_comb      <= 8'h14;
           end
          else if (current_bw_reg == 8'h14)          // HBR2
           begin
             new_bw_cr_comb       <= 8'h0A;
             current_bw_comb      <= 8'h0A;
           end
          else if (current_bw_reg == 8'h0A)          // HBR
           begin
             new_bw_cr_comb       <= 8'h06;
             current_bw_comb      <= 8'h06;
           end
          else                                       // Default
           begin
             new_bw_cr_comb       <= 8'h06;          // RBR
             current_bw_comb      <= 8'h06;
           end 	        
				end
  CHK_LC: 
        begin
          err_cr_failed_comb      <= 1'b0;
          drive_setting_flag_comb <= 1'b0;
          bw_flag_comb            <= 1'b0; 
          lc_flag_comb            <= 1'b0;                          
				end	
  REDUCE_LC: 
        begin
          bw_flag_comb            <= 1'b1;
          lc_flag_comb            <= 1'b1; 
          new_bw_cr_comb          <= max_bw_reg;
          current_bw_comb         <= max_bw_reg;
          if (current_lc_reg == 2'b11)
          begin
            new_lc_cr_comb        <= 2'b01;
            current_lc_comb       <= 2'b01;
          end
          else
          begin
            new_lc_cr_comb        <= 2'b00;
            current_lc_comb       <= 2'b00;            
          end
				end
  CR_FAILED: 
        begin
          err_cr_failed_comb      <= 1'b1; 
				end
  default: 
        begin
          new_bw_cr_comb          <=  'b0;
          new_lc_cr_comb          <=  'b0;
          err_cr_failed_comb      <= 1'b0;
          drive_setting_flag_comb <= 1'b0;
          bw_flag_comb            <= 1'b0; 
          lc_flag_comb            <= 1'b0;
          current_bw_comb         <=  'b0;
          current_lc_comb         <=  'b0;
        end	
  endcase                 	   
 end 


 // **************** Storing Max BW, LC, and Voltage Swing **************** //
always @ (posedge clk or negedge rst_n)
 begin
  if(!rst_n)
   begin
    max_vtg_reg <= 'b0;
    max_bw_reg  <= 'b0;
    max_lc_reg  <= 'b0;    
   end
  else
   begin
    if (config_param_vld)
	   begin
      max_vtg_reg <= {max_vtg, max_vtg, max_vtg, max_vtg};	  // For 4 Lanes
      max_bw_reg  <= link_bw_cr;
      max_lc_reg  <= link_lc_cr;
	   end
   end
 end

 // **************** Storing the current vtg and pre **************** //
always @ (posedge clk or negedge rst_n)
 begin
  if(!rst_n)
   begin
    current_vtg_reg <= 'b0;
    current_pre_reg <= 'b0;    
   end
  else
   begin
    if (cr_chk_start)
	   begin
      current_vtg_reg <= adj_vtg;
      current_pre_reg <= adj_pre;
	   end
   end
 end

 // **************** Storing the previous vtg and pre **************** //
always @ (posedge clk or negedge rst_n)
 begin
  if(!rst_n)
   begin
    previous_vtg_reg <= 'b0;
    previous_pre_reg <= 'b0;    
   end
  else
   begin
    if (next_state == IDLE_STATE)
	   begin
      previous_vtg_reg <= current_vtg_reg;
      previous_pre_reg <= current_pre_reg;
	   end
   end
 end

 // **************** Storing the current BW and LC **************** //
always @ (posedge clk or negedge rst_n)
 begin
  if(!rst_n)
   begin
    current_bw_reg <= 'b0;
    current_lc_reg <= 'b0;    
   end
  else
   begin
    if (config_param_vld)
	   begin
      current_bw_reg <= link_bw_cr;
      current_lc_reg <= link_lc_cr;
	   end
    else if (current_state == REDUCE_BW)
	   begin
      current_bw_reg <= current_bw_comb;
	   end
    else if (current_state == REDUCE_LC)
	   begin
      current_lc_reg <= current_lc_comb;
	   end
   end
 end

 // **************** Update driving_counter **************** //
always @ (posedge clk or negedge rst_n)
 begin
  if((!rst_n) || (cr_completed) || (fsm_cr_failed))
   begin
    driving_counter <= 'b0;    
   end
  else if (current_state == CHK_VTG)
   begin
    driving_counter <= driving_counter + 1;
   end
 end

 // **************** Update same_parameters_counter **************** //
always @ (posedge clk or negedge rst_n)
 begin
  if((!rst_n) || (cr_completed) || (fsm_cr_failed))
   begin
    same_parameters_counter <= 1'b0;    
   end
  else if ((current_state == CHK_VTG) && (current_vtg_reg == previous_vtg_reg) && (current_pre_reg == previous_pre_reg))
   begin
    same_parameters_counter <= same_parameters_counter + 1;  
   end
 end

 // **************** Make the output signals sequential **************** //
 always @ (posedge clk or negedge rst_n)
  begin
  if(!rst_n)
   begin 
    new_bw_cr          <=  'b0;
    new_lc_cr          <=  'b0;
    err_cr_failed      <= 1'b0;
    drive_setting_flag <= 1'b0;
    bw_flag            <= 1'b0; 
    lc_flag            <= 1'b0;
   end
  else
	 begin	
    new_bw_cr          <= new_bw_cr_comb;
    new_lc_cr          <= new_lc_cr_comb;
    err_cr_failed      <= err_cr_failed_comb;
    drive_setting_flag <= drive_setting_flag_comb;
    bw_flag            <= bw_flag_comb; 
    lc_flag            <= lc_flag_comb;
	 end 
  end 

endmodule