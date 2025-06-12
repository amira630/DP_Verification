
///////////////////////////////////////////////////////////////////////////////////
// Module: eq_err_chk
// Author: Mohammed Tersawy
// Description: this module is used to correct the errors in the channel equalization
//              by adjusting the bandwidth and lane count
///////////////////////////////////////////////////////////////////////////////////


`default_nettype none  // Disable implicit net declarations
module eq_err_chk 
(
input  wire        clk,                // 100 kHz clock input
input  wire        rst_n,              // Reset signal
input  wire        eq_fsm_start_cr_err,// Start clock recovery error correction
input  wire [3:0]  eq_fsm_cr_dn,       // Clock recovery data
input  wire        eq_fsm_start_eq_err,// Start channel equalization error correction
input  wire [7:0]  lpm_link_bw,        // Link policy maker bandwidth
input  wire [1:0]  lpm_link_lc,        // Link policy maker lane count
input  wire [7:0]  new_bw,             // New adjusted bandwidth during clock recovery
input  wire [1:0]  new_lc,             // New adjusted lane count during clock recovery
input  wire        eq_start,           // Equalization start signal
input  wire        config_param_vld,   // Valid for max lane count and max bandwidth sent by policy maker
output reg         eq_err_chk_failed,  // Error correction failed
output reg [7:0]   eq_err_chk_bw,      // New bandwidth chosen after error correction
output reg [1:0]   eq_err_chk_lc,      // New lane count chosen after error correction
output reg         eq_err_chk_cr_start // Flag signal to start clock recovery again after adjustment of bandwidth and lane count
);

////////////////////////////////////////////////////////////////////////////////
// State Definitions
////////////////////////////////////////////////////////////////////////////////
typedef enum reg [3:0] 
{  
    IDLE     = 4'b0000,
    LC_CHK   = 4'b0001,
    BW_CHK   = 4'b0010
} state_t;

state_t current_state, next_state;

////////////////////////////////////////////////////////////////////////////////
// Internal Registers
////////////////////////////////////////////////////////////////////////////////
reg [7:0]   lpm_link_bw_reg;
reg [1:0]   lpm_link_lc_reg;
reg [7:0]   new_bw_reg;
reg [1:0]   new_lc_reg;
reg         eq_err_chk_failed_comb;
reg [7:0]   eq_err_chk_bw_comb;
reg [1:0]   eq_err_chk_lc_comb;
reg         eq_err_chk_cr_start_comb;

////////////////////////////////////////////////////////////////////////////////
// Register Update: new_bw_reg and new_lc_reg
////////////////////////////////////////////////////////////////////////////////
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) 
    begin
        new_bw_reg          <= 8'd0;
        new_lc_reg          <= 2'b00;
    end 
    else
    if(eq_start) 
    begin
        new_bw_reg          <= new_bw;
        new_lc_reg          <= new_lc;
    end
end

////////////////////////////////////////////////////////////////////////////////
// Register Update: lpm_link_bw_reg and lpm_link_lc_reg
////////////////////////////////////////////////////////////////////////////////
always_ff@(posedge clk or negedge rst_n) begin
    if(!rst_n) 
    begin
        lpm_link_bw_reg     <= 8'd0;
        lpm_link_lc_reg     <= 2'b00;
    end
    else 
    if(config_param_vld)
    begin
        lpm_link_bw_reg     <= lpm_link_bw;
        lpm_link_lc_reg     <= lpm_link_lc;
    end
end

////////////////////////////////////////////////////////////////////////////////
// State Transition: current_state
////////////////////////////////////////////////////////////////////////////////
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) 
    begin
        current_state <= IDLE;
    end 
    else 
    begin
        current_state <= next_state;
    end
end

////////////////////////////////////////////////////////////////////////////////
// Next State Logic
////////////////////////////////////////////////////////////////////////////////
always_comb begin
    case (current_state)
        IDLE:
        begin
            if (eq_fsm_start_cr_err)
            begin
                if (eq_fsm_cr_dn == 4'b0000) // at least one lane succeeded in clock recovery
                begin
                    next_state = BW_CHK;
                end
                else
                begin
                    next_state = LC_CHK;
                end
            end
            else 
            if (eq_fsm_start_eq_err)
            begin
                next_state = LC_CHK;
            end
            else 
            begin
                next_state = IDLE;
            end
        end
        BW_CHK:
        begin
            next_state = IDLE;
        end
        LC_CHK:
        begin
            if (new_lc_reg == 2'b00) // one lane valid
            begin
                next_state = BW_CHK;
            end
            else
            begin
                next_state = IDLE;
            end
        end
        default:
        begin
            next_state = IDLE;
        end
    endcase
end

////////////////////////////////////////////////////////////////////////////////
// Output Logic
////////////////////////////////////////////////////////////////////////////////
always_comb begin
    eq_err_chk_failed_comb   = 1'b0;
    eq_err_chk_bw_comb       = 8'd0;
    eq_err_chk_lc_comb       = 2'b00;
    eq_err_chk_cr_start_comb = 1'b0;
    case (current_state) 
        IDLE:
        begin
            eq_err_chk_failed_comb   = 1'b0;
            eq_err_chk_bw_comb       = 8'd0;
            eq_err_chk_lc_comb       = 2'b00;
            eq_err_chk_cr_start_comb = 1'b0;
        end
        LC_CHK:
        begin
            case(new_lc_reg)
                2'b01: // two lanes enabled 
                begin
                    eq_err_chk_lc_comb       = 2'b00;
                    eq_err_chk_cr_start_comb = 1'b1;
                    eq_err_chk_bw_comb       = lpm_link_bw_reg;
                end
                2'b11: // four lanes enabled 
                begin
                    eq_err_chk_lc_comb       = 2'b01; 
                    eq_err_chk_cr_start_comb = 1'b1;
                    eq_err_chk_bw_comb       = lpm_link_bw_reg;
                end
                default:
                begin
                    eq_err_chk_failed_comb   = 1'b0;
                    eq_err_chk_bw_comb       = 8'd0;
                    eq_err_chk_lc_comb       = 2'b00;
                    eq_err_chk_cr_start_comb = 1'b0;
                end
            endcase
        end
        BW_CHK:
        begin
            case(new_bw_reg)
                8'h1E:
                begin
                    eq_err_chk_bw_comb       = 8'h14;
                    eq_err_chk_cr_start_comb = 1'b1;
                    eq_err_chk_lc_comb       = lpm_link_lc_reg;
                end
                8'h14:
                begin
                    eq_err_chk_bw_comb       = 8'h0A;
                    eq_err_chk_cr_start_comb = 1'b1;
                    eq_err_chk_lc_comb       = lpm_link_lc_reg;
                end
                8'h0A:
                begin
                    eq_err_chk_bw_comb       = 8'h06;
                    eq_err_chk_cr_start_comb = 1'b1;
                    eq_err_chk_lc_comb       = lpm_link_lc_reg;
                end
                8'h06:
                begin
                    eq_err_chk_failed_comb = 1'b1;
                end
                default:
                begin
                    eq_err_chk_failed_comb   = 1'b0;
                    eq_err_chk_bw_comb       = 8'd0;
                    eq_err_chk_lc_comb       = 2'b00;
                    eq_err_chk_cr_start_comb = 1'b0;
                end
            endcase
        end        
    endcase
end

////////////////////////////////////////////////////////////////////////////////
// Output Register Update
////////////////////////////////////////////////////////////////////////////////
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
    begin
        eq_err_chk_failed   <= 1'b0;
        eq_err_chk_bw       <= 8'd0;
        eq_err_chk_lc       <= 2'b00;
        eq_err_chk_cr_start <= 1'b0;
    end
    else
    begin
        eq_err_chk_failed   <= eq_err_chk_failed_comb;
        eq_err_chk_bw       <= eq_err_chk_bw_comb;
        eq_err_chk_lc       <= eq_err_chk_lc_comb;
        eq_err_chk_cr_start <= eq_err_chk_cr_start_comb;
    end
end

endmodule
`resetall  // Reset all compiler directives to their default values