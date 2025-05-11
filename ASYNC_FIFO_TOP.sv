`default_nettype none  // Disable implicit net declarations
module ASYNC_FIFO_TOP #
( 
	parameter DATA_WIDTH = 8 ,  
	parameter FIFO_DEPTH = 6 ,
	parameter WPTR_WIDTH = 4 ,
	parameter RPTR_WIDTH = 4 ,
	parameter NUM_STAGES = 2 ,
	parameter ADDR_WIDTH = 3 
) 
(
	input  wire [DATA_WIDTH-1:0]   wr_data ,
	input  wire                    winc ,
	input  wire                    rinc ,
	input  wire                    wclk ,
	input  wire                    wrst_n ,
	input  wire                    rclk ,
	input  wire                    rrst_n ,
	
	output wire                    wfull ,
	output wire                    rempty ,
	output wire [2*DATA_WIDTH-1:0] rd_data ,
	output wire                    rd_data_valid 
);

wire [WPTR_WIDTH-2:0] wr_addr ;
wire [RPTR_WIDTH-2:0] rd_addr ;
wire [RPTR_WIDTH-1:0] gray_rd_ptr ;
wire [WPTR_WIDTH-1:0] gray_wr_ptr ;
wire [WPTR_WIDTH-1:0] sync_wr_ptr ;
wire [RPTR_WIDTH-1:0] sync_rd_ptr ;

FIFO_MEM #
(
	.DATA_WIDTH(DATA_WIDTH),
	.ADDR_WIDTH(ADDR_WIDTH),
	.FIFO_DEPTH(FIFO_DEPTH)
) u0 
(
	.winc   (winc),
	.wr_data(wr_data),
	.wfull  (wfull),
	.wr_addr(wr_addr),
	.rd_addr(rd_addr),
	.wclk   (wclk),
	.wrst_n (wrst_n),
	.rd_data(rd_data),
	.rinc   (rinc),
	.rempty (rempty),
	.rclk   (rclk),
	.rrst_n (rrst_n),
	.rd_data_valid(rd_data_valid)
) ;

WPTR_FULL #
(
	.ADDR_WIDTH(ADDR_WIDTH),
	.RPTR_WIDTH(RPTR_WIDTH),
	.WPTR_WIDTH(WPTR_WIDTH)
) u1 
(
	.winc       (winc),
	.wclk       (wclk),
	.wfull      (wfull),
	.wrst_n     (wrst_n),
	.gray_rd_ptr(sync_rd_ptr),
	.w_addr     (wr_addr),
	.gray_wr_ptr(gray_wr_ptr)
) ;

RPTR_EMPTY #
(
	.ADDR_WIDTH(ADDR_WIDTH),
	.WPTR_WIDTH(WPTR_WIDTH),
	.RPTR_WIDTH(RPTR_WIDTH)
) u2
(
	.gray_wr_ptr(sync_wr_ptr),
	.rinc       (rinc),
	.rclk       (rclk),
	.rrst_n     (rrst_n),
	.rempty     (rempty),
	.r_addr     (rd_addr),
	.gray_rd_ptr(gray_rd_ptr)
) ;

DF_SYNC #
(
	.NUM_STAGES(NUM_STAGES),
	.PTR_WIDTH (WPTR_WIDTH)
) u3
(
	.async_ptr(gray_wr_ptr),
	.clk      (rclk),
	.rst_n    (rrst_n),
	.sync_ptr (sync_wr_ptr)
) ;

DF_SYNC #
(
	.NUM_STAGES(NUM_STAGES),
	.PTR_WIDTH (RPTR_WIDTH)
) u4
(
	.async_ptr(gray_rd_ptr),
	.clk      (wclk),
	.rst_n    (wrst_n),
	.sync_ptr (sync_rd_ptr)
) ;
endmodule 
`resetall  // Reset all compiler directives to their default values
