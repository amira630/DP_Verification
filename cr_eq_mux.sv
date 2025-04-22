
`default_nettype none
module cr_eq_mux 
(
  ////////////////// Inputs //////////////////
  input wire  [1:0]  cr_phy_instruct,
  input wire         cr_phy_instruct_vld,
  input wire  [1:0]  cr_adj_lc, 
  input wire  [7:0]  cr_adj_bw,
  input wire  [1:0]  eq_adj_lc,
  input wire  [7:0]  eq_adj_bw,
  input wire  [1:0]  eq_phy_instruct,
  input wire         eq_phy_instruct_vld, 

  ////////////////// Outputs //////////////////
  output reg  [1:0]  phy_instruct,
  output reg         phy_instruct_vld,
  output reg  [1:0]  phy_adj_lc, 
  output reg  [7:0]  phy_adj_bw
);

always @(*) begin
  if (cr_phy_instruct_vld)
    begin
      phy_instruct     = cr_phy_instruct;
      phy_instruct_vld = cr_phy_instruct_vld;
      phy_adj_lc       = cr_adj_lc;
      phy_adj_bw       = cr_adj_bw;
    end
  else
    begin
      phy_instruct     = eq_phy_instruct;
      phy_instruct_vld = eq_phy_instruct_vld;
      phy_adj_lc       = eq_adj_lc;
      phy_adj_bw       = eq_adj_bw;
    end    
end

endmodule
`resetall