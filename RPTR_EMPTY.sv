//=======================================================================
// Module: RPTR_EMPTY
// Author: Mohammed Tersawy
// Description: 
// This module implements the read pointer and empty flag logic for an 
// asynchronous FIFO. It includes functionality for gray-to-binary 
// conversion of the write pointer, binary-to-gray conversion of the 
// read pointer, and calculation of the empty flag based on the 
// difference between the read and write pointers. The module ensures 
// proper synchronization between the read and write domains and 
// provides an almost empty signal to indicate when the FIFO is nearly 
// empty. The read address is derived from the binary read pointer, 
// and the empty flag is updated based on the almost empty condition.
//======================================================================

`default_nettype none  // Disable implicit net declarations to avoid unintended wire declarations.

module RPTR_EMPTY 
#( 
   parameter WPTR_WIDTH = 4 , 
   parameter RPTR_WIDTH = 4 , 
   parameter ADDR_WIDTH = 3
)
(
	input  wire                  rinc ,        // Read increment signal to indicate a read operation.
	input  wire [RPTR_WIDTH-1:0] gray_wr_ptr , // Gray-coded write pointer from the write domain.
	input  wire                  rclk ,        // Read clock signal.
	input  wire                  rrst_n ,      // Active-low reset signal for the read domain.
	output wire                  rempty ,      // Empty flag indicating if the FIFO is alnmost empty.
	output wire [ADDR_WIDTH-1:0] r_addr ,      // Read address derived from the binary read pointer.
	output reg  [WPTR_WIDTH-1:0] gray_rd_ptr   // Gray-coded read pointer for synchronization with the write domain.
);

reg [RPTR_WIDTH-1:0] bn_rptr ;      // Binary read pointer.
reg [WPTR_WIDTH-1:0] bn_wptr ;      // Binary write pointer (converted from gray_wr_ptr).
wire                 almost_empty ; // Flag asserted when the FIFO has less than 2 valid data slots.
//reg                 almost_empty ; // Flag asserted when the FIFO has less than 2 valid data slots.
//======================================================================
// SECTION 1: Gray to Binary Conversion for Write Pointer
//======================================================================
always@(posedge rclk or negedge rrst_n) begin
	if(~rrst_n)
	begin
      bn_wptr <= 'b000000;
	end
	else
	begin

case (gray_wr_ptr)
8'b00000000: bn_wptr <= 8'b00000000;
8'b00000001: bn_wptr <= 8'b00000001;
8'b00000011: bn_wptr <= 8'b00000010;
8'b00000010: bn_wptr <= 8'b00000011;
8'b00000110: bn_wptr <= 8'b00000100;
8'b00000111: bn_wptr <= 8'b00000101;
8'b00000101: bn_wptr <= 8'b00000110;
8'b00000100: bn_wptr <= 8'b00000111;
8'b00001100: bn_wptr <= 8'b00001000;
8'b00001101: bn_wptr <= 8'b00001001;
8'b00001111: bn_wptr <= 8'b00001010;
8'b00001110: bn_wptr <= 8'b00001011;
8'b00001010: bn_wptr <= 8'b00001100;
8'b00001011: bn_wptr <= 8'b00001101;
8'b00001001: bn_wptr <= 8'b00001110;
8'b00001000: bn_wptr <= 8'b00001111;
8'b00011000: bn_wptr <= 8'b00010000;
8'b00011001: bn_wptr <= 8'b00010001;
8'b00011011: bn_wptr <= 8'b00010010;
8'b00011010: bn_wptr <= 8'b00010011;
8'b00011110: bn_wptr <= 8'b00010100;
8'b00011111: bn_wptr <= 8'b00010101;
8'b00011101: bn_wptr <= 8'b00010110;
8'b00011100: bn_wptr <= 8'b00010111;
8'b00010100: bn_wptr <= 8'b00011000;
8'b00010101: bn_wptr <= 8'b00011001;
8'b00010111: bn_wptr <= 8'b00011010;
8'b00010110: bn_wptr <= 8'b00011011;
8'b00010010: bn_wptr <= 8'b00011100;
8'b00010011: bn_wptr <= 8'b00011101;
8'b00010001: bn_wptr <= 8'b00011110;
8'b00010000: bn_wptr <= 8'b00011111;
8'b00110000: bn_wptr <= 8'b00100000;
8'b00110001: bn_wptr <= 8'b00100001;
8'b00110011: bn_wptr <= 8'b00100010;
8'b00110010: bn_wptr <= 8'b00100011;
8'b00110110: bn_wptr <= 8'b00100100;
8'b00110111: bn_wptr <= 8'b00100101;
8'b00110101: bn_wptr <= 8'b00100110;
8'b00110100: bn_wptr <= 8'b00100111;
8'b00111100: bn_wptr <= 8'b00101000;
8'b00111101: bn_wptr <= 8'b00101001;
8'b00111111: bn_wptr <= 8'b00101010;
8'b00111110: bn_wptr <= 8'b00101011;
8'b00111010: bn_wptr <= 8'b00101100;
8'b00111011: bn_wptr <= 8'b00101101;
8'b00111001: bn_wptr <= 8'b00101110;
8'b00111000: bn_wptr <= 8'b00101111;
8'b00101000: bn_wptr <= 8'b00110000;
8'b00101001: bn_wptr <= 8'b00110001;
8'b00101011: bn_wptr <= 8'b00110010;
8'b00101010: bn_wptr <= 8'b00110011;
8'b00101110: bn_wptr <= 8'b00110100;
8'b00101111: bn_wptr <= 8'b00110101;
8'b00101101: bn_wptr <= 8'b00110110;
8'b00101100: bn_wptr <= 8'b00110111;
8'b00100100: bn_wptr <= 8'b00111000;
8'b00100101: bn_wptr <= 8'b00111001;
8'b00100111: bn_wptr <= 8'b00111010;
8'b00100110: bn_wptr <= 8'b00111011;
8'b00100010: bn_wptr <= 8'b00111100;
8'b00100011: bn_wptr <= 8'b00111101;
8'b00100001: bn_wptr <= 8'b00111110;
8'b00100000: bn_wptr <= 8'b00111111;
8'b01100000: bn_wptr <= 8'b01000000;
8'b01100001: bn_wptr <= 8'b01000001;
8'b01100011: bn_wptr <= 8'b01000010;
8'b01100010: bn_wptr <= 8'b01000011;
8'b01100110: bn_wptr <= 8'b01000100;
8'b01100111: bn_wptr <= 8'b01000101;
8'b01100101: bn_wptr <= 8'b01000110;
8'b01100100: bn_wptr <= 8'b01000111;
8'b01101100: bn_wptr <= 8'b01001000;
8'b01101101: bn_wptr <= 8'b01001001;
8'b01101111: bn_wptr <= 8'b01001010;
8'b01101110: bn_wptr <= 8'b01001011;
8'b01101010: bn_wptr <= 8'b01001100;
8'b01101011: bn_wptr <= 8'b01001101;
8'b01101001: bn_wptr <= 8'b01001110;
8'b01101000: bn_wptr <= 8'b01001111;
8'b01111000: bn_wptr <= 8'b01010000;
8'b01111001: bn_wptr <= 8'b01010001;
8'b01111011: bn_wptr <= 8'b01010010;
8'b01111010: bn_wptr <= 8'b01010011;
8'b01111110: bn_wptr <= 8'b01010100;
8'b01111111: bn_wptr <= 8'b01010101;
8'b01111101: bn_wptr <= 8'b01010110;
8'b01111100: bn_wptr <= 8'b01010111;
8'b01110100: bn_wptr <= 8'b01011000;
8'b01110101: bn_wptr <= 8'b01011001;
8'b01110111: bn_wptr <= 8'b01011010;
8'b01110110: bn_wptr <= 8'b01011011;
8'b01110010: bn_wptr <= 8'b01011100;
8'b01110011: bn_wptr <= 8'b01011101;
8'b01110001: bn_wptr <= 8'b01011110;
8'b01110000: bn_wptr <= 8'b01011111;
8'b01010000: bn_wptr <= 8'b01100000;
8'b01010001: bn_wptr <= 8'b01100001;
8'b01010011: bn_wptr <= 8'b01100010;
8'b01010010: bn_wptr <= 8'b01100011;
8'b01010110: bn_wptr <= 8'b01100100;
8'b01010111: bn_wptr <= 8'b01100101;
8'b01010101: bn_wptr <= 8'b01100110;
8'b01010100: bn_wptr <= 8'b01100111;
8'b01011100: bn_wptr <= 8'b01101000;
8'b01011101: bn_wptr <= 8'b01101001;
8'b01011111: bn_wptr <= 8'b01101010;
8'b01011110: bn_wptr <= 8'b01101011;
8'b01011010: bn_wptr <= 8'b01101100;
8'b01011011: bn_wptr <= 8'b01101101;
8'b01011001: bn_wptr <= 8'b01101110;
8'b01011000: bn_wptr <= 8'b01101111;
8'b01001000: bn_wptr <= 8'b01110000;
8'b01001001: bn_wptr <= 8'b01110001;
8'b01001011: bn_wptr <= 8'b01110010;
8'b01001010: bn_wptr <= 8'b01110011;
8'b01001110: bn_wptr <= 8'b01110100;
8'b01001111: bn_wptr <= 8'b01110101;
8'b01001101: bn_wptr <= 8'b01110110;
8'b01001100: bn_wptr <= 8'b01110111;
8'b01000100: bn_wptr <= 8'b01111000;
8'b01000101: bn_wptr <= 8'b01111001;
8'b01000111: bn_wptr <= 8'b01111010;
8'b01000110: bn_wptr <= 8'b01111011;
8'b01000010: bn_wptr <= 8'b01111100;
8'b01000011: bn_wptr <= 8'b01111101;
8'b01000001: bn_wptr <= 8'b01111110;
8'b01000000: bn_wptr <= 8'b01111111;
8'b11000000: bn_wptr <= 8'b10000000;
8'b11000001: bn_wptr <= 8'b10000001;
8'b11000011: bn_wptr <= 8'b10000010;
8'b11000010: bn_wptr <= 8'b10000011;
8'b11000110: bn_wptr <= 8'b10000100;
8'b11000111: bn_wptr <= 8'b10000101;
8'b11000101: bn_wptr <= 8'b10000110;
8'b11000100: bn_wptr <= 8'b10000111;
8'b11001100: bn_wptr <= 8'b10001000;
8'b11001101: bn_wptr <= 8'b10001001;
8'b11001111: bn_wptr <= 8'b10001010;
8'b11001110: bn_wptr <= 8'b10001011;
8'b11001010: bn_wptr <= 8'b10001100;
8'b11001011: bn_wptr <= 8'b10001101;
8'b11001001: bn_wptr <= 8'b10001110;
8'b11001000: bn_wptr <= 8'b10001111;
8'b11011000: bn_wptr <= 8'b10010000;
8'b11011001: bn_wptr <= 8'b10010001;
8'b11011011: bn_wptr <= 8'b10010010;
8'b11011010: bn_wptr <= 8'b10010011;
8'b11011110: bn_wptr <= 8'b10010100;
8'b11011111: bn_wptr <= 8'b10010101;
8'b11011101: bn_wptr <= 8'b10010110;
8'b11011100: bn_wptr <= 8'b10010111;
8'b11010100: bn_wptr <= 8'b10011000;
8'b11010101: bn_wptr <= 8'b10011001;
8'b11010111: bn_wptr <= 8'b10011010;
8'b11010110: bn_wptr <= 8'b10011011;
8'b11010010: bn_wptr <= 8'b10011100;
8'b11010011: bn_wptr <= 8'b10011101;
8'b11010001: bn_wptr <= 8'b10011110;
8'b11010000: bn_wptr <= 8'b10011111;
8'b11110000: bn_wptr <= 8'b10100000;
8'b11110001: bn_wptr <= 8'b10100001;
8'b11110011: bn_wptr <= 8'b10100010;
8'b11110010: bn_wptr <= 8'b10100011;
8'b11110110: bn_wptr <= 8'b10100100;
8'b11110111: bn_wptr <= 8'b10100101;
8'b11110101: bn_wptr <= 8'b10100110;
8'b11110100: bn_wptr <= 8'b10100111;
8'b11111100: bn_wptr <= 8'b10101000;
8'b11111101: bn_wptr <= 8'b10101001;
8'b11111111: bn_wptr <= 8'b10101010;
8'b11111110: bn_wptr <= 8'b10101011;
8'b11111010: bn_wptr <= 8'b10101100;
8'b11111011: bn_wptr <= 8'b10101101;
8'b11111001: bn_wptr <= 8'b10101110;
8'b11111000: bn_wptr <= 8'b10101111;
8'b11101000: bn_wptr <= 8'b10110000;
8'b11101001: bn_wptr <= 8'b10110001;
8'b11101011: bn_wptr <= 8'b10110010;
8'b11101010: bn_wptr <= 8'b10110011;
8'b11101110: bn_wptr <= 8'b10110100;
8'b11101111: bn_wptr <= 8'b10110101;
8'b11101101: bn_wptr <= 8'b10110110;
8'b11101100: bn_wptr <= 8'b10110111;
8'b11100100: bn_wptr <= 8'b10111000;
8'b11100101: bn_wptr <= 8'b10111001;
8'b11100111: bn_wptr <= 8'b10111010;
8'b11100110: bn_wptr <= 8'b10111011;
8'b11100010: bn_wptr <= 8'b10111100;
8'b11100011: bn_wptr <= 8'b10111101;
8'b11100001: bn_wptr <= 8'b10111110;
8'b11100000: bn_wptr <= 8'b10111111;
8'b10100000: bn_wptr <= 8'b11000000;
8'b10100001: bn_wptr <= 8'b11000001;
8'b10100011: bn_wptr <= 8'b11000010;
8'b10100010: bn_wptr <= 8'b11000011;
8'b10100110: bn_wptr <= 8'b11000100;
8'b10100111: bn_wptr <= 8'b11000101;
8'b10100101: bn_wptr <= 8'b11000110;
8'b10100100: bn_wptr <= 8'b11000111;
8'b10101100: bn_wptr <= 8'b11001000;
8'b10101101: bn_wptr <= 8'b11001001;
8'b10101111: bn_wptr <= 8'b11001010;
8'b10101110: bn_wptr <= 8'b11001011;
8'b10101010: bn_wptr <= 8'b11001100;
8'b10101011: bn_wptr <= 8'b11001101;
8'b10101001: bn_wptr <= 8'b11001110;
8'b10101000: bn_wptr <= 8'b11001111;
8'b10111000: bn_wptr <= 8'b11010000;
8'b10111001: bn_wptr <= 8'b11010001;
8'b10111011: bn_wptr <= 8'b11010010;
8'b10111010: bn_wptr <= 8'b11010011;
8'b10111110: bn_wptr <= 8'b11010100;
8'b10111111: bn_wptr <= 8'b11010101;
8'b10111101: bn_wptr <= 8'b11010110;
8'b10111100: bn_wptr <= 8'b11010111;
8'b10110100: bn_wptr <= 8'b11011000;
8'b10110101: bn_wptr <= 8'b11011001;
8'b10110111: bn_wptr <= 8'b11011010;
8'b10110110: bn_wptr <= 8'b11011011;
8'b10110010: bn_wptr <= 8'b11011100;
8'b10110011: bn_wptr <= 8'b11011101;
8'b10110001: bn_wptr <= 8'b11011110;
8'b10110000: bn_wptr <= 8'b11011111;
8'b10010000: bn_wptr <= 8'b11100000;
8'b10010001: bn_wptr <= 8'b11100001;
8'b10010011: bn_wptr <= 8'b11100010;
8'b10010010: bn_wptr <= 8'b11100011;
8'b10010110: bn_wptr <= 8'b11100100;
8'b10010111: bn_wptr <= 8'b11100101;
8'b10010101: bn_wptr <= 8'b11100110;
8'b10010100: bn_wptr <= 8'b11100111;
8'b10011100: bn_wptr <= 8'b11101000;
8'b10011101: bn_wptr <= 8'b11101001;
8'b10011111: bn_wptr <= 8'b11101010;
8'b10011110: bn_wptr <= 8'b11101011;
8'b10011010: bn_wptr <= 8'b11101100;
8'b10011011: bn_wptr <= 8'b11101101;
8'b10011001: bn_wptr <= 8'b11101110;
8'b10011000: bn_wptr <= 8'b11101111;
8'b10001000: bn_wptr <= 8'b11110000;
8'b10001001: bn_wptr <= 8'b11110001;
8'b10001011: bn_wptr <= 8'b11110010;
8'b10001010: bn_wptr <= 8'b11110011;
8'b10001110: bn_wptr <= 8'b11110100;
8'b10001111: bn_wptr <= 8'b11110101;
8'b10001101: bn_wptr <= 8'b11110110;
8'b10001100: bn_wptr <= 8'b11110111;
8'b10000100: bn_wptr <= 8'b11111000;
8'b10000101: bn_wptr <= 8'b11111001;
8'b10000111: bn_wptr <= 8'b11111010;
8'b10000110: bn_wptr <= 8'b11111011;
8'b10000010: bn_wptr <= 8'b11111100;
8'b10000011: bn_wptr <= 8'b11111101;
8'b10000001: bn_wptr <= 8'b11111110;
8'b10000000: bn_wptr <= 8'b11111111;
endcase


/*			
case (gray_wr_ptr)
8'b0000000: bn_wptr <= 8'b0000000;
8'b0000001: bn_wptr <= 8'b0000001;
8'b0000011: bn_wptr <= 8'b0000010;
8'b0000010: bn_wptr <= 8'b0000011;
8'b0000110: bn_wptr <= 8'b0000100;
8'b0000111: bn_wptr <= 8'b0000101;
8'b0000101: bn_wptr <= 8'b0000110;
8'b0000100: bn_wptr <= 8'b0000111;
8'b0001100: bn_wptr <= 8'b0001000;
8'b0001101: bn_wptr <= 8'b0001001;
8'b0001111: bn_wptr <= 8'b0001010;
8'b0001110: bn_wptr <= 8'b0001011;
8'b0001010: bn_wptr <= 8'b0001100;
8'b0001011: bn_wptr <= 8'b0001101;
8'b0001001: bn_wptr <= 8'b0001110;
8'b0001000: bn_wptr <= 8'b0001111;

8'b0011000: bn_wptr <= 8'b0010000;
8'b0011001: bn_wptr <= 8'b0010001;
8'b0011011: bn_wptr <= 8'b0010010;
8'b0011010: bn_wptr <= 8'b0010011;
8'b0011110: bn_wptr <= 8'b0010100;
8'b0011111: bn_wptr <= 8'b0010101;
8'b0011101: bn_wptr <= 8'b0010110;
8'b0011100: bn_wptr <= 8'b0010111;
8'b0010100: bn_wptr <= 8'b0011000;
8'b0010101: bn_wptr <= 8'b0011001;
8'b0010111: bn_wptr <= 8'b0011010;
8'b0010110: bn_wptr <= 8'b0011011;
8'b0010010: bn_wptr <= 8'b0011100;
8'b0010011: bn_wptr <= 8'b0011101;
8'b0010001: bn_wptr <= 8'b0011110;
8'b0010000: bn_wptr <= 8'b0011111;

8'b0011000: bn_wptr <= 8'b0100000;
8'b0011001: bn_wptr <= 8'b0100001;
8'b0011011: bn_wptr <= 8'b0100010;
8'b0011010: bn_wptr <= 8'b0100011;
8'b0011110: bn_wptr <= 8'b0100100;
8'b0011111: bn_wptr <= 8'b0100101;
8'b0011101: bn_wptr <= 8'b0100110;
8'b0011100: bn_wptr <= 8'b0100111;
8'b0010100: bn_wptr <= 8'b0101000;
8'b0010101: bn_wptr <= 8'b0101001;
8'b0010111: bn_wptr <= 8'b0101010;
8'b0010110: bn_wptr <= 8'b0101011;
8'b0010010: bn_wptr <= 8'b0101100;
8'b0010011: bn_wptr <= 8'b0101101;
8'b0010001: bn_wptr <= 8'b0101110;
8'b0010000: bn_wptr <= 8'b0101111;

8'b0110000: bn_wptr <= 8'b0100000;
8'b0110001: bn_wptr <= 8'b0100001;
8'b0110011: bn_wptr <= 8'b0100010;
8'b0110010: bn_wptr <= 8'b0100011;
8'b0110110: bn_wptr <= 8'b0100100;
8'b0110111: bn_wptr <= 8'b0100101;
8'b0110101: bn_wptr <= 8'b0100110;
8'b0110100: bn_wptr <= 8'b0100111;
8'b0111100: bn_wptr <= 8'b0101000;
8'b0111101: bn_wptr <= 8'b0101001;
8'b0111111: bn_wptr <= 8'b0101010;
8'b0111110: bn_wptr <= 8'b0101011;
8'b0111010: bn_wptr <= 8'b0101100;
8'b0111011: bn_wptr <= 8'b0101101;
8'b0111001: bn_wptr <= 8'b0101110;
8'b0111000: bn_wptr <= 8'b0101111;

8'b1101000: bn_wptr <= 8'b0110000;
8'b1101001: bn_wptr <= 8'b0110001;
8'b1101011: bn_wptr <= 8'b0110010;
8'b1101010: bn_wptr <= 8'b0110011;
8'b1101110: bn_wptr <= 8'b0110100;
8'b1101111: bn_wptr <= 8'b0110101;
8'b1101101: bn_wptr <= 8'b0110110;
8'b1101100: bn_wptr <= 8'b0110111;
8'b1100100: bn_wptr <= 8'b0111000;
8'b1100101: bn_wptr <= 8'b0111001;
8'b1100111: bn_wptr <= 8'b0111010;
8'b1100110: bn_wptr <= 8'b0111011;
8'b1100010: bn_wptr <= 8'b0111100;
8'b1100011: bn_wptr <= 8'b0111101;
8'b1100001: bn_wptr <= 8'b0111110;
8'b1100000: bn_wptr <= 8'b0111111;

8'b1111000: bn_wptr <= 8'b1000000;
8'b1111001: bn_wptr <= 8'b1000001;
8'b1111011: bn_wptr <= 8'b1000010;
8'b1111010: bn_wptr <= 8'b1000011;
8'b1111110: bn_wptr <= 8'b1000100;
8'b1111111: bn_wptr <= 8'b1000101;
8'b1111101: bn_wptr <= 8'b1000110;
8'b1111100: bn_wptr <= 8'b1000111;
8'b1110100: bn_wptr <= 8'b1001000;
8'b1110101: bn_wptr <= 8'b1001001;
8'b1110111: bn_wptr <= 8'b1001010;
8'b1110110: bn_wptr <= 8'b1001011;
8'b1110010: bn_wptr <= 8'b1001100;
8'b1110011: bn_wptr <= 8'b1001101;
8'b1110001: bn_wptr <= 8'b1001110;
8'b1110000: bn_wptr <= 8'b1001111;

8'b1010000: bn_wptr <= 8'b1010000;
8'b1010001: bn_wptr <= 8'b1010001;
8'b1010011: bn_wptr <= 8'b1010010;
8'b1010010: bn_wptr <= 8'b1010011;
8'b1010110: bn_wptr <= 8'b1010100;
8'b1010111: bn_wptr <= 8'b1010101;
8'b1010101: bn_wptr <= 8'b1010110;
8'b1010100: bn_wptr <= 8'b1010111;
8'b1011100: bn_wptr <= 8'b1011000;
8'b1011101: bn_wptr <= 8'b1011001;
8'b1011111: bn_wptr <= 8'b1011010;
8'b1011110: bn_wptr <= 8'b1011011;
8'b1011010: bn_wptr <= 8'b1011100;
8'b1011011: bn_wptr <= 8'b1011101;
8'b1011001: bn_wptr <= 8'b1011110;
8'b1011000: bn_wptr <= 8'b1011111;

8'b1001000: bn_wptr <= 8'b1100000;
8'b1001001: bn_wptr <= 8'b1100001;
8'b1001011: bn_wptr <= 8'b1100010;
8'b1001010: bn_wptr <= 8'b1100011;
8'b1001110: bn_wptr <= 8'b1100100;
8'b1001111: bn_wptr <= 8'b1100101;
8'b1001101: bn_wptr <= 8'b1100110;
8'b1001100: bn_wptr <= 8'b1100111;
8'b1000100: bn_wptr <= 8'b1101000;
8'b1000101: bn_wptr <= 8'b1101001;
8'b1000111: bn_wptr <= 8'b1101010;
8'b1000110: bn_wptr <= 8'b1101011;
8'b1000010: bn_wptr <= 8'b1101100;
8'b1000011: bn_wptr <= 8'b1101101;
8'b1000001: bn_wptr <= 8'b1101110;
8'b1000000: bn_wptr <= 8'b1101111;

8'b0001000: bn_wptr <= 8'b1110000;
8'b0001001: bn_wptr <= 8'b1110001;
8'b0001011: bn_wptr <= 8'b1110010;
8'b0001010: bn_wptr <= 8'b1110011;
8'b0001110: bn_wptr <= 8'b1110100;
8'b0001111: bn_wptr <= 8'b1110101;
8'b0001101: bn_wptr <= 8'b1110110;
8'b0001100: bn_wptr <= 8'b1110111;
8'b0000100: bn_wptr <= 8'b1111000;
8'b0000101: bn_wptr <= 8'b1111001;
8'b0000111: bn_wptr <= 8'b1111010;
8'b0000110: bn_wptr <= 8'b1111011;
8'b0000010: bn_wptr <= 8'b1111100;
8'b0000011: bn_wptr <= 8'b1111101;
8'b0000001: bn_wptr <= 8'b1111110;
8'b0000000: bn_wptr <= 8'b1111111;

// Complete 8-bit bit reversal mapping (256 cases)
// Format: 8'bABCDEFGH maps to 8'bHGFEDCBA

// Cases 0-15
8'b00000000: bn_wptr <= 8'b00000000;
8'b00000001: bn_wptr <= 8'b10000000;
8'b00000010: bn_wptr <= 8'b01000000;
8'b00000011: bn_wptr <= 8'b11000000;
8'b00000100: bn_wptr <= 8'b00100000;
8'b00000101: bn_wptr <= 8'b10100000;
8'b00000110: bn_wptr <= 8'b01100000;
8'b00000111: bn_wptr <= 8'b11100000;
8'b00001000: bn_wptr <= 8'b00010000;
8'b00001001: bn_wptr <= 8'b10010000;
8'b00001010: bn_wptr <= 8'b01010000;
8'b00001011: bn_wptr <= 8'b11010000;
8'b00001100: bn_wptr <= 8'b00110000;
8'b00001101: bn_wptr <= 8'b10110000;
8'b00001110: bn_wptr <= 8'b01110000;
8'b00001111: bn_wptr <= 8'b11110000;

// Cases 16-31
8'b00010000: bn_wptr <= 8'b00001000;
8'b00010001: bn_wptr <= 8'b10001000;
8'b00010010: bn_wptr <= 8'b01001000;
8'b00010011: bn_wptr <= 8'b11001000;
8'b00010100: bn_wptr <= 8'b00101000;
8'b00010101: bn_wptr <= 8'b10101000;
8'b00010110: bn_wptr <= 8'b01101000;
8'b00010111: bn_wptr <= 8'b11101000;
8'b00011000: bn_wptr <= 8'b00011000;
8'b00011001: bn_wptr <= 8'b10011000;
8'b00011010: bn_wptr <= 8'b01011000;
8'b00011011: bn_wptr <= 8'b11011000;
8'b00011100: bn_wptr <= 8'b00111000;
8'b00011101: bn_wptr <= 8'b10111000;
8'b00011110: bn_wptr <= 8'b01111000;
8'b00011111: bn_wptr <= 8'b11111000;

// Cases 32-48
8'b00100000: bn_wptr <= 8'b00000100;
8'b00100001: bn_wptr <= 8'b10000100;
8'b00100010: bn_wptr <= 8'b01000100;
8'b00100011: bn_wptr <= 8'b11000100;
8'b00100100: bn_wptr <= 8'b00100100;
8'b00100101: bn_wptr <= 8'b10100100;
8'b00100110: bn_wptr <= 8'b01100100;
8'b00100111: bn_wptr <= 8'b11100100;
8'b00101000: bn_wptr <= 8'b00010100;
8'b00101001: bn_wptr <= 8'b10010100;
8'b00101010: bn_wptr <= 8'b01010100;
8'b00101011: bn_wptr <= 8'b11010100;
8'b00101100: bn_wptr <= 8'b00110100;
8'b00101101: bn_wptr <= 8'b10110100;
8'b00101110: bn_wptr <= 8'b01110100;
8'b00101111: bn_wptr <= 8'b11110100;

// Cases 48-63
8'b00110000: bn_wptr <= 8'b00001100;
8'b00110001: bn_wptr <= 8'b10001100;
8'b00110010: bn_wptr <= 8'b01001100;
8'b00110011: bn_wptr <= 8'b11001100;
8'b00110100: bn_wptr <= 8'b00101100;
8'b00110101: bn_wptr <= 8'b10101100;
8'b00110110: bn_wptr <= 8'b01101100;
8'b00110111: bn_wptr <= 8'b11101100;
8'b00111000: bn_wptr <= 8'b00011100;
8'b00111001: bn_wptr <= 8'b10011100;
8'b00111010: bn_wptr <= 8'b01011100;
8'b00111011: bn_wptr <= 8'b11011100;
8'b00111100: bn_wptr <= 8'b00111100;
8'b00111101: bn_wptr <= 8'b10111100;
8'b00111110: bn_wptr <= 8'b01111100;
8'b00111111: bn_wptr <= 8'b11111100;

// Cases 64-89
8'b01000000: bn_wptr <= 8'b00000010;
8'b01000001: bn_wptr <= 8'b10000010;
8'b01000010: bn_wptr <= 8'b01000010;
8'b01000011: bn_wptr <= 8'b11000010;
8'b01000100: bn_wptr <= 8'b00100010;
8'b01000101: bn_wptr <= 8'b10100010;
8'b01000110: bn_wptr <= 8'b01100010;
8'b01000111: bn_wptr <= 8'b11100010;
8'b01001000: bn_wptr <= 8'b00010010;
8'b01001001: bn_wptr <= 8'b10010010;
8'b01001010: bn_wptr <= 8'b01010010;
8'b01001011: bn_wptr <= 8'b11010010;
8'b01001100: bn_wptr <= 8'b00110010;
8'b01001101: bn_wptr <= 8'b10110010;
8'b01001110: bn_wptr <= 8'b01110010;
8'b01001111: bn_wptr <= 8'b11110010;

// Cases 80-95
8'b01010000: bn_wptr <= 8'b00001010;
8'b01010001: bn_wptr <= 8'b10001010;
8'b01010010: bn_wptr <= 8'b01001010;
8'b01010011: bn_wptr <= 8'b11001010;
8'b01010100: bn_wptr <= 8'b00101010;
8'b01010101: bn_wptr <= 8'b10101010;
8'b01010110: bn_wptr <= 8'b01101010;
8'b01010111: bn_wptr <= 8'b11101010;
8'b01011000: bn_wptr <= 8'b00011010;
8'b01011001: bn_wptr <= 8'b10011010;
8'b01011010: bn_wptr <= 8'b01011010;
8'b01011011: bn_wptr <= 8'b11011010;
8'b01011100: bn_wptr <= 8'b00111010;
8'b01011101: bn_wptr <= 8'b10111010;
8'b01011110: bn_wptr <= 8'b01111010;
8'b01011111: bn_wptr <= 8'b11111010;

// Cases 96-111
8'b01100000: bn_wptr <= 8'b00000110;
8'b01100001: bn_wptr <= 8'b10000110;
8'b01100010: bn_wptr <= 8'b01000110;
8'b01100011: bn_wptr <= 8'b11000110;
8'b01100100: bn_wptr <= 8'b00100110;
8'b01100101: bn_wptr <= 8'b10100110;
8'b01100110: bn_wptr <= 8'b01100110;
8'b01100111: bn_wptr <= 8'b11100110;
8'b01101000: bn_wptr <= 8'b00010110;
8'b01101001: bn_wptr <= 8'b10010110;
8'b01101010: bn_wptr <= 8'b01010110;
8'b01101011: bn_wptr <= 8'b11010110;
8'b01101100: bn_wptr <= 8'b00110110;
8'b01101101: bn_wptr <= 8'b10110110;
8'b01101110: bn_wptr <= 8'b01110110;
8'b01101111: bn_wptr <= 8'b11110110;

// Cases 112-128
8'b01110000: bn_wptr <= 8'b00001110;
8'b01110001: bn_wptr <= 8'b10001110;
8'b01110010: bn_wptr <= 8'b01001110;
8'b01110011: bn_wptr <= 8'b11001110;
8'b01110100: bn_wptr <= 8'b00101110;
8'b01110101: bn_wptr <= 8'b10101110;
8'b01110110: bn_wptr <= 8'b01101110;
8'b01110111: bn_wptr <= 8'b11101110;
8'b01111000: bn_wptr <= 8'b00011110;
8'b01111001: bn_wptr <= 8'b10011110;
8'b01111010: bn_wptr <= 8'b01011110;
8'b01111011: bn_wptr <= 8'b11011110;
8'b01111100: bn_wptr <= 8'b00111110;
8'b01111101: bn_wptr <= 8'b10111110;
8'b01111110: bn_wptr <= 8'b01111110;
8'b01111111: bn_wptr <= 8'b11111110;

// Cases 128-143
8'b10000000: bn_wptr <= 8'b00000001;
8'b10000001: bn_wptr <= 8'b10000001;
8'b10000010: bn_wptr <= 8'b01000001;
8'b10000011: bn_wptr <= 8'b11000001;
8'b10000100: bn_wptr <= 8'b00100001;
8'b10000101: bn_wptr <= 8'b10100001;
8'b10000110: bn_wptr <= 8'b01100001;
8'b10000111: bn_wptr <= 8'b11100001;
8'b10001000: bn_wptr <= 8'b00010001;
8'b10001001: bn_wptr <= 8'b10010001;
8'b10001010: bn_wptr <= 8'b01010001;
8'b10001011: bn_wptr <= 8'b11010001;
8'b10001100: bn_wptr <= 8'b00110001;
8'b10001101: bn_wptr <= 8'b10110001;
8'b10001110: bn_wptr <= 8'b01110001;
8'b10001111: bn_wptr <= 8'b11110001;

// Cases 144-159
8'b10010000: bn_wptr <= 8'b00001001;
8'b10010001: bn_wptr <= 8'b10001001;
8'b10010010: bn_wptr <= 8'b01001001;
8'b10010011: bn_wptr <= 8'b11001001;
8'b10010100: bn_wptr <= 8'b00101001;
8'b10010101: bn_wptr <= 8'b10101001;
8'b10010110: bn_wptr <= 8'b01101001;
8'b10010111: bn_wptr <= 8'b11101001;
8'b10011000: bn_wptr <= 8'b00011001;
8'b10011001: bn_wptr <= 8'b10011001;
8'b10011010: bn_wptr <= 8'b01011001;
8'b10011011: bn_wptr <= 8'b11011001;
8'b10011100: bn_wptr <= 8'b00111001;
8'b10011101: bn_wptr <= 8'b10111001;
8'b10011110: bn_wptr <= 8'b01111001;
8'b10011111: bn_wptr <= 8'b11111001;

// Cases 160-185
8'b10100000: bn_wptr <= 8'b00000101;
8'b10100001: bn_wptr <= 8'b10000101;
8'b10100010: bn_wptr <= 8'b01000101;
8'b10100011: bn_wptr <= 8'b11000101;
8'b10100100: bn_wptr <= 8'b00100101;
8'b10100101: bn_wptr <= 8'b10100101;
8'b10100110: bn_wptr <= 8'b01100101;
8'b10100111: bn_wptr <= 8'b11100101;
8'b10101000: bn_wptr <= 8'b00010101;
8'b10101001: bn_wptr <= 8'b10010101;
8'b10101010: bn_wptr <= 8'b01010101;
8'b10101011: bn_wptr <= 8'b11010101;
8'b10101100: bn_wptr <= 8'b00110101;
8'b10101101: bn_wptr <= 8'b10110101;
8'b10101110: bn_wptr <= 8'b01110101;
8'b10101111: bn_wptr <= 8'b11110101;

// Cases 186-191
8'b10110000: bn_wptr <= 8'b00001101;
8'b10110001: bn_wptr <= 8'b10001101;
8'b10110010: bn_wptr <= 8'b01001101;
8'b10110011: bn_wptr <= 8'b11001101;
8'b10110100: bn_wptr <= 8'b00101101;
8'b10110101: bn_wptr <= 8'b10101101;
8'b10110110: bn_wptr <= 8'b01101101;
8'b10110111: bn_wptr <= 8'b11101101;
8'b10111000: bn_wptr <= 8'b00011101;
8'b10111001: bn_wptr <= 8'b10011101;
8'b10111010: bn_wptr <= 8'b01011101;
8'b10111011: bn_wptr <= 8'b11011101;
8'b10111100: bn_wptr <= 8'b00111101;
8'b10111101: bn_wptr <= 8'b10111101;
8'b10111110: bn_wptr <= 8'b01111101;
8'b10111111: bn_wptr <= 8'b11111101;

// Cases 192-208
8'b11000000: bn_wptr <= 8'b00000011;
8'b11000001: bn_wptr <= 8'b10000011;
8'b11000010: bn_wptr <= 8'b01000011;
8'b11000011: bn_wptr <= 8'b11000011;
8'b11000100: bn_wptr <= 8'b00100011;
8'b11000101: bn_wptr <= 8'b10100011;
8'b11000110: bn_wptr <= 8'b01100011;
8'b11000111: bn_wptr <= 8'b11100011;
8'b11001000: bn_wptr <= 8'b00010011;
8'b11001001: bn_wptr <= 8'b10010011;
8'b11001010: bn_wptr <= 8'b01010011;
8'b11001011: bn_wptr <= 8'b11010011;
8'b11001100: bn_wptr <= 8'b00110011;
8'b11001101: bn_wptr <= 8'b10110011;
8'b11001110: bn_wptr <= 8'b01110011;
8'b11001111: bn_wptr <= 8'b11110011;

// Cases 208-223
8'b11010000: bn_wptr <= 8'b00001011;
8'b11010001: bn_wptr <= 8'b10001011;
8'b11010010: bn_wptr <= 8'b01001011;
8'b11010011: bn_wptr <= 8'b11001011;
8'b11010100: bn_wptr <= 8'b00101011;
8'b11010101: bn_wptr <= 8'b10101011;
8'b11010110: bn_wptr <= 8'b01101011;
8'b11010111: bn_wptr <= 8'b11101011;
8'b11011000: bn_wptr <= 8'b00011011;
8'b11011001: bn_wptr <= 8'b10011011;
8'b11011010: bn_wptr <= 8'b01011011;
8'b11011011: bn_wptr <= 8'b11011011;
8'b11011100: bn_wptr <= 8'b00111011;
8'b11011101: bn_wptr <= 8'b10111011;
8'b11011110: bn_wptr <= 8'b01111011;
8'b11011111: bn_wptr <= 8'b11111011;

// Cases 224-239
8'b11100000: bn_wptr <= 8'b00000111;
8'b11100001: bn_wptr <= 8'b10000111;
8'b11100010: bn_wptr <= 8'b01000111;
8'b11100011: bn_wptr <= 8'b11000111;
8'b11100100: bn_wptr <= 8'b00100111;
8'b11100101: bn_wptr <= 8'b10100111;
8'b11100110: bn_wptr <= 8'b01100111;
8'b11100111: bn_wptr <= 8'b11100111;
8'b11101000: bn_wptr <= 8'b00010111;
8'b11101001: bn_wptr <= 8'b10010111;
8'b11101010: bn_wptr <= 8'b01010111;
8'b11101011: bn_wptr <= 8'b11010111;
8'b11101100: bn_wptr <= 8'b00110111;
8'b11101101: bn_wptr <= 8'b10110111;
8'b11101110: bn_wptr <= 8'b01110111;
8'b11101111: bn_wptr <= 8'b11110111;

// Cases 240-255
8'b11110000: bn_wptr <= 8'b00001111;
8'b11110001: bn_wptr <= 8'b10001111;
8'b11110010: bn_wptr <= 8'b01001111;
8'b11110011: bn_wptr <= 8'b11001111;
8'b11110100: bn_wptr <= 8'b00101111;
8'b11110101: bn_wptr <= 8'b10101111;
8'b11110110: bn_wptr <= 8'b01101111;
8'b11110111: bn_wptr <= 8'b11101111;
8'b11111000: bn_wptr <= 8'b00011111;
8'b11111001: bn_wptr <= 8'b10011111;
8'b11111010: bn_wptr <= 8'b01011111;
8'b11111011: bn_wptr <= 8'b11011111;
8'b11111100: bn_wptr <= 8'b00111111;
8'b11111101: bn_wptr <= 8'b10111111;
8'b11111110: bn_wptr <= 8'b01111111;
8'b11111111: bn_wptr <= 8'b11111111;
	endcase
	*/
//bn_wptr <= gray_wr_ptr ^ (gray_wr_ptr >> 1);
	end
end


//======================================================================
// SECTION 2: Almost Empty Signal Calculation
//======================================================================
assign almost_empty = ((bn_wptr - bn_rptr) <= 1); // Check if the difference between write and read pointers is less than 2 slots.
assign rempty = almost_empty ; // Set the empty flag based on the almost_empty condition.
/*
always @(posedge rclk or negedge rrst_n) begin 
	// Update the binary read pointer (bn_rptr) on the rising edge of the read clock or reset.
	if(~rrst_n) 
	begin
		almost_empty <= 1'b0 ; // Reset the binary read pointer to 0.
	end 
	else if ( (bn_wptr - bn_rptr) <= 1 ) 
	begin
		almost_empty <= 1'b1 ; // Increment the binary read pointer by 2 if rinc is asserted and FIFO is not almost empty.
	end 
	else
	begin
       almost_empty <= 1'b0 ;
	end

end
*/
//======================================================================
// SECTION 3: Binary Read Pointer Update
//======================================================================
always @(posedge rclk or negedge rrst_n) begin 
	// Update the binary read pointer (bn_rptr) on the rising edge of the read clock or reset.
	if(~rrst_n) 
	begin
		bn_rptr <= 'b0 ; // Reset the binary read pointer to 0.
	end 
	else 
	if ( rinc == 1'b1 && !almost_empty ) 
	begin
		bn_rptr <= bn_rptr + 'd2 ; // Increment the binary read pointer by 2 if rinc is asserted and FIFO is not almost empty.
	end 
end

//======================================================================
// SECTION 4: Read Address Calculation
//======================================================================
assign r_addr = bn_rptr[ADDR_WIDTH-1:0] ; // Extract the read address from the binary read pointer (excluding the MSB).

//======================================================================
// SECTION 5: Gray-Coded Read Pointer Update
//======================================================================
always @(posedge rclk or negedge rrst_n ) begin
	// Update the gray-coded read pointer (gray_rd_ptr) on the rising edge of the read clock or reset.
	if (~rrst_n) 
	begin
		gray_rd_ptr <= 'b0 ; // Reset the gray-coded read pointer to 0.
	end 
	else 
	begin
		gray_rd_ptr <= bn_rptr ^ (bn_rptr >> 1); // Convert the binary read pointer to gray code.
	end
end

endmodule 

`resetall  // Reset all compiler directives to their default values.
