////////////////////////////////////////////////////////////////////////////////
// Block Name:  Aux CTRL Unit
//
// Author:      Mohamed Alaa
//
// Discription: This Block is responsible for managing request and reply 
//              transactions for both transaction types - Native 
//              transactions and I2C-over-AUX transactions 
////////////////////////////////////////////////////////////////////////////////

module aux_ctrl_unit 
(
  // Inputs
  input  wire        clk,
  input  wire        rst_n,  
  input  wire        spm_transaction_vld, 
  input  wire [1:0]  spm_cmd,
  input  wire [19:0] spm_address,
  input  wire [7:0]  spm_len,
  input  wire [7:0]  spm_data,
  input  wire        lpm_transaction_vld, 
  input  wire [1:0]  lpm_cmd,
  input  wire [19:0] lpm_address,
  input  wire [7:0]  lpm_len,
  input  wire [7:0]  lpm_data,
  input  wire        cr_transaction_vld, 
  input  wire [1:0]  cr_cmd,
  input  wire [19:0] cr_address,
  input  wire [7:0]  cr_len,
  input  wire [7:0]  cr_data,
  input  wire        eq_transaction_vld, 
  input  wire [1:0]  eq_cmd,
  input  wire [19:0] eq_address,
  input  wire [7:0]  eq_len,
  input  wire [7:0]  eq_data,
  input  wire        reply_data_vld,   
  input  wire [7:0]  reply_data,       
  input  wire [1:0]  reply_ack,
  input  wire        reply_ack_vld,  
  input  wire        timer_timeout,
  input  wire        i2c_complete,
  input  wire        i2c_fsm_failed,   
  // Outputs
  output reg         ctrl_tr_vld, 
  output reg  [1:0]  ctrl_msg_cmd,
  output reg  [19:0] ctrl_msg_address,
  output reg  [7:0]  ctrl_msg_len,
  output reg  [7:0]  ctrl_msg_data,
  output reg  [7:0]  ctrl_done_data_number, 
  output reg         ctrl_native_retrans,
  output reg         ctrl_ack_flag,
  output reg         ctrl_i2c_native,
  output reg         ctrl_native_failed,   
  output reg         ctrl_i2c_failed       
);
  
// state encoding (Gray Code)
typedef enum reg [3:0] 
{
  IDLE_MODE                            = 4'b0000, 
  NATIVE_TALK_MODE_ONE_DATA_BYTE       = 4'b0001,  
  NATIVE_TALK_MODE_MULTIPLE_DATA_BYTES = 4'b0011,  
  NATIVE_LISTEN_MODE_WAIT_ACK          = 4'b0010,  
  NATIVE_LISTEN_MODE_WAIT_DATA         = 4'b0110,  
  NATIVE_RETRANS_MODE                  = 4'b0111,  
  NATIVE_FAILED_TRANSACTION            = 4'b0101,  
  I2C_TALK_MODE                        = 4'b1101,  
  I2C_LISTEN_MODE                      = 4'b1111,  
  I2C_FAILED_TRANSACTION               = 4'b1110   
} state_t;

// Internal Signals
state_t     current_state, next_state;
reg [1:0]   cmd_saved_reg;
reg         cmd_save;
reg [7:0]   nack_data_number_reg;
reg         nack_data_number_save;
reg         link_training_flag;
reg [2:0]   defer_counter;
reg [7:0]   data_counter;

reg [1:0]   cmd_reg;
reg [19:0]  address_reg;
reg [7:0]   len_reg;
reg [7:0]   data_reg;

reg         ctrl_tr_vld_comb; 
reg  [1:0]  ctrl_msg_cmd_comb;
reg  [19:0] ctrl_msg_address_comb;
reg  [7:0]  ctrl_msg_len_comb;
reg  [7:0]  ctrl_msg_data_comb;
reg  [7:0]  ctrl_done_data_number_comb; 
reg         ctrl_native_retrans_comb;
reg         ctrl_ack_flag_comb;
reg         ctrl_i2c_native_comb;
reg         ctrl_native_failed_comb;   
reg         ctrl_i2c_failed_comb;      


