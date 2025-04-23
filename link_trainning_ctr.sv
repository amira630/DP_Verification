////////////////////////////////////////////////////////////////////////////////
// Module: link_trainning_ctr
// Author: Mohammed Tersawy
// Description: this module is used to count the waiting time 
//              for the transmitter to read the adjusted values in the receiver
////////////////////////////////////////////////////////////////////////////////

`default_nettype none  // Disable implicit net declarations
module link_trainning_ctr 
(
    //=================================================================================================
    // Input signals
    //================================================================================================= 
    input  wire        clk,          // 100 khz clock input
    input  wire        rst_n,        // reset signal
    input  wire        eq_ctr_start, 
    input  wire [7:0]  eq_rd_value,  
    input  wire        cr_ctr_start,
    //=================================================================================================
    // Output signals
    //=================================================================================================
    output reg         cr_ctr_fire,  
    output reg         eq_ctr_fire 

);
//=================================================================================================
// State Definitions
//=================================================================================================
typedef enum reg [3:0] 
{  
    IDLE     = 4'b0000,
    CR_CTR   = 4'b0001,
    EQ_CTR   = 4'b0010
} state_t;
state_t    current_state, next_state;
//=================================================================================================
// Internal Registers
//=================================================================================================
reg [7:0]  loop_count;
reg [7:0]  loop_count_reg;
reg [31:0] value; // waiting value according to eq_rd_value recieved
reg        cr_ctr_prev;
reg        eq_ctr_prev;
reg        loaded_value;
wire       cr_ctr_rise, eq_ctr_rise;
//=================================================================================================
// Edge detection logic 
//=================================================================================================
assign cr_ctr_rise = cr_ctr_start & ~cr_ctr_prev; // detecting the posedge of cr_ctr_start to start the counter
assign eq_ctr_rise = eq_ctr_start & ~eq_ctr_prev; // detecting the posedge of eq_ctr_start to start the counter

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        cr_ctr_prev <= 0;
        eq_ctr_prev <= 0;
    end 
    else 
    begin
        cr_ctr_prev <= cr_ctr_start;
        eq_ctr_prev <= eq_ctr_start;
    end
end
//=================================================================================================
//next state transition logic 
//=================================================================================================
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) 
    begin
        loop_count_reg  <= 8'b0;
        current_state   <= IDLE;
    end 
    else 
    begin
        loop_count_reg  <= loop_count;
        current_state   <= next_state;
    end
end


//=================================================================================================
// Wainting value logic according to eq_rd_value
//=================================================================================================

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) 
    begin
        value <= 32'd0;
        loaded_value <= 1'b0;
    end 
    else 
    begin
        if(cr_ctr_rise)
        begin
            value <= 8'd10;
            loaded_value <= 1'b1;
        end
        else 
        if(eq_ctr_rise)
        begin 
            case(eq_rd_value)
                8'h00:
                begin
                value <= 32'd40; // calculated number of clock cycles given clk period = 10us
                loaded_value <= 1'b1;
                end
                8'h01:
                begin
                value <= 32'd400;
                loaded_value <= 1'b1;
                end
                8'h02:
                begin    
                value <= 32'd800;
                loaded_value <= 1'b1;
                end
                8'h03:
                begin
                value <= 32'd1200;
                loaded_value <= 1'b1;
                end
                8'h04:
                begin
                value <= 32'd1600;
                loaded_value <= 1'b1;
                end
                default:
                begin
                value <= 32'd1600; // default is the Max value
                loaded_value <= 1'b1; 
                end
            endcase
        end
        else
        if(next_state == IDLE)
        begin
            value <= 32'd0;
            loaded_value <= 1'b0;
        end
    end
end
//=================================================================================================
// Next state logic
//=================================================================================================
always_comb begin
    loop_count = loop_count_reg;
    case (current_state)
        IDLE:
        begin
            loop_count = 8'd0;
            if (eq_ctr_rise) 
            begin
                next_state = EQ_CTR;
            end
            else 
            if (cr_ctr_rise) 
            begin
                next_state = CR_CTR;
            end
            else 
            begin
                next_state = IDLE;
            end
        end
        CR_CTR:
        begin
            loop_count = loop_count_reg + 8'd1;   
            if ( loop_count == value && loaded_value) // in clock ecovery we count 100us  
            begin
                next_state = IDLE;
            end
            else 
            begin
                next_state = CR_CTR; 
            end
        end   
        EQ_CTR:
        begin
            loop_count = loop_count_reg + 8'd1; 
            if ( loop_count == value && loaded_value) 
            begin
                next_state = IDLE;
            end
            else 
            begin
                next_state = EQ_CTR;
               
            end
        end
        default: 
        begin
            next_state = IDLE;
        end
    endcase
end
//=================================================================================================
// Output Logic
//=================================================================================================

always_comb begin
    cr_ctr_fire = 1'b0;
    eq_ctr_fire = 1'b0;
    case (current_state)
        IDLE:
        begin
            cr_ctr_fire = 1'b0;
            eq_ctr_fire = 1'b0;  
        end
        CR_CTR:
        begin
            if(loop_count == value && loaded_value)
            begin
                cr_ctr_fire = 1'b1;
                eq_ctr_fire = 1'b0;     
            end
            else
            begin
                cr_ctr_fire = 1'b0;
                eq_ctr_fire = 1'b0;
            end
        end
        EQ_CTR:
        begin
            if(loop_count == value && loaded_value)
            begin
                cr_ctr_fire = 1'b0;
                eq_ctr_fire = 1'b1;
            end
            else
            begin
                cr_ctr_fire = 1'b0;
                eq_ctr_fire = 1'b0;
            end
        end
        default: 
        begin
            cr_ctr_fire = 1'b0;
            eq_ctr_fire = 1'b0;
        end
    endcase 
end
endmodule
`resetall  // Reset all compiler directives to their default values