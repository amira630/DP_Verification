//=====================================================================================//
// Design for:   blank mapper
// Author:       Mohamed Magdy
// Major Block:  ISO
// Description:  The "blank_mapper" module handles blanking periods in DisplayPort 
//               by generating appropriate blanking symbols based on scheduling signals.
//               It supports Blanking Start (BS), Start of HBlank/VBlank,
//               General Blank (HBlank/VBlank), and Blanking End (BE) states.
//               The module tracks Main Stream Attributes (MSA) during VBlank. 
//======================================================================================//

`default_nettype none

module blank_mapper (
    input wire        clk                    ,
    input wire        rst_n                  ,
    input wire        sched_blank_en         ,
    input wire        sched_blank_id         ,
    input wire [1:0]  sched_blank_state      ,
    input wire [1:0]  td_lane_count          ,    
    input wire [7:0]  sec_steered_out        , 
	  input wire        sec_steered_vld        ,
    
    output reg [1:0]  blank_steering_state   ,    
    output reg        blank_control_sym_flag ,
    output reg [7:0]  blank_symbols 
);

reg       msa_done;
reg [1:0] msa_state;
reg [2:0] bs_symbols_ctr;
reg [3:0] start_symbols_ctr;


always @(posedge clk or negedge rst_n)
  begin
    if(!rst_n)
      begin
        blank_steering_state   <= 'b0;
        blank_control_sym_flag <= 'b0;
		bs_symbols_ctr         <= 'b0;
		start_symbols_ctr      <= 'b0;
        blank_symbols          <= 'b0;
		msa_done               <= 'b0;
		msa_state              <= 'b0;
      end
    else if(sched_blank_en)
      begin
        case (sched_blank_state)
        //============================================================================================================//
        //                                          BS + BF + BF + BS                                                 //
        //============================================================================================================//		
		2'b01:  begin // BS
				  if (bs_symbols_ctr == 'b00)
				    begin
                      blank_symbols <= 'hBC ; //BS
                      blank_steering_state <= 'b00; //idle                      					  
					  end
				  else if (bs_symbols_ctr == 'b11)
				    begin
                      blank_symbols <= 'hBC ; //BF
                      blank_steering_state <= 'b01; //idle   					  
					  end
				  else
				    begin
                      blank_symbols <= 'hBD ; //BF
                      blank_steering_state <= 'b00; //idle   					  
					  end          
                  bs_symbols_ctr <= bs_symbols_ctr + 'b1;					
                  blank_control_sym_flag <= 'b1;
                  start_symbols_ctr <= 'b0;				  
            end
        //============================================================================================================//
        //                                          VBID + Mvid + Maud                                                //
        //============================================================================================================//				
        2'b10:  begin // START
				  if (start_symbols_ctr == 'b00 || start_symbols_ctr == 'b11 || start_symbols_ctr == 'b110|| start_symbols_ctr == 'b1001)
				    begin
              blank_steering_state <= 'b00; //Mvid
              if(sched_blank_id) // HBlank
                begin
                  blank_symbols <= 8'b00000000; //VBID
                end
              else
                begin
                  blank_symbols <= 8'b00000001; //VBID                      
                end					  
					  end
				  else if ((start_symbols_ctr == 'b1 || start_symbols_ctr == 'b100 || start_symbols_ctr == 'b111|| start_symbols_ctr == 'b1010))
				    begin
                      blank_steering_state <= 'b00; //idle
                      blank_symbols <= sec_steered_out ; //Mvid 					  
					end
				  else 
				    begin
                      blank_steering_state <= 'b01; //idle
                      blank_symbols <= 'b0; //Maud					  
					  end	
					
                  start_symbols_ctr <= start_symbols_ctr + 'b1;					
                  blank_control_sym_flag <= 'b0;
                  bs_symbols_ctr <= 'b0;				  
                end
        //============================================================================================================//
        //                                  1st VBlank: SS + SS + MSA + SE + Dummy                                    //
        //                                  VBlank:                          Dummy                                    //
		//		                            HBlank:                          Dummy                                    //
        //============================================================================================================//				
		2'b00:  begin // Blank
				  if (!sched_blank_id) // VBlank
				    begin
					  if(!msa_done && msa_state == 'b0)
					    begin
						  msa_done <= 1'b0;						
						  msa_state <= msa_state + 'b1;
                          blank_steering_state <= 'b10; // idle
                          blank_symbols <= 'hDC ; // SS 
						  blank_control_sym_flag <= 'b1; 
						end
					  else if(!msa_done && msa_state == 'b1)
					    begin
						  msa_done <= 1'b0;						
						  msa_state <= msa_state + 'b1;						
                          blank_steering_state <= 'b10; //MSA
                          blank_symbols <= 'hDC ; //SS 
						  blank_control_sym_flag <= 'b1; 
						end
					  else if(!msa_done && msa_state == 'b10 && sec_steered_vld)
					    begin
						  msa_done <= 1'b0;						
						  msa_state <= msa_state;							
                          blank_steering_state <= 'b10; //MSA
                          blank_symbols <= sec_steered_out; //MSA 
						  blank_control_sym_flag <= 'b0; 
						end						
					  else if(!msa_done && msa_state == 'b10 && !sec_steered_vld)
						begin
						  msa_done <= 1'b1;
						  msa_state <= msa_state;							
                          blank_steering_state <= 'b00; //idle
                          blank_symbols <= 'hDE ; //SE 
                          blank_control_sym_flag <= 'b1; 						  
						end	
                      else
                        begin
						  msa_done <= msa_done;
						  msa_state <= msa_state;							
                          blank_steering_state <= 'b0; //idle
                          blank_symbols <= 'b0 ; //dummy 
						  blank_control_sym_flag <= 'b0; 
                        end
                      bs_symbols_ctr <= 'b0;						
                      start_symbols_ctr <= 'b0;						
					end
				  else //HBlank 
				    begin
					  msa_done <= 'b0;
					  msa_state <= 'b0;							
                      blank_steering_state <= 'b0; //idle
                      blank_symbols <= 'b0; //dummy  
					  blank_control_sym_flag <= 'b0;
                      bs_symbols_ctr <= 'b0;						
                      start_symbols_ctr <= 'b0;					  
					end	
          bs_symbols_ctr <= 'b0;	
		        end	
        //============================================================================================================//
        //                                          BE + BF + BF + BE                                                 //
        //============================================================================================================//				
        2'b11:  begin // BE
				  if (bs_symbols_ctr == 'b00 || bs_symbols_ctr == 'b11)
				    begin
                      blank_symbols <= 'hBE ; //BE					  
					end
				  else
				    begin
                      blank_symbols <= 'hBD ; //BF 					  
					end
					
				  bs_symbols_ctr <= bs_symbols_ctr + 'b1;	
				  blank_steering_state <= 'b0; //idle	
                  blank_control_sym_flag <= 'b1;
                  start_symbols_ctr <= 'b0;				  
                end		
        endcase   
      end
	else
	  begin
        blank_steering_state   <= 'b0;
        blank_control_sym_flag <= 'b0;
        blank_symbols          <= 'b0;	
        bs_symbols_ctr <= 'b0;  
	  end
  end

endmodule

`resetall