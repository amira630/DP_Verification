// import macro_pkg::*;

// module alu_ref(alu_interface.REF intf);

// logic            clk;
// logic            reset;
// logic            valid_in;    //validate input signals
// logic [3:0]      a;           //port A
// logic [3:0]      b;           //port B 
// logic            cin;         //carry input from carry flag register 
// logic [3:0]      ctl;         //functionality control for ALU 
// //Output signals
// logic            valid_out;   //validate output signals
// logic [3:0]      alu;         //the result 
// logic            carry;       //carry output 
// logic            zero;         //zero output 


// assign clk = intf.clk;
// assign reset = intf.reset; 
// assign a = intf.a;
// assign b = intf.b;
// assign cin = intf.cin;
// assign ctl = intf.ctl;
// assign valid_in = intf.valid_in;

// assign intf.valid_out_ref = valid_out; 
// assign intf.alu_ref = alu; 
// assign intf.carry_ref = carry; 
// assign intf.zero_ref = zero; 


// opcode_e opcode;
// reg [4:0] out_r;
// reg valid_r, zero_r;

// assign opcode = opcode_e'(ctl);

// always @(posedge clk or negedge reset) begin
//     if(~reset) begin
//         valid_out <= 1'b0;
//         alu <= 4'b0;
//         carry <= 1'b0;
//         zero <= 1'b0;
//     end
//     else begin 
//         valid_out <= valid_r;
//         if(valid_in) begin
//             alu   <= out_r[3:0];
//             carry <= out_r[4];
//             zero  <= zero_r;
//         end
//     end
// end

// always @(*) begin
//     valid_r = valid_in;
//     case (opcode)
//         SEL:      out_r = b;
//         INC: begin 
//             if (b < 4'hf) 
//                 out_r = b + 1; 
//             else 
//                 out_r = b; 
//         end
//         DEC: begin 
//             if (b > 0) 
//                 out_r = b - 1; 
//             else 
//                 out_r = b; 
//         end
//         ADD:      out_r = a + b;
//         ADD_c:    out_r = a + b + cin;
//         SUB:      out_r = a - b;
//         SUB_b:    out_r = a - b - cin;
//         AND:      out_r = a & b; 
//         OR:       out_r = a | b;
//         XOR:      out_r = a ^ b;
//         SHIFT_L:  out_r = {out_r[3:0], 1'b0};
//         SHIFT_R:  out_r = {1'b0, out_r[4:1]};
//         ROTATE_L: out_r = {out_r[3:0], out_r[4]};
//         ROTATE_R: out_r = {out_r[0], out_r[4:1]};
//         default:  valid_r = 1'b0;
//     endcase
//     if (~|out_r[3:0]) 
//         zero_r = 1'b1;
//     else
//         zero_r = 1'b0;
// end
// endmodule