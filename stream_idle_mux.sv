//======================================================//
// Design for:   Stream IDLE MUX
// Author:       Mohamed Magdy
// Major Block:  ISO
// Description:  MUX :)
//=====================================================//
`default_nettype none
module stream_idle_mux (
    input wire       clk,
    input wire       rst_n,
    input wire [7:0] active_symbols             ,
    input wire       active_control_sym_flag    ,
    input wire [7:0] blank_symbols              ,
    input wire       blank_control_sym_flag     ,
    input wire [7:0] idle_symbols               ,
    input wire       idle_control_sym_flag      ,	
    input wire [1:0] sched_stream_idle_sel,
    
    output reg [7:0] mux_idle_stream_symbols    ,
    output reg       mux_control_sym_flag
);  

always @(posedge clk or posedge rst_n) 
begin
  if (!rst_n) 
    begin
      mux_idle_stream_symbols <= 'b0;
      mux_control_sym_flag <= 'b0;
    end  
  else if (sched_stream_idle_sel == 2'b10)
    begin
      mux_idle_stream_symbols <= active_symbols;
      mux_control_sym_flag <= active_control_sym_flag;
    end
  else if (sched_stream_idle_sel == 2'b01)
    begin
      mux_idle_stream_symbols <= blank_symbols;
      mux_control_sym_flag <= blank_control_sym_flag;
    end
  else
    begin
      mux_idle_stream_symbols <= idle_symbols;
      mux_control_sym_flag <= idle_control_sym_flag;
    end	
end

endmodule
`resetall