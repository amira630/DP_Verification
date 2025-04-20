interface dp_tl_if(input clk);

    logic rst_n;   // Reset is asynchronous active low
    logic ready;   // Ready signal indicating that the DUT will respond to the transaction

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
    logic                         LPM_Reply_ACK_VLD, LPM_Reply_Data_VLD, LPM_NATIVE_I2C, LPM_Transaction_VLD;
    logic                         HPD_Detect, HPD_IRQ, CTRL_Native_Failed;

    ////////////////// LINK Training Signals //////////////////////
    
    logic [AUX_DATA_WIDTH-1:0] Link_BW_CR, PRE, VTG, EQ_RD_Value, Lane_Align, EQ_Final_ADJ_BW;
    logic [3:0] CR_DONE, EQ_CR_DN, Channel_EQ, Symbol_Lock;
    logic [1:0] Link_LC_CR, EQ_Final_ADJ_LC, MAX_TPS_SUPPORTED, MAX_VTG, MAX_PRE;
    logic       LPM_Start_CR, Driving_Param_VLD, EQ_Data_VLD, FSM_CR_Failed, EQ_FSM_CR_Failed, EQ_Failed, EQ_LT_Pass, Config_Param_VLD, CR_DONE_VLD;
    logic       LPM_Start_CR_VLD, CR_Completed, MAX_TPS_SUPPORTED_VLD, Timer_Timeout;

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
    logic        MS_Stm_CLK, MS_DE, MS_VSYNC, MS_HSYNC;

    ///////////////////////////////////////////////////////////////
    //////////////////////// MODPORTS /////////////////////////////
    ///////////////////////////////////////////////////////////////

    ////////////////////////// DUT ////////////////////////////////

    modport DUT (
          input clk, rst_n,
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
                 LPM_Native_I2C,          // Signal representing the most significant bit in the command field to determine the type of transaction whether I2C or Native
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

    //////////////////////// DRIVER /////////////////////////////

    modport DRV (
        // SPM - AUX
        output rst_n, SPM_Address, SPM_Data, SPM_LEN, SPM_CMD, SPM_Transaction_VLD, 
        // LPM - AUX      
               LPM_Data, LPM_Address, LPM_LEN, LPM_CMD, LPM_Transaction_VLD, 
        // LPM - Link Training      
               LPM_Start_CR, CR_DONE, Link_LC_CR, Link_BW_CR, PRE, VTG, Driving_Param_VLD, 
               EQ_RD_Value, EQ_CR_DN, Channel_EQ, Symbol_Lock, Lane_Align, EQ_Data_VLD, MAX_VTG,
               MAX_PRE, MAX_TPS_SUPPORTED, MAX_TPS_SUPPORTED_VLD, Config_Param_VLD, CR_DONE_VLD,
        // MSS - ISO
               MS_Pixel_Data, MS_Stm_CLK, MS_DE, MS_Stm_BW, MS_VSYNC, MS_HSYNC,
        // SPM - ISO
               SPM_ISO_start, SPM_Lane_Count, SPM_Lane_BW, SPM_MSA, SPM_MSA_VLD, SPM_BW_Sel,        
        // SPM - AUX       
        input clk, SPM_Reply_Data, SPM_Reply_ACK, SPM_Reply_ACK_VLD, SPM_Reply_Data_VLD, SPM_NATIVE_I2C, CTRL_I2C_Failed,         
        // LPM - AUX
              HPD_Detect, HPD_IRQ, LPM_Reply_Data, LPM_Reply_Data_VLD, LPM_Reply_ACK, LPM_Reply_ACK_VLD, LPM_Native_I2C, CTRL_Native_Failed,         
        // LPM - Link Training
              FSM_CR_Failed, EQ_Failed, EQ_LT_Pass, EQ_Final_ADJ_BW, EQ_Final_ADJ_LC, CR_Completed, EQ_FSM_CR_Failed, Timer_Timeout
    );

      //////////////////////// MONITOR /////////////////////////////

    modport MONITOR (
        input clk, rst_n,
        // SPM - AUX
              SPM_Address, SPM_Data, SPM_LEN, SPM_CMD, SPM_Transaction_VLD, 
        // LPM - AUX      
              LPM_Data, LPM_Address, LPM_LEN, LPM_CMD, LPM_Transaction_VLD, 
        // LPM - Link Training      
              LPM_Start_CR, CR_DONE, Link_LC_CR, Link_BW_CR, PRE, VTG, Driving_Param_VLD, 
              EQ_RD_Value, EQ_CR_DN, Channel_EQ, Symbol_Lock, Lane_Align, EQ_Data_VLD, MAX_VTG,
              MAX_PRE, MAX_TPS_SUPPORTED, MAX_TPS_SUPPORTED_VLD, Config_Param_VLD, CR_DONE_VLD,
        // SPM - AUX      
              SPM_Reply_Data, SPM_Reply_ACK, SPM_Reply_ACK_VLD, SPM_Reply_Data_VLD, SPM_NATIVE_I2C, CTRL_I2C_Failed,         
        // LPM - AUX
              HPD_Detect, HPD_IRQ, LPM_Reply_Data, LPM_Reply_Data_VLD, LPM_Reply_ACK, LPM_Reply_ACK_VLD, LPM_Native_I2C, CTRL_Native_Failed,        
        // LPM - Link Training
              FSM_CR_Failed, EQ_Failed, EQ_LT_Pass, EQ_Final_ADJ_BW, EQ_Final_ADJ_LC, CR_Completed , EQ_FSM_CR_Failed, Timer_Timeout,
        // MSS - ISO
              MS_Pixel_Data, MS_Stm_CLK, MS_DE, MS_Stm_BW, MS_VSYNC, MS_HSYNC,
        // SPM - ISO
              SPM_ISO_start, SPM_Lane_Count, SPM_Lane_BW, SPM_MSA, SPM_MSA_VLD, SPM_BW_Sel      
    );

      // RESET task
      // This task is used to reset the DUT by asserting and deasserting the reset signal
      task Reset();
            rst_n = 1'b0;           // Assert reset
            @(negedge clk);         // Wait for clock edge
            rst_n = 1'b1;           // Deassert reset
      endtask

      // I2C_READ task
      task I2C_READ(input dp_tl_sequence_item SPM);
            // Set SPM-related signals to perform a read operation
            SPM_Address = SPM.SPM_Address;
            SPM_CMD     = SPM.SPM_CMD;
            SPM_LEN     = SPM.SPM_LEN;
            SPM_Transaction_VLD = SPM.SPM_Transaction_VLD;
            // SPM_Data = SPM.SPM_Data;                                 // Data is not used in read operation

            wait(SPM_Reply_Data_VLD == 1 || SPM_Reply_ACK_VLD == 1);    // Wait for the reply data to be valid
            ready = 1;                                                  // Set ready signal to indicate that the DUT is ready to respond
      endtask

      // I2C_WRITE task
      task I2C_WRITE(input dp_tl_sequence_item SPM);
            // Set SPM-related signals to perform a write operation
            SPM_Address = SPM.SPM_Address;
            SPM_CMD     = SPM.SPM_CMD;
            SPM_LEN     = SPM.SPM_LEN;
            SPM_Transaction_VLD = SPM.SPM_Transaction_VLD;
            SPM_Data = SPM.SPM_Data;

            wait(SPM_Reply_Data_VLD == 1 || SPM_Reply_ACK_VLD == 1);    // Wait for the reply data to be valid
            ready = 1;                                                  // Set ready signal to indicate that the DUT is ready to respond
      endtask

      // NATIVE_READ task
      task NATIVE_READ(input dp_tl_sequence_item LPM);
            // Set LPM-related signals to perform a read operation
            LPM_Address = LPM.LPM_Address;
            LPM_CMD     = LPM.LPM_CMD;
            LPM_LEN     = LPM.LPM_LEN;
            LPM_Transaction_VLD = LPM.LPM_Transaction_VLD;
            // LPM_Data = LPM.LPM_Data; // Data is not used in read operation

            wait(LPM_Reply_Data_VLD == 1 || LPM_Reply_ACK_VLD == 1);    // Wait for the reply data to be valid
            ready = 1;                                                  // Set ready signal to indicate that the DUT is ready to respond
      endtask

      // NATIVE_WRITE task
      task NATIVE_WRITE(input dp_tl_sequence_item LPM);
            // Set LPM-related signals to perform a write operation
            LPM_Address = LPM.LPM_Address;
            LPM_CMD     = LPM.LPM_CMD;
            LPM_LEN     = LPM.LPM_LEN;
            LPM_Transaction_VLD = LPM.LPM_Transaction_VLD;
            LPM_Data = LPM.LPM_Data;

            wait(LPM_Reply_Data_VLD == 1 || LPM_Reply_ACK_VLD == 1);    // Wait for the reply data to be valid
            ready = 1;                                                  // Set ready signal to indicate that the DUT is ready to respond
      endtask

      //////////////////////////// LINK TRAINING ////////////////////////////

      task LINK_TRAINING (input dp_tl_sequence_item LPM);
            // Set LPM-related signals for Clock Recovery Link Training
            LPM_Transaction_VLD = LPM.LPM_Transaction_VLD;
            LPM_Start_CR = LPM.LPM_Start_CR;
            CR_DONE_VLD  = LPM.CR_DONE_VLD;
            CR_DONE      = LPM.CR_DONE;
            Link_LC_CR   = LPM.Link_LC_CR;
            Link_BW_CR   = LPM.Link_BW_CR;
            PRE          = LPM.PRE;
            VTG          = LPM.VTG;
            Driving_Param_VLD = LPM.Driving_Param_VLD;
            Config_Param_VLD = LPM.Config_Param_VLD;
            EQ_RD_Value  = LPM.EQ_RD_Value;
            EQ_CR_DN     = LPM.EQ_CR_DN;
            Channel_EQ   = LPM.Channel_EQ;
            Symbol_Lock  = LPM.Symbol_Lock;
            Lane_Align   = LPM.Lane_Align;
            EQ_Data_VLD  = LPM.EQ_Data_VLD;
            MAX_VTG      = LPM.MAX_VTG;
            MAX_PRE      = LPM.MAX_PRE;
            MAX_TPS_SUPPORTED = LPM.MAX_TPS_SUPPORTED;
            MAX_TPS_SUPPORTED_VLD      = LPM.MAX_TPS_SUPPORTED_VLD;

            wait(LPM_Reply_Data_VLD == 1 || LPM_Reply_ACK_VLD == 1);    // Wait for the link training to complete
            ready = 1;                                             // Set ready signal to indicate that the DUT is ready to respond
      endtask

endinterface
