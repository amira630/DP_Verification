interface dp_sink_if(input clk);

    ///////////////////////////////////////////////////////////////
    ///////////////////// PHYSICAL LAYER //////////////////////////
    ///////////////////////////////////////////////////////////////

    logic [AUX_DATA_WIDTH-1:0] AUX_IN_OUT, CR_ADJ_BW, EQ_ADJ_BW;
    logic [1:0] CR_PHY_Instruct, CR_ADJ_LC, EQ_PHY_Instruct, EQ_ADJ_LC;
    logic       START_STOP, HPD_Signal;

    ///////////////////////////////////////////////////////////////
    //////////////////////// MODPORTS /////////////////////////////
    ///////////////////////////////////////////////////////////////

    ////////////////////////// DUT ////////////////////////////////

    modport DUT (
        input clk, 
              HPD_Signal,           // The HPD signal indicates the connection status based on its duration
        inout AUX_IN_OUT,           // A request/reply transaction where each byte is transmitted or received during every individual clock cycle, byte-by-byte data exchange.
              START_STOP,           // A single bit indicating the beginning and end of a transaction. It is set to one during the transmission or reception of the transaction and set to zero when no transaction is occurring.
        output CR_PHY_Instruct,     // A signal which instructs the physical layer to begin sending a specific link training pattern (TPS1, 2, 3, 4) during the link training process.
               CR_ADJ_BW,           // The value of the BW during the link training.
               CR_ADJ_LC,           // The value of the Lane Count during the link training.
               EQ_PHY_Instruct,     // Same description of the above 3 signals but
               EQ_ADJ_BW,           // they are sent during EQ stage in the
               EQ_ADJ_LC            // channel equalization phase
    );

    //////////////////////// DRIVER /////////////////////////////
    
    modport DRV (
        input clk, CR_PHY_Instruct, CR_ADJ_BW, CR_ADJ_LC, EQ_PHY_Instruct, EQ_ADJ_BW, EQ_ADJ_LC,
        inout AUX_IN_OUT, START_STOP,
        output HPD_Signal
              
    );

    //////////////////////// MONITOR /////////////////////////////  
    
    modport MONITOR (
        input clk, HPD_Signal, AUX_IN_OUT, START_STOP, 
              CR_PHY_Instruct, CR_ADJ_BW, CR_ADJ_LC, 
              EQ_PHY_Instruct, EQ_ADJ_BW, EQ_ADJ_LC          
    );  
endinterface
