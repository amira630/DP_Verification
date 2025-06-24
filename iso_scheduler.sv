//===================================================================//
// Design for:   iso scheduler
// Author:       Mohamed Magdy
// Major Block:  ISO
// Description:  The "iso_scheduler" module manages data flow timing in an ISO transmission system. 
//               It synchronizes valid data, blanking periods, and idle patterns across multiple lanes. 
//               A finite state machine (FSM) controls transitions between states like IDLE, BLANKING, and ACTIVE.
//               It also handles transport unit (TU) management, stuffing, and synchronization signals. 
//               The module ensures efficient data scheduling and lane steering for reliable transmission.
//===================================================================//

`default_nettype none

module iso_scheduler (
    //===============================================================//
    //                        clock & reset                          //
    //===============================================================//
    input    wire            clk,
    input    wire            rst_n,
    //===============================================================//
    //                    time_decision interface                    //
    //===============================================================//
    input    wire            td_vld_data,
    input    wire            td_scheduler_start,
    input    wire    [1:0]   td_lane_count,
    input    wire    [13:0]  td_h_blank_ctr,
    input    wire    [15:0]  td_h_active_ctr,
    input    wire    [9:0]   td_v_blank_ctr,
    input    wire    [12:0]  td_v_active_ctr,
    input    wire    [5:0]   td_tu_vld_data_size,
    input    wire    [5:0]   td_tu_stuffed_data_size,
    input    wire            td_hsync,
    input    wire            td_vsync,
    input    wire            td_hsync_polarity,
    input    wire            td_vsync_polarity,
    input    wire            td_de,
    input    wire    [15:0]   td_tu_alternate_up,
    input    wire    [15:0]   td_tu_alternate_down,
    input    wire    [15:0]  td_h_total_ctr,    
    //===============================================================//
    //                    idle_pattern interface                     //
    //===============================================================//
    input    wire            idle_activate_en_lane0,
    input    wire            idle_activate_en_lane1,
    input    wire            idle_activate_en_lane2,
    input    wire            idle_activate_en_lane3, 

    input    wire    [15:0]  total_stuffing_req, 
    //===============================================================//
    //                 main_bus_steering interface                   //
    //===============================================================//
    output    reg            sched_steering_en,
    //===============================================================//
    //                   active_mapper interface                     //
    //===============================================================//
    output    reg    [1:0]   sched_stream_state,
    output    reg            sched_stream_en_lane0,
    output    reg            sched_stream_en_lane1,
    output    reg            sched_stream_en_lane2,
    output    reg            sched_stream_en_lane3,
    //===============================================================//
    //                     blank_mapper interface                    //
    //===============================================================//
    output    reg            sched_blank_id,
    output    reg    [1:0]   sched_blank_state,
    output    reg            sched_blank_en_lane0,
    output    reg            sched_blank_en_lane1,
    output    reg            sched_blank_en_lane2,
    output    reg            sched_blank_en_lane3,
    //===============================================================//
    //                    idle_pattern interface                     //
    //===============================================================//
    //output    reg            sched_idle_en_lane0,
    //output    reg            sched_idle_en_lane1,
    //output    reg            sched_idle_en_lane2,
    //output    reg            sched_idle_en_lane3,
    //===============================================================//
    //              stream_idle_mux selections interface             //
    //===============================================================//
    output    reg    [1:0]   sched_stream_idle_sel_lane0,
    output    reg    [1:0]   sched_stream_idle_sel_lane1,
    output    reg    [1:0]   sched_stream_idle_sel_lane2,
    output    reg    [1:0]   sched_stream_idle_sel_lane3,

    output    reg            sched_active_line    
);


//===================================================================//
//                       internal signals                            //
//===================================================================//           
reg     [3:0]     current_state,
                  next_state;
//-------------------------------------------------------------------//                 
reg     [13:0]    h_blank_ctr;
reg     [15:0]    h_active_ctr;
reg     [9:0]     v_blank_ctr;
reg     [12:0]    v_active_ctr;
reg     [15:0]    h_total_ctr;
//-------------------------------------------------------------------//                 
reg     [6:0]     tu_vld_data_ctr;
reg     [6:0]     tu_stuffed_data_ctr;
reg     [15:0]    total_stuffing_ctr;
reg     [15:0]    alternate_up_ctr;
reg     [15:0]    alternate_down_ctr;
//-------------------------------------------------------------------//                 
reg     [13:0]    h_blank_ctr_reg;
reg     [15:0]    h_active_ctr_reg;
reg     [9:0]     v_blank_ctr_reg;
reg     [12:0]    v_active_ctr_reg;
reg     [15:0]    h_total_ctr_reg;
//-------------------------------------------------------------------//                 
reg     [6:0]     tu_vld_data_ctr_reg;
reg     [6:0]     tu_stuffed_data_ctr_reg;
reg     [15:0]    total_stuffing_ctr_reg;
reg     [15:0]     alternate_up_ctr_reg;
reg     [15:0]     alternate_down_ctr_reg;
//-------------------------------------------------------------------//                 
reg               td_scheduler_start_reg;
reg     [1:0]     td_lane_count_reg;
reg     [13:0]    td_h_blank_ctr_max;
reg     [15:0]    td_h_active_ctr_max;
reg     [9:0]     td_v_blank_ctr_max;
reg     [12:0]    td_v_active_ctr_max;
reg     [6:0]     td_tu_vld_data_size_min;
reg     [6:0]     td_tu_stuffed_data_size_max;
reg               td_hsync_polarity_reg;
reg               td_vsync_polarity_reg;
reg     [15:0]     td_tu_alternate_up_reg;
reg     [15:0]     td_tu_alternate_down_reg;
reg     [15:0]    td_h_total_ctr_max;
//-------------------------------------------------------------------//
reg     [5:0]     max_stuffing_reg;
//-------------------------------------------------------------------//
reg               td_hsync_reg;
reg               td_vsync_reg;
reg               td_de_reg; 
//-------------------------------------------------------------------//
reg               v_blank_flag;
reg               h_blank_flag;
//-------------------------------------------------------------------//
wire              alternate_up_flag;
//-------------------------------------------------------------------//
reg    [1:0]   sched_stream_idle_sel_lane0_comb;
reg    [1:0]   sched_stream_idle_sel_lane1_comb;
reg    [1:0]   sched_stream_idle_sel_lane2_comb;
reg    [1:0]   sched_stream_idle_sel_lane3_comb;

reg    [15:0]  total_stuffing_req_reg;

//===================================================================//
//                          FSM states                               //
//===================================================================// 
localparam  IDLE             = 4'b0000,
            BS               = 4'b0001,
            START            = 4'b0010,
            VBLANK           = 4'b0011,            
            HBLANK           = 4'b0100,
            BE               = 4'b0101,
            ACTIVE_VLD       = 4'b0110,
            FS               = 4'b0111,
            ACTIVE_STUFFING  = 4'b1000,
            FE               = 4'b1001;
//===================================================================//
//      store counters max & min // registering mux selections       //
//===================================================================//
always @(posedge clk or negedge rst_n)
  begin
    if(!rst_n)
        begin
            td_scheduler_start_reg      <= 1'b0;           
        end
    else
        begin
            td_scheduler_start_reg      <= td_scheduler_start;            
        end   
  end

//===================================================================//
//      store counters max & min // registering mux selections       //
//===================================================================//
always @(posedge clk or negedge rst_n)
  begin
    if(!rst_n)
        begin
            //td_scheduler_start_reg      <= 1'b0;
            td_lane_count_reg           <= 2'b0;
            td_h_blank_ctr_max          <= 14'b0;
            td_h_active_ctr_max         <= 16'b0;
            td_v_blank_ctr_max          <= 10'b0;
            td_v_active_ctr_max         <= 13'b0;
            td_tu_vld_data_size_min     <= 7'b0;
            td_tu_stuffed_data_size_max <= 7'b0;
            td_hsync_polarity_reg       <= 1'b0;
            td_vsync_polarity_reg       <= 1'b0;
            td_tu_alternate_up_reg      <= 'b0;
            td_tu_alternate_down_reg    <= 'b0;
            td_h_total_ctr_max          <= 16'b0;

            sched_stream_idle_sel_lane0 <= 2'b0;
            sched_stream_idle_sel_lane1 <= 2'b0;
            sched_stream_idle_sel_lane2 <= 2'b0;
            sched_stream_idle_sel_lane3 <= 2'b0; 

            total_stuffing_req_reg      <= 'b0;        
        end
    else if(td_vld_data == 1'b1)
        begin
            //td_scheduler_start_reg      <= td_scheduler_start;
            td_lane_count_reg           <= td_lane_count;
            td_h_blank_ctr_max          <= td_h_blank_ctr;
            td_h_active_ctr_max         <= td_h_active_ctr;
            td_v_blank_ctr_max          <= td_v_blank_ctr;
            td_v_active_ctr_max         <= td_v_active_ctr;
            td_tu_vld_data_size_min     <= td_tu_vld_data_size;
            td_tu_stuffed_data_size_max <= td_tu_stuffed_data_size;
            td_hsync_polarity_reg       <= td_hsync_polarity;
            td_vsync_polarity_reg       <= td_vsync_polarity;
            td_tu_alternate_up_reg      <= td_tu_alternate_up;
            td_tu_alternate_down_reg    <= td_tu_alternate_down;
            td_h_total_ctr_max          <= td_h_total_ctr;

            sched_stream_idle_sel_lane0 <= sched_stream_idle_sel_lane0_comb;
            sched_stream_idle_sel_lane1 <= sched_stream_idle_sel_lane1_comb;
            sched_stream_idle_sel_lane2 <= sched_stream_idle_sel_lane2_comb;
            sched_stream_idle_sel_lane3 <= sched_stream_idle_sel_lane3_comb;  

            total_stuffing_req_reg      <= total_stuffing_req;            
        end
      else
        begin
            sched_stream_idle_sel_lane0 <= sched_stream_idle_sel_lane0_comb;
            sched_stream_idle_sel_lane1 <= sched_stream_idle_sel_lane1_comb;
            sched_stream_idle_sel_lane2 <= sched_stream_idle_sel_lane2_comb;
            sched_stream_idle_sel_lane3 <= sched_stream_idle_sel_lane3_comb;
        end    
  end
  
 
//===================================================================//
//                         internal counters                         //
//===================================================================//
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
      h_blank_ctr_reg           <= 'b0;
      h_active_ctr_reg          <= 'b0;
      v_blank_ctr_reg           <= 'b0;
      v_active_ctr_reg          <= 'b0;
      h_total_ctr_reg           <= 'b0;

      tu_vld_data_ctr_reg       <= 'b0;
      tu_stuffed_data_ctr_reg   <= 'b0;
      total_stuffing_ctr        <= 'b0;
      alternate_up_ctr_reg      <= 'b0;
      alternate_down_ctr_reg    <= 'b0;
    end
    else
    begin
      h_blank_ctr_reg           <= h_blank_ctr;
      h_active_ctr_reg          <= h_active_ctr; 
      v_blank_ctr_reg           <= v_blank_ctr;
      v_active_ctr_reg          <= v_active_ctr;
      h_total_ctr_reg           <= h_total_ctr;

      tu_vld_data_ctr_reg       <= tu_vld_data_ctr;
      tu_stuffed_data_ctr_reg   <= tu_stuffed_data_ctr;
      total_stuffing_ctr_reg    <= total_stuffing_ctr;
      alternate_up_ctr_reg      <= alternate_up_ctr;
      alternate_down_ctr_reg    <= alternate_down_ctr;    
    end
end


//===================================================================//
//                         state transition                          //
//===================================================================//
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        current_state <= IDLE;
    end
    else
    begin
        current_state <= next_state;
    end
end


//===================================================================//
//                           sync signals                            //
//===================================================================//   
always @(posedge clk or negedge rst_n)
  begin
    if(!rst_n)
      begin
        td_hsync_reg <= 1'b0;
        td_vsync_reg <= 1'b0;
        td_de_reg    <= 1'b0;        
      end
    else
      begin
        td_hsync_reg <= td_hsync;
        td_vsync_reg <= td_vsync;
        td_de_reg    <= td_de;        
      end
  end
  
  
//===================================================================//
//      indecate when TU valid data size should be max not min       //
//===================================================================//   
assign alternate_up_flag = (alternate_down_ctr_reg == td_tu_alternate_down_reg);
  
  
//===================================================================//
//         max number for stuffed symbol in the current TU           //
//===================================================================//
always @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
      max_stuffing_reg <= 'b0;
    end
    else if(!alternate_up_flag)
    begin
      max_stuffing_reg <= td_tu_stuffed_data_size_max;    
    end
    else
    begin
      max_stuffing_reg <= td_tu_stuffed_data_size_max - 'b1;    
    end
end  


//===================================================================//
//                            Blank flags                            //
//===================================================================//
always @(*)
begin
    if((v_blank_ctr_reg != td_v_blank_ctr_max + 'b1)||
	   ((h_total_ctr_reg != 'b0)&&(v_blank_ctr_reg == td_v_blank_ctr_max + 'b1))||
	   (v_active_ctr_reg == td_v_active_ctr_max)) //that condition needs no (-1) for reg as one clk delay will not effect as it count every line not every symbol, and needs no (-1) for starting count from 0 as this happen at the start of the line, and the (+1) is for the last shorter vblank line which ends with BE
      begin
        v_blank_flag = 'b1;
        h_blank_flag = 'b0;    
      end
    else
      begin
        v_blank_flag = 'b0;
        h_blank_flag = 'b1;
      end   
end


//===================================================================//
//                         next state logic                          //
//===================================================================//
always @ (*)
  begin
  next_state = IDLE;
    case(current_state)
    IDLE:           begin
                      if(td_scheduler_start_reg 
                        && idle_activate_en_lane0 && idle_activate_en_lane1 
                        && idle_activate_en_lane2 && idle_activate_en_lane3) // td_vld_data && 
                        begin
                          next_state = BS;
                        end
                      else
                        begin
                          next_state = IDLE;
                        end
                    end
                    
    BS:             begin
                      if(h_total_ctr_reg == ('b100 - 'b01) || h_blank_ctr_reg == ('b100 - 'b01))
                        begin
                          next_state = START;
                        end
                      else 
                        begin
                          next_state = BS;                          
                        end                        
                    end
                    
    START:          begin
                      if(  (td_lane_count_reg == 'b11 &&(h_total_ctr_reg == ('b0111 - 'b01)  || h_blank_ctr_reg == ('b0111 - 'b01)))
                        || (td_lane_count_reg == 'b01 &&(h_total_ctr_reg == ('b1010 - 'b01)  || h_blank_ctr_reg == ('b1010 - 'b01)))
                        || (td_lane_count_reg == 'b00 &&(h_total_ctr_reg == ('b10000 - 'b01) || h_blank_ctr_reg == ('b10000 - 'b01)))
                        )
                        begin
                          if (v_blank_flag)
                            begin
                              next_state = VBLANK;
                            end    
                          else
                            begin
                              next_state = HBLANK;
                            end                    
                        end   
                      else
                        begin
                          next_state = START;
                        end
                    end
                    
    VBLANK:         begin
                      if(h_total_ctr_reg == td_h_total_ctr_max - 'b1)
                        begin
                          next_state = BS;
                        end
                      //else if((v_blank_ctr_reg == td_v_blank_ctr_max) && (h_total_ctr_reg == td_h_blank_ctr_max - 'b101))	
                      else if((v_blank_ctr_reg == td_v_blank_ctr_max) && (h_total_ctr_reg == td_h_blank_ctr_max - 'b010))				  
                        begin
                           next_state = BE;                         
                        end  
                      else
                        begin
                           next_state = VBLANK;                          
                        end						
                    end
                    
    HBLANK:         begin
                      //if(h_blank_ctr_reg == td_h_blank_ctr_max - 'b110) // max -4(for BE symbols) -1
                      if(h_blank_ctr_reg == td_h_blank_ctr_max - 'b011) // max -4(for BE symbols) -1
                        begin
                          next_state = BE;
                        end
                      else
                        begin
                           next_state = HBLANK;                         
                        end
                    end
                    
    BE:             begin
                      //if((h_blank_ctr_reg == td_h_blank_ctr_max - 'd2)||(h_total_ctr_reg == td_h_blank_ctr_max - 'b1))
                      //  begin
                          next_state = ACTIVE_VLD;
                      //  end
                      //else
                      //  begin
                      //    next_state = BE;
                      //  end
                    end 
                    
    ACTIVE_VLD:     begin
      /*
                      if((h_active_ctr != td_h_active_ctr_max)&&(total_stuffing_ctr == total_stuffing_req_reg))
                      begin
                        next_state = ACTIVE_VLD;
                      end
                      else if (
                          (!(max_stuffing_reg == 'b00 || max_stuffing_reg == 'b01 || max_stuffing_reg == 'b10)&&(((tu_vld_data_ctr_reg == td_tu_vld_data_size_min - 'b1) && !alternate_up_flag) ||((tu_vld_data_ctr_reg == td_tu_vld_data_size_min) && alternate_up_flag)) && h_active_ctr_reg != td_h_active_ctr_max - 'b1)
                          || ((h_active_ctr == td_h_active_ctr_max)&&(total_stuffing_ctr != total_stuffing_req_reg - 1)&&(total_stuffing_ctr != total_stuffing_req_reg))
                         )
                        begin
                          next_state = FS;
                        end
                      else if (
                               ((max_stuffing_reg == 'b1)&& (((tu_vld_data_ctr_reg == td_tu_vld_data_size_min - 'b1) && !alternate_up_flag)||((tu_vld_data_ctr_reg == td_tu_vld_data_size_min ) && alternate_up_flag))&& h_active_ctr_reg != td_h_active_ctr_max - 'b1)
                               || ((h_active_ctr == td_h_active_ctr_max)&&(total_stuffing_ctr == total_stuffing_req_reg - 1))
                              ) 
                        begin
                          next_state = FE;
                        end
                      else if (((h_active_ctr == td_h_active_ctr_max)&&(total_stuffing_ctr == total_stuffing_req_reg))&& 
                               !((v_active_ctr_reg == td_v_active_ctr_max)&&(td_scheduler_start_reg == 'b0)))
                        begin
                          next_state = BS;
                        end                        
                      else if((h_active_ctr == td_h_active_ctr_max)&&(total_stuffing_ctr == total_stuffing_req_reg) 
                               &&(v_active_ctr_reg == td_v_active_ctr_max)&&(td_scheduler_start_reg == 'b0))
                        begin
                          next_state = IDLE;
                        end
                      else
                        begin
                          next_state = ACTIVE_VLD;
                        end     
                        */                   

                 

///*

                      if((h_active_ctr_reg != td_h_active_ctr_max-1)&&(total_stuffing_ctr_reg == total_stuffing_req_reg)&&(h_active_ctr_reg != td_h_active_ctr_max))
                      begin
                        next_state = ACTIVE_VLD;
                      end
                      else if (
                          (!(max_stuffing_reg == 'b00 || max_stuffing_reg == 'b01 || max_stuffing_reg == 'b10)&&(((tu_vld_data_ctr_reg == td_tu_vld_data_size_min - 'b1) && !alternate_up_flag) ||((tu_vld_data_ctr_reg == td_tu_vld_data_size_min) && alternate_up_flag)) && h_active_ctr_reg != td_h_active_ctr_max - 'b1)
                          || ((h_active_ctr_reg == td_h_active_ctr_max-1)&&(total_stuffing_ctr_reg != total_stuffing_req_reg - 1)&&(total_stuffing_ctr_reg != total_stuffing_req_reg))
                         )
                        begin
                          next_state = FS;
                        end
                      else if (
                               ((max_stuffing_reg == 'b1)&& (((tu_vld_data_ctr_reg == td_tu_vld_data_size_min - 'b1) && !alternate_up_flag)||((tu_vld_data_ctr_reg == td_tu_vld_data_size_min ) && alternate_up_flag))&& h_active_ctr_reg != td_h_active_ctr_max - 'b1)
                               || ((h_active_ctr_reg == td_h_active_ctr_max-1)&&(total_stuffing_ctr_reg == total_stuffing_req_reg - 1))
                              ) 
                        begin
                          next_state = FE;
                        end
                      else if ((((h_active_ctr_reg == td_h_active_ctr_max-1)&&(total_stuffing_ctr == total_stuffing_req_reg))||(((h_active_ctr_reg == td_h_active_ctr_max)&&(total_stuffing_ctr_reg == total_stuffing_req_reg-1))))&& 
                               !((v_active_ctr_reg == td_v_active_ctr_max)&&(td_scheduler_start_reg == 'b0)))
                        begin
                          next_state = BS;
                        end                        
                      else if(((h_active_ctr_reg == td_h_active_ctr_max-1)&&(total_stuffing_ctr == total_stuffing_req_reg))||(((h_active_ctr_reg == td_h_active_ctr_max)&&(total_stuffing_ctr_reg == total_stuffing_req_reg-1))) 
                               &&(v_active_ctr_reg == td_v_active_ctr_max)&&(td_scheduler_start_reg == 'b0))
                        begin
                          next_state = IDLE;
                        end
                      else
                        begin
                          next_state = ACTIVE_VLD;
                        end 
  //*/                      

                    end
                    
    FS:             begin
                      if((total_stuffing_ctr_reg == total_stuffing_req_reg - 2) || (max_stuffing_reg == 'b10))
                        begin
                          next_state = FE;
                        end   
                      else
                        begin
                          next_state = ACTIVE_STUFFING;
                        end
                    end
                    
    ACTIVE_STUFFING:   
                    begin
                      if((total_stuffing_ctr_reg == total_stuffing_req_reg - 2)||((tu_stuffed_data_ctr_reg == max_stuffing_reg - 'b10)&&(h_active_ctr_reg != td_h_active_ctr_max)))// 1 for reg & 1 for FE
                        begin
                          next_state = FE;
                        end
                      else
                        begin
                           next_state = ACTIVE_STUFFING;                         
                        end                        
                    end
                    
    FE:             begin
                      if((total_stuffing_ctr_reg == total_stuffing_req_reg - 1)&&(h_active_ctr_reg == td_h_active_ctr_max))
                        begin
                          next_state = BS;
                        end
                      else
                        begin
                           next_state = ACTIVE_VLD;                         
                        end
                    end
                    
    default:        begin
                      next_state = IDLE;
                    end
    endcase
end 


//===================================================================//
//                           output logic                            //
//===================================================================//
always @ (*)
  begin
    //-------------------------------------------------------------------//
                      sched_steering_en           = 'b0;
    //-------------------------------------------------------------------//                     
                      sched_stream_state          = 'b0;
                      sched_stream_en_lane0       = 'b0;
                      sched_stream_en_lane1       = 'b0;
                      sched_stream_en_lane2       = 'b0;
                      sched_stream_en_lane3       = 'b0;
    //-------------------------------------------------------------------//                      
                      sched_blank_id              = 'b0;
                      sched_blank_state           = 'b0;
                      sched_blank_en_lane0        = 'b0;
                      sched_blank_en_lane1        = 'b0;
                      sched_blank_en_lane2        = 'b0;
                      sched_blank_en_lane3        = 'b0;
    //-------------------------------------------------------------------//                     
                      //sched_idle_en_lane0         = 'b1;
                      //sched_idle_en_lane1         = 'b1;
                      //sched_idle_en_lane2         = 'b1;
                      //sched_idle_en_lane3         = 'b1;    
    //-------------------------------------------------------------------//
                      sched_stream_idle_sel_lane0_comb = 'b0;
                      sched_stream_idle_sel_lane1_comb = 'b0;
                      sched_stream_idle_sel_lane2_comb = 'b0;
                      sched_stream_idle_sel_lane3_comb = 'b0;
    //-------------------------------------------------------------------//                      
                      h_total_ctr = h_total_ctr_reg;
                      h_blank_ctr = h_blank_ctr_reg;
                      v_blank_ctr = v_blank_ctr_reg;
                      v_active_ctr = v_active_ctr_reg;
                      h_active_ctr = h_active_ctr_reg;                  
                      tu_stuffed_data_ctr = 'b0;                       
                      tu_vld_data_ctr = 'b0;
                      alternate_up_ctr = alternate_up_ctr_reg;
                      alternate_down_ctr = alternate_down_ctr_reg; 

                      sched_active_line = 'b0;
    //===================================================================//                      
  
    case(current_state)
    IDLE:           begin
                      sched_steering_en           = 'b0;
    //-------------------------------------------------------------------//                    
                      sched_stream_state          = 'b0;
                      sched_stream_en_lane0       = 'b0;
                      sched_stream_en_lane1       = 'b0;
                      sched_stream_en_lane2       = 'b0;
                      sched_stream_en_lane3       = 'b0;
    //-------------------------------------------------------------------//                    
                      sched_blank_id              = 'b0;
                      sched_blank_state           = 'b0;
                      sched_blank_en_lane0        = 'b0;
                      sched_blank_en_lane1        = 'b0;
                      sched_blank_en_lane2        = 'b0;
                      sched_blank_en_lane3        = 'b0;
    //-------------------------------------------------------------------//                    
                      //sched_idle_en_lane0         = 'b0;
                      //sched_idle_en_lane1         = 'b0;
                      //sched_idle_en_lane2         = 'b0;
                      //sched_idle_en_lane3         = 'b0;    
    //-------------------------------------------------------------------//
                      sched_stream_idle_sel_lane0_comb = 'b0;
                      sched_stream_idle_sel_lane1_comb = 'b0;
                      sched_stream_idle_sel_lane2_comb = 'b0;
                      sched_stream_idle_sel_lane3_comb = 'b0;
    //-------------------------------------------------------------------//                  
                      tu_stuffed_data_ctr = 'b0;
                      total_stuffing_ctr = 'b0;        
                      h_total_ctr = 'b0;
                      h_blank_ctr = 'b0;
                      v_blank_ctr = 'b0;
                      v_active_ctr = 'b0;
                      h_active_ctr = 'b0;    
                      tu_vld_data_ctr = 'b0;
                      alternate_up_ctr = 'b0;
                      alternate_down_ctr = 'b0;  

                      sched_active_line = 'b0;                    
                    end
    //===================================================================//
	
    BS:             begin
    //-------------------------main_bus_steering-------------------------//
                      sched_steering_en           = 'b0;
    //--------------------------active_mapper----------------------------//                   
                      sched_stream_state          = 'b0;
                      sched_stream_en_lane0       = 'b0;
                      sched_stream_en_lane1       = 'b0;
                      sched_stream_en_lane2       = 'b0;
                      sched_stream_en_lane3       = 'b0;
    //--------------------------blank_mapper-----------------------------//                  
                      if(v_blank_flag)
                        begin
                          sched_blank_id          = 'b0; // VBlank
                        end
                      else
                        begin
                          sched_blank_id          = 'b1; // HBlank
                        end
                      sched_blank_state           = 'b01;
                      if(td_lane_count_reg == 'b00) // 1 lane
                        begin
    //------------------------------blank_mapper-------------------------//
                          sched_blank_en_lane0        = 'b1;
                          sched_blank_en_lane1        = 'b0;
                          sched_blank_en_lane2        = 'b0;
                          sched_blank_en_lane3        = 'b0;
    //------------------------------idle_pattern-------------------------//                          
                          //sched_idle_en_lane0         = 'b0;
                          //sched_idle_en_lane1         = 'b1;
                          //sched_idle_en_lane2         = 'b1;
                          //sched_idle_en_lane3         = 'b1;
    //------------------------------stream_idle_mux----------------------//                      
                          sched_stream_idle_sel_lane0_comb = 'b01;
                          sched_stream_idle_sel_lane1_comb = 'b0;
                          sched_stream_idle_sel_lane2_comb = 'b0;
                          sched_stream_idle_sel_lane3_comb = 'b0;                      
                        end
                      else if(td_lane_count_reg == 'b01) // 2 lanes
                        begin
                          sched_blank_en_lane0        = 'b1;
                          sched_blank_en_lane1        = 'b1;
                          sched_blank_en_lane2        = 'b0;
                          sched_blank_en_lane3        = 'b0;
                          
                          //sched_idle_en_lane0         = 'b0;
                          //sched_idle_en_lane1         = 'b0;
                          //sched_idle_en_lane2         = 'b1;
                          //sched_idle_en_lane3         = 'b1;
                      
                          sched_stream_idle_sel_lane0_comb = 'b01;
                          sched_stream_idle_sel_lane1_comb = 'b01;
                          sched_stream_idle_sel_lane2_comb = 'b0;
                          sched_stream_idle_sel_lane3_comb = 'b0;                      
                        end
                      else // 4 lanes
                        begin
                          sched_blank_en_lane0        = 'b1;
                          sched_blank_en_lane1        = 'b1;
                          sched_blank_en_lane2        = 'b1;
                          sched_blank_en_lane3        = 'b1;                        
                        
                          //sched_idle_en_lane0         = 'b0;
                          //sched_idle_en_lane1         = 'b0;
                          //sched_idle_en_lane2         = 'b0;
                          //sched_idle_en_lane3         = 'b0;
                      
                          sched_stream_idle_sel_lane0_comb = 'b01;
                          sched_stream_idle_sel_lane1_comb = 'b01;
                          sched_stream_idle_sel_lane2_comb = 'b01;
                          sched_stream_idle_sel_lane3_comb = 'b01;                      
                        end
    //-------------------------------------------------------------------//                    
                      if(v_blank_flag)
                        begin
                          h_total_ctr = h_total_ctr_reg + 'b1;
                          h_blank_ctr = h_blank_ctr_reg;
                        end
                      else if(h_blank_flag)
                        begin
                          h_total_ctr = h_total_ctr_reg;
                          h_blank_ctr = h_blank_ctr_reg + 'b1;
                        end
                      else
                        begin
                          h_total_ctr = h_total_ctr_reg;
                          h_blank_ctr = h_blank_ctr_reg;
                        end    
    //-------------------------------------------------------------------//                  
                      if((td_hsync_reg == !td_hsync_polarity_reg) && td_de_reg == 'b0)
                        begin
                          h_active_ctr = 'b0;
                        end
                      else
                        begin
                          h_active_ctr = h_active_ctr_reg;
                        end
    //-------------------------------------------------------------------//                    
                      if((td_vsync_reg == !td_vsync_polarity_reg) && td_de_reg == 'b0)
                        begin
                          v_active_ctr = 'b0;
                        end
                      else
                        begin
                          v_active_ctr = v_active_ctr_reg;
                        end
    //-------------------------------------------------------------------//                   
                      v_blank_ctr = v_blank_ctr_reg;                       
                      tu_vld_data_ctr = 'b0;
                      tu_stuffed_data_ctr = 'b0;
                      total_stuffing_ctr = 'b0;
                      alternate_up_ctr = alternate_up_ctr_reg;
                      alternate_down_ctr = alternate_down_ctr_reg;                
                      //bs_be_size_ctr = bs_be_size_ctr_reg + 'b1;
                      sched_active_line = 'b0;                      
                    end
	//===================================================================//				
                    
    START:          begin
                      sched_steering_en           = 'b0;
                      // active_mapper 
                      sched_stream_state          = 'b0;
                      sched_stream_en_lane0       = 'b0;
                      sched_stream_en_lane1       = 'b0;
                      sched_stream_en_lane2       = 'b0;
                      sched_stream_en_lane3       = 'b0;
                      // blank_mapper
                      if(v_blank_flag)
                        begin
                          sched_blank_id          = 'b0; // VBlank
                        end
                      else
                        begin
                          sched_blank_id          = 'b1; // HBlank
                        end
                      sched_blank_state           = 'b10;
                      if(td_lane_count_reg == 'b00) // 1 lane
                        begin
                          // blank_mapper
                          sched_blank_en_lane0        = 'b1;
                          sched_blank_en_lane1        = 'b0;
                          sched_blank_en_lane2        = 'b0;
                          sched_blank_en_lane3        = 'b0;
                          // idle_pattern
                          //sched_idle_en_lane0         = 'b0;
                          //sched_idle_en_lane1         = 'b1;
                          //sched_idle_en_lane2         = 'b1;
                          //sched_idle_en_lane3         = 'b1;
                          // stream_idle_mux
                          sched_stream_idle_sel_lane0_comb = 'b01;
                          sched_stream_idle_sel_lane1_comb = 'b0;
                          sched_stream_idle_sel_lane2_comb = 'b0;
                          sched_stream_idle_sel_lane3_comb = 'b0;                      
                        end
                      else if(td_lane_count_reg == 'b01) // 2 lanes
                        begin
                          sched_blank_en_lane0        = 'b1;
                          sched_blank_en_lane1        = 'b1;
                          sched_blank_en_lane2        = 'b0;
                          sched_blank_en_lane3        = 'b0;
                          
                          //sched_idle_en_lane0         = 'b0;
                          //sched_idle_en_lane1         = 'b0;
                          //sched_idle_en_lane2         = 'b1;
                          //sched_idle_en_lane3         = 'b1;
                      
                          sched_stream_idle_sel_lane0_comb = 'b01;
                          sched_stream_idle_sel_lane1_comb = 'b01;
                          sched_stream_idle_sel_lane2_comb = 'b0;
                          sched_stream_idle_sel_lane3_comb = 'b0;                      
                        end
                      else // 4 lanes
                        begin
                          sched_blank_en_lane0        = 'b1;
                          sched_blank_en_lane1        = 'b1;
                          sched_blank_en_lane2        = 'b1;
                          sched_blank_en_lane3        = 'b1;                        
                        
                          //sched_idle_en_lane0         = 'b0;
                          //sched_idle_en_lane1         = 'b0;
                          //sched_idle_en_lane2         = 'b0;
                          //sched_idle_en_lane3         = 'b0;
                      
                          sched_stream_idle_sel_lane0_comb = 'b01;
                          sched_stream_idle_sel_lane1_comb = 'b01;
                          sched_stream_idle_sel_lane2_comb = 'b01;
                          sched_stream_idle_sel_lane3_comb = 'b01;                      
                        end
    //-------------------------------------------------------------------//                    
                      if(v_blank_flag)
                        begin
                          h_total_ctr = h_total_ctr_reg + 'b1;
                          h_blank_ctr = h_blank_ctr_reg;
                        end
                      else if(h_blank_flag)
                        begin
                          h_total_ctr = h_total_ctr_reg;
                          h_blank_ctr = h_blank_ctr_reg + 'b1;
                        end
                      else
                        begin
                          h_total_ctr = h_total_ctr_reg;
                          h_blank_ctr = h_blank_ctr_reg;
                        end
    //-------------------------------------------------------------------//                  
                      if(td_hsync_reg == !td_hsync_polarity_reg && td_de_reg == 'b0)
                        begin
                          h_active_ctr = 'b0;
                        end
                      else
                        begin
                          h_active_ctr = h_active_ctr_reg;
                        end
    //-------------------------------------------------------------------//                    
                      if(td_vsync_reg == !td_vsync_polarity_reg && td_de_reg == 'b0)
                        begin
                          v_active_ctr = 'b0;
                        end
                      else
                        begin
                          v_active_ctr = v_active_ctr_reg;
                        end
    //-------------------------------------------------------------------// 
                      v_blank_ctr = v_blank_ctr_reg;    
                      tu_vld_data_ctr = 'b0;
                      tu_stuffed_data_ctr = 'b0;
                      total_stuffing_ctr = 'b0;
                      alternate_up_ctr = alternate_up_ctr_reg;
                      alternate_down_ctr = alternate_down_ctr_reg;  
                      sched_active_line = 'b0;                   
                    end
	//===================================================================//				
                    
    VBLANK:         begin

                      if((v_blank_ctr_reg == td_v_blank_ctr_max) && (h_total_ctr_reg == td_h_blank_ctr_max - 'b010))				  
                        begin
                           sched_steering_en      = 'b1;                         
                        end  
                      else
                        begin
                           sched_steering_en      = 'b0;                          
                        end	
                      //sched_steering_en           = 'b0;
                      // active_mapper 
                      sched_stream_state          = 'b0;
                      sched_stream_en_lane0       = 'b0;
                      sched_stream_en_lane1       = 'b0;
                      sched_stream_en_lane2       = 'b0;
                      sched_stream_en_lane3       = 'b0;
                      // blank_mapper
                      sched_blank_id              = 'b0; // VBlank
                      sched_blank_state           = 'b00;
                      if(td_lane_count_reg == 'b00) // 1 lane
                        begin
                          // blank_mapper
                          sched_blank_en_lane0        = 'b1;
                          sched_blank_en_lane1        = 'b0;
                          sched_blank_en_lane2        = 'b0;
                          sched_blank_en_lane3        = 'b0;
                          // idle_pattern
                          //sched_idle_en_lane0         = 'b0;
                          //sched_idle_en_lane1         = 'b1;
                          //sched_idle_en_lane2         = 'b1;
                          //sched_idle_en_lane3         = 'b1;
                          // stream_idle_mux
                          sched_stream_idle_sel_lane0_comb = 'b01;
                          sched_stream_idle_sel_lane1_comb = 'b0;
                          sched_stream_idle_sel_lane2_comb = 'b0;
                          sched_stream_idle_sel_lane3_comb = 'b0;                      
                        end
                      else if(td_lane_count_reg == 'b01) // 2 lanes
                        begin
                          sched_blank_en_lane0        = 'b1;
                          sched_blank_en_lane1        = 'b1;
                          sched_blank_en_lane2        = 'b0;
                          sched_blank_en_lane3        = 'b0;
                          
                          //sched_idle_en_lane0         = 'b0;
                          //sched_idle_en_lane1         = 'b0;
                          //sched_idle_en_lane2         = 'b1;
                          //sched_idle_en_lane3         = 'b1;
                      
                          sched_stream_idle_sel_lane0_comb = 'b01;
                          sched_stream_idle_sel_lane1_comb = 'b01;
                          sched_stream_idle_sel_lane2_comb = 'b0;
                          sched_stream_idle_sel_lane3_comb = 'b0;                      
                        end
                      else // 4 lanes
                        begin
                          sched_blank_en_lane0        = 'b1;
                          sched_blank_en_lane1        = 'b1;
                          sched_blank_en_lane2        = 'b1;
                          sched_blank_en_lane3        = 'b1;                        
                        
                          //sched_idle_en_lane0         = 'b0;
                          //sched_idle_en_lane1         = 'b0;
                          //sched_idle_en_lane2         = 'b0;
                          //sched_idle_en_lane3         = 'b0;
                      
                          sched_stream_idle_sel_lane0_comb = 'b01;
                          sched_stream_idle_sel_lane1_comb = 'b01;
                          sched_stream_idle_sel_lane2_comb = 'b01;
                          sched_stream_idle_sel_lane3_comb = 'b01;                      
                        end    
    //-------------------------------------------------------------------//
                      h_blank_ctr = h_blank_ctr_reg;
    //-------------------------------------------------------------------//                  
                      if((h_total_ctr_reg == td_h_total_ctr_max - 'b1)&& (v_blank_ctr_reg != td_v_blank_ctr_max))// 1 for reg
                        begin
                          v_blank_ctr = v_blank_ctr_reg + 'b1;
                          h_total_ctr = 'b0;
                        end
                      //else if((v_blank_ctr_reg == td_v_blank_ctr_max) && (h_total_ctr_reg == td_h_blank_ctr_max - 'b101))
                      else if((v_blank_ctr_reg == td_v_blank_ctr_max) && (h_total_ctr_reg == td_h_blank_ctr_max - 'b010))
                        begin
                          v_blank_ctr = v_blank_ctr_reg + 'b1;
                          h_total_ctr = h_total_ctr_reg + 'b1;
                        end
					  else
                        begin
                          v_blank_ctr = v_blank_ctr_reg;
                          h_total_ctr = h_total_ctr_reg + 'b1;
                        end						
    //-------------------------------------------------------------------//                    
                      if(td_vsync_reg == !td_vsync_polarity_reg && td_de_reg == 'b0)
                        begin
                          v_active_ctr = 'b0;
                        end
                      else
                        begin
                          v_active_ctr = v_active_ctr_reg;
                        end
    //-------------------------------------------------------------------//                    
                      //h_active_ctr = h_active_ctr_reg;  
                      h_active_ctr = 'b0;                       
                      tu_vld_data_ctr = 'b0;
                      tu_stuffed_data_ctr = 'b0;
                      total_stuffing_ctr = 'b0;
                      alternate_up_ctr = alternate_up_ctr_reg;
                      alternate_down_ctr = alternate_down_ctr_reg; 
                      sched_active_line = 'b0;                      
                    end
	//===================================================================//				
                    
    HBLANK:         begin
                      if(h_blank_ctr_reg == td_h_blank_ctr_max - 'b011) // max -4(for BE symbols) -1
                        begin
                          sched_steering_en       = 'b1;
                        end
                      else
                        begin
                           sched_steering_en      = 'b0;                        
                        end
                      //sched_steering_en           = 'b0;
                      // active_mapper 
                      sched_stream_state          = 'b0;
                      sched_stream_en_lane0       = 'b0;
                      sched_stream_en_lane1       = 'b0;
                      sched_stream_en_lane2       = 'b0;
                      sched_stream_en_lane3       = 'b0;
                      // blank_mapper
                      sched_blank_id              = 'b1; // HBlank
                      sched_blank_state           = 'b00;
                      if(td_lane_count_reg == 'b00) // 1 lane
                        begin
                          // blank_mapper
                          sched_blank_en_lane0        = 'b1;
                          sched_blank_en_lane1        = 'b0;
                          sched_blank_en_lane2        = 'b0;
                          sched_blank_en_lane3        = 'b0;
                          // idle_pattern
                          //sched_idle_en_lane0         = 'b0;
                          //sched_idle_en_lane1         = 'b1;
                          //sched_idle_en_lane2         = 'b1;
                          //sched_idle_en_lane3         = 'b1;
                          // stream_idle_mux
                          sched_stream_idle_sel_lane0_comb = 'b01;
                          sched_stream_idle_sel_lane1_comb = 'b0;
                          sched_stream_idle_sel_lane2_comb = 'b0;
                          sched_stream_idle_sel_lane3_comb = 'b0;                      
                        end
                      else if(td_lane_count_reg == 'b01) // 2 lanes
                        begin
                          sched_blank_en_lane0        = 'b1;
                          sched_blank_en_lane1        = 'b1;
                          sched_blank_en_lane2        = 'b0;
                          sched_blank_en_lane3        = 'b0;
                          
                          //sched_idle_en_lane0         = 'b0;
                          //sched_idle_en_lane1         = 'b0;
                          //sched_idle_en_lane2         = 'b1;
                          //sched_idle_en_lane3         = 'b1;
                      
                          sched_stream_idle_sel_lane0_comb = 'b01;
                          sched_stream_idle_sel_lane1_comb = 'b01;
                          sched_stream_idle_sel_lane2_comb = 'b0;
                          sched_stream_idle_sel_lane3_comb = 'b0;                      
                        end
                      else // 4 lanes
                        begin
                          sched_blank_en_lane0        = 'b1;
                          sched_blank_en_lane1        = 'b1;
                          sched_blank_en_lane2        = 'b1;
                          sched_blank_en_lane3        = 'b1;                        
                        
                          //sched_idle_en_lane0         = 'b0;
                          //sched_idle_en_lane1         = 'b0;
                          //sched_idle_en_lane2         = 'b0;
                          //sched_idle_en_lane3         = 'b0;
                      
                          sched_stream_idle_sel_lane0_comb = 'b01;
                          sched_stream_idle_sel_lane1_comb = 'b01;
                          sched_stream_idle_sel_lane2_comb = 'b01;
                          sched_stream_idle_sel_lane3_comb = 'b01;                      
                        end
    //-------------------------------------------------------------------//                    
                      h_total_ctr = h_total_ctr_reg;
                      h_blank_ctr = h_blank_ctr_reg + 'b1;
                      v_blank_ctr = v_blank_ctr_reg;    
    //-------------------------------------------------------------------//
                      if(td_hsync_reg == !td_hsync_polarity_reg && td_de_reg == 'b0)
                        begin
                          h_active_ctr = 'b0;
                        end
                      else
                        begin
                          h_active_ctr = h_active_ctr_reg;
                        end
    //-------------------------------------------------------------------//                    
                      v_active_ctr = v_active_ctr_reg;
                      tu_vld_data_ctr = 'b0;
                      tu_stuffed_data_ctr = 'b0;
                      total_stuffing_ctr = 'b0;
                      //alternate_up_ctr = alternate_up_ctr_reg;
                      //alternate_down_ctr = alternate_down_ctr_reg; 
                      alternate_up_ctr = 'b0;
                      alternate_down_ctr = 'b0;     
                      sched_active_line = 'b0;                                                             
                    end 
    //===================================================================//					
                    
    BE:             begin
                    //  if((h_blank_ctr == td_h_blank_ctr_max - 'b10) || (h_total_ctr == td_h_blank_ctr_max - 'b10) || (h_blank_ctr == td_h_blank_ctr_max - 'b1) || (h_total_ctr == td_h_blank_ctr_max - 'b1))
                    //    begin
                          sched_steering_en           = 'b1;                        
                    //    end
                    //  else
                    //    begin
                    //      sched_steering_en           = 'b0;                        
                    //    end
                        
                      // active_mapper 
                      sched_stream_state          = 'b0;
                      sched_stream_en_lane0       = 'b0;
                      sched_stream_en_lane1       = 'b0;
                      sched_stream_en_lane2       = 'b0;
                      sched_stream_en_lane3       = 'b0;
                      // blank_mapper
					  if(v_blank_flag)
					    begin
                          sched_blank_id              = 'b0; // VBlank						
						end
					  else
						begin
                          sched_blank_id              = 'b1; // HBlank						
						end
						
                      sched_blank_state           = 'b11;
                      if(td_lane_count_reg == 'b00) // 1 lane
                        begin
                          // blank_mapper
                          sched_blank_en_lane0        = 'b1;
                          sched_blank_en_lane1        = 'b0;
                          sched_blank_en_lane2        = 'b0;
                          sched_blank_en_lane3        = 'b0;

                          // stream_idle_mux
                          sched_stream_idle_sel_lane0_comb = 'b01;
                          sched_stream_idle_sel_lane1_comb = 'b0;
                          sched_stream_idle_sel_lane2_comb = 'b0;
                          sched_stream_idle_sel_lane3_comb = 'b0;                      
                        end
                      else if(td_lane_count_reg == 'b01) // 2 lanes
                        begin
                          sched_blank_en_lane0        = 'b1;
                          sched_blank_en_lane1        = 'b1;
                          sched_blank_en_lane2        = 'b0;
                          sched_blank_en_lane3        = 'b0;

                      
                          sched_stream_idle_sel_lane0_comb = 'b01;
                          sched_stream_idle_sel_lane1_comb = 'b01;
                          sched_stream_idle_sel_lane2_comb = 'b0;
                          sched_stream_idle_sel_lane3_comb = 'b0;                      
                        end
                      else // 4 lanes
                        begin
                          sched_blank_en_lane0        = 'b1;
                          sched_blank_en_lane1        = 'b1;
                          sched_blank_en_lane2        = 'b1;
                          sched_blank_en_lane3        = 'b1;                        
                      
                          sched_stream_idle_sel_lane0_comb = 'b01;
                          sched_stream_idle_sel_lane1_comb = 'b01;
                          sched_stream_idle_sel_lane2_comb = 'b01;
                          sched_stream_idle_sel_lane3_comb = 'b01;                      
                        end
    //-------------------------------------------------------------------//
                      if(v_blank_flag)
                        begin
                      h_total_ctr = h_total_ctr_reg + 'b1;
                        end
                      else
					    begin
                      h_total_ctr = h_total_ctr_reg;						
						end
						
                      //h_total_ctr = h_total_ctr_reg + 'b1;
                      h_blank_ctr = h_blank_ctr_reg + 'b1;
                      v_blank_ctr = v_blank_ctr_reg;
    //-------------------------------------------------------------------//
                      if(td_hsync_reg == !td_hsync_polarity_reg && td_de_reg == 'b0)
                        begin
                          h_active_ctr = 'b0;
                        end
                      else
                        begin
                          h_active_ctr = h_active_ctr_reg;
                        end
    //-------------------------------------------------------------------//                    
                      if(td_vsync_reg == !td_vsync_polarity_reg && td_de_reg == 'b0)
                        begin
                          v_active_ctr = 'b0;
                        end
                      else
                        begin
                          v_active_ctr = v_active_ctr_reg;
                        end
    //-------------------------------------------------------------------//                    
                      tu_vld_data_ctr = 'b0;
                      tu_stuffed_data_ctr = 'b0;
                      total_stuffing_ctr = 'b0;
                      alternate_up_ctr = alternate_up_ctr_reg;
                      alternate_down_ctr = alternate_down_ctr_reg; 
                      sched_active_line = 'b0;                    
                    end
    //===================================================================//					
                    
    ACTIVE_VLD:     begin
                      if(  ((tu_vld_data_ctr_reg == td_tu_vld_data_size_min - 'b1 && !alternate_up_flag)&&(total_stuffing_ctr_reg!=total_stuffing_req_reg)) 
                        || ((tu_vld_data_ctr_reg == td_tu_vld_data_size_min && alternate_up_flag)&&(total_stuffing_ctr_reg!=total_stuffing_req_reg))
						            || (h_active_ctr_reg == td_h_active_ctr_max - 'b1))
                        begin
                          sched_steering_en       = 'b0;
                        end
                      else
                        begin
                          sched_steering_en       = 'b1;
                        end
                      // blank_mapper
                      sched_blank_id              = 'b0; // VBlank
                      sched_blank_state           = 'b0;
                      sched_blank_en_lane0        = 'b0;
                      sched_blank_en_lane1        = 'b0;
                      sched_blank_en_lane2        = 'b0;
                      sched_blank_en_lane3        = 'b0;
                      if(td_lane_count_reg == 'b00) // 1 lane
                        begin
                          // active_mapper 
                          sched_stream_state          = 'b01; // active_vld
                          sched_stream_en_lane0       = 'b1;
                          sched_stream_en_lane1       = 'b0;
                          sched_stream_en_lane2       = 'b0;
                          sched_stream_en_lane3       = 'b0;

                          // stream_idle_mux
                          sched_stream_idle_sel_lane0_comb = 'b10;
                          sched_stream_idle_sel_lane1_comb = 'b0;
                          sched_stream_idle_sel_lane2_comb = 'b0;
                          sched_stream_idle_sel_lane3_comb = 'b0;                      
                        end
                      else if(td_lane_count_reg == 'b01) // 2 lanes
                        begin
                          // active_mapper 
                          sched_stream_state          = 'b01; // active_vld
                          sched_stream_en_lane0       = 'b1;
                          sched_stream_en_lane1       = 'b1;
                          sched_stream_en_lane2       = 'b0;
                          sched_stream_en_lane3       = 'b0;
                 
                          sched_stream_idle_sel_lane0_comb = 'b10;
                          sched_stream_idle_sel_lane1_comb = 'b10;
                          sched_stream_idle_sel_lane2_comb = 'b0;
                          sched_stream_idle_sel_lane3_comb = 'b0;                      
                        end
                      else // 4 lanes
                        begin
                          // active_mapper 
                          sched_stream_state          = 'b01; // active_vld
                          sched_stream_en_lane0       = 'b1;
                          sched_stream_en_lane1       = 'b1;
                          sched_stream_en_lane2       = 'b1;
                          sched_stream_en_lane3       = 'b1;                    
                      
                          sched_stream_idle_sel_lane0_comb = 'b10;
                          sched_stream_idle_sel_lane1_comb = 'b10;
                          sched_stream_idle_sel_lane2_comb = 'b10;
                          sched_stream_idle_sel_lane3_comb = 'b10;                      
                        end
    //-------------------------------------------------------------------//                    
                      h_active_ctr = h_active_ctr_reg + 'b1;
    //-------------------------------------------------------------------//                  
                      if(h_active_ctr == td_h_active_ctr_max)
                      begin
                        v_active_ctr = v_active_ctr_reg + 1'b1;
                      end
                      else
                      begin
                        v_active_ctr = v_active_ctr_reg;
                      end
    //-------------------------------------------------------------------//                  
                      if(v_active_ctr == td_v_active_ctr_max)
                      begin
                        v_blank_ctr = 'b0;
                      end
                      else
                      begin
                        v_blank_ctr = v_blank_ctr_reg;
                      end
    //-------------------------------------------------------------------//                  
                      tu_vld_data_ctr = tu_vld_data_ctr_reg + 'b1;
    //-------------------------------------------------------------------//                  
                      if(alternate_up_ctr_reg == td_tu_alternate_up_reg)
                      begin
                        alternate_down_ctr = 'b0;
                        alternate_up_ctr = 'b0;                        
                      end    
                      else
                      begin                      
                        alternate_up_ctr = alternate_up_ctr_reg;
                        alternate_down_ctr = alternate_down_ctr_reg;    
                      end                      
    //-------------------------------------------------------------------//
                      h_total_ctr = 'b0;
                      h_blank_ctr = 'b0;
                      tu_stuffed_data_ctr = 'b0; 
                      total_stuffing_ctr = total_stuffing_ctr_reg;
                      sched_active_line = 'b1;                        
                    end 
    //===================================================================//					
                    
    FS:             begin
                      sched_steering_en           = 'b0;
                      // blank_mapper
                      sched_blank_id              = 'b0; // VBlank
                      sched_blank_state           = 'b0;
                      sched_blank_en_lane0        = 'b0;
                      sched_blank_en_lane1        = 'b0;
                      sched_blank_en_lane2        = 'b0;
                      sched_blank_en_lane3        = 'b0;
                      if(td_lane_count_reg == 'b00) // 1 lane
                        begin
                          // active_mapper 
                          sched_stream_state          = 'b10; // fs
                          sched_stream_en_lane0       = 'b1;
                          sched_stream_en_lane1       = 'b0;
                          sched_stream_en_lane2       = 'b0;
                          sched_stream_en_lane3       = 'b0;

                          // stream_idle_mux
                          sched_stream_idle_sel_lane0_comb = 'b10;
                          sched_stream_idle_sel_lane1_comb = 'b0;
                          sched_stream_idle_sel_lane2_comb = 'b0;
                          sched_stream_idle_sel_lane3_comb = 'b0;                      
                        end
                      else if(td_lane_count_reg == 'b01) // 2 lanes
                        begin
                          // active_mapper 
                          sched_stream_state          = 'b10; // fs
                          sched_stream_en_lane0       = 'b1;
                          sched_stream_en_lane1       = 'b1;
                          sched_stream_en_lane2       = 'b0;
                          sched_stream_en_lane3       = 'b0;
                          
                      
                          sched_stream_idle_sel_lane0_comb = 'b10;
                          sched_stream_idle_sel_lane1_comb = 'b10;
                          sched_stream_idle_sel_lane2_comb = 'b0;
                          sched_stream_idle_sel_lane3_comb = 'b0;                      
                        end
                      else // 4 lanes
                        begin
                          // active_mapper 
                          sched_stream_state          = 'b10; // fs
                          sched_stream_en_lane0       = 'b1;
                          sched_stream_en_lane1       = 'b1;
                          sched_stream_en_lane2       = 'b1;
                          sched_stream_en_lane3       = 'b1;                    
                        
                          sched_stream_idle_sel_lane0_comb = 'b10;
                          sched_stream_idle_sel_lane1_comb = 'b10;
                          sched_stream_idle_sel_lane2_comb = 'b10;
                          sched_stream_idle_sel_lane3_comb = 'b10;                      
                        end 
    //-------------------------------------------------------------------//
                      tu_vld_data_ctr = 'b0;	
                      tu_stuffed_data_ctr = tu_stuffed_data_ctr_reg + 'b1;
                      total_stuffing_ctr = total_stuffing_ctr_reg + 'b1;    
    //-------------------------------------------------------------------//
                      h_total_ctr = 'b0;
                      h_blank_ctr = 'b0;
                      v_blank_ctr = v_blank_ctr_reg;
                      v_active_ctr = v_active_ctr_reg;
                      h_active_ctr = h_active_ctr_reg;
    //-------------------------------------------------------------------//
                      alternate_up_ctr = alternate_up_ctr_reg;
                      alternate_down_ctr = alternate_down_ctr_reg;   
                      sched_active_line = 'b1;                   
                    end
	//===================================================================//				
                    
    ACTIVE_STUFFING:   
                    begin
                      sched_steering_en           = 'b0;
                      // blank_mapper
                      sched_blank_id              = 'b0; // VBlank
                      sched_blank_state           = 'b0;
                      sched_blank_en_lane0        = 'b0;
                      sched_blank_en_lane1        = 'b0;
                      sched_blank_en_lane2        = 'b0;
                      sched_blank_en_lane3        = 'b0;
                      if(td_lane_count_reg == 'b00) // 1 lane
                        begin
                          // active_mapper 
                          sched_stream_state          = 'b00; // active_stuffing
                          sched_stream_en_lane0       = 'b1;
                          sched_stream_en_lane1       = 'b0;
                          sched_stream_en_lane2       = 'b0;
                          sched_stream_en_lane3       = 'b0;

                          // stream_idle_mux
                          sched_stream_idle_sel_lane0_comb = 'b10;
                          sched_stream_idle_sel_lane1_comb = 'b0;
                          sched_stream_idle_sel_lane2_comb = 'b0;
                          sched_stream_idle_sel_lane3_comb = 'b0;                      
                        end
                      else if(td_lane_count_reg == 'b01) // 2 lanes
                        begin
                          // active_mapper 
                          sched_stream_state          = 'b00; // active_stuffing
                          sched_stream_en_lane0       = 'b1;
                          sched_stream_en_lane1       = 'b1;
                          sched_stream_en_lane2       = 'b0;
                          sched_stream_en_lane3       = 'b0;
                          
                      
                          sched_stream_idle_sel_lane0_comb = 'b10;
                          sched_stream_idle_sel_lane1_comb = 'b10;
                          sched_stream_idle_sel_lane2_comb = 'b0;
                          sched_stream_idle_sel_lane3_comb = 'b0;                      
                        end
                      else // 4 lanes
                        begin
                          // active_mapper 
                          sched_stream_state          = 'b00; // active_stuffing
                          sched_stream_en_lane0       = 'b1;
                          sched_stream_en_lane1       = 'b1;
                          sched_stream_en_lane2       = 'b1;
                          sched_stream_en_lane3       = 'b1;                    
                      
                          sched_stream_idle_sel_lane0_comb = 'b10;
                          sched_stream_idle_sel_lane1_comb = 'b10;
                          sched_stream_idle_sel_lane2_comb = 'b10;
                          sched_stream_idle_sel_lane3_comb = 'b10;                      
                        end
    //-------------------------------------------------------------------//  
                      tu_vld_data_ctr = 'b0;	
                      tu_stuffed_data_ctr = tu_stuffed_data_ctr_reg + 'b1; 
                      total_stuffing_ctr = total_stuffing_ctr_reg + 'b1;       
    //-------------------------------------------------------------------//
                      h_total_ctr = 'b0;
                      h_blank_ctr = 'b0;
                      v_blank_ctr = v_blank_ctr_reg;
                      v_active_ctr = v_active_ctr_reg;
                      h_active_ctr = h_active_ctr_reg;                      
    //-------------------------------------------------------------------//
                      alternate_up_ctr = alternate_up_ctr_reg;
                      alternate_down_ctr = alternate_down_ctr_reg;
                      sched_active_line = 'b1;
                    end
	//===================================================================//				
                    
    FE:             begin
                      if((total_stuffing_ctr_reg == total_stuffing_req_reg - 1)&&(h_active_ctr_reg == td_h_active_ctr_max))
                        begin
                          sched_steering_en           = 'b0;
                        end
                        else
                        begin
                          sched_steering_en           = 'b1;
                        end  
                      //sched_steering_en           = 'b1;

                      // blank_mapper
                      sched_blank_id              = 'b0; // VBlank
                      sched_blank_state           = 'b0;
                      sched_blank_en_lane0        = 'b0;
                      sched_blank_en_lane1        = 'b0;
                      sched_blank_en_lane2        = 'b0;
                      sched_blank_en_lane3        = 'b0;
                      if(td_lane_count_reg == 'b00) // 1 lane
                        begin
                          // active_mapper 
                          sched_stream_state          = 'b11; // FE
                          sched_stream_en_lane0       = 'b1;
                          sched_stream_en_lane1       = 'b0;
                          sched_stream_en_lane2       = 'b0;
                          sched_stream_en_lane3       = 'b0;

                          // stream_idle_mux
                          sched_stream_idle_sel_lane0_comb = 'b10;
                          sched_stream_idle_sel_lane1_comb = 'b0;
                          sched_stream_idle_sel_lane2_comb = 'b0;
                          sched_stream_idle_sel_lane3_comb = 'b0;                      
                        end
                      else if(td_lane_count_reg == 'b01) // 2 lanes
                        begin 
                          sched_stream_state          = 'b11; // FE
                          sched_stream_en_lane0       = 'b1;
                          sched_stream_en_lane1       = 'b1;
                          sched_stream_en_lane2       = 'b0;
                          sched_stream_en_lane3       = 'b0;

                          //------------------------------//
                          sched_stream_idle_sel_lane0_comb = 'b10;
                          sched_stream_idle_sel_lane1_comb = 'b10;
                          sched_stream_idle_sel_lane2_comb = 'b0;
                          sched_stream_idle_sel_lane3_comb = 'b0;                      
                        end
                      else // 4 lanes
                        begin 
                          sched_stream_state          = 'b11; // FE
                          sched_stream_en_lane0       = 'b1;
                          sched_stream_en_lane1       = 'b1;
                          sched_stream_en_lane2       = 'b1;
                          sched_stream_en_lane3       = 'b1;                    

                          //-------------------------------//
                          sched_stream_idle_sel_lane0_comb = 'b10;
                          sched_stream_idle_sel_lane1_comb = 'b10;
                          sched_stream_idle_sel_lane2_comb = 'b10;
                          sched_stream_idle_sel_lane3_comb = 'b10;                      
                        end 
                      //------------------------------------------------//  
                      tu_vld_data_ctr = 'b0;					  
                      tu_stuffed_data_ctr = tu_stuffed_data_ctr_reg + 'b1;
                      total_stuffing_ctr = total_stuffing_ctr_reg + 'b1;
                      //------------------------------------------------//					  
                      h_total_ctr = 'b0;
                      h_blank_ctr = 'b0;
                      v_blank_ctr = v_blank_ctr_reg;
                      v_active_ctr = v_active_ctr_reg;
                      h_active_ctr = h_active_ctr_reg;   
                      //------------------------------------------------//
                      if((tu_stuffed_data_ctr_reg == td_tu_stuffed_data_size_max - 'b1) && !alternate_up_flag)
                      begin
                        alternate_down_ctr = alternate_down_ctr_reg + 'b1;
                        alternate_up_ctr = 'b0;
                      end
                      else if((tu_stuffed_data_ctr_reg == td_tu_stuffed_data_size_max - 'b10) && alternate_up_flag)
                      begin
                        alternate_down_ctr = alternate_down_ctr_reg;
                        alternate_up_ctr = alternate_up_ctr_reg + 'b1;
                      end    
                      else
                      begin
                        alternate_down_ctr = alternate_down_ctr_reg;
                        alternate_up_ctr = alternate_up_ctr_reg;                        
                      end 
                      sched_active_line = 'b1;                     
                    end
	//===================================================================//				
                    
    default:        begin
                      sched_steering_en           = 'b0;
                      //------------------------------//  
                      sched_stream_state          = 'b0;
                      sched_stream_en_lane0       = 'b0;
                      sched_stream_en_lane1       = 'b0;
                      sched_stream_en_lane2       = 'b0;
                      sched_stream_en_lane3       = 'b0;
                      //------------------------------// 
                      sched_blank_id              = 'b0;
                      sched_blank_state           = 'b0;
                      sched_blank_en_lane0        = 'b0;
                      sched_blank_en_lane1        = 'b0;
                      sched_blank_en_lane2        = 'b0;
                      sched_blank_en_lane3        = 'b0;
                      //------------------------------// 
  
                      //------------------------------//
                      sched_stream_idle_sel_lane0_comb = 'b0;
                      sched_stream_idle_sel_lane1_comb = 'b0;
                      sched_stream_idle_sel_lane2_comb = 'b0;
                      sched_stream_idle_sel_lane3_comb = 'b0;
                      //------------------------------//
                      tu_vld_data_ctr = 'b0;					  
                      tu_stuffed_data_ctr = 'b0; 
                      total_stuffing_ctr = 'b0;
                      //------------------------------//					  
                      h_total_ctr = 'b0;
                      h_blank_ctr = 'b0;
                      v_blank_ctr = v_blank_ctr_reg;
                      v_active_ctr = v_active_ctr_reg;
                      h_active_ctr = h_active_ctr_reg;   
                      //------------------------------//
                      alternate_up_ctr = alternate_up_ctr_reg;
                      alternate_down_ctr = alternate_down_ctr_reg;   
                      sched_active_line = 'b0;                   
                    end
    endcase    

  end 
  
endmodule

`resetall