//state transiton 
always @ (posedge clk or negedge rst_n)
 begin
  if(!rst_n)
   begin
    current_state <= IDLE_MODE;
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
  IDLE_MODE: 
        begin
          if (lpm_transaction_vld || cr_transaction_vld || eq_transaction_vld)
          begin
            next_state = NATIVE_TALK_MODE_ONE_DATA_BYTE;
          end
          else if (spm_transaction_vld)
          begin
            next_state = I2C_TALK_MODE;
          end
          else
          begin
            next_state = IDLE_MODE;
          end
				end			  							  			
  NATIVE_TALK_MODE_ONE_DATA_BYTE: 
        begin
          if (((lpm_transaction_vld || cr_transaction_vld || eq_transaction_vld) && (len_reg == 8'b00000000)) || ( cmd_reg == 2'b01))
          begin
            next_state = NATIVE_LISTEN_MODE_WAIT_ACK;
          end
          else 
          begin
            next_state = NATIVE_TALK_MODE_MULTIPLE_DATA_BYTES;
          end
        end		
  NATIVE_TALK_MODE_MULTIPLE_DATA_BYTES: 
        begin
          if (data_counter == 'b1)
          begin
            next_state = NATIVE_LISTEN_MODE_WAIT_ACK;
          end
          else
          begin
            next_state = NATIVE_TALK_MODE_MULTIPLE_DATA_BYTES;
          end
        end	          
  NATIVE_LISTEN_MODE_WAIT_ACK:
        begin
          if(timer_timeout)
			      begin
			        next_state = NATIVE_RETRANS_MODE; 				
            end
				   else if(reply_ack_vld)
			      begin
			        next_state = NATIVE_LISTEN_MODE_WAIT_DATA; 				
            end
			     else
			      begin
			        next_state = NATIVE_LISTEN_MODE_WAIT_ACK; 			
            end			  
        end
  NATIVE_LISTEN_MODE_WAIT_DATA:
        begin
				 if(reply_data_vld)
			      begin
			        next_state = NATIVE_LISTEN_MODE_WAIT_DATA; 				
            end
			     else
			      begin
              if (cmd_saved_reg == 'b00)
                  begin
                    next_state = IDLE_MODE; 	
                  end	
              else if (cmd_saved_reg == 'b01)  // NACK
                  begin 
                    next_state = NATIVE_RETRANS_MODE; 
                  end
              else if ((cmd_saved_reg == 'b10) && (defer_counter != 'b111))  // DEFER
                  begin 
                    next_state = NATIVE_RETRANS_MODE; 
                  end
              else if (defer_counter == 'b111)
                  begin 
                    next_state = NATIVE_FAILED_TRANSACTION; 
                  end
            end	          
        end
  NATIVE_RETRANS_MODE: 
        begin
            next_state = NATIVE_LISTEN_MODE_WAIT_ACK;
        end
  NATIVE_FAILED_TRANSACTION:
        begin
            next_state = IDLE_MODE;
        end
  I2C_TALK_MODE: 
        begin
            next_state = I2C_LISTEN_MODE;
        end  
  I2C_LISTEN_MODE: 
        begin	
          if (i2c_complete) 
          begin
            next_state = IDLE_MODE;
          end
          else if (i2c_fsm_failed) 
          begin
            next_state = I2C_FAILED_TRANSACTION;
          end
          else
          begin
            next_state = I2C_LISTEN_MODE;
          end
        end
  I2C_FAILED_TRANSACTION:
        begin
            next_state = IDLE_MODE;
        end
  default: 
        begin
          next_state = IDLE_MODE; 
        end	
  endcase                 	   
 end 

// output logic
always @ (*)
 begin
	 ctrl_tr_vld_comb           = 1'b0;
   ctrl_msg_cmd_comb          =  'b0;
	 ctrl_msg_address_comb      =  'b0;  
	 ctrl_msg_len_comb          =  'b0; 
	 ctrl_msg_data_comb         =  'b0;
	 ctrl_native_retrans_comb   = 1'b0;
	 ctrl_ack_flag_comb         = 1'b0;
	 ctrl_i2c_native_comb       = 1'b0;
   cmd_save                   = 1'b0;
   ctrl_native_failed_comb    = 1'b0;
   ctrl_i2c_failed_comb       = 1'b0; 
   ctrl_done_data_number_comb = 1'b0;
   nack_data_number_save      = 1'b0;
  case(current_state)
  IDLE_MODE:
        begin
				  ctrl_tr_vld_comb           = 1'b0;
          ctrl_msg_cmd_comb          =  'b0;
				  ctrl_msg_address_comb      =  'b0;  
				  ctrl_msg_len_comb          =  'b0; 
				  ctrl_msg_data_comb         =  'b0;
				  ctrl_native_retrans_comb   = 1'b0;
				  ctrl_ack_flag_comb         = 1'b0;
				  ctrl_i2c_native_comb       = 1'b0;
          cmd_save                   = 1'b0;
          ctrl_native_failed_comb    = 1'b0;
          ctrl_i2c_failed_comb       = 1'b0; 
          ctrl_done_data_number_comb = 1'b0;
          nack_data_number_save      = 1'b0;
				end			  							  			
  NATIVE_TALK_MODE_ONE_DATA_BYTE: 
        begin
          ctrl_tr_vld_comb         = 1'b1;
          ctrl_i2c_native_comb     = 1'b0;
          ctrl_msg_cmd_comb        = cmd_reg;
				  ctrl_msg_address_comb    = address_reg;  
				  ctrl_msg_len_comb        = len_reg;
          if ((lpm_transaction_vld) && (lpm_cmd == 2'b00) || (cr_transaction_vld) && (cr_cmd == 2'b00) || (eq_transaction_vld) && (eq_cmd == 2'b00))                    //////////////////////////////////
          begin 
				  ctrl_msg_data_comb       = data_reg; 
          end
          else
          begin
          ctrl_msg_data_comb       = 'b0;   
          end        					   	  
        end
  NATIVE_TALK_MODE_MULTIPLE_DATA_BYTES: 
        begin
          ctrl_tr_vld_comb         = 1'b1;
          ctrl_i2c_native_comb     = 1'b0;
				  ctrl_msg_data_comb       = data_reg; 
        end		
  NATIVE_LISTEN_MODE_WAIT_ACK: 
        begin
          ctrl_tr_vld_comb         = 1'b0;
          cmd_save                 = 1'b1;					   	  
        end				
  NATIVE_LISTEN_MODE_WAIT_DATA: 
        begin
         nack_data_number_save     = 1'b1;
 				 if((link_training_flag) && (cmd_saved_reg == 'b00))
			      begin
			        ctrl_ack_flag_comb   = 1'b1; 				
            end
			     else
			      begin
			        ctrl_ack_flag_comb   = 1'b0; 
            end         
				end
  NATIVE_RETRANS_MODE: 
        begin
          ctrl_native_retrans_comb = 1'b1;
          if (cmd_saved_reg == 'b01)  // NACK
          begin
            ctrl_done_data_number_comb = nack_data_number_reg;
          end
				end
  NATIVE_FAILED_TRANSACTION: 
        begin
          ctrl_native_failed_comb  = 1'b1; 
				end
  I2C_TALK_MODE: 
        begin
          ctrl_tr_vld_comb         = 1'b1;
          ctrl_i2c_native_comb     = 1'b1;
          ctrl_msg_cmd_comb        = cmd_reg;
				  ctrl_msg_address_comb    = address_reg;  
				  ctrl_msg_len_comb        = len_reg; 
          if (spm_cmd == 2'b00)                   
          begin 
				  ctrl_msg_data_comb       = data_reg; 
          end
          else
          begin
          ctrl_msg_data_comb       = 'b0;   
          end			   	  
        end
  I2C_LISTEN_MODE: 
        begin
          ctrl_tr_vld_comb         = 1'b0;
        end		
  I2C_FAILED_TRANSACTION: 
        begin
          ctrl_i2c_failed_comb     = 1'b1;
        end	
  default: 
        begin
				  ctrl_tr_vld_comb           = 1'b0;
          ctrl_msg_cmd_comb          =  'b0;
				  ctrl_msg_address_comb      =  'b0;  
				  ctrl_msg_len_comb          =  'b0; 
				  ctrl_msg_data_comb         =  'b0;
				  ctrl_native_retrans_comb   = 1'b0;
				  ctrl_ack_flag_comb         = 1'b0;
				  ctrl_i2c_native_comb       = 1'b0;
          cmd_save                   = 1'b0;
          ctrl_native_failed_comb    = 1'b0;
          ctrl_i2c_failed_comb       = 1'b0;
          ctrl_done_data_number_comb = 1'b0;
          nack_data_number_save      = 1'b0;
        end	
  endcase                 	   
 end 

// **************** Storing CMD Field from Reply Decoder Block **************** //
always @ (posedge clk or negedge rst_n)
 begin
  if((!rst_n) || (current_state == IDLE_MODE))
   begin
    cmd_saved_reg <= 'b0;
   end
  else
   begin
    if (cmd_save)
	 begin	
      cmd_saved_reg <= reply_ack;
	 end 
   end
 end

// ************************ Saving the type of current transaction  *********************** //
// **************** (Whether it was From LPM or From Link Training Blocks) **************** //
always @(posedge clk or negedge rst_n) 
begin
  if (!rst_n) 
  begin
    link_training_flag <= 1'b0;
  end 
  else 
  begin
    if ((cr_transaction_vld || eq_transaction_vld) ) 
    begin
      link_training_flag <= 1'b1;
    end
    else if (current_state == IDLE_MODE)
    begin
      link_training_flag <= 1'b0;
    end
  end
end

 // **************** defer_counter update **************** //
always @ (posedge clk or negedge rst_n)
 begin
  if((!rst_n) || (current_state == IDLE_MODE))
   begin
    defer_counter <= 'b0;
   end
  else
   begin
    if ((current_state == NATIVE_LISTEN_MODE_WAIT_DATA) && (!reply_data_vld))
	 begin	
      if (cmd_saved_reg == 'b10) // DEFER
       begin
        defer_counter <= defer_counter + 1;
       end
      else                 // ACK or NACK
       begin
        defer_counter <= 'b0;
       end
	 end 
   end
 end

 // **************** data_counter update **************** //
always @ (posedge clk or negedge rst_n)
 begin
  if((!rst_n) || (current_state == IDLE_MODE))
   begin
    data_counter <= 'b0;
   end
  else
   begin
    if ((current_state == NATIVE_TALK_MODE_ONE_DATA_BYTE) && (cmd_reg == 2'b00))
	   begin	
      data_counter <= len_reg;
     end
    else if ((current_state == NATIVE_TALK_MODE_MULTIPLE_DATA_BYTES))
	   begin	
      data_counter <= data_counter - 1;
     end
    else               
     begin
      data_counter <= 'b0;
     end 
	 end 
 end

// **************** Storing the Number of Data Bytes written in case of NACK from Reply Decoder Block **************** //
always @ (posedge clk or negedge rst_n)
 begin
  if((!rst_n) || (current_state == IDLE_MODE))
   begin
    nack_data_number_reg <= 'b0;
   end
  else if (reply_data_vld)
	 begin	
      nack_data_number_reg <= reply_data;
	 end 
 end

 // **************** Storing the cmd, address, lenrth, and data of the Native Transactions **************** //
always @ (posedge clk or negedge rst_n)
 begin
  if((!rst_n))
   begin
    cmd_reg     <= 'b0;
    address_reg <= 'b0;
    len_reg     <= 'b0;
    data_reg    <= 'b0;
   end
  else
   begin
    if (lpm_transaction_vld)
    begin
      cmd_reg     <= lpm_cmd;
      address_reg <= lpm_address;
      len_reg     <= lpm_len;
      data_reg    <= lpm_data;
    end
    else if (cr_transaction_vld)
    begin
      cmd_reg     <= cr_cmd;
      address_reg <= cr_address;
      len_reg     <= cr_len;
      data_reg    <= cr_data;
    end
    else if (eq_transaction_vld)
    begin
      cmd_reg     <= eq_cmd;
      address_reg <= eq_address;
      len_reg     <= eq_len;
      data_reg    <= eq_data;
    end
    else if (spm_transaction_vld)
    begin
      cmd_reg     <= spm_cmd;
      address_reg <= spm_address;
      len_reg     <= spm_len;
      data_reg    <= spm_data;
    end 
   end
 end

 // **************** Make the output signals sequential **************** //
 always @ (posedge clk or negedge rst_n)
 begin
  if(!rst_n)
   begin
    ctrl_tr_vld           <= 'b0;
    ctrl_msg_cmd          <= 'b0;
    ctrl_msg_address      <= 'b0;
    ctrl_msg_len          <= 'b0;
    ctrl_msg_data         <= 'b0;
    ctrl_done_data_number <= 'b0; 
    ctrl_native_retrans   <= 'b0;
    ctrl_ack_flag         <= 'b0;
    ctrl_i2c_native       <= 'b0;
    ctrl_native_failed    <= 'b0;   
    ctrl_i2c_failed       <= 'b0;
   end
  else
	 begin	
    ctrl_tr_vld           <= ctrl_tr_vld_comb;
    ctrl_msg_cmd          <= ctrl_msg_cmd_comb;
    ctrl_msg_address      <= ctrl_msg_address_comb;
    ctrl_msg_len          <= ctrl_msg_len_comb;
    ctrl_msg_data         <= ctrl_msg_data_comb;
    ctrl_done_data_number <= ctrl_done_data_number_comb; 
    ctrl_native_retrans   <= ctrl_native_retrans_comb;
    ctrl_ack_flag         <= ctrl_ack_flag_comb;
    ctrl_i2c_native       <= ctrl_i2c_native_comb;
    ctrl_native_failed    <= ctrl_native_failed_comb; 
    ctrl_i2c_failed       <= ctrl_i2c_failed_comb;
	 end 
   end 

endmodule