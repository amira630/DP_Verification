//======================================================//
// Design for:   native i2c de mux
// Author:       Mohamed Magdy
// Major Block:  AUX
// Description:  DE-MUX :)
//=====================================================//
`default_nettype none
module native_i2c_de_mux (
    input wire [1:0]  ctrl_msg_cmd          ,
    input wire [7:0]  ctrl_msg_data         ,
    input wire [19:0] ctrl_msg_address      ,
    input wire [7:0]  ctrl_msg_len          ,    
    input wire        ctrl_tr_vld           , 
    
    input wire        ctrl_i2c_native       ,
    
    output reg [1:0]  de_mux_native_cmd     ,    
    output reg [7:0]  de_mux_native_data    ,
    output reg [19:0] de_mux_native_address ,
    output reg [7:0]  de_mux_native_len     ,
    output reg        de_mux_native_tr_vld  ,
    
    output reg [1:0]  de_mux_i2c_cmd        ,
//  output reg [7:0]  de_mux_i2c_data       ,
    output reg [19:0] de_mux_i2c_address    ,
    output reg [7:0]  de_mux_i2c_len        ,
    output reg        de_mux_i2c_tr_vld         
);

always @(*) begin
  if (ctrl_i2c_native)
    begin
    de_mux_native_cmd = 2'b0;
    de_mux_native_data = 8'b0;
    de_mux_native_address = 20'b0;
    de_mux_native_len = 8'b0;
    de_mux_native_tr_vld = 1'b0;
    
    de_mux_i2c_cmd = ctrl_msg_cmd;
//  de_mux_i2c_data = ctrl_msg_data;
    de_mux_i2c_address = ctrl_msg_address;
    de_mux_i2c_len = ctrl_msg_len;
    de_mux_i2c_tr_vld = ctrl_tr_vld;
    end
  else
    begin
    de_mux_native_cmd = ctrl_msg_cmd;
    de_mux_native_data = ctrl_msg_data;
    de_mux_native_address = ctrl_msg_address;
    de_mux_native_len = ctrl_msg_len;
    de_mux_native_tr_vld = ctrl_tr_vld;
    
    de_mux_i2c_cmd = 2'b0;
//  de_mux_i2c_data = 8'b0;
    de_mux_i2c_address = 20'b0;
    de_mux_i2c_len = 8'b0;
    de_mux_i2c_tr_vld = 1'b0;    
    end    
end

endmodule
`resetall