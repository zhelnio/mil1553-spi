/* MIL-STD-1553 <-> SPI bridge
 * Copyright(c) 2016 Stanislav Zhelnio
 * Licensed under the MIT license (MIT)
 * https://github.com/zhelnio/mil1553-spi
 */

`timescale 10 ns/ 1 ns

`include "settings.sv"

module test_spiCore();
	bit nRst, clk, ioClk; 
	logic[`DATAW_TOP:0] tData1, rData1, tData2, rData2;
	logic nCS, tFinish1, tFinish2, iPin, oPin;
	logic tDone1, rDone1, tDone2, rDone2;
	
	spiCore spi1(.nRst(nRst), .clk(clk), .spiClk(ioClk), .tData(tData1), 
	             .rData(rData1), .nCS(nCS), .iPin(iPin), .tDone(tDone1), 
	             .rDone(rDone1), .oPin(oPin), .tFinish(tFinish1));
	spiCore spi2(.nRst(nRst), .clk(clk), .spiClk(ioClk), .tData(tData2), 
	             .rData(rData2), .nCS(nCS), .iPin(oPin), .tDone(tDone2), 
	             .rDone(rDone2), .oPin(iPin), .tFinish(tFinish2));
	
  initial begin
	  nRst	= 0;
	  tData1 = 16'hABCD;
	  tData2 = 16'h1234;
	  nCS = 1;

	#2	nRst = 1;
    #10	nCS = 0;
    #300 $stop;
  end

  always #1 clk = !clk;
  always #8 ioClk = !ioClk;

  t1_isEqual_r2: assert property (@(posedge clk) $rose(rDone1) |=> (tData2 == rData1));
  t2_isEqual_r1: assert property (@(posedge clk) $rose(rDone2) |=> (tData1 == rData2));

  property oPinSignal;
    @(posedge ioClk)
    $fell(nCS) |->
    oPin == tData1[15] ##1 oPin == tData1[14] ##1 oPin == tData1[13] ##1 oPin == tData1[12] ##1 
    oPin == tData1[11] ##1 oPin == tData1[10] ##1 oPin == tData1[9]  ##1 oPin == tData1[8]  ##1 
    oPin == tData1[7]  ##1 oPin == tData1[6]  ##1 oPin == tData1[5]  ##1 oPin == tData1[4]  ##1
    oPin == tData1[3]  ##1 oPin == tData1[2]  ##1 oPin == tData1[1]  ##1 oPin == tData1[0]; 
  endproperty
  oPinSpiSignal: assert property(oPinSignal);

  property iPinSignal;
    @(posedge ioClk)
    $fell(nCS) |->
    iPin == tData2[15] ##1 iPin == tData2[14] ##1 iPin == tData2[13] ##1 iPin == tData2[12] ##1 
    iPin == tData2[11] ##1 iPin == tData2[10] ##1 iPin == tData2[9]  ##1 iPin == tData2[8]  ##1 
    iPin == tData2[7]  ##1 iPin == tData2[6]  ##1 iPin == tData2[5]  ##1 iPin == tData2[4]  ##1
    iPin == tData2[3]  ##1 iPin == tData2[2]  ##1 iPin == tData2[1]  ##1 iPin == tData2[0]; 
  endproperty
  iPinSpiSignal: assert property(iPinSignal);

endmodule


module test_spiMaster();
	bit nRst, clk, ioClk; 
	logic[`DATAW_TOP:0] tData1, rData1, tData2, rData2;
	logic nCS, tFinish1, tFinish2, iPin, oPin;
	logic tDone1, rDone1, tDone2, rDone2;
	logic transmitRequest, rDataWriteRequest, tOverflow, rOverflow, rDataWriteDone, sck;

	spiMaster spiM(.nRst(nRst), .clk(clk), .spiClk(ioClk), 
						.tData(tData1), .requestInsertToTQueue(transmitRequest), .doneInsertToTQueue(tDone1), 
						.rData(rData1), .requestReceivedToRQueue(rDataWriteRequest), .doneSavedFromRQueue(rDataWriteDone), 
						.overflowInTQueue(tOverflow), .overflowInRQueue(rOverflow), 
						.miso(iPin), .mosi(oPin), .nCS(nCS), .sck(sck));
						
	spiCore spiC(.nRst(nRst), .clk(clk), .spiClk(sck), .tData(tData2), 
	             .rData(rData2), .nCS(nCS), .iPin(oPin), .tDone(tDone2), 
	             .rDone(rDone2), .oPin(iPin), .tFinish(tFinish2));
	
  initial begin
	   clk = 1; ioClk = 0;
	   tData1 = 16'hABCD;
	   tData2 = 16'h1234;
	   transmitRequest = 1;
	   rDataWriteDone = 0;
	   nRst = 0;
	
     #2 nRst = 1;
     #2 transmitRequest = 0;

     #300 $stop;
  end
	
  always #1  clk =  ! clk;
  always #6 ioClk = !ioClk;

  t1_isEqual_r2: assert property (@(posedge clk) $rose(rDataWriteRequest) |=> (tData2 == rData1));
  t2_isEqual_r1: assert property (@(posedge clk) $rose(rDone2) |=> (tData1 == rData2));

