`default_nettype none  // Disable implicit net declarations to avoid unintended wire declarations

/****************************************************************************************
 * Module Name: WPTR_FULL
 * Description: 
 *   This module implements the write pointer and full flag logic for an asynchronous FIFO.
 *   It includes binary and Gray-coded write pointer generation, write address calculation,
 *   and full flag determination based on the relationship between the write and read pointers.
 * Author: Mohammed Tersawy
 ****************************************************************************************/

module WPTR_FULL 
#
( 
	parameter WPTR_WIDTH = 4,  // Width of the write pointer
	parameter RPTR_WIDTH = 4,  // Width of the read pointer
	parameter ADDR_WIDTH = 3   // Address width 3 bits only from 0 to 7 
)
(
	input  wire                  wclk,         // Write clock
	input  wire                  wrst_n,       // Active-low write reset	
	input  wire                  winc,         // Write enable signal enables write in FIFO memory
	input  wire [RPTR_WIDTH-1:0] gray_rd_ptr,  // Read pointer in Gray code
	output reg                   wfull,        // Write full flag
	output reg [ADDR_WIDTH-1:0]  w_addr,       // Write address
	output reg [WPTR_WIDTH-1:0]  gray_wr_ptr   // Write pointer in Gray code
);

//////////////////////////////////////////////////////////////////////////////////////////
// Internal Signals
//////////////////////////////////////////////////////////////////////////////////////////
reg [WPTR_WIDTH-1:0] bn_wptr;    // Binary write pointer
wire                 full_flag;  // Signal indicating if the FIFO is full

//////////////////////////////////////////////////////////////////////////////////////////
// Full Flag Logic
//////////////////////////////////////////////////////////////////////////////////////////
// Full flag logic: FIFO is full when the Gray-coded write pointer and read pointer meet specific conditions
assign full_flag = (
	(gray_wr_ptr[WPTR_WIDTH-1] != gray_rd_ptr[RPTR_WIDTH-1]) &&   // MSB of write and read pointers differ
	(gray_wr_ptr[WPTR_WIDTH-2] != gray_rd_ptr[RPTR_WIDTH-2]) &&   // Second MSB of write and read pointers differ
	(gray_wr_ptr[WPTR_WIDTH-3:0] == gray_rd_ptr[RPTR_WIDTH-3:0])  // Remaining bits of write and read pointers match
) ? 1'b1 : 1'b0;

//////////////////////////////////////////////////////////////////////////////////////////
// Binary Write Pointer Update Logic
//////////////////////////////////////////////////////////////////////////////////////////
always @(posedge wclk or negedge wrst_n) begin 
	if (~wrst_n) 
	begin
		bn_wptr <= 'b0;  // Reset binary write pointer to 0
	end 
	else 
	if (winc == 1'b1 && !full_flag) 
	begin
		bn_wptr <= bn_wptr + 'b1;  // Increment binary write pointer if write is enabled and FIFO is not full
	end 
end

//////////////////////////////////////////////////////////////////////////////////////////
// Write Address Generation
//////////////////////////////////////////////////////////////////////////////////////////
// Write address generation: lower bits of binary write pointer
assign w_addr = bn_wptr[ADDR_WIDTH-1:0];

//////////////////////////////////////////////////////////////////////////////////////////
// Gray-Coded Write Pointer Generation
//////////////////////////////////////////////////////////////////////////////////////////
always @(posedge wclk or negedge wrst_n) begin
	if (~wrst_n) 
	begin
		gray_wr_ptr <= 'b0;  // Reset Gray-coded write pointer to 0
	end 
	else 
	begin
		gray_wr_ptr <= bn_wptr ^ (bn_wptr >> 1);  // Convert binary write pointer to Gray code such that this value is crossing to another time domain
	end
end

//////////////////////////////////////////////////////////////////////////////////////////
// Write Full Flag Update Logic
//////////////////////////////////////////////////////////////////////////////////////////
always @(posedge wclk or negedge wrst_n) begin
	if (~wrst_n) 
	begin
		wfull <= 1'b0;  // Reset write full flag to 0
	end 
	else 
	begin
		wfull <= full_flag;  // Update write full flag based on full_flag signal
	end 
end

endmodule 

`resetall  // Reset all compiler directives to their default values
