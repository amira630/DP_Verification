module  sec_bus_steering 
(
    input  wire         clk,
    input  wire         rst_n,
    input  wire [1:0]   td_lane_count,
    input  wire         td_vld_data,
    input  wire [191:0] spm_msa,
    input  wire         spm_vld,
    input  wire [1:0]   blank_steering_state0,
    input  wire [1:0]   blank_steering_state1,
    input  wire [1:0]   blank_steering_state2,
    input  wire [1:0]   blank_steering_state3,
    output reg  [7:0]   sec_steered_lane0,
    output reg  [7:0]   sec_steered_lane1,
    output reg  [7:0]   sec_steered_lane2,
    output reg  [7:0]   sec_steered_lane3,
    output reg          sec_steered_lane_vld
);

    reg [1:0] blank_steering_state;
    reg [7:0] memory [0:35];
    reg [5:0] i;
    reg[1:0] lane_count_sync;
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) 
        begin
            lane_count_sync <= 2'b00;
        end 
        else 
        if(td_vld_data == 1)
        begin
            lane_count_sync <= td_lane_count;
        end
    end

    always_comb begin
        case(lane_count_sync)
            2'b00: // one lane is enabled
            begin
                blank_steering_state = blank_steering_state0;
            end
            2'b01: // two lanes are enabled
            begin
                if(blank_steering_state0 == blank_steering_state1) 
                begin
                    blank_steering_state = blank_steering_state0;
                end
                else
                begin
                    blank_steering_state = 2'b00;
                end
            end
            2'b11: // four lanes are enabled
            begin
                if(blank_steering_state0 == blank_steering_state1 && blank_steering_state1 == blank_steering_state2 && blank_steering_state2 == blank_steering_state3) 
                begin
                    blank_steering_state = blank_steering_state0;
                end
                else
                begin
                    blank_steering_state = 2'b00;
                end
            end
            default: blank_steering_state = 2'b00; // Default case to avoid latches
        endcase
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) 
        begin
            // Reset memory to 0
            memory <= '{default: 8'b0};
        end 
        else 
        if(spm_vld == 1)
        begin
            memory[0]  <= spm_msa[191:184];//Mvid_0
            memory[1]  <= spm_msa[183:176];//Mvid_1
            memory[2]  <= spm_msa[175:168];//Mvid_2

            memory[3]  <= spm_msa[143:136];//Htotal_0
            memory[4]  <= spm_msa[135:128];//Htotal_1

            memory[5]  <= spm_msa[127:120];//Vtotal_0
            memory[6]  <= spm_msa[119:112];//Vtotal_1

            memory[7]  <= spm_msa[79:72];//HSP_HSW
            memory[8]  <= spm_msa[71:64];//HSW

            memory[9]  <= spm_msa[191:184];//Mvid_0
            memory[10] <= spm_msa[183:176];//Mvid_1
            memory[11] <= spm_msa[175:168];//Mvid_2

            memory[12] <= spm_msa[111:104];//HStart_0
            memory[13] <= spm_msa[103:96];//HStart_1

            memory[14] <= spm_msa[95:88];//VStart_0
            memory[15] <= spm_msa[87:80];//VStart_1

            memory[16] <= spm_msa[63:56];//VSP_VSW
            memory[17] <= spm_msa[55:48];//VSW

            memory[18] <= spm_msa[191:184];//Mvid_0
            memory[19] <= spm_msa[183:176];//Mvid_1
            memory[20] <= spm_msa[175:168];//Mvid_2

            memory[21] <= spm_msa[47:40];//Hwidth_0
            memory[22] <= spm_msa[39:32];//Hwidth_1

            memory[23] <= spm_msa[31:24];//Vheight_0
            memory[24] <= spm_msa[23:16];//Vheight_1

            memory[25] <= 8'd0;//all 0s
            memory[26] <= 8'd0;//all 0s

            memory[27] <= spm_msa[191:184];//Mvid_0
            memory[28] <= spm_msa[183:176];//Mvid_1
            memory[29] <= spm_msa[175:168];//Mvid_2

            memory[30] <= spm_msa[167:160];//Nvid_0
            memory[31] <= spm_msa[159:152];//Nvid_1
            memory[32] <= spm_msa[151:144];//Nvid_2

            memory[33] <= spm_msa[15:8];//Misc0 
            memory[34] <= spm_msa[7:0];//Misc1

            memory[35]  <= 8'd0;//all 0s
        end
    end 
  


    always_ff@(posedge clk or negedge rst_n)
    begin
        if(~rst_n)
        begin
            sec_steered_lane0 <= 7'b0;
            sec_steered_lane1 <= 7'b0;
            sec_steered_lane2 <= 7'b0;
            sec_steered_lane3 <= 7'b0;
            i <= 0;
            sec_steered_lane_vld <= 0;
        end
        else
        begin
            case (blank_steering_state)
                2'b00: // all lanes are disabled 
                begin
                    sec_steered_lane0 <= 7'b0;
                    sec_steered_lane1 <= 7'b0;
                    sec_steered_lane2 <= 7'b0;
                    sec_steered_lane3 <= 7'b0;
                    i <= 0;
                end
                2'b01: // sending Mvid[7:0] 
                begin
                    case(lane_count_sync)
                        2'b11: // four lanes are enabled
                        begin
                            sec_steered_lane0 <= memory[2];
                            sec_steered_lane1 <= memory[2];
                            sec_steered_lane2 <= memory[2];
                            sec_steered_lane3 <= memory[2];
                            sec_steered_lane_vld <= 1;
                        end
                        2'b01: // two lanes are enabled
                        begin
                            sec_steered_lane0 <= memory[2];
                            sec_steered_lane1 <= memory[2];
                            sec_steered_lane2 <= 8'd0;
                            sec_steered_lane3 <= 8'd0;
                            sec_steered_lane_vld <= 1;
                        end
                        2'b00: // one lane is enabled
                        begin
                            sec_steered_lane0 <= memory[2];
                            sec_steered_lane1 <= 8'd0;
                            sec_steered_lane2 <= 8'd0;
                            sec_steered_lane3 <= 8'd0;
                            sec_steered_lane_vld <= 1;
                        end
                        default: // no lane is enabled
                        begin
                            sec_steered_lane0 <= 8'd0;
                            sec_steered_lane1 <= 8'd0;
                            sec_steered_lane2 <= 8'd0;
                            sec_steered_lane3 <= 8'd0;
                            sec_steered_lane_vld <= 0;
                        end
                    endcase
                    i <= 0;
                end
                2'b10: // sending MSA
                    case(lane_count_sync)
                        2'b11: // four lanes are enabled

                        begin
                            if( i < 9 ) 
                            begin
                                sec_steered_lane0 <= memory[i];
                                sec_steered_lane1 <= memory[i+9];
                                sec_steered_lane2 <= memory[i+18];
                                sec_steered_lane3 <= memory[i+27];
                                i <= i + 1;
                                sec_steered_lane_vld <= 1;
                            end
                            else 
                            begin
                                sec_steered_lane_vld <= 0;
                            end
                        end
                        2'b01: // two lanes are enabled
                        begin
                            if( i < 18 )
                            begin
                                if(i<9)
                                begin
                                    sec_steered_lane0 <= memory[i];
                                    sec_steered_lane1 <= memory[i+9];
                                    sec_steered_lane2 <= 7'b0;
                                    sec_steered_lane3 <= 7'b0;
                                    i <= i + 1;
                                end
                                else
                                begin
                                    sec_steered_lane0 <= memory[i+9];
                                    sec_steered_lane1 <= memory[i+18];
                                    sec_steered_lane2 <= 7'b0;
                                    sec_steered_lane3 <= 7'b0;
                                    i <= i + 1;
                                end
                                sec_steered_lane_vld <= 1;
                            end
                            else
                            begin
                                sec_steered_lane_vld <= 0;
                            end
                        end
                        2'b00: // one lane is enabled
                        begin
                            if( i < 36 )
                            begin
                                sec_steered_lane0 <= memory[i];
                                sec_steered_lane1 <= 7'b0;
                                sec_steered_lane2 <= 7'b0;
                                sec_steered_lane3 <= 7'b0;
                                i <= i + 1;
                                sec_steered_lane_vld <= 1;
                            end
                            else
                            begin
                                sec_steered_lane_vld <= 0;
                            end
                        end
                        default: // no lane is enabled
                        begin
                            sec_steered_lane0 <= 7'b0;
                            sec_steered_lane1 <= 7'b0;
                            sec_steered_lane2 <= 7'b0;
                            sec_steered_lane3 <= 7'b0;
                            i <= 0;
                        end
                    endcase
                default: 
                begin
                    sec_steered_lane0 <= 7'b0;
                    sec_steered_lane1 <= 7'b0;
                    sec_steered_lane2 <= 7'b0;
                    sec_steered_lane3 <= 7'b0;
                    i <= 0;
                end
            endcase
        end
    end       
endmodule


