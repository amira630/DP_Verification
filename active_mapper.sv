module active_mapper 
(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       sched_stream_en ,
    input  wire [1:0] sched_stream_state,
    input  wire [7:0] main_steered,
    output wire [7:0] am_active_symbol,
    output wire       am_control_sym_flag
); 


reg [7:0] active_symbol_reg;
reg       control_sym_flag_reg;

always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) 
    begin
        active_symbol_reg    <= 8'b0;
        control_sym_flag_reg <= 1'b0;
    end 
    else 
    if (sched_stream_en) 
    begin
        case (sched_stream_state)
            2'b10: 
            begin
                active_symbol_reg    <= 8'hFC; // stuffing start control symbol
                control_sym_flag_reg <= 1'b1;
            end
            2'b11: 
            begin
                active_symbol_reg    <= 8'hFE; // stuffing end control symbol
                control_sym_flag_reg <= 1'b1;
            end
            2'b01:
            begin
                active_symbol_reg    <= main_steered; // main steered data
                control_sym_flag_reg <= 1'b0;
            end
            default: 
            begin
                active_symbol_reg    <= 8'h00; // stuffed data 
                control_sym_flag_reg <= 1'b0;
            end
        endcase
    end
end

assign am_active_symbol = active_symbol_reg;
assign am_control_sym_flag = control_sym_flag_reg;

endmodule