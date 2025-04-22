//============================================================================================================================================//
// Design for:   timeout timer 
// Author:       Mohamed Magdy
// Major Block:  AUX
// Description:  The `timeout_timer` module implements a 40-cycle timeout mechanism for AUX transactions, 
//               starting when `mux_aux_out_vld` is detected and resetting upon `bdi_timer_reset`. 
//               It ensures proper timing control by triggering `timer_timeout` after 40 clock cycles if no reset occurs.
//============================================================================================================================================//
`default_nettype none
module timeout_timer
  (
//=======================================================================================//
//=============================== module ports ==========================================//
//=======================================================================================//    
    input   wire   clk              ,
    input   wire   rst_n            ,
    input   wire   mux_aux_out_vld  ,
    input   wire   bdi_timer_reset  ,
    output  reg    timer_timeout
  );
//=======================================================================================//
//================================ internal signals =====================================//
//=======================================================================================//
reg [5:0] timer_count;  
reg       last_vld_flag;     
reg       timer_set;         
reg       set_flag;      
//=======================================================================================//
//========================= timer triggering always block ===============================//
//=======================================================================================//  
always @(posedge clk , negedge rst_n)
  begin
    if (!rst_n)
      begin
        timer_set <= 1'b0;
        last_vld_flag <= 1'b0;
      end 
    else if(mux_aux_out_vld && !last_vld_flag)
      begin
        timer_set <= 1'b0;
        last_vld_flag <= 1'b1;
      end
    else if(last_vld_flag) // detect negative edge of mux_aux_out_vld signal
      begin
        timer_set <= 1'b1;
        last_vld_flag <= 1'b0;
      end
    else 
      begin
        timer_set <= 1'b0;
        last_vld_flag <= 1'b0;
      end
  end
//=======================================================================================//
//============================= timer output always block ===============================//
//=======================================================================================//  
always @(posedge clk , negedge rst_n)
  begin
    if (!rst_n)
      begin
        timer_timeout <= 1'b0;
        timer_count <= 6'b0;
        set_flag <= 1'b0;
      end 
    else if (bdi_timer_reset)
      begin
        timer_timeout <= 1'b0;
        timer_count <= 6'b0; 
        set_flag <= 1'b0;
      end         
    else if (timer_set || set_flag) // timer set or running right now... 
      begin
        timer_count <= timer_count + 6'b000001;        
        if (timer_count == 6'b100111) // 40-1
          begin
            timer_timeout <= 1'b1;
            set_flag <= 1'b0;    
          end
        else
          begin
            timer_timeout <= 1'b0;
            set_flag <= 1'b1;    
          end                
      end
    else if (timer_timeout == 1'b1)
      begin
        timer_timeout <= 1'b0;
        timer_count <= 6'b0;
      end
  end    

endmodule
`resetall