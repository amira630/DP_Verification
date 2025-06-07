//==========================================================================================
// module name : DF_SYNC
// Author name : Mohammed Tersawy
// Describtion : synchronizing read and write conters to check on empty and full conditions 
//               in both clock domains 
//===========================================================================================

module DF_SYNC #( parameter NUM_STAGES = 2 , parameter PTR_WIDTH = 4 )
(
    input wire [PTR_WIDTH-1:0] async_ptr,
    input wire clk,
    input wire rst_n,
    output reg [PTR_WIDTH-1:0] sync_ptr
);

reg [PTR_WIDTH-1:0] sync_stage [NUM_STAGES-1:0]; 


always @(posedge clk or negedge rst_n) begin
    if (~rst_n) 
	begin
        sync_stage[0] <= 'd0;
        sync_stage[1] <= 'd0;
        sync_ptr      <= 'd0;
    end 
	else 
	begin
        sync_stage[0] <= async_ptr;     // Capture the asynchronous input
        sync_stage[1] <= sync_stage[0];   // First stage to second stage
        sync_ptr      <= sync_stage[1];   // Second stage to output
    end
end

endmodule 
