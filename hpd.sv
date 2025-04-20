/*==================================================================                        
* File Name:   hpd.sv                                         
* Module Name: hpd                                          
* Purpose:     Detect HPD signal and generate interrupt request                                          
* Date:        6th May 2025 
* Nmae:        *Mohammed Hisham Tersawy*                                       
====================================================================*/

`default_nettype none  // Disable implicit net declarations
module hpd 
(
    input wire clk,           // 100 kHz clock input
    input wire rst_n,         // Reset signal
    input wire hpd_signal,    // HPD signal
    output reg hpd_detect,    // HPD detect signal
    output reg hpd_irq        // HPD interrupt request signal 
);

    /*********************************************
     * PARAMETERS AND CONSTANTS
     *********************************************/
    localparam  int CLK_FREQ            = 100_000;            // Clock frequency in Hz
    localparam  int MS_TICKS            = CLK_FREQ / 1_000;   // Number of clock ticks per millisecond
    localparam  int HPD_THRESHOLD       = 100 * MS_TICKS;     // HPD signal threshold in milliseconds (100 ms)
    localparam  int HPD_IRQ_MIN         = 0.5 * MS_TICKS;     // Minimum ticks for HPD IRQ (0.5 ms)
    localparam  int HPD_IRQ_MAX         = 1 * MS_TICKS;       // Maximum ticks for HPD IRQ (1 ms)
    localparam  int HPD_IRQ_MIN_SPACING = 2 * MS_TICKS;       // Minimum spacing between two successive HPD IRQ requests (2 ms)

    /*********************************************
     * INTERNAL SIGNALS AND REGISTERS
     *********************************************/
    reg [31:0] hpd_counter;             // Counter to keep track of high duration of HPD signal
    reg [31:0] hpd_low_counter;         // Counter to keep track of low duration of HPD signal
    reg [31:0] irq_min_spacing_counter; // Counter to keep track of minimum spacing between two sucessive HPD IRQ requests
    reg        hpd_signal_prev;         // Previous state of hpd_signal
    reg        toggle_up_down;          // HPD signal toggle detection from high to low 
    reg        toggle_down_up;          // HPD signal toggle detection from low to high
    reg        flag;                    // flag asserted to indicate that there is a toggle up down happens in HPD signal 
                                        //to count on low counter 
           


    /*********************************************
     * HPD SIGNAL DURATION AND TOGGLE DETECTION
     *********************************************/
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
        begin
            hpd_counter             <= 0;
            hpd_low_counter         <= 0;
            hpd_detect              <= 0;
            hpd_irq                 <= 0;
            flag                    <= 0;
            irq_min_spacing_counter <= HPD_IRQ_MIN_SPACING;
        end 
        else 
        begin
            if (toggle_down_up && !flag) 
            begin
                hpd_irq         <= 0;
                hpd_low_counter <= 0;
                if (irq_min_spacing_counter < HPD_IRQ_MIN_SPACING)
                begin
                    irq_min_spacing_counter <= irq_min_spacing_counter + 1;            // Increment spacing counter after each IRQ request
                end
                if (hpd_counter == HPD_THRESHOLD - 1) 
                begin
                    hpd_detect  <= 1;
                end 
                else 
                begin
                    hpd_counter <= hpd_counter + 1;
                end
            end 
            else 
            if(toggle_up_down)
            begin
                hpd_counter     <= 0;
                hpd_low_counter <= hpd_low_counter + 1;
                flag            <= 1;
                if (hpd_low_counter >= HPD_THRESHOLD - 1)
                begin
                    hpd_detect  <= 0;
                end
            end
            else
            if(toggle_down_up && flag)
            begin
                if ((hpd_low_counter >= HPD_IRQ_MIN) && (hpd_low_counter <= HPD_IRQ_MAX))
                begin
                    if(irq_min_spacing_counter >= HPD_IRQ_MIN_SPACING - 1 ) 
                    begin
                        hpd_irq                 <= 1;
                        irq_min_spacing_counter <= 0;  
                    end
                    else
                    begin 
                        hpd_irq <= 0;
                    end
                end
                hpd_low_counter <= 0;
                flag            <= 0;
            end


        end
    end



    /*********************************************
     * DETECTING TOGGLE IN HPD SIGNAL
     *********************************************/
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
        begin
            toggle_up_down  <= 0;
            toggle_down_up  <= 0;
            hpd_signal_prev <= 0;
        end 
        else 
        if ((hpd_signal == 0) && (hpd_signal_prev == 1)) // Detect toggle from high to low 
        begin
            toggle_up_down  <= 1;
            toggle_down_up  <= 0;
        end 
        else
        if ((hpd_signal == 1) && (hpd_signal_prev == 0)) // Detect toggle from low to high
        begin
            toggle_down_up  <= 1;
            toggle_up_down  <= 0;
        end 
            hpd_signal_prev <= hpd_signal; // Store current HPD signal state
    end
endmodule
`resetall  // Reset all compiler directives to their default values