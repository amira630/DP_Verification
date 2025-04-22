/////////////////////////////////////////////////////////////////////////////////////////////////////
// Block Name:  CR FSM
//
// Author:      Mohamed Alaa
//
// Discription: The CR FSM block is the primary component that initiates the link 
//              training process by executing the clock recovery phase, which is the 
//              first step in link training. This phase is crucial for synchronizing the 
//              source and sink to the same clock, as there is no dedicated clock line between them. 
/////////////////////////////////////////////////////////////////////////////////////////////////////

module cr_fsm 
(
  ////////////////// Inputs //////////////////
  input  wire        clk,
  input  wire        rst_n,  
  // LPM
  input  wire        lpm_start_cr, 
  input  wire        driving_param_vld,
  input  wire        config_param_vld,            
  input  wire [7:0]  vtg,
  input  wire [7:0]  pre,
  input  wire [7:0]  link_bw_cr,
  input  wire [1:0]  link_lc_cr,
  input  wire        cr_done_vld,                
  input  wire [3:0]  cr_done,
  input  wire [1:0]  max_vtg,                    
  input  wire [1:0]  max_pre,                     
  // CR ERR CHK 
  input  wire [7:0]  new_bw_cr,
  input  wire [1:0]  new_lc_cr,  
  input  wire        err_cr_failed, 
  input  wire        drive_setting_flag,
  input  wire        bw_Flag, 
  input  wire        lc_Flag, 
  // EQ ERR CHK
  input  wire [7:0]  new_bw_eq,
  input  wire [1:0]  new_lc_eq,  
  input  wire        err_chk_cr_start, 
  // CTR
  input  wire        cr_ctr_fire, 
  // AUX CTRL Unit
  input  wire        ctrl_ack_flag, 
  input  wire        ctrl_native_failed,         

  ////////////////// Outputs //////////////////
  // LPM & CR ERR CHK
  output reg         fsm_cr_failed,
  output reg         cr_completed,                    
  // CR ERR CHK
  output reg         cr_chk_start,   
  output reg  [7:0]  adj_vtg,
  output reg  [7:0]  adj_pre,
  // CTR
  output reg         cr_ctr_start,  
  // AUX CTRL Unit
  output reg         cr_transaction_vld, 
  output reg  [1:0]  cr_cmd,
  output reg  [19:0] cr_address,
  output reg  [7:0]  cr_len,
  output reg  [7:0]  cr_data,
  // EQ FSM
  output reg         eq_start,   
  output reg  [7:0]  new_vtg,
  output reg  [7:0]  new_pre,
  output reg  [7:0]  new_bw,
  output reg  [1:0]  new_lc,
  // PHY Layer
  output reg  [1:0]  cr_phy_instruct,
  output reg         cr_phy_instruct_vld,
  output reg  [1:0]  cr_adj_lc, 
  output reg  [7:0]  cr_adj_bw 
);
  
// State encoding (Gray Code)
typedef enum reg [4:0] {
  IDLE_STATE                          = 5'b00000,  
  SINK_CONFIGURATION_BYTE_ONE         = 5'b00001,  
  SINK_CONFIGURATION_BYTE_TWO         = 5'b00011,  
  SINK_CONFIGURATION_BYTE_THREE       = 5'b00010, 
  WAIT_REPLY_ACK_SINK_CONFIGURATION   = 5'b00110,  
  PHY_CONFIGURATION                   = 5'b00111,  
  WAIT_REPLY_ACK_PHY_CONFIGURATION    = 5'b00101,  
  DRIVING_PARAMETERS_SET_LANE0        = 5'b00100,  
  DRIVING_PARAMETERS_SET_LANE1        = 5'b01100,  
  DRIVING_PARAMETERS_SET_LANE2        = 5'b01101,  
  DRIVING_PARAMETERS_SET_LANE3        = 5'b01111,  
  WAIT_REPLY_ACK_DRIVING_PARAMETERS   = 5'b01110,  
  WAIT_CTR_FIRE                       = 5'b01010,  
  READ_CR_RESULT                      = 5'b01011,  
  WAIT_REPLY_ACK_READ_CR_RESULT       = 5'b01001,  
  WAIT_REPLY_DATA_READ_CR_RESULT      = 5'b01000,  
  CHK_CR_RESULTS                      = 5'b11000,  
  READ_ADJUSTED_DRIVING_PARAMETERS    = 5'b11001,  
  WAIT_REPLY_ACK_ADJUSTED_PARAMETERS  = 5'b11011,  
  WAIT_REPLY_DATA_ADJUSTED_PARAMETERS = 5'b11010,  
  EQ_START                            = 5'b11110,
  CR_ERR_CHK_START                    = 5'b11111,  
  CR_FAILED                           = 5'b10111   
} state_t;


