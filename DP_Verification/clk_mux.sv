//======================================================//
// Design for:   clk mux
// Author:       Mohamed Magdy
// Major Block:  ISO
// Description:  MUX :)
//=====================================================//
`default_nettype none
module clk_mux (
    input wire       hbr3_clk    ,
    input wire       hbr2_clk    ,
    input wire       hbr_clk     ,
    input wire       rbr_clk     ,
    input wire [1:0] spm_bw_sel  ,

    output reg       ls_clk
);  

always @(*) begin
  if (spm_bw_sel == 2'b11)
    begin
      ls_clk = hbr3_clk;
    end
  else if (spm_bw_sel == 2'b10)
    begin
      ls_clk = hbr2_clk;
    end
  else if(spm_bw_sel == 2'b01)
    begin
      ls_clk = hbr_clk;
    end
  else
    begin
      ls_clk = rbr_clk;
    end	
end

endmodule
`resetall