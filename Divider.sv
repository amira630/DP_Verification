module Divider 
#(
    parameter WIDTH = 64  // Bit-width of dividend and divisor
)
(
    input  logic                  clk,       // Clock signal
    input  logic                  rst,       // Reset signal (active low)
    input  logic                  start,     // Start division
    input  logic [WIDTH-1:0]      dividend,  // Dividend (Numerator)
    input  logic [WIDTH-1:0]      divisor,   // Divisor (Denominator)
    output logic [WIDTH-1:0]      quotient,  // Quotient Output
    output logic [WIDTH-1:0]      remainder, // Remainder Output
    output logic                  done       // Done Flag
);

    // Internal registers
    logic [WIDTH-1:0] quotient_reg, remainder_reg, divisor_reg;
    logic [WIDTH-1:0] temp_dividend;
    logic [WIDTH-1:0] next_remainder;
    logic [WIDTH-1:0] subtracted_remainder;
    logic [6:0]       count;  // Counter for iteration
    logic             busy;
    logic             subtract;

    // Combinational logic for shift and subtract
    always_comb begin
        next_remainder = {remainder_reg[WIDTH-2:0], temp_dividend[WIDTH-1]};
        subtract = (next_remainder >= divisor_reg);
        subtracted_remainder = next_remainder - divisor_reg;
    end

    // Sequential control logic
    always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            quotient_reg  <= 0;
            remainder_reg <= 0;
            divisor_reg   <= 0;
            temp_dividend <= 0;
            count         <= 0;
            busy          <= 0;
            done          <= 0;
        end 
        else 
        if (start && !busy) 
        begin
            quotient_reg  <= 0;
            remainder_reg <= 0;
            divisor_reg   <= divisor;
            temp_dividend <= dividend;
            count         <= WIDTH;
            busy          <= 1;
            done          <= 0;
        end 
        else 
        if (busy) 
        begin
            if (count > 0) 
            begin
                remainder_reg <= subtract ? subtracted_remainder : next_remainder;
                quotient_reg  <= {quotient_reg[WIDTH-2:0], subtract};
                temp_dividend <= {temp_dividend[WIDTH-2:0], 1'b0};
                count <= count - 1;
            end 
            else 
            begin
                busy <= 0;
                done <= 1;
            end
        end 
        else 
        begin
            done <= 0; // Hold done high for one clock only
        end
    end

    // Assign outputs
    assign quotient  = quotient_reg;
    assign remainder = remainder_reg;
endmodule