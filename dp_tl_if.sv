import uvm_pkg::*;
    `include "uvm_macros.svh"
      import test_parameters_pkg::*;

interface dp_tl_if #(parameter AUX_ADDRESS_WIDTH = 20, AUX_DATA_WIDTH = 8) (input clk_AUX, clk_RBR, clk_HBR, clk_HBR2, clk_HBR3, MS_Stm_CLK);

    
    logic rst_n;   // Reset is asynchronous active low
    
    ///////////////////////////////////////////////////////////////
    //////////////////// AUXILIARY CHANNEL ////////////////////////
    /////////////////////////////////////////////////////////////// 

    /////////////////// STREAM POLICY MAKER ///////////////////////

    logic [AUX_ADDRESS_WIDTH-1:0] SPM_Address;
    logic [AUX_DATA_WIDTH-1:0]  SPM_Data, SPM_LEN, SPM_Reply_Data;
    logic [1:0]  SPM_CMD, SPM_Reply_ACK;
    logic        SPM_Reply_ACK_VLD, SPM_Reply_Data_VLD, SPM_NATIVE_I2C, SPM_Transaction_VLD;
    logic        CTRL_I2C_Failed;

    //////////////////// LINK POLICY MAKER ////////////////////////
    
    logic [AUX_ADDRESS_WIDTH-1:0] LPM_Address;
    logic [AUX_DATA_WIDTH-1:0]    LPM_Data, LPM_LEN, LPM_Reply_Data;
    logic [1:0]                   LPM_CMD, LPM_Reply_ACK;
    logic                         LPM_Reply_ACK_VLD, LPM_Reply_Data_VLD,LPM_Transaction_VLD;
    logic                         HPD_Detect, HPD_IRQ, CTRL_Native_Failed;
    logic                         LPM_NATIVE_I2C;            

    ////////////////// LINK Training Signals //////////////////////

    logic [AUX_DATA_WIDTH-1:0] Link_BW_CR, PRE, VTG, EQ_RD_Value, Lane_Align, EQ_Final_ADJ_BW;
    logic [3:0] CR_DONE, EQ_CR_DN, Channel_EQ, Symbol_Lock;
    logic [1:0] Link_LC_CR, EQ_Final_ADJ_LC, MAX_TPS_SUPPORTED, MAX_VTG, MAX_PRE;
    logic       LPM_Start_CR, Driving_Param_VLD, EQ_Data_VLD, FSM_CR_Failed, EQ_FSM_CR_Failed, EQ_Failed, EQ_LT_Pass, Config_Param_VLD, CR_DONE_VLD;
    logic       CR_Completed, MAX_TPS_SUPPORTED_VLD, Timer_Timeout;

    ///////////////////////////////////////////////////////////////
    ////////////////// ISOCHRONOUS TRANSPORT //////////////////////
    ///////////////////////////////////////////////////////////////

    /////////////////// STREAM POLICY MAKER ///////////////////////

    logic [AUX_DATA_WIDTH-1:0] SPM_Lane_BW;
    logic [7:0]                SPM_MSA [23:0]; // 24 bytes of MSA data
    logic [1:0]                SPM_Lane_Count, SPM_BW_Sel;
    logic                      SPM_ISO_start, SPM_MSA_VLD;

    /////////////////// MAIN STREAM SOURCE ///////////////////////

    logic [47:0] MS_Pixel_Data;
    logic [9:0]  MS_Stm_BW;
    logic        MS_DE, MS_VSYNC, MS_HSYNC;

    real CLOCK_PERIOD;

    ///////////////////////////////////////////////////////////////
    //////////////////////// MODPORTS /////////////////////////////
    ///////////////////////////////////////////////////////////////

    ////////////////////////// DUT ////////////////////////////////

    modport DUT (
          input clk_AUX, rst_n, clk_RBR, clk_HBR, clk_HBR2, clk_HBR3,
          // MSS - ISO
                MS_Pixel_Data,        // A 48-bit pixel data signal representing the pixel values for the transmitted frame.
                MS_Stm_CLK,           // This signal represents the clock signal for the stream rate.
                MS_DE,                // This signal indicates the active period of the stream when HIGH and the blanking period when LOW.
                MS_Stm_BW,            // This signal indicates the bandwidth of the stream source (e.g, 60 MHz, 80 MHz, etc.)
                MS_VSYNC,             // This signal is asserted to indicate the start of the vertical blanking period and is activated after the front porch phase at its beginning.
                MS_HSYNC,             // This signal is asserted to indicate the start of the horizontal blanking period and is activated after the front porch phase at its beginning.
          // SPM - ISO
                SPM_ISO_start,        // The signal marks the beginning of a new video transmission and is asserted by the Stream Policy Maker to indicate that the main video stream is valid and should be processed. When de-asserted, it signifies either the end of the video stream or an error that requires stopping stream data transmission.          
                SPM_Lane_Count,       // The signal represents the number of lanes that will be used for the stream transmission.  
                SPM_Lane_BW,          // The signal indicates the bandwidth of a single lane for stream transmission after link training. The 8-bit value is multiplied by 0.27 to determine the lane bandwidth (e.g., 1.62 Gbps, 2.7 Gbps).
                SPM_MSA,              // The signal defines the Main Stream Attributes (MSA), which includes Hactive, Hblank, Vactive, Vblank, Color Depth, and other video timing details.
                SPM_MSA_VLD,          // This signal represents the valid flag of the MSA Data, asserting when the MSA input is valid and ready for use.
                SPM_BW_Sel,           // It represents the selection line for the PLL-generated clock, corresponding to the different rates supported by 8b/10b DisplayPort devices. It selects the proper clock based on the lane bandwidth after link training.
          // SPM - AUX  
                SPM_Address,          // Address sent by SPM to indicate register to be written to or read from when initiating a transaction.
                SPM_Data,             // Data written by SPM when initiating a write transaction (byte-by-byte)
                SPM_LEN,              // Length of data, in bytes, sent by SPM to be written or read for request transaction
                SPM_CMD,              // The command field sent to specify the transaction type (Read or Write).
                SPM_Transaction_VLD,  // A valid signal activated by the SPM during a request transaction.
          // LPM - AUX
                LPM_Data,             // Data written by LPM when initiating a write transaction
                LPM_Address,          // Address sent by LPM to indicate register to be written to or read from when initiating a transaction
                LPM_LEN,              // Length of data, in bytes, send by LPM to be written or read for request transaction
                LPM_CMD,              // The command field sent to specify the transaction type (Read or Write).
                LPM_Transaction_VLD,  // A valid signal activated by the LPM during a request transaction.
          // LPM - Link Training
                LPM_Start_CR,         // the LPM starts link training by asserting this signal, which marks the beginning of the Clock Recovery phase.
                CR_DONE,              // Four bits indicating whether clock recovery has been completed for the four lanes (with the least significant bit representing Lane 0).
                Link_LC_CR,           // The maximum number of lanes that the sink can support, based on its capability, which are specified in the sink DPCD capability registers.
                Link_BW_CR,           // Maximum Bandwidth that the sink can support, based on its capability, which are specified in the sink DPCD capability registers.
                PRE,                  // The minimum pre-emphasis level, which is either retrieved from the sink DPCD capability registers at the beginning of the link training process or adjusted during the link training
                VTG,                  // The minimum voltage swing level, which is either retrieved from the sink DPCD capability registers at the beginning of the link training process or adjusted during the link training
                Driving_Param_VLD,    // Flag signal asserted by link policy maker indicating the arrival of voltage swing and pre-emphasis data.
                EQ_RD_Value,          // The time the source waits during the link training process before checking the status update registers, which are read from the Capability Register (0000Eh).
                EQ_CR_DN,             // During EQ Stage, Clock recovery done bits that read from register 202h-203h and sent to link layer via link policy maker through this signal, if all ones indicating the successful clock recovery from different lanes
                Channel_EQ,           // Channel Equalization bits read from register 202h-203h and sent to link layer via Link Policy Maker through this signal, if all ones indicating the successful channel equalization of different lanes
                Symbol_Lock,          // Same concept as the both signals EQ_CR_DN and Channel_EQ
                Lane_Align,           // The result of the Equalization phase during link training for the four lanes, found in the Status Update registers (00204h), indicating whether Lane Align achieved.
                EQ_Data_VLD,          // Valid signal indicating the arrival of these data from LPM
                MAX_VTG,              // Maximum voltage swing supported by the sink capability
                MAX_PRE,              // Maximum pre-emphasis supported by the sink capability
                MAX_TPS_SUPPORTED,    // Maximum TPS supported by the sink capability
                MAX_TPS_SUPPORTED_VLD,// Valid signal indicating the arrival of MAX_TPS_SUPPORTED data from LPM
                Config_Param_VLD,     // Valid signal indicating the arrival of configuration parameters from LPM, for MAX_PRE, MAX_VTG, Link_LC_CR and Link_BW_CR          
                CR_DONE_VLD,          // Valid signal indicating the arrival of CR_DONE data from LPM
          // SPM - AUX       
          output SPM_Reply_Data,          // I2C-over-AUX Reply Transaction (Data Part) for I2C-over-AUX Request Read Transaction, using I2C Transaction Method 1 (transfer 1 byte per transaction)
                 SPM_Reply_ACK,           // This signal represents the status of the reply transaction whether ACK, NACK or DEFER.
                 SPM_Reply_ACK_VLD,       // A valid signal indicating that the status of the reply transaction is ready.
                 SPM_Reply_Data_VLD,      // A valid signal indicating that the data is ready (set to one when receiving data from an I2C-over-AUX reply transaction).    
                 SPM_NATIVE_I2C,          // Signal representing the most significant bit in the command field to determine the type of transaction whether I2C or Native
                 CTRL_I2C_Failed,         // A signal indicating the failure of the I2C-over-AUX transaction, which is set to one when the I2C-over-AUX transaction fails.
          // LPM - AUX
                 HPD_Detect,              // The signal is activated when the HPD (Hot Plug Detection) signal remains asserted for a period exceeding 2ms, which indicates that a sink device has been successfully connected.
                 HPD_IRQ,                 // The signal is active when the HPD (Hot Plug Detection) signal is set to low for a duration of 0.5ms to 1ms before returning to high, indicating an interrupt request from the sink.
                 LPM_Reply_Data,          // Native Reply Transaction (Data Part) for a Native Request Read Transaction.
                 LPM_Reply_Data_VLD,      // A valid signal indicating that the data is ready (set to one when receiving data from a Native reply transaction).
                 LPM_Reply_ACK,           // Native Reply Transaction (Command Part) for a Native Request Transaction.
                 LPM_Reply_ACK_VLD,       // A valid signal indicating that the acknowledge data is ready (set to one when receiving reply acknowledge data from a Native reply transaction).
                 LPM_NATIVE_I2C,          // Signal representing the most significant bit in the command field to determine the type of transaction whether I2C or Native
                 CTRL_Native_Failed,      // A signal indicating the failure of the Native transaction, which is set to one when the Native transaction fails.
          // LPM - Link Training
                 FSM_CR_Failed,           // A Signal indicating the failure of the Clock Recovery phase during link training, meaning the sink failed to acquire the clock frequency during the training process
                 EQ_Failed,               // Signal indicating the failure of the Channel Equalization phase during link training.
                 EQ_LT_Pass,              // This signal represents a successful channel equalization phase which indicates successful link training process
                 EQ_Final_ADJ_BW,         // The adjusted link BW after successful link training used for sending main video stream.
                 EQ_Final_ADJ_LC,         // The adjusted number of lanes after successful link training, used for sending main video stream.
                 CR_Completed,            // Signal indicating the completion of the Clock Recovery phase during link training.   
                 EQ_FSM_CR_Failed,        // Signal indicating the failure of the Clock Recovery phase during EQ phase of link training.  
                 Timer_Timeout            // Signal indicating the timeout of the timer during link training process.
    );
    
      // RESET task
      // This task is used to reset the DUT by asserting and deasserting the reset signal
      task Reset();
            rst_n = 1'b0;                       // Assert reset
            SPM_Address = 20'b0;                // Reset SPM Address
            SPM_Data = 8'b0;                    // Reset SPM Data
            SPM_LEN = 8'b0;                     // Reset SPM Length
            SPM_CMD = 2'b0;                     // Reset SPM Command
            SPM_Transaction_VLD = 1'b0;         // Reset SPM Transaction Valid
            LPM_Data = 8'b0;                    // Reset LPM Data
            LPM_Address = 20'b0;                // Reset LPM Address
            LPM_LEN = 8'b0;                     // Reset LPM Length
            LPM_CMD = 2'b0;                     // Reset LPM Command
            LPM_Transaction_VLD = 1'b0;         // Reset LPM Transaction Valid
            LPM_Start_CR = 1'b0;                // Reset LPM Start Clock Recovery                
            CR_DONE = 4'b0;                     // Reset CR_DONE
            Link_LC_CR = 2'b0;                  // Reset Link Lane Count Clock Recovery
            Link_BW_CR = 8'b0;                  // Reset Link Bandwidth Clock Recovery
            PRE = 8'b0;                         // Reset PRE
            VTG = 8'b0;                         // Reset VTG
            Driving_Param_VLD = 1'b0;           // Reset Driving Parameter Valid
            EQ_RD_Value = 8'b0;                 // Reset EQ_RD_Value
            EQ_CR_DN = 4'b0;                    // Reset EQ_CR_DN
            Channel_EQ = 4'b0;                  // Reset Channel_EQ
            Symbol_Lock = 4'b0;                 // Reset Symbol_Lock
            Lane_Align = 4'b0;                  // Reset Lane_Align
            EQ_Data_VLD = 1'b0;                 // Reset EQ_Data Valid
            MAX_VTG = 8'b0;                     // Reset MAX_VTG
            MAX_PRE = 8'b0;                     // Reset MAX_PRE
            MAX_TPS_SUPPORTED = 2'b0;           // Reset MAX_TPS_SUPPORTED
            MAX_TPS_SUPPORTED_VLD = 1'b0;       // Reset MAX_TPS_SUPPORTED Valid
            Config_Param_VLD = 1'b0;            // Reset Config Parameter Valid
            CR_DONE_VLD = 1'b0;                 // Reset CR_DONE Valid        

            @(negedge clk_AUX);         // Wait for clock edge
            rst_n = 1'b1;           // Deassert reset
      endtask

      // I2C_READ task
      task I2C_READ(input logic[19:0] address, input logic[7:0] length, input logic [1:0] command, input bit transaction_vld);
            // Set SPM-related signals to perform a read operation
            wait(HPD_Detect == 1'b1); // Wait for HPD detection
            @(negedge clk_AUX);
            SPM_Address = address;
            SPM_CMD     = command;
            SPM_LEN     = length;
            SPM_Transaction_VLD = transaction_vld;
            LPM_Transaction_VLD = 1'b0; // Set LPM transaction valid to 0
            // SPM_Data = SPM.SPM_Data;                                 // Data is not used in read operation
      endtask
    
      // I2C_WRITE task
      task I2C_WRITE(input logic[19:0] address, input logic[7:0] length, input logic [1:0] command, input bit transaction_vld, input logic[7:0] data);
            // Set SPM-related signals to perform a write operation
            wait(HPD_Detect == 1'b1); // Wait for HPD detection
            SPM_Address = address;
            SPM_CMD     = command;
            SPM_LEN     = length;
            SPM_Transaction_VLD = transaction_vld;
            LPM_Transaction_VLD = 1'b0; // Set LPM transaction valid to 0
            SPM_Data = data;
      endtask

      // // NATIVE_READ task
      task NATIVE_READ(input logic[19:0] address, input logic[7:0] length, input logic [1:0] command, input bit transaction_vld);
            // Set LPM-related signals to perform a read operation
            wait(HPD_Detect == 1'b1); // Wait for HPD detection
            @(negedge clk_AUX);
            LPM_Address = address;
            LPM_CMD     = command;
            LPM_LEN     = length;
            LPM_Transaction_VLD = transaction_vld;
            SPM_Transaction_VLD = 1'b0; // Set SPM transaction valid to 0
            // LPM_Data = LPM.LPM_Data; // Data is not used in read operation
            //@(negedge clk_AUX); // Wait for clock edge
            //LPM_Transaction_VLD = 1'b0; // Set the reply data valid signal to indicate that the data is ready

      endtask

      // NATIVE_WRITE task
      task NATIVE_WRITE(input logic[19:0] address, input logic[7:0] length, input logic [1:0] command, input bit transaction_vld, input logic[7:0] data);
            // Set LPM-related signals to perform a write operation
            wait(HPD_Detect == 1'b1); // Wait for HPD detection
            LPM_Address = address;
            LPM_CMD     = command;
            LPM_LEN     = length;
            LPM_Transaction_VLD = transaction_vld;
            SPM_Transaction_VLD = 1'b0; // Set SPM transaction valid to 0
            LPM_Data = data;
      endtask

      task Transaction_wait(input bit lpm_transaction_vld, input bit spm_transaction_vld);
            LPM_Transaction_VLD = lpm_transaction_vld;
            SPM_Transaction_VLD = spm_transaction_vld;
      endtask

      // //////////////////////////// LINK TRAINING ////////////////////////////

      // Clock Recovery Link Training task
      // This task is used to set the parameters for the Clock Recovery Link Training phase
      task LT_CT (input bit config_vld, driving_vld, start_cr, done_vld, logic [AUX_DATA_WIDTH-1:0] pre, vtg, link_bw_cr, eq_rd_value, [3:0] cr_done, [1:0] link_lc_cr, max_vtg, max_pre, output logic hpd_detect, hpd_irq, reply_data_vld, lpm_vld, native_failed, fsm_cr_failed, eq_failed, eq_lt_pass, cr_completed, eq_fsm_cr_failed, timer_timeout, reply_ack_vld, [1:0] reply_ack, eq_final_adj_lc, [AUX_DATA_WIDTH-1:0] reply_data, eq_final_adj_bw);
            // Set LPM-related signals for Clock Recovery Link Training
            // wait(HPD_Detect == 1'b1); // Wait for HPD detection
            // @(negedge clk_AUX)
            LPM_Transaction_VLD = 1'b0;
            SPM_Transaction_VLD = 1'b0;
            LPM_Start_CR = start_cr;
            CR_DONE_VLD  = done_vld;
            CR_DONE      = cr_done;
            Link_LC_CR   = link_lc_cr;
            Link_BW_CR   = link_bw_cr;
            PRE          = pre;
            VTG          = vtg;
            MAX_VTG      = max_vtg;
            MAX_PRE      = max_pre;
            Driving_Param_VLD = driving_vld;
            Config_Param_VLD = config_vld;
            EQ_RD_Value  = eq_rd_value;

            hpd_detect = HPD_Detect;
            hpd_irq = HPD_IRQ;
            reply_data = LPM_Reply_Data;
            reply_data_vld = LPM_Reply_Data_VLD;
            reply_ack = LPM_Reply_ACK;
            reply_ack_vld = LPM_Reply_ACK_VLD;
            lpm_vld = LPM_NATIVE_I2C;
            native_failed = CTRL_Native_Failed; 

            fsm_cr_failed = FSM_CR_Failed;
            eq_failed = EQ_Failed;
            eq_lt_pass = EQ_LT_Pass;
            eq_final_adj_bw = EQ_Final_ADJ_BW;
            eq_final_adj_lc = EQ_Final_ADJ_LC;
            cr_completed = CR_Completed;
            eq_fsm_cr_failed = EQ_FSM_CR_Failed;
            timer_timeout = Timer_Timeout;
      endtask

      // Channel Equalization Link Training task
      // This task is used to set the parameters for the Channel Equalization Link Training phase
      task LT_EQ (input bit driving_vld, done_vld, eq_data_vld, max_tps_supported_vld, logic [AUX_DATA_WIDTH-1:0] pre, vtg, lane_align, [3:0] cr_done, eq_cr_dn, channel_eq, symbol_lock, training_pattern_t max_tps_supported, output logic hpd_detect, hpd_irq, reply_data_vld, lpm_vld, native_failed, fsm_cr_failed, eq_failed, eq_lt_pass, cr_completed, eq_fsm_cr_failed, timer_timeout, reply_ack_vld, [1:0] reply_ack, eq_final_adj_lc, [AUX_DATA_WIDTH-1:0] reply_data, eq_final_adj_bw);
            // @(negedge clk_AUX)
            LPM_Transaction_VLD = 1'b0;
            SPM_Transaction_VLD = 1'b0;
            CR_DONE_VLD  = done_vld;
            CR_DONE      = cr_done;
            PRE          = pre;
            VTG          = vtg;
            Driving_Param_VLD = driving_vld;
            Config_Param_VLD = 1'b0;

            EQ_CR_DN     = eq_cr_dn;
            Channel_EQ   = channel_eq;
            Symbol_Lock  = symbol_lock;
            Lane_Align   = lane_align;
            EQ_Data_VLD  = eq_data_vld;

            MAX_TPS_SUPPORTED = max_tps_supported;
            MAX_TPS_SUPPORTED_VLD = logic'(max_tps_supported_vld);

            hpd_detect = HPD_Detect;
            hpd_irq = HPD_IRQ;
            reply_data = LPM_Reply_Data;
            reply_data_vld = LPM_Reply_Data_VLD;
            reply_ack = LPM_Reply_ACK;
            reply_ack_vld = LPM_Reply_ACK_VLD;
            lpm_vld = LPM_NATIVE_I2C;
            native_failed = CTRL_Native_Failed; 

            fsm_cr_failed = FSM_CR_Failed;
            eq_failed = EQ_Failed;
            eq_lt_pass = EQ_LT_Pass;
            eq_final_adj_bw = EQ_Final_ADJ_BW;
            eq_final_adj_lc = EQ_Final_ADJ_LC;
            cr_completed = CR_Completed;
            eq_fsm_cr_failed = EQ_FSM_CR_Failed;
            timer_timeout = Timer_Timeout;
      endtask

      task ISO(input real clk_stream, bit iso_start, msa_vld, de, vsync, hsync, [AUX_DATA_WIDTH-1:0] adj_bw, [1:0] adj_lc, bw_sel, [47:0] pixels, [9:0] stm_bw, [7:0] msa [23:0], output logic hpd_detect, hpd_irq);
            // Set SPM-related signals for Isochronous Transport Layer
            SPM_Lane_BW = adj_bw;
            SPM_Lane_Count = adj_lc;
            SPM_BW_Sel = bw_sel;
            SPM_ISO_start = iso_start;
            SPM_MSA_VLD = msa_vld; // Set MSA valid signal to indicate that the MSA data is ready
            SPM_MSA = msa ; // Set MSA data to indicate the attributes of the main stream
            MS_Pixel_Data = pixels; // Set pixel data to indicate the pixel values for the transmitted frame
            MS_Stm_BW = stm_bw; // Set stream bandwidth to indicate the bandwidth of the stream source
            MS_DE = de; // Set DE signal to indicate the active period of the stream
            MS_VSYNC = vsync; // Set Vsync signal to indicate the start of the vertical blanking period
            MS_HSYNC = hsync; // Set Hsync signal to indicate the start of the horizontal blanking period
            CLOCK_PERIOD = clk_stream;

            hpd_detect = HPD_Detect;
            hpd_irq = HPD_IRQ;
      endtask

      task DETECT(output logic hpd_detect);
            hpd_detect = HPD_Detect;
      endtask
      
endinterface
