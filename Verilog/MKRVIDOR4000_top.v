/*
* Copyright 2018 ARDUINO SA (http://www.arduino.cc/)
* This file is part of Vidor IP.
* Copyright (c) 2018
* Authors: Dario Pennisi
*
* This software is released under:
* The GNU General Public License, which covers the main part of 
* Vidor IP
* The terms of this license can be found at:
* https://www.gnu.org/licenses/gpl-3.0.en.html
*
* You can be released from the requirements of the above licenses by purchasing
* a commercial license. Buying such a license is mandatory if you want to modify or
* otherwise use the software for commercial activities involving the Arduino
* software without disclosing the source code of your own applications. To purchase
* a commercial license, send an email to license@arduino.cc.
*
*/

module MKRVIDOR4000_top
(
  // system signals
  input         iCLK,
  input         iRESETn,
  input         iSAM_INT,
  output        oSAM_INT,
  
  // SDRAM
  output        oSDRAM_CLK,
  output [11:0] oSDRAM_ADDR,
  output [1:0]  oSDRAM_BA,
  output        oSDRAM_CASn,
  output        oSDRAM_CKE,
  output        oSDRAM_CSn,
  inout  [15:0] bSDRAM_DQ,
  output [1:0]  oSDRAM_DQM,
  output        oSDRAM_RASn,
  output        oSDRAM_WEn,

  // SAM D21 PINS
  inout         bMKR_AREF,
  inout  [6:0]  bMKR_A,
  inout  [14:0] bMKR_D,
  
  // Mini PCIe
  inout         bPEX_RST,
  inout         bPEX_PIN6,
  inout         bPEX_PIN8,
  inout         bPEX_PIN10,
  input         iPEX_PIN11,
  inout         bPEX_PIN12,
  input         iPEX_PIN13,
  inout         bPEX_PIN14,
  inout         bPEX_PIN16,
  inout         bPEX_PIN20,
  input         iPEX_PIN23,
  input         iPEX_PIN25,
  inout         bPEX_PIN28,
  inout         bPEX_PIN30,
  input         iPEX_PIN31,
  inout         bPEX_PIN32,
  input         iPEX_PIN33,
  inout         bPEX_PIN42,
  inout         bPEX_PIN44,
  inout         bPEX_PIN45,
  inout         bPEX_PIN46,
  inout         bPEX_PIN47,
  inout         bPEX_PIN48,
  inout         bPEX_PIN49,
  inout         bPEX_PIN51,

  // NINA interface
  inout         bWM_PIO1,
  inout         bWM_PIO2,
  inout         bWM_PIO3,
  inout         bWM_PIO4,
  inout         bWM_PIO5,
  inout         bWM_PIO7,
  inout         bWM_PIO8,
  inout         bWM_PIO18,
  inout         bWM_PIO20,
  inout         bWM_PIO21,
  inout         bWM_PIO27,
  inout         bWM_PIO28,
  inout         bWM_PIO29,
  inout         bWM_PIO31,
  input         iWM_PIO32,
  inout         bWM_PIO34,
  inout         bWM_PIO35,
  inout         bWM_PIO36,
  input         iWM_TX,
  inout         oWM_RX,
  inout         oWM_RESET,

  // HDMI output
  output [2:0]  oHDMI_TX,
  output        oHDMI_CLK,

  inout         bHDMI_SDA,
  inout         bHDMI_SCL,
  
  input         iHDMI_HPD,
  
  // MIPI input
  input  [1:0]  iMIPI_D,
  input         iMIPI_CLK,
  inout         bMIPI_SDA,
  inout         bMIPI_SCL,
  inout  [1:0]  bMIPI_GP,

  // Q-SPI Flash interface
  output        oFLASH_SCK,
  output        oFLASH_CS,
  inout         oFLASH_MOSI,
  inout         iFLASH_MISO,
  inout         oFLASH_HOLD,
  inout         oFLASH_WP

);





wire        wOSC_CLK;
wire        wCLK8,wCLK24, wCLK64, wCLK120;
wire [31:0] wJTAG_ADDRESS, wJTAG_READ_DATA, wJTAG_WRITE_DATA, wDPRAM_READ_DATA;
wire        wJTAG_READ, wJTAG_WRITE, wJTAG_WAIT_REQUEST, wJTAG_READ_DATAVALID;
wire [4:0]  wJTAG_BURST_COUNT;
wire        wDPRAM_CS;
wire [7:0]  wDVI_RED,wDVI_GRN,wDVI_BLU;
wire        wDVI_HS, wDVI_VS, wDVI_DE;
wire        wVID_CLK, wVID_CLKx5;
wire        wMEM_CLK;
assign wVID_CLK   = wCLK24;
assign wVID_CLKx5 = wCLK120;
assign wCLK8      = iCLK;
wire reset;


MY_PLL	MY_PLL_inst (
	.areset ( areset_sig ),
	.inclk0 ( iCLK ),
	.c0 (PLL_clock),
	.locked ( locked_sig )
	);
	
//EndPLL



//TOP PINS
wire incoming_pulse, ss_n, stop_count, sck, iSPI_IN, pulseCountMode;
wire serial_out, burst_detected;
wire PLL_clock;
assign incoming_pulse = bMKR_D[6];
assign ss_n = iSAM_INT;
assign stop_count = bMKR_D[7];
assign iSPI_IN = bMKR_D[8];
assign sck = bMKR_D[9];
assign bMKR_D[10] = serial_out;
assign bMKR_D[11] = burst_detected;
assign pulseCountMode = bMKR_D[12]; //TODO






