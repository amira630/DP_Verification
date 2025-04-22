//============================================================================================================================================//
// Design for:   bidirectional aux phy interface 
// Author:       Mohamed Magdy
// Major Block:  AUX
// Description:  The `bidirectional_aux_phy_interface` module manages bidirectional data transfer over an AUX bus, 
//               controlling data flow direction and timing. It includes timeout handling, start/stop control.
//============================================================================================================================================//
`default_nettype none
module bidirectional_aux_phy_interface 
  (
//=======================================================================================//
//=============================== module ports ==========================================//
//=======================================================================================//  
    input  wire       clk             ,
    input  wire       rst_n           ,
    input  wire [7:0] mux_aux_out     ,
    input  wire       mux_aux_out_vld ,
    input  wire       timer_timeout   ,
    input  wire       phy_start_stop  ,    
    output reg  [7:0] bdi_aux_in      ,
    output reg        bdi_aux_in_vld  ,
    output reg        bdi_timer_reset ,
    output reg        aux_start_stop  ,
    inout  wire [7:0] aux_in_out      
  );
//=======================================================================================//
//================================ internal signals =====================================//
//=======================================================================================//
reg [7:0] mux_aux_out_reg;
reg       timeout_flag;
reg       out_dirction_flag;
//=======================================================================================//
//========================== Bidirectional Data Bus Control =============================//
//=======================================================================================//
// Drive output when mux_aux_out_vld = 1, else set aux_in_out to high impedance (Z)
assign aux_in_out = (out_dirction_flag) ? mux_aux_out_reg : 8'bz;
//=======================================================================================//
//================================ Main Control Logic ===================================//
//=======================================================================================//
always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
      begin
        bdi_aux_in <= 8'b0;
        bdi_aux_in_vld <= 1'b0;    
        aux_start_stop <= 1'b0;    
        timeout_flag <= 1'b0;
        out_dirction_flag <= 1'b0;        
      end  
    else if (mux_aux_out_vld) // transmitter mode
      begin
        bdi_aux_in <= 8'b0;
        bdi_aux_in_vld <= 1'b0;    
        aux_start_stop <= 1'b1;
        timeout_flag <= 1'b0;
        out_dirction_flag <= 1'b1;        
      end
    else if (timer_timeout || timeout_flag) // timeout asserted while in receiver mode
      begin
        bdi_aux_in <= 8'b0;
        bdi_aux_in_vld <= 1'b0;    
        aux_start_stop <= 1'b0;    
        timeout_flag <= 1'b1;
        out_dirction_flag <= 1'b0;        
      end      
    else if (!timer_timeout && !timeout_flag) // receiver mode 
      begin
        if (phy_start_stop)    // receiving now...
          begin        
            bdi_aux_in <= aux_in_out;
            bdi_aux_in_vld <= 1'b1;    
          end
        else
          begin
            bdi_aux_in <= 8'b0;
            bdi_aux_in_vld <= 1'b0;    
          end    
        aux_start_stop <= 1'b0; 
        out_dirction_flag <= 1'b0;        
      end
    else
      begin
        bdi_aux_in <= 8'b0;
        bdi_aux_in_vld <= 1'b0;    
        aux_start_stop <= 1'b0;
        timeout_flag <= 1'b0;
        out_dirction_flag <= 1'b0;        
      end      
  end
//=======================================================================================//
//================================ Timer Reset Logic ====================================//
//=======================================================================================//
always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
      begin
        bdi_timer_reset <= 1'b0;        
      end
    else if (!mux_aux_out_vld && phy_start_stop == 1'b1) // receiving now...
      begin
        bdi_timer_reset <= 1'b1;
      end
    else
      begin
        bdi_timer_reset <= 1'b0;
      end        
  end
//=======================================================================================//
//================================ Output Register ======================================//
//=======================================================================================//
always @(posedge clk or negedge rst_n)
  begin
    if (!rst_n)
      begin
        mux_aux_out_reg <= 8'b0;        
      end
    else 
      begin
        mux_aux_out_reg <= mux_aux_out;
      end        
  end
  
endmodule
`resetall