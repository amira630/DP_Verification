//-----------------------------------------------------------------------------
// Module: FIFO_MEM
//
// Description: 
// This module implements a memory block for an asynchronous FIFO. 
// It is responsible for storing data written by the write clock domain and 
// providing it to the read clock domain. The module ensures proper handling 
// of data integrity and synchronization between the two clock domains.
// 
// Author: Mohammed Tersawy
//-----------------------------------------------------------------------------


`default_nettype none  // Disable implicit net declarations to avoid unintended wire declarations.

//==========================================================================
// Module Declaration
//==========================================================================
module FIFO_MEM 
#
( 
	parameter DATA_WIDTH = 8 , 
	parameter ADDR_WIDTH = 3 , 
	parameter FIFO_DEPTH = 8 
	
)
(
	input  wire [DATA_WIDTH-1:0]   wr_data ,       // Write data input.
	input  wire                    winc ,          // Write enable signal.
	input  wire                    wfull ,         // Write full flag, indicates FIFO is full.
	input  wire [ADDR_WIDTH-1:0]   wr_addr ,       // Write address pointer.
	input  wire [ADDR_WIDTH-1:0]   rd_addr ,       // Read address pointer.
	input  wire                    wclk ,          // Write clock signal.
	input  wire                    wrst_n ,        // Write reset signal (active low).
	input  wire                    rclk ,          // Read clock signal.
	input  wire                    rrst_n ,        // Read reset signal (active low).
	input  wire                    rinc ,          // Read enable signal.
	input  wire                    rempty ,        // Read empty flag, indicates FIFO is empty.
	output wire [2*DATA_WIDTH-1:0] rd_data ,       // Read data output (concatenated from two FIFO entries).
	output reg                     rd_data_valid   // Read data valid flag, indicates valid data is available.
);

//==========================================================================
// Internal Signals and Registers
//==========================================================================
reg  [DATA_WIDTH-1:0] fifo_buffer [FIFO_DEPTH-1:0] ; // FIFO memory buffer array.
wire wclken ;                                        // Write clock enable signal.
wire rclken ;                                        // Read clock enable signal.
reg [2*DATA_WIDTH-1:0] rd_data_reg;                  // Register to hold read data.
 

//==========================================================================
// ENABLING READ AND WRITE CONDITIONS 
//===========================================================================
assign wclken = (winc && !wfull) ;                  // Write enable when not full and write signal is active.
assign rclken = (rinc && !rempty) ;                 // Read enable when not empty and read signal is active.

//==========================================================================
// Write Logic
//==========================================================================
always @(posedge wclk or negedge wrst_n) begin 
	if(~wrst_n) 
	begin
		// Reset FIFO buffer to zero on write reset without using a for loop.
		fifo_buffer <= '{default: 8'b0};
	end
	else 
	if ( wclken == 1'b1 ) 
	begin
		// Write data into FIFO buffer at the write address.
		fifo_buffer [wr_addr] <= wr_data ;
	end 
end

//==========================================================================
// Read Logic
//==========================================================================

assign rd_data = rd_data_reg;                       // Assign read data register to output.

always @(posedge rclk or negedge rrst_n) begin
	if (~rrst_n) 
	begin
		// Reset read data register to zero on read reset.
		rd_data_reg <= 'd0;
		rd_data_valid <= 1'b0; // Clear read data valid flag.
	end 
	else 
	if (rclken == 1'b1) 
	begin
		// Read two consecutive entries from FIFO buffer and concatenate them.
		rd_data_reg <= {fifo_buffer[rd_addr + 1],fifo_buffer[rd_addr]};
		rd_data_valid <= 1'b1; // Set read data valid flag.
	end
	else
	begin
		rd_data_valid <= 1'b0; // Clear read data valid flag when not reading.
	end
end
endmodule 

//==========================================================================
// End of Module
//==========================================================================
`resetall  // Reset all compiler directives to their default values.