parameter WIDTH = 32; 
parameter MAX_N = 32;

parameter SIZE_N = $clog2(MAX_N);



//DATA RECIEVED	
wire wSPI_WRITE_SIG;
wire [7:0] wSPI_RCV_BYTE, wSPI_RCV_CMD;
wire  [7:0] threshold ,window_width; 

 
//DATA & CONTROL FLOW SIGNALS
wire [WIDTH-1:0] pulseCount, edgeCount, dataSelected, Latched;
wire edgeCounterReset, enable_latch, after_posedge , after_posedge_delayed;

 


//always @(posedge wSPI_WRITE_SIG)
//begin
//        if 		 (wSPI_RCV_CMD[0] == 1'b0)   
//                window_width_reg <= wSPI_RCV_BYTE;					 
//        else if (wSPI_RCV_CMD[0] == 1'b1)  
//               threshold_reg <= wSPI_RCV_BYTE;   
//end


enable_flop #(.WIDTH(WIDTH)) THRESHOLD_FF (.din(wSPI_RCV_BYTE), .clock(PLL_clock), .ss_n(ss_n),  .dout(threshold), .en(~wSPI_RCV_CMD[0]));

enable_flop #(.WIDTH(WIDTH)) WIDTH_FF (.din(wSPI_RCV_BYTE), .clock(PLL_clock), .ss_n(ss_n),  .dout(window_width), .en(wSPI_RCV_CMD[0]));


pulse_riser PULS_RSR	(.din(incoming_pulse), .dout(after_posedge), .clock(PLL_clock), .reset(ss_n));

delay_flop DLY_FLOP (.clock(PLL_clock), .din(after_posedge), .reset(ss_n), .dout(after_posedge_delayed));

pulse_counter  #(.WIDTH(WIDTH)) PULS_CNTR  (.din(after_posedge), .dout(pulseCount), .clock(PLL_clock), .reset(ss_n));

edge_counter  	#(.WIDTH(WIDTH)) EDG_CNTR   (.clock(PLL_clock), .dout(edgeCount), .reset(edgeCounterReset));

//SlidingWindow_muxiada_new  #(.WIDTH(WIDTH), .SHIFT_LEN(MAX_N)) DUT
								//	(.din(edgeCount), .dout(windowsum),  .n(window_width), .clock(PLL_clock), .ss_n(ss_n));


burst_search   #(.WIDTH(WIDTH), .SHIFT_LEN(MAX_N)) DUT   (.din(edgeCount), .n(window_width), .threshold(threshold), .burst_detected(burst_detected), .clock(PLL_clock), .ss_n(ss_n));									
									
assign dataSelected = (pulseCountMode) ? pulseCount : edgeCount;

simple_latch 	#(.WIDTH(WIDTH)) LATCH      (.din(dataSelected), .dout(Latched), .en(enable_latch));


assign enable_latch = (pulseCountMode) ? stop_count : after_posedge_delayed;

assign edgeCounterReset = ss_n | after_posedge_delayed;

SPISlave SPISlave_inst(
    .iSPI_CLK(sck),
    .iSPI_SS_n(ss_n),
    .iSPI_IN(iSPI_IN),
	 .oSPI_RCV_BYTE(wSPI_RCV_BYTE),
    .oSPI_RCV_CMD(wSPI_RCV_CMD),
	 .oSPI_WRITE_SIG(wSPI_WRITE_SIG),
	 
	.oSPI_OUT(serial_out),
	.iSPI_SEND_BYTE(Latched)
	//.oSPI_PERIPH_SLCT(oSPI_PERIPH_SLCT),
	//.oSPI_READ_SIG(oSPI_READ_SIG),
	//.oSPI_INC_WRADDR(oSPI_INC_WRADDR),  
	//.oSPI_INC_RDADDR(oSPI_INC_RDADDR)
);  

//SPI_module   	#(.WIDTH(WIDTH)) SPI_INST   (.din(Latched), .dout(serial_out), .clock(sck), .ss_n(ss_n));


//SlidingWindow  #(.WIDTH(WIDTH), .N(N)) DUT (.din(edgeCount), .dout(windowsum), .clock(PLL_clock), .ss_n(ss_n));
//parameter N = 3;


//In field configurable
//SlidingWindow_muxiada  #(.WIDTH(WIDTH), .SIZE_N(3)) DUT (.din(edgeCount), .dout(windowsum),  .n(3), .clock(PLL_clock), .ss_n(ss_n));

//Decris meforach dans le code


//Old version all included
//pulse_counter PULS_CNTR(.din(sync_out), .clock(PLL_clock), .reset(ss_n), .dout(Count));


//always@(posedge PLL_clock or posedge ss_n)
//	begin
//		if (ss_n) after_posedge_delayed <= 1'b0;
//		else after_posedge_delayed <= after_posedge;
//	end


  
reg [5:0] rRESETCNT;

always @(posedge wMEM_CLK)
begin
  if (!rRESETCNT[5])
  begin
  rRESETCNT<=rRESETCNT+1;
  end
end






endmodule
