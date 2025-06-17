`timescale 1ns / 1ps
import uvm_pkg::*;
    `include "uvm_macros.svh"

interface dp_sink_if #(parameter AUX_ADDRESS_WIDTH = 20, AUX_DATA_WIDTH = 8) (input clk_AUX, clk_RBR, clk_HBR, clk_HBR2, clk_HBR3);


    ///////////////////////////////////////////////////////////////
    //////////////////// AUXILIARY CHANNEL ////////////////////////
    ///////////////////////////////////////////////////////////////

    ///////////////////// PHYSICAL LAYER //////////////////////////

    logic [AUX_DATA_WIDTH-1:0]  aux_data, PHY_ADJ_BW;
    logic [1:0]                 PHY_ADJ_LC, PHY_Instruct;
    logic                       HPD_Signal, AUX_START_STOP, PHY_START_STOP, PHY_Instruct_VLD;

    ///////////////////////////////////////////////////////////////
    ////////////////// ISOCHRONOUS TRANSPORT //////////////////////
    ///////////////////////////////////////////////////////////////

    ///////////////////// PHYSICAL LAYER //////////////////////////

    logic [AUX_DATA_WIDTH-1:0] ISO_symbols_lane0, ISO_symbols_lane1, ISO_symbols_lane2, ISO_symbols_lane3;
    logic                      Control_sym_flag_lane0, Control_sym_flag_lane1, Control_sym_flag_lane2, Control_sym_flag_lane3;

    wire [AUX_DATA_WIDTH-1:0] AUX_IN_OUT; // The AUX_IN_OUT signal is a bidirectional signal used for the DisplayPort auxiliary channel communication. It carries the data between the source and sink devices.


    assign AUX_IN_OUT = PHY_START_STOP ? aux_data : 8'bz; // The AUX_IN_OUT signal is driven by the PHY_START_STOP signal. When PHY_START_STOP is high, the aux_data is driven onto the AUX_IN_OUT line. Otherwise, it is in high impedance state (8'bz).

    // aux_in_out_tb = phy_start_stop_tb ? aux_in_value : 8'bz;
    logic [AUX_DATA_WIDTH-1:0] Final_BW; // to know which clock to use

    ///////////////////////////////////////////////////////////////
    //////////////////////// MODPORTS /////////////////////////////
    ///////////////////////////////////////////////////////////////

    ////////////////////////// DUT ////////////////////////////////

    modport DUT (
        input clk_AUX,
        input PHY_START_STOP,       // The PHY_START_STOP signal indicates the start/stop of the PHY layer operation.
              HPD_Signal,           // The HPD signal indicates the connection status based on its duration
        inout AUX_IN_OUT,           // A request/reply transaction where each byte is transmitted or received during every individual clock cycle, byte-by-byte data exchange.
        output AUX_START_STOP,
               PHY_Instruct,        // A signal which instructs the physical layer to begin sending a specific link training pattern (TPS1, 2, 3, 4) during the link training process.
               PHY_ADJ_BW,          // The value of the BW during the link training.
               PHY_ADJ_LC,          // The value of the Lane Count during the link training.
               PHY_Instruct_VLD,     // The PHY_Instruct_VLD signal indicates the validity of the PHY_Instruct signal.
               ISO_symbols_lane0,   // Four 8-bit signals carry the processed main video stream data output from the Isochronous Transport Services Block. They are transmitted over the active lanes with the selected video format.
               ISO_symbols_lane1, 
               ISO_symbols_lane2, 
               ISO_symbols_lane3,
               Control_sym_flag_lane0, // This signal is asserted when the block outputs control symbols, enabling the Physical Layer to distinguish between control and data symbols.
               Control_sym_flag_lane1,
               Control_sym_flag_lane2,
               Control_sym_flag_lane3
    ); 


    ///////////////////////////////////////////////////////////////
    /////////////////////// TASKS AND FUNCTIONS ///////////////////
    ///////////////////////////////////////////////////////////////
    
    // TASK: SINK_Reset
    // This task is used to reset the DUT by asserting and deasserting the reset signal
    task SINK_Reset();
        HPD_Signal = 1'b0;          // Deassert reset
        PHY_START_STOP = 1'b0;      // Deassert PHY_START_STOP
    endtask

    // TASK: Active
    // This task is used to assert the HPD_Signal
    task Active(output logic aux_start_stop, output logic [7:0] value, output logic [1:0] phy_instruct, output logic [7:0] phy_adj_bw, output logic [1:0] phy_adj_lc, output logic phy_instruct_vld);
        HPD_Signal = 1'b1;                      // Drive the HPD_Signal with the specified value
        `uvm_info("DP_SINK_INTERFACE", $sformatf("Active Sink: HPD_Signal = %b", HPD_Signal), UVM_MEDIUM)

        PHY_START_STOP = 1'b0;                  // Deassert PHY_START_STOP
        aux_start_stop = AUX_START_STOP;        // Return the value of AUX_START_STOP
        
        // Return the PHY signals which are used in the Link Training process
        phy_instruct = PHY_Instruct;
        phy_adj_bw = PHY_ADJ_BW;
        phy_adj_lc = PHY_ADJ_LC;
        phy_instruct_vld = PHY_Instruct_VLD;

        if (AUX_START_STOP) begin
            value = AUX_IN_OUT;
            `uvm_info("DP_SINK_INTERFACE", $sformatf("Read AUX_IN_OUT = 0x%0h", value), UVM_LOW)

        end else begin
            value = 8'b0;                      // If AUX_START_STOP is not asserted, set value to 0
        end
    endtask

    task ISO_sink(output logic control_sym_flag_lane0, control_sym_flag_lane1, control_sym_flag_lane2, control_sym_flag_lane3, iso_symbols_lane0, iso_symbols_lane1, iso_symbols_lane2, iso_symbols_lane3);
        // Return the ISO symbols flags of the ISO symbols to be checked if they take any values in the Link Training steps
        iso_symbols_lane0 = ISO_symbols_lane0;
        iso_symbols_lane1 = ISO_symbols_lane1; 
        iso_symbols_lane2 = ISO_symbols_lane2; 
        iso_symbols_lane3 = ISO_symbols_lane3;

        // Return the Control symbols flags of the ISO symbols to be checked if they take any values in the Link Training steps
        control_sym_flag_lane0 = Control_sym_flag_lane0; 
        control_sym_flag_lane1 = Control_sym_flag_lane1;
        control_sym_flag_lane2 = Control_sym_flag_lane2;
        control_sym_flag_lane3 = Control_sym_flag_lane3;
    endtask

    // TASK: drive_aux_in_out
    // This task is used to drive the AUX_IN_OUT signal with a specific value
    // It takes a 8-bit value as input and drives the AUX_IN_OUT signal with that value
    task drive_aux_in_out(input logic [7:0] value);
        HPD_Signal = 1'b1;              // Assert HPD_Signal
        aux_data = value;               // Drive the AUX_IN_OUT signal with the specified value
        `uvm_info("DP_SINK_INTERFACE", $sformatf("Driving AUX_IN_OUT = 0x%0h", value), UVM_LOW);
        PHY_START_STOP = 1'b1;          // Start the PHY operation
    endtask

    // TASK: Interrupt
    task HPD_Interrupt();
        PHY_START_STOP = 1'b0;
        `uvm_info("DP_SINK_INTERFACE", $sformatf("Driving Interrupt _NOW "), UVM_MEDIUM)
        HPD_Signal = 1'b1;              // Assert HPD_Signal
        #10000;                       // Wait for 10us 
        HPD_Signal = 1'b0;              // Deassert HPD_Signal
        #1000000;                       // Wait for 1ms
        HPD_Signal = 1'b1;              // Assert HPD_Signal
        //PHY_START_STOP = 1'b1;          // Deassert PHY_START_STOP
        `uvm_info("DP_SINK_INTERFACE", $sformatf("Driving Interrupt _DONE "), UVM_MEDIUM)
    endtask

    // TASK: Random HPD (HPD Testing)
    task HPD_Test();
        `uvm_info("DP_SINK_INTERFACE", $sformatf("Start Driving 0.1ms HPD "), UVM_MEDIUM)
        HPD_Signal = 1'b0;              // Assert HPD_Signal
        #100000;                       // Wait for 0.1ms 
        HPD_Signal = 1'b1; 
        `uvm_info("DP_SINK_INTERFACE", $sformatf("Finish Driving 0.1ms HPD "), UVM_MEDIUM)
    endtask

endinterface