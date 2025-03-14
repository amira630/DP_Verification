`ifndef DP_UVM_PARAMS_SVH
`define DP_UVM_PARAMS_SVH

// Parameters for DisplayPort UVM Environment

// Data Rates in Gbps per lane
    parameter int RBR  = 1620; // 1.62 Gbps
    parameter int HBR  = 2700; // 2.7 Gbps
    parameter int HBR2 = 5400; // 5.4 Gbps
    parameter int HBR3 = 8100; // 8.1 Gbps

// Lane Count
    parameter int LANE_1 = 1;
    parameter int LANE_2 = 2;
    parameter int LANE_4 = 4;

// Timeouts and delays
    parameter int AUX_REPLY_TIMEOUT_TIMER_WITH_LTTPR    = 3200000;  // 3.2ms timeout for AUX reply (if LTTPR is supported or not)
    parameter int AUX_REPLY_TIMEOUT_TIMER_WITHOUT_LTTPR = 400000;   // 400us timeout for AUX reply (if LTTPR is not supported)
    parameter int AUX_RESPONSE_TIMEOUT_TIMER            = 300000;   // 300us timeout for AUX reply (if LTTPR is supported or not)

// AUX Transaction Types (bit 3)
    parameter bit AUX_I2C_OVER_AUX_TRANSACTION = 1'b1;  // Bit 3 = 1
    parameter bit AUX_NATIVE_TRANSACTION = 1'b0;        // Bit 3 = 0

// AUX Request Command Definitions (bits 0-2 when bit 3 = 1, I2C-over-AUX)
    parameter logic [3:0] AUX_I2C_WRITE               = 4'b0000;  // Bit 3=0, Bits[2:0]=000
    parameter logic [3:0] AUX_I2C_READ                = 4'b0001;  // Bit 3=0, Bits[2:0]=001
    parameter logic [3:0] AUX_I2C_WRITE_STATUS_UPDATE = 4'b0010;  // Bit 3=0, Bits[2:0]=010
    parameter logic [3:0] AUX_I2C_RESERVED            = 4'b0011;  // Bit 3=0, Bits[2:0]=011

// AUX Request Command Definitions (bits 0-2 when bit 3 = 0, Native AUX)
    parameter logic [3:0] AUX_NATIVE_WRITE            = 4'b1000;  // Bit 3=1, Bits[2:0]=000
    parameter logic [3:0] AUX_NATIVE_READ             = 4'b1001;  // Bit 3=1, Bits[2:0]=001
  
// MOT (Middle-of-Transaction) bit is bit 2 for I2C transactions
    parameter int MOT_BIT_POSITION = 2;

// Configuration parameters
    parameter int AUX_MAX_PAYLOAD_BYTES = 16;  // Maximum AUX payload size

    parameter int AUX_ADDRESS_WIDTH = 20;      // 20-bit AUX address



// typedef enums

// Training Patterns
    typedef enum bit [2:0] {
        TPS1 = 3'b000,
        TPS2 = 3'b001,
        TPS3 = 3'b010,
        TPS4 = 3'b011
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

// LTTPR MODES
    typedef enum bit {
        LTTPR_NON_TRANSPARENT_MODE, 
        LTTPR_TRANSPARENT_MODE
    } lttpr_mode_e;

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

// Reply command for (Native AUX Replay field) based on Table 2-177 (Bit#0,1) of the replay command 
    typedef enum logic [1:0] {
        AUX_ACK   = 2'b00,  // ACK
        AUX_NACK  = 2'b01,  // NACK
        AUX_DEFER = 2'b10,  // DEFER
        RESERVED  = 2'b11  // Reserved
    } native_aux_reply_cmd_e;

// Reply command for (I2C-over-AUX Replay field) based on Table 2-177 (Bit#2,3) of the replay command 
    typedef enum logic [1:0] {
        I2C_ACK   = 2'b00,  // ACK
        I2C_NACK  = 2'b01,  // NACK
        I2C_DEFER = 2'b10,  // DEFER
        RESERVED  = 2'b11  // Reserved
    } i2c_aux_reply_cmd_e;

// Link Training Phases
    typedef enum bit [1:0] {
        CLOCK_RECOVERY = 2'b00,
        CHANNEL_EQUALIZATION = 2'b01,
        LINK_READY = 2'b10
    } link_training_phase_t;

`endif // DP_UVM_PARAMS_SVH