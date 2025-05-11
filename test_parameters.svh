`ifndef DP_UVM_PARAMS_SVH
`define DP_UVM_PARAMS_SVH

// Parameters for DisplayPort UVM Environment

// Contol Link Symbols
    parameter logic [7:0] SR = 8'h0F; // SR (Scramble Reset) symbol
    parameter logic [7:0] BS = 8'hBC; // BS (Blanking Start) symbol
    parameter logic [7:0] BE = 8'hBE; // BE (Blanking End) symbol
    parameter logic [7:0] BF = 8'hBD; // BF (Blanking Fill) symbol
    parameter logic [7:0] SS = 8'hDC; // SS (Secondary data Start) symbol
    parameter logic [7:0] SE = 8'hDE; // SE (Secondary data End) symbol
    parameter logic [7:0] FS = 8'hFC; // BS (Fill Start) symbol
    parameter logic [7:0] FE = 8'hFE; // BE (Fill End) symbol 

// Data Rates in Gbps per lane
    parameter int RBR  = 1620;          // 1.62 Gbps/lane, meaning 162MHz, which means a clock period of 6.172839506 ns
    parameter int HBR  = 2700;          // 2.7 Gbps/lane, meaning 270MHz, which means a clock period of 3.703703704 ns
    parameter int HBR2 = 5400;          // 5.4 Gbps/lane, meaning 540MHz, which means a clock period of 1.851851852 ns
    parameter int HBR3 = 8100;          // 8.1 Gbps/lane, meaning 810MHz, which means a clock period of 0.1234567901 ns
    parameter int AUX_RATE = 100000;    // 1OO KHz for AUX_CH, which means a clock period of 10us 

// Lane Count
    parameter int LANE_1 = 1;
    parameter int LANE_2 = 2;
    parameter int LANE_4 = 4;

// Timeouts and delays
    parameter int AUX_REPLY_TIMEOUT_TIMER_WITH_LTTPR    = 3200000;  // 3.2ms timeout for AUX reply (if LTTPR is supported or not)
    parameter int AUX_REPLY_TIMEOUT_TIMER_WITHOUT_LTTPR = 400000;   // 400us timeout for AUX reply (if LTTPR is not supported)
    parameter int AUX_RESPONSE_TIMEOUT_TIMER            = 300000;   // 300us timeout for AUX response (if LTTPR is supported or not)
    parameter int AUX_TRANSACTION_MAX_TIME              = 500000;   // AUX transactions should not be longer than 500us 
    parameter int LINK_TRAINING_TARGET_TIME             = 10000000; // 10-ms link training completion time target

// AUX Transaction Types (bit 3)
    parameter bit AUX_I2C_OVER_AUX_TRANSACTION = 1'b0;  // Bit 3 = 1
    parameter bit AUX_NATIVE_TRANSACTION = 1'b1;        // Bit 3 = 0
  
// MOT (Middle-of-Transaction) bit is bit 2 for I2C transactions
    parameter int MOT_BIT_POSITION = 2;

// Configuration parameters
    parameter int AUX_MAX_PAYLOAD_BYTES = 16;  // Maximum AUX payload size

    parameter int AUX_ADDRESS_WIDTH = 20;      // 20-bit AUX address

    parameter int AUX_DATA_WIDTH = 8;      // 8-bit AUX data

// typedef enums
    typedef enum bit [1:0] {
        DETECTING = 2'b00,
        CR_STAGE = 2'b01,
        EQ_STAGE = 2'b10,
        ISO_STAGE = 2'b11
    } tl_flow_stages_e;

    typedef enum bit [1:0] {
        SINK_NOT_READY = 2'b00,
        SINK_READY = 2'b01
    } sink_flow_stages_e;

// Training Patterns
    typedef enum bit [1:0] {
        IDLE_PATTERN = 2'b00,
        TPS2 = 2'b01,
        TPS3 = 2'b10,
        TPS4 = 2'b11
    } training_pattern_t;

// Voltage Swing Levels
    typedef enum bit [1:0] {
        VTG_LVL_0 = 2'b00,
        VTG_LVL_1 = 2'b01,
        VTG_LVL_2 = 2'b10,
        VTG_LVL_3 = 2'b11
    } voltage_swing_t;

// Pre-Emphasis Levels
    typedef enum bit [1:0] {
        PRE_LVL_0 = 2'b00,
        PRE_LVL_1 = 2'b01,
        PRE_LVL_2 = 2'b10,
        PRE_LVL_3 = 2'b11
    } pre_emphasis_t;

// HPD Events
    typedef enum bit [1:0] {
        HPD_NONE    = 2'b00,
        HPD_PLUG    = 2'b01,
        HPD_UNPLUG  = 2'b10,
        HPD_IRQ     = 2'b11
    } hpd_event_t;

// SOURCE MODES
    typedef enum bit {
        TALK_MODE, 
        LISTEN_MODE
    } source_mode_e;

