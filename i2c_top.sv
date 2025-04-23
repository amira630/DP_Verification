module i2c_top 
	(
        input wire        clk,               // Clock Signal
        input wire        rst_n,             // Active-low Reset
        input wire        de_mux_i2c_tr_vld, // I2C Transaction Valid
        input wire [1:0]  reply_ack,         // I2C Acknowledgment Response
        input wire        reply_ack_vld,     // Acknowledgment Valid Flag
        input wire        timer_timeout,     // Timeout Signal
        input wire [1:0]  de_mux_i2c_cmd,    // I2C command (2 bits) 
        input wire [19:0] de_mux_i2c_address,// I2C address (20 bits)
        input wire [7:0]  de_mux_i2c_len,    // I2C data length (8 bits)
		output wire       i2c_fsm_complete,  // I2C Completion Flag
		output wire [7:0] i2c_splitted_msg,  // Shifted-out byte
		output wire       i2c_msg_vld,       // Valid signal for shifted-out byte
		output wire       i2c_fsm_failed     // I2C Failed Flag
	);
    

    wire i2c_fsm_add_s;
    wire i2c_fsm_data_s;
    wire i2c_fsm_end_s;
    
    i2c_fsm U0_i2c_fsm 
    (
    	.clk              (clk),
    	.rst_n            (rst_n),
    	.de_mux_i2c_tr_vld(de_mux_i2c_tr_vld), 
    	.reply_ack        (reply_ack),
    	.reply_ack_vld    (reply_ack_vld),
    	.timer_timeout    (timer_timeout),   	
    	.i2c_fsm_add_s    (i2c_fsm_add_s),
    	.i2c_fsm_end_s    (i2c_fsm_end_s),
    	.i2c_fsm_data_s   (i2c_fsm_data_s),
    	.i2c_fsm_complete (i2c_fsm_complete),
		.i2c_fsm_failed   (i2c_fsm_failed)
    ); 

    i2c_msg_encoder U1_i2c_msg_encoder 
    (   
    	.clk               (clk),
    	.rst_n             (rst_n),
    	.i2c_fsm_add_s     (i2c_fsm_add_s),
    	.i2c_fsm_data_s    (i2c_fsm_data_s),
    	.i2c_fsm_end_s     (i2c_fsm_end_s),
		.de_mux_i2c_tr_vld (de_mux_i2c_tr_vld),
    	.de_mux_i2c_cmd    (de_mux_i2c_cmd),
    	.de_mux_i2c_len    (de_mux_i2c_len),
    	.de_mux_i2c_address(de_mux_i2c_address),
    	.i2c_splitted_msg  (i2c_splitted_msg),
    	.i2c_msg_vld       (i2c_msg_vld) 
    );
endmodule