// Internal Signals
state_t     current_state, next_state;

reg [3:0]  cr_done_reg;
reg [7:0]  vtg_reg;
reg [7:0]  pre_reg;
reg [1:0]  max_vtg_reg;
reg [1:0]  max_pre_reg;
reg [7:0]  link_bw_cr_reg;
reg [4:0]  link_lc_cr_reg;

reg         fsm_cr_failed_comb;
reg         cr_completed_comb;
reg         cr_chk_start_comb;  
reg  [7:0]  adj_vtg_comb;
reg  [7:0]  adj_pre_comb;
reg         cr_ctr_start_comb; 
reg         cr_transaction_vld_comb;
reg  [1:0]  cr_cmd_comb;
reg  [19:0] cr_address_comb;
reg  [7:0]  cr_len_comb;
reg  [7:0]  cr_data_comb;
reg         eq_start_comb;  
reg  [7:0]  new_vtg_comb;
reg  [7:0]  new_pre_comb;
reg  [7:0]  new_bw_comb;
reg  [1:0]  new_lc_comb;
reg  [1:0]  cr_phy_instruct_comb;
reg         cr_phy_instruct_vld_comb;
reg  [1:0]  cr_adj_lc_comb;
reg  [7:0]  cr_adj_bw_comb;      


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
          if ((lpm_start_cr) || (bw_Flag || lc_Flag) || (err_chk_cr_start))
          begin
            next_state = SINK_CONFIGURATION_BYTE_ONE;
          end
          else if (drive_setting_flag)
          begin
            next_state = DRIVING_PARAMETERS_SET_LANE0;
          end
          else if (err_cr_failed)
          begin
            next_state = CR_FAILED;
          end
          else
          begin
            next_state = IDLE_STATE; 
          end
				end			  							  			
  SINK_CONFIGURATION_BYTE_ONE: 
        begin
            next_state = SINK_CONFIGURATION_BYTE_TWO;
        end		
  SINK_CONFIGURATION_BYTE_TWO: 
        begin
            next_state = SINK_CONFIGURATION_BYTE_THREE;
        end	          
  SINK_CONFIGURATION_BYTE_THREE:
        begin
			      next_state = WAIT_REPLY_ACK_SINK_CONFIGURATION; 	 					  
        end
  WAIT_REPLY_ACK_SINK_CONFIGURATION:
        begin
				 if(ctrl_ack_flag)
			      begin
              next_state = PHY_CONFIGURATION; 			
            end
			    else if (ctrl_native_failed)
			      begin
              next_state = IDLE_STATE; 	
            end	 
			    else
			      begin
              next_state = WAIT_REPLY_ACK_SINK_CONFIGURATION; 	
            end	          
        end
  PHY_CONFIGURATION: 
        begin
          next_state = WAIT_REPLY_ACK_PHY_CONFIGURATION;
        end
  WAIT_REPLY_ACK_PHY_CONFIGURATION:
        begin
				 if(ctrl_ack_flag)
			      begin
              next_state = DRIVING_PARAMETERS_SET_LANE0; 				
            end
			    else if (ctrl_native_failed)
			      begin
              next_state = IDLE_STATE; 	
            end
			     else
			      begin
              next_state = WAIT_REPLY_ACK_PHY_CONFIGURATION; 	
            end	          
        end
  DRIVING_PARAMETERS_SET_LANE0: 
        begin
          if (link_lc_cr_reg == 'b00)
           begin
            next_state = WAIT_REPLY_ACK_DRIVING_PARAMETERS;
           end
          else
           begin
            next_state = DRIVING_PARAMETERS_SET_LANE1;
           end
        end		
  DRIVING_PARAMETERS_SET_LANE1: 
        begin
          if (link_lc_cr_reg == 'b01)
           begin
            next_state = WAIT_REPLY_ACK_DRIVING_PARAMETERS;
           end
          else
           begin
            next_state = DRIVING_PARAMETERS_SET_LANE2;
           end
        end	          
  DRIVING_PARAMETERS_SET_LANE2:
        begin
			      next_state = DRIVING_PARAMETERS_SET_LANE3; 	 					  
        end
  DRIVING_PARAMETERS_SET_LANE3:
        begin
			      next_state = WAIT_REPLY_ACK_DRIVING_PARAMETERS; 	 					  
        end
  WAIT_REPLY_ACK_DRIVING_PARAMETERS:
        begin
				 if(ctrl_ack_flag)
			      begin
              next_state = WAIT_CTR_FIRE; 			
            end
			    else if (ctrl_native_failed)
			      begin
              next_state = IDLE_STATE; 	
            end	 
			    else
			      begin
              next_state = WAIT_REPLY_ACK_DRIVING_PARAMETERS; 	
            end	          
        end
  WAIT_CTR_FIRE:
        begin
				 if(cr_ctr_fire)
			      begin
              next_state = READ_CR_RESULT; 
            end
			     else
			      begin
              next_state = WAIT_CTR_FIRE; 	
            end	 
        end         
  READ_CR_RESULT: 
        begin
          next_state = WAIT_REPLY_ACK_READ_CR_RESULT;
        end
  WAIT_REPLY_ACK_READ_CR_RESULT:
        begin
				 if(ctrl_ack_flag)
            begin
              next_state = WAIT_REPLY_DATA_READ_CR_RESULT;			
            end
			    else if (ctrl_native_failed)
			      begin
              next_state = IDLE_STATE; 	
            end
			     else
			      begin
              next_state = WAIT_REPLY_ACK_READ_CR_RESULT; 	  
            end	          
        end
  WAIT_REPLY_DATA_READ_CR_RESULT:
        begin
				 if(cr_done_vld)
            begin
              next_state = CHK_CR_RESULTS;			
            end
			     else
			      begin
              next_state = WAIT_REPLY_DATA_READ_CR_RESULT; 	
            end	          
        end
  CHK_CR_RESULTS:
        begin
				 if((link_lc_cr_reg == 'b11) && (&cr_done_reg))
            begin
              next_state = EQ_START;			
            end
          else if((link_lc_cr_reg == 'b01) && (&cr_done_reg[1:0]))
            begin
              next_state = EQ_START;			
            end
          else if((link_lc_cr_reg == 'b00) && (cr_done_reg[0]))
            begin
              next_state = EQ_START;			
            end
          else if(link_lc_cr_reg == 'b10)   // Error Value of LC so it goes to the IDLE STATE 
            begin
              next_state = IDLE_STATE;			
            end
			     else
			      begin
              next_state = READ_ADJUSTED_DRIVING_PARAMETERS; 	
            end	          
        end
  READ_ADJUSTED_DRIVING_PARAMETERS: 
        begin
          next_state = WAIT_REPLY_ACK_ADJUSTED_PARAMETERS;
        end
  WAIT_REPLY_ACK_ADJUSTED_PARAMETERS:
        begin
				 if(ctrl_ack_flag)
            begin
              next_state = WAIT_REPLY_DATA_ADJUSTED_PARAMETERS;			
            end
			    else if (ctrl_native_failed)
			      begin
              next_state = IDLE_STATE; 	
            end
			     else
			      begin
              next_state = WAIT_REPLY_ACK_ADJUSTED_PARAMETERS; 	
            end	          
        end
  WAIT_REPLY_DATA_ADJUSTED_PARAMETERS:
        begin
				 if(driving_param_vld)
            begin
              next_state = CR_ERR_CHK_START;			
            end
			     else
			      begin
              next_state = WAIT_REPLY_DATA_ADJUSTED_PARAMETERS; 	
            end	          
        end
  EQ_START: 
        begin
          next_state = IDLE_STATE;   
        end
  CR_ERR_CHK_START: 
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
   fsm_cr_failed_comb       = 1'b0; 
   cr_completed_comb        = 1'b0;  
   cr_chk_start_comb        = 1'b0;   
   adj_vtg_comb             =  'b0;
   adj_pre_comb             =  'b0;
   cr_ctr_start_comb        = 1'b0;  
   cr_transaction_vld_comb  = 1'b0; 
   cr_cmd_comb              =  'b0;
   cr_address_comb          =  'b0;
   cr_len_comb              =  'b0;
   cr_data_comb             =  'b0;
   eq_start_comb            = 1'b0;   
   new_vtg_comb             =  'b0;
   new_pre_comb             =  'b0;
   new_bw_comb              =  'b0;
   new_lc_comb              =  'b0;
   cr_phy_instruct_comb     =  'b0;
   cr_phy_instruct_vld_comb = 1'b0;
   cr_adj_lc_comb           =  'b0; 
   cr_adj_bw_comb           =  'b0;
  case(current_state)
  IDLE_STATE:
        begin
          // LPM & CR ERR CHK
          fsm_cr_failed_comb        = 1'b0; 
          cr_completed_comb         = 1'b0;
          // CR ERR CHK
          cr_chk_start_comb         = 1'b0;   
          adj_vtg_comb              =  'b0;
          adj_pre_comb              =  'b0;
          // CTR 
          cr_ctr_start_comb         = 1'b0; 
          // AUX CTRL UNIT 
          cr_transaction_vld_comb   = 1'b0; 
          cr_cmd_comb               =  'b0;
          cr_address_comb           =  'b0;
          cr_len_comb               =  'b0;
          cr_data_comb              =  'b0;
          // EQ FSM
          eq_start_comb             = 1'b0;   
          new_vtg_comb              =  'b0;
          new_pre_comb              =  'b0;
          new_bw_comb               =  'b0;
          new_lc_comb               =  'b0;
          // PhY
          cr_phy_instruct_comb      =  'b0;
          cr_phy_instruct_vld_comb  = 1'b0;
          cr_adj_lc_comb            =  'b0; 
          cr_adj_bw_comb            =  'b0;
				end			  							  			
  SINK_CONFIGURATION_BYTE_ONE: 
        begin
          cr_transaction_vld_comb   = 1'b1; 
          cr_cmd_comb               = 2'b00;
          cr_address_comb           =  'h00100;
          cr_len_comb               =  'b0000_0010;
          cr_data_comb              = link_bw_cr_reg;       					   	  
        end
  SINK_CONFIGURATION_BYTE_TWO: 
        begin
          cr_transaction_vld_comb   = 1'b1;
          cr_data_comb              = {3'b100, 5'(link_lc_cr_reg + 5'b01)};
        end		
  SINK_CONFIGURATION_BYTE_THREE: 
        begin
          cr_transaction_vld_comb   = 1'b1; 
          cr_data_comb              =  'h00; 					   	  
        end				
  WAIT_REPLY_ACK_SINK_CONFIGURATION: 
        begin
          cr_transaction_vld_comb   = 1'b0;         
				end
  PHY_CONFIGURATION: 
        begin
          cr_phy_instruct_comb      = 2'b00;
          cr_phy_instruct_vld_comb  = 1'b1;
          cr_adj_lc_comb            = link_lc_cr_reg[1:0]; 
          cr_adj_bw_comb            = link_bw_cr_reg;
          cr_transaction_vld_comb   = 1'b1; 
          cr_cmd_comb               = 2'b00;
          cr_address_comb           =  'h00102;
          cr_len_comb               =  'b0000_0000;
          cr_data_comb              =  'h21;                           
				end	
  WAIT_REPLY_ACK_PHY_CONFIGURATION: 
        begin
          cr_phy_instruct_vld_comb  = 1'b0;
          cr_transaction_vld_comb   = 1'b0;            
				end
  DRIVING_PARAMETERS_SET_LANE0: 
        begin
          cr_transaction_vld_comb   = 1'b1; 
          cr_cmd_comb               = 2'b00;
          cr_address_comb           =  'h00103;
          if (link_lc_cr_reg == 'b11)
           begin
            cr_len_comb             =  'b0000_0011;
           end
          else if (link_lc_cr_reg == 'b01)
           begin
            cr_len_comb             =  'b0000_0001;
           end
          else
           begin
            cr_len_comb             =  'b0000_0000;
           end
          if ((vtg_reg[1:0] == max_vtg_reg) && (pre_reg[1:0] == max_pre_reg))
           begin
            cr_data_comb            = {2'b00, 1'b1, pre_reg[1:0], 1'b1, vtg_reg[1:0]};
           end
          else if ((vtg_reg[1:0] == max_vtg_reg))
           begin
            cr_data_comb            = {2'b00, 1'b0, pre_reg[1:0], 1'b1, vtg_reg[1:0]};
           end
          else if ((pre_reg[1:0] == max_pre_reg))
           begin
            cr_data_comb            = {2'b00, 1'b1, pre_reg[1:0], 1'b0, vtg_reg[1:0]};
           end
          else
           begin
            cr_data_comb            = {2'b00, 1'b0, pre_reg[1:0], 1'b0, vtg_reg[1:0]};
           end     					   	  
        end
  DRIVING_PARAMETERS_SET_LANE1: 
        begin
          cr_transaction_vld_comb   = 1'b1; 
          if ((vtg_reg[3:2] == max_vtg_reg) && (pre_reg[3:2] == max_pre_reg))
           begin
            cr_data_comb            = {2'b00, 1'b1, pre_reg[3:2], 1'b1, vtg_reg[3:2]};
           end
          else if ((vtg_reg[3:2] == max_vtg_reg))
           begin
            cr_data_comb            = {2'b00, 1'b0, pre_reg[3:2], 1'b1, vtg_reg[3:2]};
           end
          else if ((pre_reg[3:2] == max_pre_reg))
           begin
            cr_data_comb            = {2'b00, 1'b1, pre_reg[3:2], 1'b0, vtg_reg[3:2]};
           end
          else
           begin
            cr_data_comb            = {2'b00, 1'b0, pre_reg[3:2], 1'b0, vtg_reg[3:2]};
           end  
        end		
  DRIVING_PARAMETERS_SET_LANE2: 
        begin
          cr_transaction_vld_comb   = 1'b1; 
          if ((vtg_reg[5:4] == max_vtg_reg) && (pre_reg[5:4] == max_pre_reg))
           begin
            cr_data_comb            = {2'b00, 1'b1, pre_reg[5:4], 1'b1, vtg_reg[5:4]};
           end
          else if ((vtg_reg[5:4] == max_vtg_reg))
           begin
            cr_data_comb            = {2'b00, 1'b0, pre_reg[5:4], 1'b1, vtg_reg[5:4]};
           end
          else if ((pre_reg[5:4] == max_pre_reg))
           begin
            cr_data_comb            = {2'b00, 1'b1, pre_reg[5:4], 1'b0, vtg_reg[5:4]};
           end
          else
           begin
            cr_data_comb            = {2'b00, 1'b0, pre_reg[5:4], 1'b0, vtg_reg[5:4]};
           end 					   	  
        end		
  DRIVING_PARAMETERS_SET_LANE3: 
        begin
          cr_transaction_vld_comb   = 1'b1; 
          if ((vtg_reg[7:6] == max_vtg_reg) && (pre_reg[7:6] == max_pre_reg))
           begin
            cr_data_comb            = {2'b00, 1'b1, pre_reg[7:6], 1'b1, vtg_reg[7:6]};
           end
          else if ((vtg_reg[7:6] == max_vtg_reg))
           begin
            cr_data_comb            = {2'b00, 1'b0, pre_reg[7:6], 1'b1, vtg_reg[7:6]};
           end
          else if ((pre_reg[7:6] == max_pre_reg))
           begin
            cr_data_comb            = {2'b00, 1'b1, pre_reg[7:6], 1'b0, vtg_reg[7:6]};
           end
          else
           begin
            cr_data_comb            = {2'b00, 1'b0, pre_reg[7:6], 1'b0, vtg_reg[7:6]};
           end					   	  
        end				
  WAIT_REPLY_ACK_DRIVING_PARAMETERS: 
        begin
          cr_transaction_vld_comb   = 1'b0;         
				end
  WAIT_CTR_FIRE: 
        begin
          cr_ctr_start_comb         = 1'b1; 
				end
  READ_CR_RESULT: 
        begin
          cr_transaction_vld_comb   = 1'b1; 
          cr_cmd_comb               = 2'b01;
          cr_address_comb           =  'h00202;
          cr_len_comb               =  'b0000_0001;
          cr_data_comb              =  'h00;    
				end
  WAIT_REPLY_ACK_READ_CR_RESULT: 
        begin
          cr_transaction_vld_comb   = 1'b0; 
				end
  WAIT_REPLY_DATA_READ_CR_RESULT: 
        begin
          cr_transaction_vld_comb   = 1'b0;    
				end
  CHK_CR_RESULTS: 
        begin
          cr_transaction_vld_comb   = 1'b0; 
				end
  READ_ADJUSTED_DRIVING_PARAMETERS: 
        begin
          cr_transaction_vld_comb   = 1'b1; 
          cr_cmd_comb               = 2'b01;
          cr_address_comb           =  'h00206;
          cr_len_comb               =  'b0000_0001;
          cr_data_comb              =  'h00;    
				end
  WAIT_REPLY_ACK_ADJUSTED_PARAMETERS: 
        begin
          cr_transaction_vld_comb   = 1'b0; 
				end
  WAIT_REPLY_DATA_ADJUSTED_PARAMETERS: 
        begin
          cr_transaction_vld_comb   = 1'b0;      
				end
  EQ_START: 
        begin
          eq_start_comb            = 1'b1;   
          new_vtg_comb             = vtg_reg;
          new_pre_comb             = pre_reg;
          new_bw_comb              = link_bw_cr_reg;
          new_lc_comb              = link_lc_cr_reg[1:0];  
          cr_completed_comb        = 1'b1;  
				end
  CR_ERR_CHK_START: 
        begin
          cr_chk_start_comb        = 1'b1;   
          adj_vtg_comb             = vtg_reg;
          adj_pre_comb             = pre_reg;    
				end
  CR_FAILED: 
        begin
          fsm_cr_failed_comb       = 1'b1;      
				end
  default: 
        begin
          fsm_cr_failed_comb       = 1'b0; 
          cr_completed_comb        = 1'b0;
          cr_chk_start_comb        = 1'b0;   
          adj_vtg_comb             =  'b0;
          adj_pre_comb             =  'b0;
          cr_ctr_start_comb        = 1'b0;  
          cr_transaction_vld_comb  = 1'b0; 
          cr_cmd_comb              =  'b0;
          cr_address_comb          =  'b0;
          cr_len_comb              =  'b0;
          cr_data_comb             =  'b0;
          eq_start_comb            = 1'b0;   
          new_vtg_comb             =  'b0;
          new_pre_comb             =  'b0;
          new_bw_comb              =  'b0;
          new_lc_comb              =  'b0;
          cr_phy_instruct_comb     =  'b0;
          cr_phy_instruct_vld_comb = 1'b0;
          cr_adj_lc_comb           =  'b0; 
          cr_adj_bw_comb           =  'b0;
        end	
  endcase                 	   
 end 


// **************** Storing CR_DONE Bits from the Link Policy Maker **************** //
always @ (posedge clk or negedge rst_n)
 begin
  if(!rst_n)
   begin
    cr_done_reg <= 'b0;
   end
  else
   begin
    if (cr_done_vld)
	   begin	
      cr_done_reg <= cr_done;
	   end 
   end
 end

// **************** Storing VTG and PRE from the Link Policy Maker **************** //
always @ (posedge clk or negedge rst_n)
 begin
  if(!rst_n)
   begin
    vtg_reg <= 'b0;
    pre_reg <= 'b0;
   end
  else
   begin
    if (driving_param_vld)
	   begin	
      vtg_reg <= vtg;
      pre_reg <= pre;
	   end 
   end
 end

 // **************** Storing BW and LC **************** //
always @ (posedge clk or negedge rst_n)
 begin
  if(!rst_n)
   begin
    link_bw_cr_reg <= 'b0;
    link_lc_cr_reg <= 'b0;
    max_vtg_reg    <= 'b0;
    max_pre_reg    <= 'b0;
   end
  else
   begin
    if (config_param_vld)
	   begin	
      link_bw_cr_reg <= link_bw_cr;
      link_lc_cr_reg <= link_lc_cr;
      max_vtg_reg    <= max_vtg;
      max_pre_reg    <= max_pre;
	   end
     else if (err_chk_cr_start)
	   begin	
      link_bw_cr_reg <= new_bw_eq;
      link_lc_cr_reg <= new_lc_eq;
	   end 
     else if (bw_Flag && lc_Flag)
	   begin	
      link_lc_cr_reg <= new_lc_cr;
	   end
     else if (bw_Flag)
	   begin
      link_bw_cr_reg <= new_bw_cr;	
	   end
   end
 end

 // **************** Make the output signals sequential **************** //
 always @ (posedge clk or negedge rst_n)
  begin
  if(!rst_n)
   begin
    fsm_cr_failed       <= 1'b0; 
    cr_completed        <= 1'b0;
    cr_chk_start        <= 1'b0;   
    adj_vtg             <=  'b0;
    adj_pre             <=  'b0;
    cr_ctr_start        <= 1'b0;  
    cr_transaction_vld  <= 1'b0; 
    cr_cmd              <=  'b0;
    cr_address          <=  'b0;
    cr_len              <=  'b0;
    cr_data             <=  'b0;
    eq_start            <= 1'b0;   
    new_vtg             <=  'b0;
    new_pre             <=  'b0;
    new_bw              <=  'b0;
    new_lc              <=  'b0;
    cr_phy_instruct     <=  'b0;
    cr_phy_instruct_vld <= 1'b0;
    cr_adj_lc           <=  'b0; 
    cr_adj_bw           <=  'b0;
   end
  else
	 begin	
    fsm_cr_failed       <= fsm_cr_failed_comb;
    cr_completed        <= cr_completed_comb;
    cr_chk_start        <= cr_chk_start_comb;  
    adj_vtg             <= adj_vtg_comb;
    adj_pre             <= adj_pre_comb;
    cr_ctr_start        <= cr_ctr_start_comb; 
    cr_transaction_vld  <= cr_transaction_vld_comb; 
    cr_cmd              <= cr_cmd_comb;
    cr_address          <= cr_address_comb;
    cr_len              <= cr_len_comb;
    cr_data             <= cr_data_comb;
    eq_start            <= eq_start_comb;  
    new_vtg             <= new_vtg_comb;
    new_pre             <= new_pre_comb;
    new_bw              <= new_bw_comb;
    new_lc              <= new_lc_comb;
    cr_phy_instruct     <= cr_phy_instruct_comb;
    cr_phy_instruct_vld <= cr_phy_instruct_vld_comb;
    cr_adj_lc           <= cr_adj_lc_comb;
    cr_adj_bw           <= cr_adj_bw_comb;
	 end 
  end 

endmodule