endmodule




module test_spiSlave();
	bit nRst, clk, ioClk; 
	logic[`DATAW_TOP:0] tData1, rData1, tData2, rData2;
	logic requestInsertToTQueue1, doneInsertToTQueue1, requestReceivedToRQueue1, doneSavedFromRQueue1, 
			overflowInTQueue1, overflowInRQueue1;
	logic requestInsertToTQueue2, doneInsertToTQueue2, requestReceivedToRQueue2, doneSavedFromRQueue2, 
			overflowInTQueue2, overflowInRQueue2, isBusy;
	logic oPin, iPin, nCS, sck;
	
	spiMaster spiM(.nRst(nRst), .clk(clk), .spiClk(ioClk), 
						.tData(tData1), .requestInsertToTQueue(requestInsertToTQueue1), .doneInsertToTQueue(doneInsertToTQueue1), 
						.rData(rData1), .requestReceivedToRQueue(requestReceivedToRQueue1), .doneSavedFromRQueue(doneSavedFromRQueue1), 
						.overflowInTQueue(overflowInTQueue1), .overflowInRQueue(overflowInRQueue1), 
						.miso(iPin), .mosi(oPin), .nCS(nCS), .sck(sck));
	
	spiSlave spiS(.nRst(nRst), .clk(clk),
						.tData(tData2), .requestInsertToTQueue(requestInsertToTQueue2), .doneInsertToTQueue(doneInsertToTQueue2),
						.rData(rData2), .requestReceivedToRQueue(requestReceivedToRQueue2), .doneSavedFromRQueue(doneSavedFromRQueue2), 
						.overflowInTQueue(overflowInTQueue2), .overflowInRQueue(overflowInRQueue2), .isBusy(isBusy),
						.mosi(oPin), .miso(iPin), .nCS(nCS), .sck(sck));

  initial begin
	   clk = 1;
	   tData1 = 16'hABCD;
	   tData2 = 16'h1234;
	   requestInsertToTQueue1 = 1; requestInsertToTQueue2 = 1;
	   nRst = 0;
	
    #2 nRst = 1;
    #2 requestInsertToTQueue1 = 0; requestInsertToTQueue2 = 0;
    
    #300 $stop;
  end
	
  always #1  clk =  ! clk;
  always #5 ioClk = !ioClk;
  
  t1_isEqual_r2: assert property (@(posedge clk) $rose(requestReceivedToRQueue1) |=> (tData2 == rData1));
  t2_isEqual_r1: assert property (@(posedge clk) $rose(requestReceivedToRQueue2) |=> (tData1 == rData2));

endmodule

