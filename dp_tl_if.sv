interface dp_tl_if(input clk);
    
    bit reset_n;   // Reset is asynchronous active low
    
    ///////////////////////////////////////////////////////////////
    /////////////////// STREAM POLICY MAKER ///////////////////////
    ///////////////////////////////////////////////////////////////

    logic [19:0] SPM_Address;
    logic [7:0]  SPM_Data, SPM_LEN, SPM_Reply_Data;
    logic [1:0]  SPM_CMD, SPM_Reply_ACK;
    bit          SPM_Reply_ACK_VLD, SPM_Reply_Data_VLD, SPM_NATIVE_I2C, SPM_Transaction_VLD;

    ///////////////////////////////////////////////////////////////
    //////////////////// LINK POLICY MAKER ////////////////////////
    ///////////////////////////////////////////////////////////////
    
    logic [19:0] LPM_Address;
    logic [7:0]  LPM_Data, LPM_LEN, LPM_Reply_Data;
    logic [1:0]  LPM_CMD, LPM_Reply_ACK;
    bit          LPM_Reply_ACK_VLD, LPM_Reply_Data_VLD, LPM_NATIVE_I2C,LPM_Transaction_VLD;
    bit          HPD_Detect, HPD_IRQ;
    ////////////////// LINK Training Signals //////////////////////
    logic [7:0] Link_LC_CR, Link_BW_CR, PRE, VTG, EQ_RD_Value, Lane_Align, MAX_VTG, EQ_Final_ADJ_BW;
    logic [3:0] CR_Done, EQ_CR_DN, Channel_EQ, Symbol_Lock;
    logic [1:0] EQ_Final_ADJ_LC;
    bit         LPM_Start_CR, Driving_Param_VLD, EQ_Data_VLD, FSM_CR_Failed, EQ_Failed, EQ_LT_Pass;

    ///////////////////////////////////////////////////////////////
    //////////////////////// MODPORTS /////////////////////////////
    ///////////////////////////////////////////////////////////////

    ////////////////////////// DUT ////////////////////////////////

    modport DUT (
        input clk, reset_n, 
        // SPM
        input SPM_Address,          // Address sent by SPM to indicate register to be written to or read from when initiating a transaction.
              SPM_Data,             // Data written by SPM when initiating a write transaction (byte-by-byte)
              SPM_LEN,              // Length of data, in bytes, sent by SPM to be written or read for request transaction
              SPM_CMD,              // The command field sent to specify the transaction type (Read or Write).
              SPM_Transaction_VLD,  // A valid signal activated by the SPM during a request transaction.
        // LPM
              LPM_Data,             // Data written by LPM when initiating a write transaction
              LPM_Address,          // Address sent by LPM to indicate register to be written to or read from when initiating a transaction
              LPM_LEN,              // Length of data, in bytes, send by LPM to be written or read for request transaction
              LPM_CMD,              // The command field sent to specify the transaction type (I2C-over-AUX or Native) and operation (Read or Write).
              LPM_Transaction_VLD,  // A valid signal activated by the LPM during a request transaction.
        // LPM - Link Training
              LPM_Start_CR,         // the LPM starts link training by asserting this signal, which marks the beginning of the Clock Recovery phase.
              CR_Done,              // Four bits indicating whether clock recovery has been completed for the four lanes (with the least significant bit representing Lane 0).
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
        // SPM       
        output SPM_Reply_Data,          // I2C-over-AUX Reply Transaction (Data Part) for I2C-over-AUX Request Read Transaction, using I2C Transaction Method 1 (transfer 1 byte per transaction)
               SPM_Reply_ACK,           // This signal represents the status of the reply transaction whether ACK, NACK or DEFER.
               SPM_Reply_ACK_VLD,       // A valid signal indicating that the status of the reply transaction is ready.
               SPM_Reply_Data_VLD,      // A valid signal indicating that the data is ready (set to one when receiving data from an I2C-over-AUX reply transaction).    
               SPM_NATIVE_I2C,          // Signal representing the most significant bit in the command field to determine the type of transaction whether I2C or Native
        // LPM
               HPD_Detect,              // The signal is activated when the HPD (Hot Plug Detection) signal remains asserted for a period exceeding 2ms, which indicates that a sink device has been successfully connected.
               HPD_IRQ,                 // The signal is active when the HPD (Hot Plug Detection) signal is set to low for a duration of 0.5ms to 1ms before returning to high, indicating an interrupt request from the sink.
               LPM_Reply_Data,          // Native Reply Transaction (Data Part) for a Native Request Read Transaction.
               LPM_Reply_Data_VLD,      // A valid signal indicating that the data is ready (set to one when receiving data from a Native reply transaction).
               LPM_Reply_ACK,           // Native Reply Transaction (Command Part) for a Native Request Transaction.
               LPM_Reply_ACK_VLD,       // A valid signal indicating that the acknowledge data is ready (set to one when receiving reply acknowledge data from a Native reply transaction).
               LPM_Native_I2C,          // Signal representing the most significant bit in the command field to determine the type of transaction whether I2C or Native
        // LPM - Link Training
               FSM_CR_Failed,           // A Signal indicating the failure of the Clock Recovery phase during link training, meaning the sink failed to acquire the clock frequency during the training process
               EQ_Failed,               // Signal indicating the failure of the Channel Equalization phase during link training.
               EQ_LT_Pass,              // This signal represents a successful channel equalization phase which indicates successful link training process
               EQ_Final_ADJ_BW,         // The adjusted link BW after successful link training used for sending main video stream.
               EQ_Final_ADJ_LC          // The adjusted number of lanes after successful link training, used for sending main video stream.
    );

    //////////////////////// DRIVER /////////////////////////////

    modport DRV (
        input clk, 
        // SPM
        output reset_n, SPM_Address, SPM_Data, SPM_LEN, SPM_CMD, SPM_Transaction_VLD, 
        // LPM      
              LPM_Data, LPM_Address, LPM_LEN, LPM_CMD, LPM_Transaction_VLD, 
        // LPM - Link Training      
              LPM_Start_CR, CR_Done, Link_LC_CR, Link_BW_CR, PRE, VTG, Driving_Param_VLD, 
              EQ_RD_Value, EQ_CR_DN, Channel_EQ, Symbol_Lock, Lane_Align, EQ_Data_VLD, MAX_VTG,
        // SPM       
        input SPM_Reply_Data, SPM_Reply_ACK, SPM_Reply_ACK_VLD, SPM_Reply_Data_VLD, SPM_NATIVE_I2C,         
        // LPM
              HPD_Detect, HPD_IRQ, LPM_Reply_Data, LPM_Reply_Data_VLD, LPM_Reply_ACK, LPM_Reply_ACK_VLD, LPM_Native_I2C,         
        // LPM - Link Training
              FSM_CR_Failed, EQ_Failed, EQ_LT_Pass, EQ_Final_ADJ_BW, EQ_Final_ADJ_LC 
    );

    //////////////////////// MOINTOR /////////////////////////////
    
    modport MONITOR (
        input clk, reset_n,
        // SPM
              SPM_Address, SPM_Data, SPM_LEN, SPM_CMD, SPM_Transaction_VLD, 
        // LPM      
              LPM_Data, LPM_Address, LPM_LEN, LPM_CMD, LPM_Transaction_VLD, 
        // LPM - Link Training      
              LPM_Start_CR, CR_Done, Link_LC_CR, Link_BW_CR, PRE, VTG, Driving_Param_VLD, 
              EQ_RD_Value, EQ_CR_DN, Channel_EQ, Symbol_Lock, Lane_Align, EQ_Data_VLD, MAX_VTG,
        // SPM       
              SPM_Reply_Data, SPM_Reply_ACK, SPM_Reply_ACK_VLD, SPM_Reply_Data_VLD, SPM_NATIVE_I2C,         
        // LPM
              HPD_Detect, HPD_IRQ, LPM_Reply_Data, LPM_Reply_Data_VLD, LPM_Reply_ACK, LPM_Reply_ACK_VLD, LPM_Native_I2C,         
        // LPM - Link Training
              FSM_CR_Failed, EQ_Failed, EQ_LT_Pass, EQ_Final_ADJ_BW, EQ_Final_ADJ_LC 
    );
    
endinterface
