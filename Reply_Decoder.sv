module Reply_Decoder 
(
  input wire [7:0] aux_in, 
  input wire       aux_in_vld,
  input wire       aux_ctrl_i2c_native,
  input wire       clk,
  input wire       rst,  
  output reg [7:0] reply_data,
  output reg       reply_data_vld,  
  output reg [1:0] reply_ack,
  output reg       reply_ack_vld, 
  output reg       reply_dec_i2c_native  
);
  
//internal_signals  
reg [4:0] cycle_counter;

always @(posedge clk or negedge rst)
 begin
  if(!rst)
   begin
    reply_data     <=  'b0;
    reply_data_vld <= 1'b0;	
    reply_ack      <=  'b0;
    reply_ack_vld  <= 1'b0;	
    reply_dec_i2c_native <= 1'b0;
    cycle_counter  <=  'd1;
   end

  else 
   begin  
    if (aux_in_vld)
    begin
      reply_dec_i2c_native <= aux_ctrl_i2c_native;
      if (cycle_counter == 'd1)
      begin
        reply_ack_vld <= 1'b1;
        if (!aux_ctrl_i2c_native)   // Native Transaction
        begin
        reply_ack <= aux_in[5:4];
        end
        else                        // I2C-over-Aux Transaction
        begin
        reply_ack <= aux_in[7:6];
        end        
      end
      else if (cycle_counter != 'd1)
      begin
        reply_ack_vld <= 1'b0;
        reply_ack <= 'b0;
        reply_data_vld <= 1'b1;
        reply_data <= aux_in;        
      end
      cycle_counter <= cycle_counter + 1;
    end
    else
    begin
      reply_data     <=  'b0;
      reply_data_vld <= 1'b0;	
      reply_ack      <=  'b0;
      reply_ack_vld  <= 1'b0;	
      reply_dec_i2c_native <= 1'b0;
      cycle_counter  <=  'd1;
    end
   end	
 end  
  

endmodule