// DPTX AUX_CH FSM
    typedef enum logic [3:0] {
        S0_DPTX_NOT_READY      = 4'b0001,
        S1_DPRX_NOT_DETECTED   = 4'b0010, 
        S2_AUX_CH_IDLE         = 4'b0100,
        S3_AUX_REQUEST_CMD_PENDING = 4'b1000
    } dptx_aux_ch_state_e;

// DPRX AUX_CH FSM
    typedef enum logic [2:0] {
        D0_DPRX_NOT_READY             = 3'b001, 
        D1_AUX_CH_IDLE                = 3'b010, 
        D2_DPRX_AUX_REPLY_CMD_PENDING = 3'b100
    } dprx_aux_ch_state_e;

// AUX Request Command Definitions (bits 0-2 when bit 3 = 1, Native AUX) based on Table 2-176
    typedef enum logic [1:0] {
        AUX_NATIVE_WRITE   = 2'b00,  // Bit 3=1, Bits[2:0]=000
        AUX_NATIVE_READ    = 2'b01   // Bit 3=1, Bits[2:0]=001
    } native_aux_request_cmd_e;

// AUX Request Command Definitions (bits 0-1 when bit 3 = 0, I2C-over-AUX) based on Table 2-176
    typedef enum bit [1:0] {
        AUX_I2C_WRITE               = 2'b00,  // Bit 3=0, Bit 2= MOT, Bits[1:0]=00
        AUX_I2C_READ                = 2'b01,  // Bit 3=0, Bit 2= MOT, Bits[1:0]=01
        AUX_I2C_WRITE_STATUS_UPDATE = 2'b10,  // Bit 3=0, Bit 2= MOT, Bits[1:0]=10
        AUX_I2C_RESERVED            = 2'b11   // Bit 3=0, Bit 2= MOT, Bits[1:0]=11
    } i2c_aux_request_cmd_e;

// Reply command for (Native AUX Reply field) based on Table 2-177 
    typedef enum logic [3:0] {
        AUX_ACK   = 4'b00_00,  // ACK
        AUX_NACK  = 4'b00_01,  // NACK
        AUX_DEFER = 4'b00_10,  // DEFER
        AUX_RESERVED  = 4'b00_11   // RESERVED
    } native_aux_reply_cmd_e;

// Reply command for (I2C-over-AUX Reply field) based on Table 2-177
    typedef enum logic [3:0] {
        I2C_ACK   = 4'b00_00,  // ACK
        I2C_NACK  = 4'b01_00,  // NACK
        I2C_DEFER = 4'b10_00,  // DEFER
        I2C_RESERVED  = 4'b11_00   // RESERVED
    } i2c_aux_reply_cmd_e;

// Link Training Phases
    typedef enum bit [1:0] {
        CLOCK_RECOVERY = 2'b00,         // Clock Recovery Stage of the Link Training
        CHANNEL_EQUALIZATION = 2'b01,   // Channel Equalization Stage of the Link Training
        LINK_READY = 2'b10              // Link Training has been successful
    } link_training_phase_t;

// AUX Channel Operation (TL)
    typedef enum logic [3:0] {
        reset_op        = 4'b0000,  
        I2C_READ        = 4'b0001,
        I2C_WRITE       = 4'b0010,
        NATIVE_READ     = 4'b0011,
        NATIVE_WRITE    = 4'b0100,
        CR_LT_op        = 4'b0101,
        EQ_LT_op        = 4'b0110,
        ISO             = 4'b0111,
        DETECT_op       = 4'b1000,
        FLOW_FSM_op     = 4'b1001,
        WAIT_REPLY      = 4'b1010
    } op_code;

// Sink Driver Operation
    typedef enum logic [3:0] {
        Reset                   = 4'b0000,
        Ready                   = 4'b0001,
        Reply_operation         = 4'b0010,
        HPD_test_operation      = 4'b0011,
        Interrupt_operation     = 4'b0100
    } sink_op_code;

// Isochronous Services Operation
    typedef enum logic [1:0] {
        ISO_IDLE        = 2'b00,  // Sending IDLE pattern
        ISO_VBLANK      = 2'b01,  // Vblank period
        ISO_HBLANK      = 2'b10,  // Hblank period
        ISO_ACTIVE      = 2'b11   // Active video period
    } iso_op_code;

// IDLE (or no data transmissions) in ISO Operation
    typedef enum logic [2:0] {
        ISO_SR    = 3'b000,   
        ISO_BS    = 3'b001,  
        ISO_BF    = 3'b010,  
        ISO_VB_ID = 3'b011,  
        ISO_MVID  = 3'b100,   
        ISO_MAUD  = 3'b101,   
        ISO_DUMMY = 3'b110,
        ISO_MSA   = 3'b111
    } iso_idle_code;

// Transfer Unit in ISO Operation
    typedef enum logic [1:0] {
        ISO_TU_PIXELS = 2'b00,   
        ISO_TU_FS     = 2'b01,  
        ISO_TU_FE     = 2'b10,  
        ISO_TU_DUMMY  = 2'b11
    } iso_TU_code;

`endif // DP_UVM_PARAMS_SVH