//======================================================//
// Design for:   native i2c mux
// Author:       Mohamed Magdy
// Major Block:  AUX
// Description:  MUX :)
//=====================================================//
`default_nettype none
module native_i2c_mux (
    input wire [7:0] native_splitted_msg ,
    input wire       native_msg_vld      ,
    input wire [7:0] i2c_splitted_msg    ,
    input wire       i2c_msg_vld         ,
    
    input wire       ctrl_i2c_native     ,  
    
    output reg [7:0] mux_aux_out         ,
    output reg       mux_aux_out_vld
);

always @(*) begin
  if (ctrl_i2c_native)
    begin
      mux_aux_out = i2c_splitted_msg;
      mux_aux_out_vld = i2c_msg_vld;
    end
  else
    begin
      mux_aux_out = native_splitted_msg;
      mux_aux_out_vld = native_msg_vld;
    end    
end

endmodule
`resetall