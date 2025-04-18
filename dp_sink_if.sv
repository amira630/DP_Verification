interface dp_sink_if(input clk);

    logic rst_n;
    ///////////////////////////////////////////////////////////////
    ///////////////////// PHYSICAL LAYER //////////////////////////
    ///////////////////////////////////////////////////////////////

    logic [7:0] AUX_IN_OUT, PHY_ADJ_BW;
    logic [1:0] PHY_ADJ_LC, PHY_Instruct;
    logic       HPD_Signal, AUX_START_STOP, PHY_START_STOP, PHY_Instruct_VLD;

    ///////////////////////////////////////////////////////////////
    //////////////////////// MODPORTS /////////////////////////////
    ///////////////////////////////////////////////////////////////

    ////////////////////////// DUT ////////////////////////////////

    modport DUT (
        input clk,
        input PHY_START_STOP,       // The PHY_START_STOP signal indicates the start/stop of the PHY layer operation.
              HPD_Signal,           // The HPD signal indicates the connection status based on its duration
        inout AUX_IN_OUT,           // A request/reply transaction where each byte is transmitted or received during every individual clock cycle, byte-by-byte data exchange.
        output AUX_START_STOP,
               PHY_Instruct,        // A signal which instructs the physical layer to begin sending a specific link training pattern (TPS1, 2, 3, 4) during the link training process.
               PHY_ADJ_BW,          // The value of the BW during the link training.
               PHY_ADJ_LC,          // The value of the Lane Count during the link training.
               PHY_Instruct_VLD     // The PHY_Instruct_VLD signal indicates the validity of the PHY_Instruct signal.
    );

    //////////////////////// DRIVER /////////////////////////////
    
    modport DRV (
        input clk, AUX_START_STOP, PHY_Instruct, PHY_ADJ_BW, PHY_ADJ_LC, PHY_Instruct_VLD,
        inout AUX_IN_OUT,           // start_stop will be changed
        output HPD_Signal , PHY_START_STOP       
    );

    //////////////////////// MOINTOR /////////////////////////////  
    
    modport MONITOR (
        input clk, HPD_Signal, AUX_IN_OUT, AUX_START_STOP, PHY_START_STOP,
              PHY_Instruct, PHY_ADJ_BW, PHY_ADJ_LC, PHY_Instruct_VLD
    );  


    ///////////////////////////////////////////////////////////////
    /////////////////////// TASKS AND FUNCTIONS ///////////////////
    ///////////////////////////////////////////////////////////////
    
    // RESET task
    // This task is used to reset the DUT by asserting and deasserting the reset signal
    task Reset();
        rst_n = 1'b0;           // Assert reset
        @(negedge clk);         // Wait for clock edge
        rst_n = 1'b1;           // Deassert reset
    endtask

    // TASK: drive_hpd_signal
    // This task is used to drive the HPD_Signal with a specific value
    // It takes a 1-bit value as input and drives the HPD_Signal with that value
    task drive_hpd_signal(input bit hpd);
        HPD_Signal = hpd;  // Drive the HPD_Signal with the specified value
        `uvm_info("DP_SINK_INTERFACE", $sformatf("Driving HPD_Signal = %0b", seq_item.HPD_Signal), UVM_MEDIUM);
    endtask

    // TASK: drive_aux_in_out
    // This task is used to drive the AUX_IN_OUT signal with a specific value
    // It takes a 8-bit value as input and drives the AUX_IN_OUT signal with that value
    task drive_aux_in_out(input [7:0] value);
        AUX_IN_OUT = value;  // Drive the AUX_IN_OUT signal with the specified value
        PHY_START_STOP = 1'b1;  // Start the PHY operation
        `uvm_info("DP_SINK_DRIVER", "Finished driving AUX_IN_OUT", UVM_MEDIUM);
        @(posedge clk);  // Wait for the next clock edge
        PHY_START_STOP = 1'b0;  // Stop the PHY operation
    endtask

endinterface
