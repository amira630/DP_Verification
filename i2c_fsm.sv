/*==================================================================                       
* File Name:   i2c_fsm.sv                                         
* Module Name: i2c_fsm                                          
* Purpose:     i2c transction control state machine                                         
* Date:        3rd May 2025 
* Nmae:        *Mohammed Hisham Tersawy*                                       
====================================================================*/
`default_nettype none  // Disable implicit net declarations
module i2c_fsm #
(
    parameter EDID_SIZE = 5
)
(

    // ======================================================//
    // =============== INPUT PORTS DECLARATION ==============//
    // ======================================================//
    input  wire       clk,
    input  wire       rst_n,
    input  wire       de_mux_i2c_tr_vld,       // Start transaction signal
    input  wire [1:0] reply_ack,               // ACK/NACK reply from the sink device
    input  wire       reply_ack_vld,           // Reply ACK valid
    input  wire       timer_timeout,           // Timeout signal (400 µs)



    // ======================================================//
    // =============== OUTPUT PORTS DECLARATION =============//
    // ======================================================//
    output reg        i2c_fsm_add_s,             // Address send signal (one-cycle pulse)
    output reg        i2c_fsm_data_s,            // Data send signal (one-cycle pulse)
    output reg        i2c_fsm_end_s,             // End send signal (one-cycle pulse)
    output reg        i2c_fsm_complete,           // I2C complete flag (one-cycle pulse)
    output reg        i2c_fsm_failed             // I2C failed flag (one-cycle pulse)
);

//===========================================================//
// =================Parameters and Constants=================//
//===========================================================//    
    typedef enum reg [1:0] 
    {
    IDLE    = 2'b00, 
    ADDRESS = 2'b01, 
    DATA    = 2'b11, 
    END     = 2'b10 
    } state_t;

//===========================================================//
// ================Internal Signals and Registers============//
//===========================================================//
    state_t        current_state     , next_state;
    reg            add_s_pulse       , data_s_pulse , end_s_pulse, i2c_complete_pulse , i2c_fsm_failed_pulse ; // One-cycle pulse registers
    reg            i2c_tr_vld_sync   , reply_ack_vld_sync , timeout_sync ;
    reg     [31:0] loop_counter_reg  , loop_counter;                     // 32-bit counter
    reg     [31:0] defer_counter     , defer_counter_reg ;                  // Defer counter  response
    reg     [1:0]  reply_ack_sync;
    reg            defer_flag; // this falg is asserted indicating the defer counter reach 8
    reg            edid_flag;  // this flag is asserted indicating the loop counter reach the EDID_SIZE


//===========================================================//
// ===================Synchronization Logic==================//
//===========================================================//
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
        begin
            i2c_tr_vld_sync    <= 1'b0;
            reply_ack_vld_sync <= 1'b0;
            timeout_sync       <= 1'b0;
            reply_ack_sync     <= 2'b00;
        end 
        else 
        begin
            i2c_tr_vld_sync    <= de_mux_i2c_tr_vld;
            reply_ack_vld_sync <= reply_ack_vld;
            timeout_sync       <= timer_timeout;
            reply_ack_sync     <= reply_ack;
        end
    end


//===========================================================//
// ===================Next State Logic=======================//
//===========================================================//
    // Next State Logic
    always @(*) begin
        // Default values
        next_state      = current_state;
        loop_counter    = loop_counter_reg;
        defer_counter   = defer_counter_reg;
        defer_flag      = 1'b0;
        edid_flag       = 1'b0;

        case (current_state)
            IDLE:
            begin
                loop_counter  = 32'd0;  // Reset loop count
                defer_counter = 32'd0;  // Reset defer counter
                if (i2c_tr_vld_sync) 
                begin 
                    next_state = ADDRESS;
                end 
                else 
                begin
                    next_state = IDLE;
                end 
            end
            ADDRESS:
            begin
                if (reply_ack_vld_sync && reply_ack_sync == 2'b00) // ack  
                begin
                    next_state = DATA;
                end 
                else 
                if (timeout_sync || (reply_ack_vld_sync && reply_ack_sync == 2'b01 )) begin   // nack
                    next_state = ADDRESS;  
                end
                else
                if (reply_ack_vld_sync && reply_ack_sync == 2'b10) //defer
                begin
                    defer_counter = defer_counter_reg + 1;
                    if (defer_counter == 32'd8) 
                    begin
                        next_state = IDLE;
                        defer_flag  = 1'b1;
                    end 
                    else
                    begin
                        next_state = ADDRESS;
                    end
                end
                else
                begin
                    next_state = ADDRESS;
                end
            end
            DATA:
            begin
                if (reply_ack_vld_sync && reply_ack_sync == 2'b00) // ack
                begin 
                    loop_counter = loop_counter_reg + 1;  // Update counter before checking
                    if (loop_counter  == EDID_SIZE) 
                    begin  
                        next_state = END;  // Transition to END state
                        edid_flag = 1'b1;
                    end
                    else 
                    begin
                        next_state = DATA;  // Stay in DATA state
                    end
                end 
                else 
                if (timeout_sync || (reply_ack_vld_sync && reply_ack_sync == 2'b01 ))// nack
                begin
                    next_state = DATA;
                end
                else
                if (reply_ack_vld_sync && reply_ack_sync == 2'b10) //defer
                begin
                    defer_counter = defer_counter_reg + 1;
                    if (defer_counter == 32'd8) 
                    begin
                        next_state = IDLE;
                        defer_flag  = 1'b1;
                    end 
                    else
                    begin
                        next_state = DATA;
                    end
                end
                else
                begin
                    next_state = DATA;
                end
            end
            END:
            begin
                if (reply_ack_vld_sync && reply_ack_sync == 2'b00) 
                begin 
                    next_state = IDLE;  // Transition to IDLE on ACK
                end 
                else 
                if (timeout_sync || (reply_ack_vld_sync && reply_ack_sync == 2'b01 )) 
                begin
                    next_state = END;
                end
                else 
                if (reply_ack_vld_sync && reply_ack_sync == 2'b10)
                begin
                    defer_counter = defer_counter_reg + 1;
                    if (defer_counter == 32'd8) 
                    begin
                        next_state  = IDLE;
                        defer_flag  = 1'b1;
                    end 
                    else
                    begin
                        next_state = END;
                    end
                end
                else
                begin
                    next_state = END;
                end
            end
        endcase
    end

//===========================================================//
// =======================Output Logic=======================//
//===========================================================//
    always @(*) begin
        // Default values
        add_s_pulse          = 1'b0;
        data_s_pulse         = 1'b0;
        end_s_pulse          = 1'b0;
        i2c_complete_pulse   = 1'b0;
        i2c_fsm_failed_pulse = 1'b0;

        case (current_state)
            IDLE:
            begin
                if (i2c_tr_vld_sync) 
                begin
                    add_s_pulse = 1'b1;  // Assert i2c_fsm_add_s in IDLE when de_mux_i2c_tr_vld is high
                end 
                else 
                begin
                    add_s_pulse = 1'b0;  // De-assert i2c_fsm_add_s in IDLE when de_mux_i2c_tr_vld is low
                end
            end
            ADDRESS:
            begin
                if (reply_ack_vld_sync && reply_ack_sync == 2'b00) 
                begin
                    data_s_pulse = 1'b1;  // Assert i2c_fsm_data_s when transitioning to DATA
                end 
                else 
                if (timeout_sync || (reply_ack_vld_sync && reply_ack_sync == 2'b01 )) 
                begin
                    add_s_pulse  = 1'b1;  // Re-assert i2c_fsm_add_s on timer_timeout or NACK
                end
                else
                if (reply_ack_vld_sync && reply_ack_sync == 2'b10)
                begin
                    if (defer_flag)
                    begin
                        i2c_fsm_failed_pulse = 1'b1;
                    end
                    else
                    begin
                        add_s_pulse  = 1'b1;  // Re-assert i2c_fsm_add_s on NACK
                    end
                end 
                else 
                begin
                    add_s_pulse  = 1'b0;  
                end
            end
            DATA:
            begin
                if (reply_ack_vld_sync && reply_ack_sync == 2'b00) 
                begin 
                    if (edid_flag) 
                    begin
                        end_s_pulse = 1'b1;  // Assert i2c_fsm_end_s when transitioning to END
                    end 
                    else 
                    begin
                        data_s_pulse = 1'b1;  // Assert i2c_fsm_data_s for each data byte
                    end
                end 
                else 
                if (timeout_sync || (reply_ack_vld_sync && reply_ack_sync == 2'b01 )) 
                begin
                    data_s_pulse = 1'b1;  // Re-assert i2c_fsm_data_s on timer_timeout or NACK
                end
                else
                if (reply_ack_vld_sync && reply_ack_sync == 2'b10)
                begin
                    if (defer_flag)
                    begin
                        i2c_fsm_failed_pulse = 1'b1;
                    end
                    else
                    begin
                        data_s_pulse = 1'b1;  // Re-assert i2c_fsm_data_s on NACK
                    end
                end 
                else
                begin
                    data_s_pulse = 1'b0;
                end
            end
            END:
            begin
                if (reply_ack_vld_sync && reply_ack_sync == 2'b00) 
                begin 
                    i2c_complete_pulse = 1'b1;  // Assert i2c_fsm_complete and return to IDLE
                end 
                else 
                if (timeout_sync || (reply_ack_vld_sync && reply_ack_sync == 2'b01 ))
                begin
                    end_s_pulse   = 1'b1;  // Re-assert i2c_fsm_end_s on timer_timeout or NACK
                end
                else 
                if (reply_ack_vld_sync && reply_ack_sync == 2'b10)
                begin
                    if (defer_flag)
                    begin
                        i2c_fsm_failed_pulse = 1'b1;
                    end
                    else
                    begin
                        end_s_pulse   = 1'b1;  // Re-assert i2c_fsm_end_s on NACK
                    end
                end
                else
                begin
                    end_s_pulse   = 1'b0;  
                end
            end
        endcase
    end


//===========================================================//
// ==========Sequential State & Loop Counter Update==========//
//===========================================================//
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
        begin
            current_state     <= IDLE;
            loop_counter_reg  <= 32'd0;
            defer_counter_reg <= 32'd0; 
        end 
        else 
        begin
            current_state     <= next_state;
            loop_counter_reg  <= loop_counter;
            defer_counter_reg <= defer_counter;
        end
    end

//===========================================================//
// Assign Pulses to Output (Ensuring One-Cycle Assertion)    //
//===========================================================//
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
        begin
            i2c_fsm_add_s    <= 1'b0;
            i2c_fsm_data_s   <= 1'b0;
            i2c_fsm_end_s    <= 1'b0;
            i2c_fsm_complete <= 1'b0;
            i2c_fsm_failed   <= 1'b0;
        end 
        else 
        begin
            i2c_fsm_add_s    <= add_s_pulse;
            i2c_fsm_data_s   <= data_s_pulse;
            i2c_fsm_end_s    <= end_s_pulse;
            i2c_fsm_complete <= i2c_complete_pulse;
            i2c_fsm_failed   <= i2c_fsm_failed_pulse;
        end
    end
endmodule
`resetall  // Reset all compiler directives to their default values