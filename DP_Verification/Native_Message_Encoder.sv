//==============================================================================================================================================//
// Design for:   Native Message Encoder
// Author:       Mohamed Magdy
// Major Block:  AUX
// Description:  The Native Message Encoder encodes and transmits 8-bit segments of a 5-byte native transaction {CMD | Address | LEN | Data} 
//               while supporting retransmission in case of failure.
//==============================================================================================================================================//
`default_nettype none
module     native_message_encoder
  (
//=======================================================================================//
//=============================== module ports ==========================================//
//=======================================================================================//  
    input   wire          clk                    ,
    input   wire          rst_n                  ,
    input   wire  [1:0]   de_mux_native_cmd      ,
    input   wire  [19:0]  de_mux_native_address  ,
    input   wire  [7:0]   de_mux_native_data     ,
    input   wire  [7:0]   de_mux_native_len      ,
    input   wire          de_mux_native_tr_vld   ,
    input   wire          ctrl_native_retrans    ,
    input   wire  [7:0]   ctrl_done_data_number  ,
	
    output  reg   [7:0]   native_splitted_msg    ,
    output  reg           native_msg_vld         
  );
//=======================================================================================//
//================================ internal signals =====================================//
//=======================================================================================//
  reg [3:0]   encoded_native_cmd;     
  reg [159:0] native_msg_reg;         // Storage for full message (max 20 bytes)
  reg [159:0] shift_reg;
  reg [4:0]   encoder_input_ctr;      // Counter for input byte
  reg [4:0]   encoder_input_ctr_max;
  reg [4:0]   encoder_output_ctr;     // Counter for output bytes
  reg [4:0]   encoder_output_ctr_max;
  reg [4:0]   encoder_reset_ctr;      // Counter to track reset state
  reg         retrans_flag;           // Flag to indicate retransmission is in progress
  reg [7:0]   data_done_number_reg;
//=======================================================================================//
//======================== Main Control and Data Processing =============================//
//=======================================================================================//  
  always @(posedge clk , negedge rst_n)
    begin
      if (!rst_n) // Reset all registers and signals
        begin
          native_splitted_msg     <= 8'b0;
          native_msg_vld          <= 1'b0;
          native_msg_reg          <= 160'b0;
          shift_reg               <= 160'b0;
          encoder_input_ctr_max   <= 5'b0;
          encoder_output_ctr_max  <= 5'b0; 
          encoder_input_ctr       <= 5'b0;
          encoder_output_ctr      <= 5'b0;
          encoder_reset_ctr       <= 5'b0;
          retrans_flag            <= 1'b0;
        end 
      else if(ctrl_native_retrans == 1'b1 && retrans_flag == 1'b0)  // Retransmit request
        begin
          native_splitted_msg <= native_msg_reg[159:152];
          case(ctrl_done_data_number)
            8'b00000000:shift_reg <= {native_msg_reg[151:0], 8'b0};
            8'b00000001:shift_reg <= {native_msg_reg[151:136],native_msg_reg[135:128]-ctrl_done_data_number,native_msg_reg[119:0],16'b0};
            8'b00000010:shift_reg <= {native_msg_reg[151:136],native_msg_reg[135:128]-ctrl_done_data_number,native_msg_reg[111:0],24'b0};
            8'b00000011:shift_reg <= {native_msg_reg[151:136],native_msg_reg[135:128]-ctrl_done_data_number,native_msg_reg[103:0],32'b0};
            8'b00000100:shift_reg <= {native_msg_reg[151:136],native_msg_reg[135:128]-ctrl_done_data_number,native_msg_reg[95:0],40'b0};
            8'b00000101:shift_reg <= {native_msg_reg[151:136],native_msg_reg[135:128]-ctrl_done_data_number,native_msg_reg[87:0],48'b0};
            8'b00000110:shift_reg <= {native_msg_reg[151:136],native_msg_reg[135:128]-ctrl_done_data_number,native_msg_reg[79:0],56'b0};
            8'b00000111:shift_reg <= {native_msg_reg[151:136],native_msg_reg[135:128]-ctrl_done_data_number,native_msg_reg[71:0],64'b0};
            8'b00001000:shift_reg <= {native_msg_reg[151:136],native_msg_reg[135:128]-ctrl_done_data_number,native_msg_reg[63:0],72'b0};
            8'b00001001:shift_reg <= {native_msg_reg[151:136],native_msg_reg[135:128]-ctrl_done_data_number,native_msg_reg[55:0],80'b0};
            8'b00001010:shift_reg <= {native_msg_reg[151:136],native_msg_reg[135:128]-ctrl_done_data_number,native_msg_reg[47:0],88'b0};
            8'b00001011:shift_reg <= {native_msg_reg[151:136],native_msg_reg[135:128]-ctrl_done_data_number,native_msg_reg[39:0],96'b0};
            8'b00001100:shift_reg <= {native_msg_reg[151:136],native_msg_reg[135:128]-ctrl_done_data_number,native_msg_reg[31:0],104'b0};
            8'b00001101:shift_reg <= {native_msg_reg[151:136],native_msg_reg[135:128]-ctrl_done_data_number,native_msg_reg[23:0],112'b0};
            8'b00001110:shift_reg <= {native_msg_reg[151:136],native_msg_reg[135:128]-ctrl_done_data_number,native_msg_reg[15:0],120'b0};
            8'b00001111:shift_reg <= {native_msg_reg[151:136],native_msg_reg[135:128]-ctrl_done_data_number,native_msg_reg[7:0],128'b0};
            default    :shift_reg <= {native_msg_reg[151:0], 8'b0};
          endcase            
          retrans_flag        <= 1'b1; 
          native_msg_vld      <= 1'b1;
          encoder_output_ctr  <= 5'b00001;
        end
      else if(retrans_flag == 1'b1) // Continue retransmitting
        begin
          native_splitted_msg  <= shift_reg[159:152]; 
          shift_reg <= {shift_reg[151:0], 8'b0};     
          //native_msg_vld <= 1'b1;
          //encoder_output_ctr <= encoder_output_ctr + 5'b00001;
          if(encoder_output_ctr == encoder_output_ctr_max - data_done_number_reg[4:0]) // End retransmission
            begin
              retrans_flag <= 1'b0;
			  native_msg_vld <= 1'b0;
			  encoder_output_ctr <= encoder_output_ctr_max;
            end
          else
            begin
              retrans_flag <= 1'b1;
			  native_msg_vld <= 1'b1;
			  encoder_output_ctr <= encoder_output_ctr + 5'b00001;
            end 
        end    
      else if (de_mux_native_tr_vld == 1'b1 && (encoder_output_ctr == 5'b0 || encoder_output_ctr == encoder_output_ctr_max)) // 0 for first_n time & max+1 for any time after that
        begin    
          if(de_mux_native_cmd == 2'b00)  // Write operation
            begin  
              native_msg_reg[39:0] <= {encoded_native_cmd,de_mux_native_address,de_mux_native_len,de_mux_native_data};
              native_splitted_msg <= {encoded_native_cmd,de_mux_native_address[19:16]};
              native_msg_vld <= 1'b1;
              encoder_input_ctr_max <= de_mux_native_len[4:0] + 5'b00001;            
              encoder_output_ctr_max <= de_mux_native_len[4:0] + 5'b00101;
            end      
          else  // Read operation
            begin
              native_msg_reg[39:0] <= {encoded_native_cmd,de_mux_native_address,de_mux_native_len,8'b0};
              native_splitted_msg <= {encoded_native_cmd,de_mux_native_address[19:16]};
              native_msg_vld <= 1'b1;
              encoder_input_ctr_max  <= 5'b00001;            
              encoder_output_ctr_max <= 5'b00100;
            end
          encoder_input_ctr  <= 5'b00001;
          encoder_output_ctr <= 5'b00001;
        end
      else if (encoder_output_ctr != encoder_output_ctr_max) 
        begin
          casex (encoder_output_ctr)
            5'b0xxxx:
              begin
                if(encoder_input_ctr != encoder_input_ctr_max)  // Continue storing data
                  begin    
                    native_msg_reg <= {native_msg_reg[151:0],de_mux_native_data};
                    encoder_input_ctr <= encoder_input_ctr + 5'b00001;
                    native_splitted_msg <= native_msg_reg[31:24];
                  end
                else  // Shift and output data
                  begin    
                    native_msg_reg <= {native_msg_reg[151:0],8'b0};                  
                    native_splitted_msg <= native_msg_reg[31:24];         
                  end
              end
            5'b10000:
              begin
                native_splitted_msg <= native_msg_reg[31:24];
              end        
            5'b10001:
              begin
                native_splitted_msg <= native_msg_reg[23:16];
              end        
            5'b10010:
              begin
                native_splitted_msg <= native_msg_reg[15:8];
              end
            5'b10011:
              begin
                native_splitted_msg <= native_msg_reg[7:0];
              end
          endcase
          native_msg_vld <= 1'b1;
          encoder_output_ctr <= encoder_output_ctr + 5'b00001;
          encoder_reset_ctr  <= encoder_output_ctr + 5'b00001;
        end          
      else if (encoder_output_ctr == encoder_output_ctr_max && encoder_reset_ctr[4] != 1'b1) // Reset after transmission
        begin
          native_msg_reg <= {native_msg_reg[151:0],8'b0};
          encoder_reset_ctr <= encoder_reset_ctr + 5'b00001;
          native_msg_vld <= 1'b0;
        end
      else
        begin
          native_msg_vld <= 1'b0;
        end        
    end
//=======================================================================================//
//=========================== Command Encoding Logic ====================================//
//=======================================================================================//
  // Encode CMD: 00 -> 1000 (Write), 01 -> 1001 (Read)
  always @(*)
    begin
      if(de_mux_native_cmd == 2'b00) //write
        begin
          encoded_native_cmd = 4'b1000;
        end
      else //read (default)
        begin
          encoded_native_cmd = 4'b1001;
        end  
    end
//=======================================================================================//
  always @(posedge clk , negedge rst_n)
    begin
	  if(!rst_n)
	    begin
		  data_done_number_reg = 'b0;
		end
      else if(ctrl_native_retrans == 'b1) //write
        begin
		  data_done_number_reg = ctrl_done_data_number ;
        end
    end

endmodule
`resetall