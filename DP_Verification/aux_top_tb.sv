`timescale 1us/1ns
module aux_top_tb ();
   
parameter CLK_PERIOD = 10;     // 100 KHz

////////// DUT Signals //////////////
// Inputs
reg          clk_tb;
reg          rst_n_tb;  
reg          spm_transaction_vld_tb; 
reg   [1:0]  spm_cmd_tb;
reg   [19:0] spm_address_tb;
reg   [7:0]  spm_len_tb;
reg   [7:0]  spm_data_tb;
reg          lpm_transaction_vld_tb; 
reg   [1:0]  lpm_cmd_tb;
reg   [19:0] lpm_address_tb;
reg   [7:0]  lpm_len_tb;
reg   [7:0]  lpm_data_tb;
reg          cr_transaction_vld_tb; 
reg   [1:0]  cr_cmd_tb;
reg   [19:0] cr_address_tb;
reg   [7:0]  cr_len_tb;
reg   [7:0]  cr_data_tb;
reg          eq_transaction_vld_tb; 
reg   [1:0]  eq_cmd_tb;
reg   [19:0] eq_address_tb;
reg   [7:0]  eq_len_tb;
reg   [7:0]  eq_data_tb;
reg          phy_start_stop_tb;

// Outputs
wire         aux_start_stop_tb;
wire  [7:0]  reply_data_tb;
wire         reply_data_vld_tb;
wire  [1:0]  reply_ack_tb;
wire         reply_ack_vld_tb;
wire         reply_i2c_native_tb;

// Bidirectional
wire  [7:0]  aux_in_out_tb;

reg   [7:0]  aux_in_value;


/////// Design Instantiation /////////
aux_top DUT (
.clk(clk_tb),
.rst_n(rst_n_tb),
.spm_transaction_vld(spm_transaction_vld_tb),
.spm_cmd(spm_cmd_tb),
.spm_address(spm_address_tb),
.spm_len(spm_len_tb),
.spm_data(spm_data_tb), 
.lpm_transaction_vld(lpm_transaction_vld_tb),
.lpm_cmd(lpm_cmd_tb),
.lpm_address(lpm_address_tb),
.lpm_len(lpm_len_tb),
.lpm_data(lpm_data_tb),
//.cr_transaction_vld(cr_transaction_vld_tb),
//.cr_cmd(cr_cmd_tb),
//.cr_address(cr_address_tb),
//.cr_len(cr_len_tb),
//.cr_data(cr_data_tb),
//.eq_transaction_vld(eq_transaction_vld_tb),
//.eq_cmd(eq_cmd_tb),
//.eq_address(eq_address_tb),
//.eq_len(eq_len_tb),
//.eq_data(eq_data_tb),
.phy_start_stop(phy_start_stop_tb),
.aux_start_stop(aux_start_stop_tb),
//.reply_data(reply_data_tb),
//.reply_data_vld(reply_data_vld_tb),
//.reply_ack(reply_ack_tb),
//.reply_ack_vld(reply_ack_vld_tb),
//.reply_i2c_native(reply_i2c_native_tb),
.aux_in_out(aux_in_out_tb)
);

/////////// Clock Generator /////////
always #(CLK_PERIOD/2) clk_tb = ~clk_tb;

// Assign bidirectional bus - drives the bus when drive_aux_bus is high
assign aux_in_out_tb = phy_start_stop_tb ? aux_in_value : 8'bz;

////////// initial block ///////////
initial
 begin
   // Initialization
   initialize();
   // Reset
   reset();
   
   
   
   //============================================================================================================//
   //                 Test Case 1 (LPM Native Write Transaction (4 Bytes of Data))                               //
   //============================================================================================================//
   // Load Data
   lpm_drive(1'b1, 2'b00, 20'hABCDE, 8'b0000_0011, 8'b0000_0001); // CMD -> Address -> Length -> DATA0 
   #(CLK_PERIOD)
   lpm_drive(1'b1, 2'b00, 20'b00000000000000000000, 8'b0000_0000, 8'b0000_0010); // DATA1 
   #(CLK_PERIOD)
   lpm_drive(1'b1, 2'b00, 20'b00000000000000000000, 8'b0000_0000, 8'b0000_0011); // DATA2 
   #(CLK_PERIOD)
   lpm_drive(1'b1, 2'b00, 20'b00000000000000000000, 8'b0000_0000, 8'b0000_0100); // DATA3
   // No Data 
   #(CLK_PERIOD)
   lpm_drive(1'b0, 2'b00, 20'b00000000000000000000, 8'b0000_0000, 8'b0000_0000);
   //------------------------------------------------------------------------------------------------------------//
   // Wait for transmission and simulate reply by driving the aux_in_out bus
   #(20*CLK_PERIOD);
   //------------------------------------------------------------------------------------------------------------//
   // Simulate ACK response on bidirectional bus
   phy_start_stop_tb = 1'b1;
   aux_in_value = 8'h00; // ACK value
   #(CLK_PERIOD);
   phy_start_stop_tb = 1'b0;
   //------------------------------------------------------------------------------------------------------------//
   #(20*CLK_PERIOD);
   
   
   
   
   //============================================================================================================//
   //                 Test Case 2 (LPM Native Read Transaction (3 Bytes of Data))                               //
   //============================================================================================================//
   // Load Data
   lpm_drive(1'b1, 2'b01, 20'hBCBCA, 8'b0000_0010, 8'b0000_0000); // CMD -> Address -> Length -> No DATA  
   #(CLK_PERIOD)
   lpm_drive(1'b0, 2'b00, 20'b00000000000000000000, 8'b0000_0000, 8'b0000_0000);
   //------------------------------------------------------------------------------------------------------------//
   // Wait for transmission and simulate reply by driving the aux_in_out bus
   #(20*CLK_PERIOD);
   //------------------------------------------------------------------------------------------------------------//
   // Simulate ACK response on bidirectional bus
   phy_start_stop_tb = 1'b1;
   aux_in_value = 8'h00; // ACK value
   #(CLK_PERIOD);
   aux_in_value = 8'h02; // DATA0 value
   #(CLK_PERIOD);
   aux_in_value = 8'h03; // DATA1 value
   #(CLK_PERIOD);
   aux_in_value = 8'h04; // DATA2 value
   #(CLK_PERIOD);
   phy_start_stop_tb = 1'b0;
   //------------------------------------------------------------------------------------------------------------//
   #(20*CLK_PERIOD);
   


   //============================================================================================================//
   //                               Test Case 3 (SPM Read EDID Transaction)                                      //
   //============================================================================================================//
   // Load Data for EDID read
   spm_drive(1'b1, 2'b01, 20'hADEFB, 8'b0000_0000, 8'b0000_0000); // CMD -> Address -> Length
   // No Data 
   #(CLK_PERIOD)
   spm_drive(1'b0, 2'b00, 20'b00000000000000000000, 8'b0000_0000, 8'b0000_0000);
   //------------------------------------------------------------------------------------------------------------//ADD
   // Wait for transmission and simulate reply by driving the aux_in_out bus   
   #(20*CLK_PERIOD);
   // Simulate ACK response on bidirectional bus
   phy_start_stop_tb = 1'b1;
   aux_in_value = 8'h00; // ACK value
   #(CLK_PERIOD);
   phy_start_stop_tb = 1'b0;
   //------------------------------------------------------------------------------------------------------------//DATA0
   // Wait for transmission and simulate reply by driving the aux_in_out bus   
   #(20*CLK_PERIOD);
   // Simulate ACK response on bidirectional bus
   phy_start_stop_tb = 1'b1;
   aux_in_value = 8'h00; // ACK value
   #(CLK_PERIOD);
   phy_start_stop_tb = 1'b0;
   //------------------------------------------------------------------------------------------------------------//DATA1
   // Wait for transmission and simulate reply by driving the aux_in_out bus   
   #(20*CLK_PERIOD);
   // Simulate ACK response on bidirectional bus
   phy_start_stop_tb = 1'b1;
   aux_in_value = 8'h00; // ACK value
   #(CLK_PERIOD);
   phy_start_stop_tb = 1'b0;
   //------------------------------------------------------------------------------------------------------------//DATA2
   // Wait for transmission and simulate reply by driving the aux_in_out bus   
   #(20*CLK_PERIOD);
   // Simulate ACK response on bidirectional bus
   phy_start_stop_tb = 1'b1;
   aux_in_value = 8'h00; // ACK value
   #(CLK_PERIOD);
   phy_start_stop_tb = 1'b0;
   //------------------------------------------------------------------------------------------------------------//DATA3
   // Wait for transmission and simulate reply by driving the aux_in_out bus   
   #(20*CLK_PERIOD);
   // Simulate ACK response on bidirectional bus
   phy_start_stop_tb = 1'b1;
   aux_in_value = 8'h00; // ACK value
   #(CLK_PERIOD);
   phy_start_stop_tb = 1'b0;
   //------------------------------------------------------------------------------------------------------------//DATA4
   // Wait for transmission and simulate reply by driving the aux_in_out bus   
   #(20*CLK_PERIOD);
   // Simulate ACK response on bidirectional bus
   phy_start_stop_tb = 1'b1;
   aux_in_value = 8'h00; // ACK value
   #(CLK_PERIOD);
   phy_start_stop_tb = 1'b0;
   //------------------------------------------------------------------------------------------------------------//END
   // Wait for transmission and simulate reply by driving the aux_in_out bus   
   #(20*CLK_PERIOD);
   // Simulate ACK response on bidirectional bus
   phy_start_stop_tb = 1'b1;
   aux_in_value = 8'h00; // ACK value
   #(CLK_PERIOD);
   phy_start_stop_tb = 1'b0;
   //------------------------------------------------------------------------------------------------------------//
   #(5*CLK_PERIOD);   
   
   
   
   //============================================================================================================//
   //                 Test Case 4 (CR Native Read Transaction (5 Bytes of Data))                                 //
   //============================================================================================================//   
   // Load Data 
   cr_drive(1'b1, 2'b01, 20'hDDAAE, 8'b0000_0100, 8'b0000_0000); // CMD -> Address -> Length -> No DATA for Read
   // No Data 
   #(CLK_PERIOD)
   cr_drive(1'b0, 2'b00, 20'h00000, 8'b0000_0000, 8'b0000_0000);
   //------------------------------------------------------------------------------------------------------------//   
   // Wait for transmission and simulate reply by driving the aux_in_out bus
   #(20*CLK_PERIOD);
   //------------------------------------------------------------------------------------------------------------//
   // Simulate ACK response on bidirectional bus
   phy_start_stop_tb = 1'b1;
   aux_in_value = 8'h00; // ACK value
   #(CLK_PERIOD); 
   
   // Simulate data response
   aux_in_value = 8'h01; // DATA1
   #(CLK_PERIOD);
   aux_in_value = 8'h02; // DATA2
   #(CLK_PERIOD);
   aux_in_value = 8'h03; // DATA3
   #(CLK_PERIOD);
   aux_in_value = 8'h04; // DATA4
   #(CLK_PERIOD);
   aux_in_value = 8'h05; // DATA5
   #(CLK_PERIOD);
   phy_start_stop_tb = 1'b0;
   //------------------------------------------------------------------------------------------------------------//
   #(20*CLK_PERIOD);
   
   

   //============================================================================================================//
   //                 Test Case 5 (CR Native Write Transaction (6 Bytes of Data))                                 //
   //============================================================================================================//   
   // Load Data 
   cr_drive(1'b1, 2'b00, 20'hACEFA, 8'b0000_0101, 8'h01); // CMD -> Address -> Length -> DATA0
   #(CLK_PERIOD)   
   cr_drive(1'b1, 2'b00, 20'h00000, 8'b0000_0000, 8'h02); // DATA1
   #(CLK_PERIOD)   
   cr_drive(1'b1, 2'b00, 20'h00000, 8'b0000_0000, 8'h03); // DATA1
   #(CLK_PERIOD)   
   cr_drive(1'b1, 2'b00, 20'h00000, 8'b0000_0000, 8'h04); // DATA1
   #(CLK_PERIOD)   
   cr_drive(1'b1, 2'b00, 20'h00000, 8'b0000_0000, 8'h05); // DATA1
   #(CLK_PERIOD)   
   cr_drive(1'b1, 2'b00, 20'h00000, 8'b0000_0000, 8'h06); // DATA1   
   // No Data 
   #(CLK_PERIOD)
   cr_drive(1'b0, 2'b00, 20'h00000, 8'b0000_0000, 8'h00);
   //------------------------------------------------------------------------------------------------------------//   
   // Wait for transmission and simulate reply by driving the aux_in_out bus
   #(20*CLK_PERIOD);
   //------------------------------------------------------------------------------------------------------------//
   // Simulate ACK response on bidirectional bus
   phy_start_stop_tb = 1'b1;
   aux_in_value = 8'h00; // ACK value
   #(CLK_PERIOD); 
   phy_start_stop_tb = 1'b0;
   //------------------------------------------------------------------------------------------------------------//
   #(20*CLK_PERIOD);



   
   //============================================================================================================//
   //                 Test Case 6 (EQ Native Read Transaction (3 Bytes of Data))                                 //
   //============================================================================================================//   
   // Load Data 
   eq_drive(1'b1, 2'b01, 20'hABCDE, 8'b0000_0100, 8'b0000_0000); // CMD -> Address -> Length -> No DATA for Read
   // No Data 
   #(CLK_PERIOD)
   eq_drive(1'b0, 2'b00, 20'h00000, 8'b0000_0000, 8'b0000_0000);
   //------------------------------------------------------------------------------------------------------------//   
   // Wait for transmission and simulate reply by driving the aux_in_out bus
   #(20*CLK_PERIOD);
   //------------------------------------------------------------------------------------------------------------//
   // Simulate ACK response on bidirectional bus
   phy_start_stop_tb = 1'b1;
   aux_in_value = 8'h00; // ACK value
   #(CLK_PERIOD); 
   
   // Simulate data response
   aux_in_value = 8'h01; // DATA1
   #(CLK_PERIOD);
   aux_in_value = 8'h02; // DATA2
   #(CLK_PERIOD);
   aux_in_value = 8'h03; // DATA3
   #(CLK_PERIOD);
   aux_in_value = 8'h04; // DATA4
   #(CLK_PERIOD);
   phy_start_stop_tb = 1'b0;
   //------------------------------------------------------------------------------------------------------------//
   #(5*CLK_PERIOD);   

  
   
   
   //============================================================================================================//
   //                 Test Case 7 (EQ Native Write Transaction (2 Bytes of Data))                                 //
   //============================================================================================================//   
   // Load Data 
   eq_drive(1'b1, 2'b00, 20'hABBDC, 8'b0000_0001, 8'h01); // CMD -> Address -> Length -> DATA0
   #(CLK_PERIOD)   
   eq_drive(1'b1, 2'b00, 20'h00000, 8'b0000_0000, 8'h02); // DATA1 
   // No Data 
   #(CLK_PERIOD)
   eq_drive(1'b0, 2'b00, 20'h00000, 8'b0000_0000, 8'h00);
   //------------------------------------------------------------------------------------------------------------//   
   // Wait for transmission and simulate reply by driving the aux_in_out bus
   #(20*CLK_PERIOD);
   //------------------------------------------------------------------------------------------------------------//
   // Simulate ACK response on bidirectional bus
   phy_start_stop_tb = 1'b1;
   aux_in_value = 8'h00; // ACK value
   #(CLK_PERIOD); 
   phy_start_stop_tb = 1'b0;
   //------------------------------------------------------------------------------------------------------------//
   #(20*CLK_PERIOD);   
   
   
  $display("continue from here: %t", $time);

   

   //============================================================================================================//
   //              Test Case 1 (LPM Native Write Transaction with NACK (4 Bytes of Data))                     //
   //============================================================================================================//
   // Load Data
   lpm_drive(1'b1, 2'b00, 20'hABCDE, 8'b0000_0011, 8'b0000_0001); // CMD -> Address -> Length -> DATA0 
   #(CLK_PERIOD)
   lpm_drive(1'b1, 2'b00, 20'b00000000000000000000, 8'b0000_0000, 8'b0000_0010); // DATA1 
   #(CLK_PERIOD)
   lpm_drive(1'b1, 2'b00, 20'b00000000000000000000, 8'b0000_0000, 8'b0000_0011); // DATA2 
   #(CLK_PERIOD)
   lpm_drive(1'b1, 2'b00, 20'b00000000000000000000, 8'b0000_0000, 8'b0000_0100); // DATA3
   // No Data 
   #(CLK_PERIOD)
   lpm_drive(1'b0, 2'b00, 20'b00000000000000000000, 8'b0000_0000, 8'b0000_0000);
   //------------------------------------------------------------------------------------------------------------//
   // Wait for transmission and simulate reply by driving the aux_in_out bus
   #(20*CLK_PERIOD);
   //------------------------------------------------------------------------------------------------------------//
   // Simulate ACK response on bidirectional bus
   phy_start_stop_tb = 1'b1;
   aux_in_value = 8'h10; // NACK value
   #(CLK_PERIOD);
   aux_in_value = 8'h02; // NACK value
   #(CLK_PERIOD);
   phy_start_stop_tb = 1'b0;
   //------------------------------------------------------------------------------------------------------------//
   #(20*CLK_PERIOD);
   


   //============================================================================================================//
   //              Test Case 1 (LPM Native Write Transaction with Timeout (4 Bytes of Data))                     //
   //============================================================================================================//
   // Load Data
   lpm_drive(1'b1, 2'b00, 20'hABCDE, 8'b0000_0011, 8'b0000_0001); // CMD -> Address -> Length -> DATA0 
   #(CLK_PERIOD)
   lpm_drive(1'b1, 2'b00, 20'b00000000000000000000, 8'b0000_0000, 8'b0000_0010); // DATA1 
   #(CLK_PERIOD)
   lpm_drive(1'b1, 2'b00, 20'b00000000000000000000, 8'b0000_0000, 8'b0000_0011); // DATA2 
   #(CLK_PERIOD)
   lpm_drive(1'b1, 2'b00, 20'b00000000000000000000, 8'b0000_0000, 8'b0000_0100); // DATA3
   // No Data 
   #(CLK_PERIOD)
   lpm_drive(1'b0, 2'b00, 20'b00000000000000000000, 8'b0000_0000, 8'b0000_0000);
   //------------------------------------------------------------------------------------------------------------//
   // Wait for transmission and Timeoutand simulate reply by driving the aux_in_out bus
   #(50*CLK_PERIOD);
   //------------------------------------------------------------------------------------------------------------//
   // Simulate ACK response on bidirectional bus
   phy_start_stop_tb = 1'b1;
   aux_in_value = 8'h00; // ACK value
   #(CLK_PERIOD);
   phy_start_stop_tb = 1'b0;
   //------------------------------------------------------------------------------------------------------------//
   #(20*CLK_PERIOD);
   // Simulate ACK response on bidirectional bus
   phy_start_stop_tb = 1'b1;
   aux_in_value = 8'h00; // ACK value
   #(CLK_PERIOD);
   phy_start_stop_tb = 1'b0;




   //============================================================================================================//
   //                Test Case 1 (LPM Native Write Transaction with DEFER (4 Bytes of Data))                     //
   //============================================================================================================//
   // Load Data
   lpm_drive(1'b1, 2'b00, 20'hABCDE, 8'b0000_0011, 8'b0000_0001); // CMD -> Address -> Length -> DATA0 
   #(CLK_PERIOD)
   lpm_drive(1'b1, 2'b00, 20'b00000000000000000000, 8'b0000_0000, 8'b0000_0010); // DATA1 
   #(CLK_PERIOD)
   lpm_drive(1'b1, 2'b00, 20'b00000000000000000000, 8'b0000_0000, 8'b0000_0011); // DATA2 
   #(CLK_PERIOD)
   lpm_drive(1'b1, 2'b00, 20'b00000000000000000000, 8'b0000_0000, 8'b0000_0100); // DATA3
   // No Data 
   #(CLK_PERIOD)
   lpm_drive(1'b0, 2'b00, 20'b00000000000000000000, 8'b0000_0000, 8'b0000_0000);
   //------------------------------------------------------------------------------------------------------------//
   // Wait for transmission and simulate reply by driving the aux_in_out bus
   #(20*CLK_PERIOD);
   //------------------------------------------------------------------------------------------------------------//
   // Simulate ACK response on bidirectional bus
   phy_start_stop_tb = 1'b1;
   aux_in_value = 8'h20; // DEFER value
   #(CLK_PERIOD);
   phy_start_stop_tb = 1'b0;
   //------------------------------------------------------------------------------------------------------------//
   #(20*CLK_PERIOD);
   //------------------------------------------------------------------------------------------------------------//
   // Simulate ACK response on bidirectional bus
   phy_start_stop_tb = 1'b1;
   aux_in_value = 8'h20; // DEFER value
   #(CLK_PERIOD);
   phy_start_stop_tb = 1'b0;
   //------------------------------------------------------------------------------------------------------------//
   #(20*CLK_PERIOD);
   //------------------------------------------------------------------------------------------------------------//
   // Simulate ACK response on bidirectional bus
   phy_start_stop_tb = 1'b1;
   aux_in_value = 8'h20; // DEFER value
   #(CLK_PERIOD);
   phy_start_stop_tb = 1'b0;
   //------------------------------------------------------------------------------------------------------------//
   #(20*CLK_PERIOD);
   //------------------------------------------------------------------------------------------------------------//
   // Simulate ACK response on bidirectional bus
   phy_start_stop_tb = 1'b1;
   aux_in_value = 8'h20; // DEFER value
   #(CLK_PERIOD);
   phy_start_stop_tb = 1'b0;
   //------------------------------------------------------------------------------------------------------------//
   #(20*CLK_PERIOD);
   //------------------------------------------------------------------------------------------------------------//
   // Simulate ACK response on bidirectional bus
   phy_start_stop_tb = 1'b1;
   aux_in_value = 8'h20; // DEFER value
   #(CLK_PERIOD);
   phy_start_stop_tb = 1'b0;
   //------------------------------------------------------------------------------------------------------------//
   #(20*CLK_PERIOD);
   //------------------------------------------------------------------------------------------------------------//
   // Simulate ACK response on bidirectional bus
   phy_start_stop_tb = 1'b1;
   aux_in_value = 8'h20; // DEFER value
   #(CLK_PERIOD);
   phy_start_stop_tb = 1'b0;
   //------------------------------------------------------------------------------------------------------------//
   #(20*CLK_PERIOD);
   //------------------------------------------------------------------------------------------------------------//
   // Simulate ACK response on bidirectional bus
   phy_start_stop_tb = 1'b1;
   aux_in_value = 8'h20; // DEFER value
   #(CLK_PERIOD);
   phy_start_stop_tb = 1'b0;
   //------------------------------------------------------------------------------------------------------------//
   #(20*CLK_PERIOD);














   //============================================================================================================//
   //                               Test Case 3 (SPM Read EDID Transaction)                                      //
   //============================================================================================================//
   // Load Data for EDID read
   spm_drive(1'b1, 2'b01, 20'hADEFB, 8'b0000_0000, 8'b0000_0000); // CMD -> Address -> Length
   // No Data 
   #(CLK_PERIOD)
   spm_drive(1'b0, 2'b00, 20'b00000000000000000000, 8'b0000_0000, 8'b0000_0000);
   //------------------------------------------------------------------------------------------------------------//ADD
   // Wait for transmission and simulate reply by driving the aux_in_out bus   
   #(20*CLK_PERIOD);
   // Simulate ACK response on bidirectional bus
   phy_start_stop_tb = 1'b1;
   aux_in_value = 8'h00; // ACK value
   #(CLK_PERIOD);
   phy_start_stop_tb = 1'b0;
   //------------------------------------------------------------------------------------------------------------//DATA0
   // Wait for transmission and simulate reply by driving the aux_in_out bus   
   #(20*CLK_PERIOD);
   // Simulate ACK response on bidirectional bus
   phy_start_stop_tb = 1'b1;
   aux_in_value = 8'h00; // ACK value
   #(CLK_PERIOD);
   phy_start_stop_tb = 1'b0;
   //------------------------------------------------------------------------------------------------------------//DATA1
   // Wait for transmission and simulate reply by driving the aux_in_out bus   
   #(20*CLK_PERIOD);
   // Simulate ACK response on bidirectional bus
   phy_start_stop_tb = 1'b1;
   aux_in_value = 8'h10; // ACK value
   #(CLK_PERIOD);
   aux_in_value = 8'h00; // ACK value
   #(CLK_PERIOD);   
   phy_start_stop_tb = 1'b0;
   //------------------------------------------------------------------------------------------------------------//DATA2
   // Wait for transmission and simulate reply by driving the aux_in_out bus   
   #(20*CLK_PERIOD);
   // Simulate ACK response on bidirectional bus
   phy_start_stop_tb = 1'b1;
   aux_in_value = 8'h00; // ACK value
   #(CLK_PERIOD);
   phy_start_stop_tb = 1'b0;
   //------------------------------------------------------------------------------------------------------------//DATA3
   // Wait for transmission and simulate reply by driving the aux_in_out bus   
   #(20*CLK_PERIOD);
   // Simulate ACK response on bidirectional bus
   phy_start_stop_tb = 1'b1;
   aux_in_value = 8'h00; // ACK value
   #(CLK_PERIOD);
   phy_start_stop_tb = 1'b0;
   //------------------------------------------------------------------------------------------------------------//DATA4
   // Wait for transmission and simulate reply by driving the aux_in_out bus   
   #(20*CLK_PERIOD);
   // Simulate ACK response on bidirectional bus
   phy_start_stop_tb = 1'b1;
   aux_in_value = 8'h00; // ACK value
   #(CLK_PERIOD);
   phy_start_stop_tb = 1'b0;
   //------------------------------------------------------------------------------------------------------------//END
   // Wait for transmission and simulate reply by driving the aux_in_out bus   
   #(20*CLK_PERIOD);
   // Simulate ACK response on bidirectional bus
   phy_start_stop_tb = 1'b1;
   aux_in_value = 8'h00; // ACK value
   #(CLK_PERIOD);
   phy_start_stop_tb = 1'b0;
   //------------------------------------------------------------------------------------------------------------//
   #(5*CLK_PERIOD);   
   



   #(20*CLK_PERIOD) 
   $stop;
 end
 
/////////////////////// TASKS //////////////////////////

// Signals Initialization
task initialize;
  begin
    clk_tb                 = 1'b0;
    rst_n_tb               = 1'b1;    // rst is deactivated
    spm_transaction_vld_tb = 1'b0; 
    spm_cmd_tb             =  'b0;
    spm_address_tb         =  'b0;
    spm_len_tb             =  'b0;
    spm_data_tb            =  'b0;
    lpm_transaction_vld_tb = 1'b0; 
    lpm_cmd_tb             =  'b0;
    lpm_address_tb         =  'b0;
    lpm_len_tb             =  'b0;
    lpm_data_tb            =  'b0;
    cr_transaction_vld_tb  = 1'b0; 
    cr_cmd_tb              =  'b0;
    cr_address_tb          =  'b0;
    cr_len_tb              =  'b0;
    cr_data_tb             =  'b0;
    eq_transaction_vld_tb  = 1'b0; 
    eq_cmd_tb              =  'b0;
    eq_address_tb          =  'b0;
    eq_len_tb              =  'b0;
    eq_data_tb             =  'b0;
    phy_start_stop_tb      = 1'b0;
	
    aux_in_value           =  'b0;
    //drive_aux_bus          = 1'b0;
  end
endtask


// RESET
task reset;
  begin
    #(CLK_PERIOD)
    rst_n_tb = 1'b0;    // rst is activated
    #(CLK_PERIOD)
    rst_n_tb = 1'b1;
    #(CLK_PERIOD);
  end
endtask


// SPM Driver
task spm_drive;
 input        vld_spm;
 input [1:0]  cmd_spm;
 input [19:0] address_spm;
 input [7:0]  len_spm;
 input [7:0]  data_spm;
begin
    spm_transaction_vld_tb = vld_spm;
    spm_cmd_tb             = cmd_spm;
    spm_address_tb         = address_spm;
    spm_len_tb             = len_spm;
    spm_data_tb            = data_spm;    
end
endtask

// LPM Driver
task lpm_drive;
 input        vld_lpm;
 input [1:0]  cmd_lpm;
 input [19:0] address_lpm;
 input [7:0]  len_lpm;
 input [7:0]  data_lpm;
begin
    lpm_transaction_vld_tb = vld_lpm;
    lpm_cmd_tb             = cmd_lpm;
    lpm_address_tb         = address_lpm;
    lpm_len_tb             = len_lpm;
    lpm_data_tb            = data_lpm;    
end
endtask

// CR Driver
task cr_drive;
 input        vld_cr;
 input [1:0]  cmd_cr;
 input [19:0] address_cr;
 input [7:0]  len_cr;
 input [7:0]  data_cr;
begin
    cr_transaction_vld_tb  = vld_cr;
    cr_cmd_tb              = cmd_cr;
    cr_address_tb          = address_cr;
    cr_len_tb              = len_cr;
    cr_data_tb             = data_cr;    
end
endtask

// EQ Driver
task eq_drive;
 input        vld_eq;
 input [1:0]  cmd_eq;
 input [19:0] address_eq;
 input [7:0]  len_eq;
 input [7:0]  data_eq;
begin
    eq_transaction_vld_tb  = vld_eq;
    eq_cmd_tb              = cmd_eq;
    eq_address_tb          = address_eq;
    eq_len_tb              = len_eq;
    eq_data_tb             = data_eq;    
end
endtask


endmodule