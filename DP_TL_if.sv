interface DP_TL_if(clk);
    logic reset, valid_in, cin, valid_out, carry, zero;    
    logic [3:0] a, b, alu; 
    logic valid_out_ref, carry_ref, zero_ref;
    logic [3:0] alu_ref;

    modport DUT (
        input clk, reset, valid_in, cin, a, b,
        output valid_out, carry, zero, alu
    );
endinterface