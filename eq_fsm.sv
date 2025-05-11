/////////////////////////////////////////////////////////
//                                                     //
//            LINK TRAINING MODULE                     //
//                                                     //
//  This module implements the link training logic     //
//  for high-speed communication between devices.      //
//  It manages initialization, training sequences,     //
//  and error handling to establish a stable link.     //
//  In this part of link training, we manage           //
//  channel equalization, lane alignment, and symbol   //
//  lock.                                              //
//                                                     //
//       Author:  Mohammed Tersawy                     //
//                                                     //
/////////////////////////////////////////////////////////

`default_nettype none  // Disable implicit net declarations

module eq_fsm 
(   //==============================================================
    // Input and Output Ports
    //==============================================================
    input  wire        clk,          // 100 kHz clock input
    input  wire        rst_n,        // Reset signal
    input  wire [7:0]  vtg,
    input  wire [7:0]  pre,
    input  wire [3:0]  eq_cr_dn,
    input  wire [3:0]  channel_eq,
    input  wire [3:0]  symbol_lock,
    input  wire [7:0]  lane_align,
    input  wire        eq_data_vld,
    input  wire        eq_ctr_fire,
    input  wire        eq_start,
    input  wire [7:0]  new_vtg,
    input  wire [7:0]  new_pre,
    input  wire [7:0]  new_bw,
    input  wire [1:0]  new_lc,
    input  wire        ctrl_ack_flag,
    input  wire        eq_err_chk_failed, // Interface with channel equalization FSM
    input  wire [1:0]  tps,
    input  wire        tps_vld, // Valid signal sent when initiating clock recovery to save max supported TPS value
    input  wire        ctrl_native_failed, // this flag is asserted when defer occurred for more than seven times
    input  wire [1:0]  max_vtg, // Max supported voltage swing
    input  wire [1:0]  max_pre, // Max supported pre emphasis 
    // ===============================================================
    // Output Ports
    //================================================================
    output reg         eq_lt_failed,
    output reg         eq_lt_pass,
    output reg  [1:0]  eq_final_adj_lc,
    output reg  [7:0]  eq_final_adj_bw,
    output reg  [1:0]  eq_phy_instruct,
    output reg         eq_phy_instruct_vld,
    output reg  [1:0]  eq_adj_lc,
    output reg  [7:0]  eq_adj_bw,
    output reg         eq_ctr_start,
    output reg         eq_fsm_start_cr_err, // Interface with error check FSM
    output reg         eq_fsm_start_eq_err, // Interface with error check FSM
    output reg  [3:0]  eq_fsm_cr_dn,        // Interface with error check FSM
    output reg  [7:0]  eq_data,
    output reg  [19:0] eq_address,
    output reg  [7:0]  eq_len,
    output reg  [1:0]  eq_cmd,
    output reg         eq_transaction_vld,
    output reg         eq_fsm_cr_failed // this signal flag is asserted to the link policy maker indicating that eq failed and i will begin cr again
);




/////////////////////////////////////////////////////////
//                   TYPE DEFINITIONS                  //
/////////////////////////////////////////////////////////

typedef enum reg [3:0] 
{
    IDLE                = 4'b0000,  
    TPS                 = 4'b0001,  
    WAIT                = 4'b0011,  
    READ_ADJ_SETTINGS   = 4'b0010,  
    CHK_CR              = 4'b0110,  
    CHK_EQ              = 4'b0111,  
    WRITE_ADJ_SETTINGS  = 4'b0100,
    PASS                = 4'b1000,
    FAIL                = 4'b1001
} state_t;

state_t    current_state, next_state;

/////////////////////////////////////////////////////////
//local parameters 
/////////////////////////////////////////////////////////
localparam WIDTH = 128;

// internal signals 
reg [1:0]       tps_sync;
reg [2:0]       shift_amount_reg;
reg [2:0]       shift_counter;
reg            eq_dn; 
reg            cr_dn;
reg             max_loop_count;             // flag to indicate that i have reached maax itirations 
reg [2:0]       loop_count; 
reg [2:0]       loop_count_reg; // loop counter counts the number of times the channel equalization failed 
reg [WIDTH-1:0] data_buffer; // buffer to save the message transction data
reg [WIDTH-1:0] data_shifter;
reg [7:0]       config_103_reg, config_104_reg, config_105_reg, config_106_reg; 
reg             saving_flag;
wire            load_flag_reg;  // this flag is used to enter shifting register after loading data in data_shifter register 
reg             load_flag_d;
reg             load_flag;        // flag to indicate that the message buffer is ready to be loaded  in data_shifter

//==============================================================
// synchronized inputs 
//==============================================================
reg [3:0] eq_cr_dn_sync;
reg [3:0] channel_eq_sync;
reg [3:0] symbol_lock_sync;
reg [7:0] lane_align_sync;
reg [7:0] new_bw_sync;
reg [1:0] new_lc_sync;
reg [1:0] max_vtg_sync;
reg [1:0] max_pre_sync;



//==============================================================
// comb output logic
//==============================================================
reg             eq_lt_failed_comb;
reg             eq_lt_pass_comb;
reg     [1:0]   eq_final_adj_lc_comb;
reg     [7:0]   eq_final_adj_bw_comb;
reg     [1:0]   eq_phy_instruct_comb;
reg     [1:0]   eq_adj_lc_comb;
reg     [7:0]   eq_adj_bw_comb;
reg             eq_ctr_start_comb;
reg             eq_fsm_start_cr_err_comb;
reg             eq_fsm_start_eq_err_comb;
reg     [3:0]   eq_fsm_cr_dn_comb;
reg     [7:0]   eq_data_comb;
reg     [19:0]  eq_address_comb;
reg     [7:0]   eq_len_comb;
reg     [1:0]   eq_cmd_comb;
reg             eq_transaction_vld_comb;
reg     [2:0]   shift_amount;
reg             eq_phy_instruct_vld_comb; // valid signal to indicate the validity of data on phy interface ports
reg             eq_fsm_cr_failed_comb;// this signal flag is asserted to the link policy maker indicating that eq failed and i will begin cr again



//==============================================================
// state transition logic
//==============================================================
always_ff@(posedge clk or negedge rst_n) begin
    if(!rst_n)
    begin
        current_state  <= IDLE;
        loop_count_reg <= 3'd0;
    end
    else 
    begin
        current_state  <= next_state;
        loop_count_reg <= loop_count;
    end
end


//==============================================================
// saving max TPS value supported by sink device  
//==============================================================
always_ff@(posedge clk or  negedge rst_n) begin
    if(!rst_n) 
    begin
        tps_sync     <= 2'b00;
        max_vtg_sync <= 2'b00;
        max_pre_sync <= 2'b00;
    end
    else
    if(tps_vld) //valid signal must be sent when intiating link trainning to indicate the max suported TPSs value
    begin
        tps_sync     <= tps;
        max_vtg_sync <= max_vtg;
        max_pre_sync <= max_pre;
    end
end

//============================================================================================
// saving the clock recovery , symbol lock , lane allign and channel equalization registers
// constructing the the update adjust settings 103-106 registers message
// saving the new bandwidth and lane count
//=============================================================================================
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) 
    begin
        config_103_reg   <= 8'd0;
        config_104_reg   <= 8'd0;
        config_105_reg   <= 8'd0;
        config_106_reg   <= 8'd0;
        eq_cr_dn_sync    <= 4'd0;
        channel_eq_sync  <= 4'd0;
        symbol_lock_sync <= 4'd0;
        lane_align_sync  <= 8'd0;
        saving_flag      <= 1'd0; 
        new_bw_sync      <= 8'd0;
        new_lc_sync      <= 2'd0;  
    end 
    else 
    if (eq_start) 
    begin
        config_103_reg <= {2'b00, (max_pre_sync == new_pre[1:0]), new_pre[1:0], (max_vtg_sync == new_vtg[1:0]), new_vtg[1:0]};
        config_104_reg <= {2'b00, (max_pre_sync == new_pre[3:2]), new_pre[3:2], (max_vtg_sync == new_vtg[3:2]), new_vtg[3:2]};
        config_105_reg <= {2'b00, (max_pre_sync == new_pre[5:4]), new_pre[5:4], (max_vtg_sync == new_vtg[5:4]), new_vtg[5:4]};
        config_106_reg <= {2'b00, (max_pre_sync == new_pre[7:6]), new_pre[7:6], (max_vtg_sync == new_vtg[7:6]), new_vtg[7:6]};
        new_bw_sync    <= new_bw;
        new_lc_sync    <= new_lc;
    end 
    else 
    if (eq_data_vld) // data requested to be read are saved in the registers
    begin
        config_103_reg   <= {2'b00, (max_pre_sync == pre[1:0]), pre[1:0], (max_vtg_sync == vtg[1:0]), vtg[1:0]};
        config_104_reg   <= {2'b00, (max_pre_sync == pre[3:2]), pre[3:2], (max_vtg_sync == vtg[3:2]), vtg[3:2]};
        config_105_reg   <= {2'b00, (max_pre_sync == pre[5:4]), pre[5:4], (max_vtg_sync == vtg[5:4]), vtg[5:4]};
        config_106_reg   <= {2'b00, (max_pre_sync == pre[7:6]), pre[7:6], (max_vtg_sync == vtg[7:6]), vtg[7:6]};
        eq_cr_dn_sync    <= eq_cr_dn;
        channel_eq_sync  <= channel_eq;
        symbol_lock_sync <= symbol_lock;
        lane_align_sync  <= lane_align;
        saving_flag      <= 1'b1;  // this flag is asserted after data requested to be read has arrived  
    end
    else 
    if (next_state == WAIT) 
    begin
        saving_flag      <= 1'b0;
    end
end
//==============================================================
// checking flags for clock recovery done and channel equalization done 
//==============================================================

always_comb begin
    // default value 
    eq_dn = 1'b0;
    if (saving_flag) begin
        case (new_lc_sync)
            2'b00:
            begin
                if ((lane_align_sync == 8'b11111111) && (channel_eq_sync[0] == 1'b1) && (symbol_lock_sync[0] == 1'b1)) 
                begin
                    eq_dn = 1'b1;
                end 
                else 
                begin
                    eq_dn = 1'b0;
                end
            end
            2'b01: 
            begin
                if ((lane_align_sync == 8'b11111111) && (channel_eq_sync[1:0] == 2'b11) && (symbol_lock_sync[1:0] == 2'b11)) 
                begin
                    eq_dn = 1'b1;
                end 
                else 
                begin
                    eq_dn = 1'b0;
                end
            end
            2'b11: 
            begin
                if ((lane_align_sync == 8'b11111111) && (channel_eq_sync == 4'b1111) && (symbol_lock_sync == 4'b1111)) 
                begin
                    eq_dn = 1'b1;
                end 
                else 
                begin
                    eq_dn = 1'b0;
                end
            end
            default: 
            begin
                eq_dn = 1'b0;
            end
        endcase
    end 
    else 
    begin
        eq_dn = 1'b0;
    end
end
always_comb begin
    //default value 
    cr_dn = 1'b0;
    if (saving_flag)
    begin
        case (new_lc_sync)
        2'b00:
        begin
            if(eq_cr_dn_sync[0] == 1'b1)
            begin
                cr_dn = 1'b1;
            end
            else 
            begin
                cr_dn = 1'b0;
            end
        end
        2'b01:
        begin
            if(eq_cr_dn_sync[1:0] == 2'b11)
            begin
                cr_dn = 1'b1;
            end
            else 
            begin
                cr_dn = 1'b0;
            end
        end
        2'b11:
        begin
            if(eq_cr_dn_sync == 4'b1111)
            begin
                cr_dn  = 1'b1;
            end
            else
            begin
                cr_dn = 1'b0;
            end
        end
        default:
        begin
            cr_dn = 1'b0;
        end
        endcase
    end
    else 
    begin
        cr_dn = 1'b0;
    end
end


//==============================================================
// next state logic
//==============================================================
always_comb begin
    loop_count     = loop_count_reg;
    max_loop_count = 1'b0;
    case(current_state) 
        IDLE: 
        begin
            if (eq_start) 
            begin
                next_state = TPS;
            end
            else 
            if (eq_err_chk_failed) 
            begin
                next_state = FAIL;
            end
            else 
            begin 
                next_state = IDLE;
            end
        end
        TPS: 
        begin
            if (ctrl_ack_flag) 
            begin
                next_state = WAIT;
                loop_count = 3'd0;
            end
            else
            if(ctrl_native_failed)
            begin
                next_state = IDLE; // if i cannot send my read or write transction i will return to idle state. 
            end 
            else
            begin
                next_state = TPS;
            end
        end
        WAIT: 
        begin
            if (eq_ctr_fire) 
            begin
                next_state = READ_ADJ_SETTINGS;
            end
            else 
            begin
                next_state = WAIT;
            end
        end
        READ_ADJ_SETTINGS: 
        begin
            if (ctrl_ack_flag) 
            begin
                next_state = CHK_CR;
            end
            else 
            if(ctrl_native_failed) 
            begin
                next_state = IDLE; 
            end
            else
            begin
                next_state = READ_ADJ_SETTINGS;
            end
        end
        CHK_CR: 
        begin
            if(saving_flag)
            begin
                if (cr_dn) 
                begin
                    next_state = CHK_EQ;
                end
                else 
                begin
                    next_state = IDLE;
                end
            end
            else 
            begin
                next_state = CHK_CR;
            end
        end
        CHK_EQ: 
        begin
            if(saving_flag)
            begin
                if(eq_dn == 1'b0)
                begin
                    loop_count = loop_count_reg + 3'd1;
                    if(loop_count == 3'd6)
                    begin
                        next_state = IDLE;
                        max_loop_count = 1'b1;                   
                    end
                    else
                    begin
                        next_state = WRITE_ADJ_SETTINGS;
                    end 
                end
                else 
                begin
                    next_state = PASS;
                end
            end
            else 
            begin
                next_state = CHK_EQ;
            end
        end
        WRITE_ADJ_SETTINGS: 
        begin
            if (ctrl_ack_flag) 
            begin
                next_state = WAIT;
            end
            else 
            if(ctrl_native_failed)
            begin
                next_state = IDLE; 
            end
            else
            begin
                next_state = WRITE_ADJ_SETTINGS;
            end
        end
        PASS:
        begin
            if (ctrl_ack_flag || ctrl_native_failed) 
            begin
                next_state = IDLE;
            end
            else 
            begin
                next_state = PASS;
            end
        end
        FAIL:
        begin
            if (ctrl_ack_flag || ctrl_native_failed) 
            begin
                next_state = IDLE;
            end
            else 
            begin
                next_state = FAIL;
            end
        end
        default: 
        begin
            next_state = IDLE;
        end
    endcase
end

//==============================================================
// output logic
//==============================================================
always_comb begin
    // Default assignments
    eq_lt_failed_comb        = 1'b0;
    eq_lt_pass_comb          = 1'b0;
    eq_final_adj_lc_comb     = 2'b00;
    eq_final_adj_bw_comb     = 8'd0;
    eq_phy_instruct_comb     = 2'b00;
    eq_phy_instruct_vld_comb = 1'b0;
    eq_adj_lc_comb           = 2'b00;
    eq_adj_bw_comb           = 8'd0;
    eq_ctr_start_comb        = 1'b0;
    eq_fsm_start_cr_err_comb = 1'b0;
    eq_fsm_start_eq_err_comb = 1'b0;
    eq_fsm_cr_dn_comb        = 4'b0000;
    eq_data_comb             = 8'd0;
    eq_address_comb          = 20'd0;
    eq_len_comb              = 8'd0;
    eq_cmd_comb              = 2'b00;
    eq_transaction_vld_comb  = 1'b0;
    data_buffer              = 128'd0;
    shift_amount             = 3'd0;
    load_flag                = 1'b0;
    eq_fsm_cr_failed_comb    = 1'b0;
    // Determine the next state and output signals based on the current state
    case(current_state)
        IDLE:
        begin
            eq_lt_failed_comb        = 1'b0;
            eq_lt_pass_comb          = 1'b0;
            eq_final_adj_lc_comb     = 2'b00;
            eq_final_adj_bw_comb     = 8'd0;
            eq_phy_instruct_comb     = 2'b00;
            eq_adj_lc_comb           = 2'b00;
            eq_adj_bw_comb           = 8'd0;
            eq_ctr_start_comb        = 1'b0;
            eq_fsm_start_cr_err_comb = 1'b0;
            eq_fsm_start_eq_err_comb = 1'b0;
            eq_fsm_cr_dn_comb        = 4'b0000;
            eq_data_comb             = 8'd0;
            eq_address_comb          = 20'd0;
            eq_len_comb              = 8'd0;
            eq_cmd_comb              = 2'b00;
            eq_transaction_vld_comb  = 1'b0;
            data_buffer              = 128'd0;
            shift_amount             = 3'd0;
            load_flag                = 1'b0;
            eq_phy_instruct_vld_comb = 1'b0;
            eq_fsm_cr_failed_comb    = 1'b0;
        end
        TPS: // we can send tps2 first then check on tps3 and tps4 in another state  
        begin
            case (tps_sync)
                2'b01: // TPS2 
                begin
                    // signals sent to phy layer to transmit TPS2
                    eq_adj_bw_comb          = new_bw_sync;
                    eq_adj_lc_comb          = new_lc_sync;
                    eq_phy_instruct_comb    = 2'b01;
                    eq_phy_instruct_vld_comb= 1'b1;
                    // write transaction in sink registers
                    eq_address_comb         = 20'h102;
                    eq_cmd_comb             = 2'b00;
                    data_buffer             = {8'h22, config_103_reg, config_104_reg, config_105_reg, config_106_reg,88'd0};
                    eq_transaction_vld_comb = 1'b1;
                    load_flag = 1'b1;
                    case (new_lc_sync)
                        2'b00:
                        begin
                            shift_amount = 3'd2;
                            eq_len_comb  = 8'h1;
                        end
                        2'b01:
                        begin
                            shift_amount = 3'd3;
                            eq_len_comb  = 8'h2;
                        end
                        2'b11:
                        begin
                            shift_amount = 3'd5;
                            eq_len_comb  = 8'h4;
                        end
                    endcase                     
                end
                2'b10: // TPS3
                begin
                    // signals sent to phy layer to transmit TPS3
                    eq_adj_bw_comb          = new_bw_sync;
                    eq_adj_lc_comb          = new_lc_sync;
                    eq_phy_instruct_comb    = 2'b10;
                    eq_phy_instruct_vld_comb= 1'b1;
                    // write transaction in sink registers
                    eq_address_comb         = 20'h102;
                    eq_cmd_comb             = 2'b00;
                    data_buffer             = {8'h23, config_103_reg, config_104_reg, config_105_reg, config_106_reg,88'd0};
                    eq_transaction_vld_comb = 1'b1;    
                    load_flag               = 1'b1;
                    case (new_lc_sync)
                        2'b00:
                        begin
                            shift_amount = 3'd2;
                            eq_len_comb  = 8'h1;
                        end
                        2'b01:
                        begin
                            shift_amount = 3'd3;
                            eq_len_comb  = 8'h2;
                        end
                        2'b11:
                        begin
                            shift_amount = 3'd5;
                            eq_len_comb  = 8'h4;
                        end
                    endcase             
                end 
                2'b11: // TPS4
                begin
                    // signals sent to phy layer to transmit TPS3
                    eq_adj_bw_comb          = new_bw_sync;
                    eq_adj_lc_comb          = new_lc_sync;
                    eq_phy_instruct_comb    = 2'b11;
                    eq_phy_instruct_vld_comb= 1'b1;
                    // write transaction in sink registers
                    eq_address_comb         = 20'h102;
                    eq_cmd_comb             = 2'b00;
                    data_buffer             = {8'h07, config_103_reg, config_104_reg, config_105_reg, config_106_reg,88'd0};
                    eq_transaction_vld_comb = 1'b1;  
                    load_flag               = 1'b1;
                    case (new_lc_sync)
                        2'b00:
                        begin
                            shift_amount = 3'd2;
                            eq_len_comb  = 8'h1;
                        end
                        2'b01:
                        begin
                            shift_amount = 3'd3;
                            eq_len_comb  = 8'h2;
                        end
                        2'b11:
                        begin
                            shift_amount = 3'd5;
                            eq_len_comb  = 8'h4;
                        end
                    endcase                   
                end
                default:
                begin
                    // Set all signals to default values of zero
                    eq_adj_bw_comb          = 8'd0;
                    eq_adj_lc_comb          = 2'b00;
                    eq_phy_instruct_comb    = 2'b00;
                    eq_address_comb         = 20'd0;
                    eq_cmd_comb             = 2'b00;
                    eq_len_comb             = 8'd0;
                    data_buffer             = 128'd0;
                    shift_amount            = 3'd0;
                    eq_transaction_vld_comb = 1'b0;    
                    load_flag               = 1'b0; 
                    eq_phy_instruct_vld_comb= 1'b0;
                end
            endcase
        end         
        WAIT:
        begin
            eq_ctr_start_comb = 1'b1;
        end
        READ_ADJ_SETTINGS:
        begin
            eq_address_comb         = 20'h202;  // output address used for read transaction
            eq_len_comb             = 8'd5;     // output length used for read transaction indicating the no. of registers to read starting from zero
            eq_cmd_comb             = 2'b01;    // output command used for read transaction
            eq_transaction_vld_comb = 1'b1;     // output transaction valid signal
            data_buffer             = 128'd0;   // output data used for read transaction
            shift_amount            = 3'd1;     // here we shift for one clock cycle to assert eq_transaction_vld for one clock cycle 
            load_flag               = 1'b1;
        end
        CHK_CR:
        begin
            if(saving_flag && !cr_dn)
            begin
                eq_fsm_start_cr_err_comb = 1'b1; // start error checking for clock recovery
                eq_fsm_cr_failed_comb    = 1'b1; // report this error to policy maker 
                eq_fsm_cr_dn_comb        = eq_cr_dn_sync; // sending cr_dn to error checking FSM
            end
            else
            begin
                eq_fsm_start_cr_err_comb = 1'b0;
                eq_fsm_cr_dn_comb        = 4'b0000;
                eq_fsm_cr_failed_comb    = 1'b0;
            end  
        end
        CHK_EQ:
        begin
            if(saving_flag && max_loop_count)
            begin
                eq_fsm_start_eq_err_comb = 1'b1; // start error checking for channel equalization
                eq_fsm_cr_failed_comb    = 1'b1; // report policy maker that we will decrease the lanecount or bw and start CR again 
            end
            else
            begin
                eq_fsm_start_eq_err_comb = 1'b0;
                eq_fsm_cr_failed_comb    = 1'b0;
            end
        end
        WRITE_ADJ_SETTINGS:
        begin
            eq_address_comb         = 20'h103;    
            eq_cmd_comb             = 2'b00;   
            eq_transaction_vld_comb = 1'b1;    
            data_buffer             = {config_103_reg, config_104_reg, config_105_reg, config_106_reg, 96'd0};        
            load_flag               = 1'b1;
            case (new_lc_sync)
                2'b00:
                begin
                    shift_amount = 3'd1;
                    eq_len_comb  = 8'h0;
                end
                2'b01:
                begin
                    shift_amount = 3'd2;
                    eq_len_comb  = 8'h1;
                end
                2'b11:
                begin
                    shift_amount = 3'd4;
                    eq_len_comb  = 8'h3;
                end
            endcase     
        end
        FAIL:
        begin
            eq_lt_failed_comb       = 1'b1;
            eq_address_comb         = 20'h102; // output address used for write transaction    
            eq_len_comb             = 8'd0;    // output length used for write transaction
            eq_cmd_comb             = 2'b00;   // output command used for write transaction
            eq_transaction_vld_comb = 1'b1;    // output transaction valid signal
            data_buffer             = 128'd0;   // output data used for write transaction
            load_flag               = 1'b1;
            shift_amount            = 3'd1; // shift amount used for byte shifter
        end
        PASS:
        begin
            // interface with policy maker to send the final adjusted bandwidth and lane count
            eq_lt_pass_comb         = 1'b1; 
            eq_final_adj_bw_comb    = new_bw_sync;
            eq_final_adj_lc_comb    = new_lc_sync;
            // write transaction to end link trainning by clearing the 102 register 
            eq_address_comb         = 20'h102; // output address used for write transaction    
            eq_len_comb             = 8'd0;    // output length used for write transaction
            eq_cmd_comb             = 2'b00;   // output command used for write transaction
            eq_transaction_vld_comb = 1'b1;    // output transaction valid signal
            data_buffer             = 128'd0;  // output data used for write transaction
            load_flag               = 1'b1;    // load flag used for byte shifter
            shift_amount            = 3'd1;    // shift amount used for byte shifter                
        end
        default:
        begin
            eq_lt_failed_comb        = 1'b0;
            eq_lt_pass_comb          = 1'b0;
            eq_final_adj_lc_comb     = 2'b00;
            eq_final_adj_bw_comb     = 8'd0;
            eq_phy_instruct_comb     = 2'b00;
            eq_adj_lc_comb           = 2'b00;
            eq_adj_bw_comb           = 8'd0;
            eq_ctr_start_comb        = 1'b0;
            eq_fsm_start_cr_err_comb = 1'b0;
            eq_fsm_start_eq_err_comb = 1'b0;
            eq_fsm_cr_dn_comb        = 4'b0000;
            eq_data_comb             = 8'd0;
            eq_address_comb          = 20'd0;
            eq_len_comb              = 8'd0;
            eq_cmd_comb              = 2'b00;
            eq_transaction_vld_comb  = 1'b0;
            data_buffer              = 128'd0;
            shift_amount             = 3'd0;
            load_flag                = 1'b0;
            eq_phy_instruct_vld_comb = 1'b0;
            eq_fsm_cr_failed_comb    = 1'b0;
        end
    endcase
end
//========================================================================
// pulse detector 
// detecting posedge of load_flag to load the message to the byte shifter 
//======================================================================== 
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
    begin
        load_flag_d    <= 1'b0;  // Delayed version of load_flag
    end
    else
    begin
        load_flag_d    <= load_flag; // Store previous state 
    end
end

assign load_flag_reg = (load_flag && ~load_flag_d) ? 1'b1 : 1'b0;

//========================================================================
// Byte Shifter
///========================================================================

always_ff @( posedge clk or negedge rst_n ) begin 
    if (!rst_n) 
    begin
        data_shifter       <= 128'd0;
        shift_amount_reg   <= 3'd0;
        shift_counter      <= 3'd0;
        eq_data            <= 8'd0;
        eq_transaction_vld <= 1'b0;
        eq_address         <= 20'd0;
        eq_len             <= 8'd0;
        eq_cmd             <= 2'b00;
        eq_lt_failed       <= 1'b0;
        eq_lt_pass         <= 1'b0;        
    end
    else
    begin
        if(load_flag_reg)
        begin
            data_shifter     <= data_buffer;
            shift_amount_reg <= shift_amount;
            shift_counter    <= 3'd0;
        end
        else 
        if(shift_counter < shift_amount_reg) 
        begin
            eq_data            <= data_shifter[WIDTH-1:WIDTH-8];
            data_shifter       <= {data_shifter[WIDTH-9:0], 8'b0}; // Right shift by 8 bits
            shift_counter      <= shift_counter + 1;
            eq_transaction_vld <= eq_transaction_vld_comb;
            eq_address         <= eq_address_comb;
            eq_len             <= eq_len_comb;
            eq_cmd             <= eq_cmd_comb;
            eq_lt_failed       <= eq_lt_failed_comb;
            eq_lt_pass         <= eq_lt_pass_comb;            
        end
        else 
        begin   
            eq_transaction_vld <= 1'b0;
            eq_lt_failed       <= 1'b0;
            eq_lt_pass         <= 1'b0;              
        end
    end
end

//================================================================================
// Sequential output Logic
//================================================================================

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) 
    begin
        eq_final_adj_lc     <= 2'b00;
        eq_final_adj_bw     <= 8'd0;
        eq_phy_instruct     <= 2'b00;
        eq_phy_instruct_vld <= 1'b0;
        eq_adj_lc           <= 2'b00;
        eq_adj_bw           <= 8'd0;
        eq_ctr_start        <= 1'b0;
        eq_fsm_start_cr_err <= 1'b0;
        eq_fsm_start_eq_err <= 1'b0;
        eq_fsm_cr_dn        <= 4'b0000;
        eq_fsm_cr_failed    <= 1'b0;
    end 
    else 
    begin
        // Assign the combinational outputs to the sequential outputs
        eq_final_adj_lc     <= eq_final_adj_lc_comb;
        eq_final_adj_bw     <= eq_final_adj_bw_comb;
        eq_phy_instruct     <= eq_phy_instruct_comb;
        eq_phy_instruct_vld <= eq_phy_instruct_vld_comb;
        eq_adj_lc           <= eq_adj_lc_comb;
        eq_adj_bw           <= eq_adj_bw_comb;
        eq_ctr_start        <= eq_ctr_start_comb;
        eq_fsm_start_cr_err <= eq_fsm_start_cr_err_comb;
        eq_fsm_start_eq_err <= eq_fsm_start_eq_err_comb;
        eq_fsm_cr_dn        <= eq_fsm_cr_dn_comb;
        eq_fsm_cr_failed    <= eq_fsm_cr_failed_comb;
    end
end
endmodule
`resetall  // Reset all compiler directives to their default values
