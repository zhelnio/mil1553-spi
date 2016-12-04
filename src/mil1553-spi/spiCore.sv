/* MIL-STD-1553 <-> SPI bridge
 * Copyright(c) 2016 Stanislav Zhelnio
 * Licensed under the MIT license (MIT)
 * https://github.com/zhelnio/mil1553-spi
 */

`include "settings.sv"

`ifndef SPI_CORE_INCLUDE
`define SPI_CORE_INCLUDE

module spiCore(input  bit nRst, clk, spiClk,
					input  logic[`DATAW_TOP:0] tData,
					output logic[`DATAW_TOP:0] rData,
					input  logic nCS, iPin,
					output logic tDone, rDone, oPin, tFinish);
					
	logic[`DATAW_TOP:0] tBuffer, rBuffer;
	logic[`DATAC_TOP:0] cntr;
	logic clkUp, clkDown;

	enum logic[4:0] {	IDLE 		= 5'b00001, 
						LOAD 		= 5'b00010, 
						TRANSMIT 	= 5'b00100, 
						READ 		= 5'b01000, 
						SAVE 		= 5'b10000	} State, Next;
	
	upFront		upStrobe(nRst, clk, spiClk, clkUp);
	downFront	downStrobe(nRst, clk, spiClk, clkDown);

	assign oPin = (State != IDLE) ? tBuffer[`DATAW_TOP] : 1'bz;
	assign tFinish = (clkDown && State == SAVE);

	always_ff @ (posedge clk)
		if(!nRst | nCS)
			State <= IDLE;
		else
			State <= Next;

	always_ff @ (posedge clk) begin
		unique case(State)
			IDLE:			begin rBuffer <= 0; {tDone, rDone} <= '0; end
			LOAD:			begin tBuffer <= tData; cntr <= 0; tDone <= 1; end
			READ:			if(clkUp) 	rBuffer <= {rBuffer[(`DATAW_TOP - 1):0], iPin};
			TRANSMIT:	if(clkDown) begin	tBuffer <= tBuffer << 1; cntr <= cntr + 1'b1; end
			SAVE:			;
		endcase
		
		if(State == READ && Next == SAVE)
			begin rData <= {rBuffer[(`DATAW_TOP - 1):0], iPin}; rDone <= 1; end
		
		if({tDone, rDone} != '0)
			{tDone, rDone} <= '0;
	end
		
	always_comb begin
		Next = State;
		unique case(State)
			IDLE:			if(!nCS) 	Next = LOAD;
			LOAD:			Next = READ;
			READ:			if(clkUp)	Next = (cntr == '1) ? SAVE : TRANSMIT;
			
			TRANSMIT:	if(clkDown) Next = READ;
			
			SAVE:			if(clkDown) Next = LOAD;
		endcase
	end
endmodule


module spiMaster(	input  bit nRst, clk, spiClk,
						input  logic[`DATAW_TOP:0] tData, input logic requestInsertToTQueue, output logic doneInsertToTQueue,
						output logic[`DATAW_TOP:0] rData, output logic requestReceivedToRQueue, input logic doneSavedFromRQueue,
						output logic overflowInTQueue, overflowInRQueue,
						input  logic miso, 
						output logic mosi, nCS, sck);
	
	logic _nCS, _wordInTransmitQueue, _wordInReceiveQueue, _transmissionFinished, _doneInsertToTQueue;
	logic clkUp;

	logic _miso;
	inputFilter	iFilter0(nRst, clk, miso, _miso);
	
	assign nCS = _nCS;
	assign sck = (!nCS) ? spiClk : 1'b1;
	
	assign overflowInTQueue = _wordInTransmitQueue & requestInsertToTQueue;
	assign overflowInRQueue = _wordInReceiveQueue & requestReceivedToRQueue;
	assign doneInsertToTQueue = (_wordInTransmitQueue) ? _doneInsertToTQueue : 1'b0;
	
	upFront		upStrobe(nRst, clk, spiClk, clkUp);
	
	always_ff @ (posedge clk) begin
		if(!nRst) begin
			{_wordInTransmitQueue, _wordInReceiveQueue} <= '0;
			_nCS <= 1;
			end
		else begin
			if(requestInsertToTQueue)
				_wordInTransmitQueue <= 1'b1;
			if(_doneInsertToTQueue & !requestInsertToTQueue)
				_wordInTransmitQueue <= 1'b0;
			
			if(requestReceivedToRQueue)
				_wordInReceiveQueue <= 1'b1;
			if(doneSavedFromRQueue & !requestReceivedToRQueue)
				_wordInReceiveQueue <= 1'b0;
				
			if((_wordInTransmitQueue | requestInsertToTQueue) & _nCS & clkUp)
				_nCS <= 1'b0;
			if(_transmissionFinished & !_wordInTransmitQueue)
				_nCS <= 1'b1;
		end
	end
	
	spiCore	spi( .nRst(nRst), .clk(clk), .spiClk(spiClk), 
	             .tData(tData), .rData(rData), .nCS(_nCS), .iPin(_miso), 
					     .tDone(_doneInsertToTQueue), .rDone(requestReceivedToRQueue), 
					     .oPin(mosi), .tFinish(_transmissionFinished));
endmodule

module spiSlave (input  bit nRst, clk, 
					  input  logic[`DATAW_TOP:0] tData, input logic requestInsertToTQueue, output logic doneInsertToTQueue,
					  output logic[`DATAW_TOP:0] rData, output logic requestReceivedToRQueue, input logic doneSavedFromRQueue,
					  output logic overflowInTQueue, overflowInRQueue, isBusy,
					  input  logic mosi, 
					  output logic miso, 
					  input logic nCS, sck);
	
	logic _wordInTransmitQueue, _wordInReceiveQueue, _transmitFinished, _doneInsertToTQueue;

	logic _mosi, _nCS, _sck;
	inputFilter	iFilter0(nRst, clk, mosi, _mosi);
	inputFilter	iFilter1(nRst, clk, nCS, _nCS);
	inputFilter	iFilter2(nRst, clk, sck, _sck);
	
	logic[`DATAW_TOP:0] _tData;
	assign _tData = (_wordInTransmitQueue | requestInsertToTQueue) ? tData : '0; //'1; //'0;
	
	assign overflowInTQueue = _wordInTransmitQueue & requestInsertToTQueue;
	assign overflowInRQueue = _wordInReceiveQueue & requestReceivedToRQueue;
	assign doneInsertToTQueue = (_wordInTransmitQueue) ? _doneInsertToTQueue : 1'b0;
	assign isBusy = !_nCS;
		
	always_ff @ (posedge clk) begin
		if(!nRst)
			{_wordInTransmitQueue, _wordInReceiveQueue} <= '0;
		else begin
			if(requestInsertToTQueue)
				_wordInTransmitQueue <= 1'b1;
			if(_doneInsertToTQueue & !requestInsertToTQueue)
				_wordInTransmitQueue <= 1'b0;
				
			if(requestReceivedToRQueue)
				_wordInReceiveQueue <= 1'b1;
			if(doneSavedFromRQueue & !requestReceivedToRQueue)
				_wordInReceiveQueue <= 1'b0;
		end
	end
	
	spiCore	spi( .nRst(nRst), .clk(clk), .spiClk(_sck), 
	             .tData(_tData), .rData(rData), .nCS(_nCS), .iPin(_mosi), 
					     .tDone(_doneInsertToTQueue), .rDone(requestReceivedToRQueue), 
					     .oPin(miso), .tFinish(_transmitFinished));
endmodule

`endif