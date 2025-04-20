`timescale 1us / 1ns

module i2c_msg_encoder 
    (
    // ======================================================
    // =============== INPUT PORTS DECLARATION ==============
    // ======================================================
    input wire        clk,                      // Clock signal
    input wire        rst_n,                    // Active-low reset signal
    input wire [1:0]  de_mux_i2c_cmd,           // I2C command (2 bits)
    input wire [19:0] de_mux_i2c_address,       // I2C address (20 bits)
    input wire [7:0]  de_mux_i2c_len,           // I2C data length (8 bits)
    input wire        i2c_fsm_add_s,            // Start of address phase
    input wire        i2c_fsm_data_s,           // Start of data phase
    input wire        i2c_fsm_end_s,            // End of transaction
    input wire        de_mux_i2c_tr_vld,        // input data availble 

    
    // ======================================================
    // =============== OUTPUT PORTS DECLARATION =============
    // ======================================================
    output reg [7:0] i2c_splitted_msg,  // Shifted-out byte
    output reg       i2c_msg_vld        // Valid signal for shifted-out byte
    );

    // ======================================================
    // =============== LOCAL PARAMETERS =====================
    // ======================================================
    localparam WIDTH = 32;             // Max width of message buffer

    
    // ======================================================
    // =============== INTERNAL REGISTERS ===================
    // ======================================================
    reg [WIDTH-1:0] msg_buffer;        // Message buffer to store encoded message
    
    reg [2:0]       shift_counter;     // Counter to track shifted bytes
    reg [2:0]       shift_amount;      // Number of bytes shifted out
    reg             load_flag;         // Flag to indicate message is loaded
    // Registers for storing encoded message and shift amount
    reg [WIDTH-1:0] msg_buffer_reg   = 'b0;
    reg [2:0]       shift_amount_reg = 3'b0;
    // saving input variables 
    reg [19:0]      de_mux_i2c_address_reg;
    reg [1:0]       de_mux_i2c_cmd_reg;
    reg [7:0]       de_mux_i2c_len_reg;

    
    // ======================================================
    // ===============  SAVING INPUTS   =====================
    // ======================================================
    always_ff @( posedge clk or negedge rst_n ) begin 
        if ( !rst_n ) begin
            de_mux_i2c_address_reg <= 20'b0;
            de_mux_i2c_cmd_reg     <= 2'b0;
            de_mux_i2c_len_reg     <= 8'b0;
        end
        else 
        if (de_mux_i2c_tr_vld) 
        begin
            de_mux_i2c_address_reg <= de_mux_i2c_address;
            de_mux_i2c_cmd_reg     <= de_mux_i2c_cmd;
            de_mux_i2c_len_reg     <= de_mux_i2c_len;
        end
    end
        


    
    // ======================================================
    // =============== MESSAGE ENCODING LOGIC ===============
    // ======================================================
    always @(*) begin
        // Default assignments
        msg_buffer   = 'b0;
        shift_amount = 3'b0;
        load_flag    = 1'b0;
        
        // Determine message encoding based on input signals
        case ({i2c_fsm_add_s, i2c_fsm_data_s, i2c_fsm_end_s})
            3'b100: 
            begin  // ADD_S (3 bytes)
                msg_buffer   = {2'b01,de_mux_i2c_cmd_reg,de_mux_i2c_address_reg,8'h00}; // message encoded in address transction state 
                shift_amount = 3'd3;
                load_flag    = 1'b1;
            end
            3'b010: 
            begin  // DATA_S (4 bytes)
                msg_buffer   = {2'b01,de_mux_i2c_cmd_reg,de_mux_i2c_address_reg,de_mux_i2c_len_reg};// message encoded in data request transction state
                shift_amount = 3'd4;
                load_flag    = 1'b1;                        
            end
            3'b001: 
            begin  // END_S (3 bytes)
                msg_buffer   = {2'b00,de_mux_i2c_cmd_reg,de_mux_i2c_address_reg,8'h00};// message encoded in end transction state
                shift_amount = 3'd3;
                load_flag    = 1'b1;
            end
            default: 
            begin
                msg_buffer   = 'b0;
                shift_amount = 3'b0;
                load_flag    = 1'b0;
            end
        endcase
    end

    // ======================================================
    // ========== BYTE SHIFTER LOGIC (RIGHT SHIFT) ==========
    // ======================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
        begin
            // -----------------------------
            // Reset logic - Initialize registers
            // -----------------------------
            shift_counter    <= 3'b0;
            i2c_splitted_msg <= 8'b0;
            i2c_msg_vld      <= 1'b0;
            msg_buffer_reg   <= 'b0;
            shift_amount_reg <= 3'b0;
        end 
        else 
        if (load_flag) 
        begin
            // -----------------------------
            // Load new message into shift register
            // -----------------------------
            shift_counter    <= 3'b0;
            i2c_msg_vld      <= 1'b0;
            msg_buffer_reg   <= msg_buffer;
            shift_amount_reg <= shift_amount;
        end 
        else 
        if (shift_counter < shift_amount_reg) 
        begin
            // -----------------------------
            // Shift out the LSB (least significant byte)
            // -----------------------------
            i2c_splitted_msg <= msg_buffer_reg[WIDTH-1:24];
            msg_buffer_reg   <= {msg_buffer_reg[WIDTH-9:0],8'b0}; // Right shift by 8 bits
            shift_counter    <= shift_counter + 1;
            i2c_msg_vld      <= 1'b1; // Assert valid signal
        end 
        else 
        begin
            // -----------------------------
            // Clear the valid signal when not shifting
            // -----------------------------
            i2c_msg_vld <= 1'b0;
        end
    end
endmodule