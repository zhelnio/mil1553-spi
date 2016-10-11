`include "settings.sv"

`ifndef SPI_CORE_INCLUDE
`define SPI_CORE_INCLUDE

module spiCore(input  bit rst, clk, spiClk,
					input  logic[`DATAW_TOP:0] tData,
					output logic[`DATAW_TOP:0] rData,
					input  logic nCS, iPin,
					output logic tDone, rDone, oPin, tFinish);
					
	logic[`DATAW_TOP:0] tBuffer, rBuffer;
	logic[`DATAC_TOP:0] cntr;
	logic clkUp, clkDown, _iPin;

	enum logic[2:0] {IDLE = 3'h1, LOAD = 3'h2, TRANSMIT = 3'h3, READ = 3'h4, SAVE = 3'h5} State, Next;
	
	upFront		upStrobe(rst, clk, spiClk, clkUp);
	downFront	downStrobe(rst, clk, spiClk, clkDown);
	inputFilter	iFilter(rst, clk, iPin, _iPin);
	
	assign oPin = (State != IDLE) ? tBuffer[`DATAW_TOP] : 1'bz;
	assign tFinish = (clkDown && State == SAVE);

	always_ff @ (posedge clk)
		if(rst | nCS)
			State <= IDLE;
		else
			State <= Next;

	always_ff @ (posedge clk) begin
		unique case(State)
			IDLE:			begin rBuffer <= 0; {tDone, rDone} <= '0; end
			LOAD:			begin tBuffer <= tData; cntr <= 0; tDone <= 1; end
			READ:			if(clkUp) 	rBuffer <= {rBuffer[(`DATAW_TOP - 1):0], _iPin};
			TRANSMIT:	if(clkDown) begin	tBuffer <= tBuffer << 1; cntr <= cntr + 1'b1; end
			SAVE:			;
		endcase
		
		if(State == READ && Next == SAVE)
			begin rData <= {rBuffer[(`DATAW_TOP - 1):0], _iPin}; rDone <= 1; end
		
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


module spiMaster(	input  bit rst, clk, spiClk,
						input  logic[`DATAW_TOP:0] tData, input logic requestInsertToTQueue, output logic doneInsertToTQueue,
						output logic[`DATAW_TOP:0] rData, output logic requestReceivedToRQueue, input logic doneSavedFromRQueue,
						output logic overflowInTQueue, overflowInRQueue,
						input  logic miso, 
						output logic mosi, nCS, sck);
	
	logic _nCS, _wordInTransmitQueue, _wordInReceiveQueue, _transmissionFinished, _doneInsertToTQueue;
	logic clkUp;
	
	assign nCS = _nCS;
	assign sck = (!nCS) ? spiClk : 1'b1;
	
	assign overflowInTQueue = _wordInTransmitQueue & requestInsertToTQueue;
	assign overflowInRQueue = _wordInReceiveQueue & requestReceivedToRQueue;
	assign doneInsertToTQueue = (_wordInTransmitQueue) ? _doneInsertToTQueue : 1'b0;
	
	upFront		upStrobe(rst, clk, spiClk, clkUp);
	
	always_ff @ (posedge clk) begin
		if(rst) begin
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
	
	spiCore	spi( .rst(rst), .clk(clk), .spiClk(spiClk), 
	             .tData(tData), .rData(rData), .nCS(_nCS), .iPin(miso), 
					     .tDone(_doneInsertToTQueue), .rDone(requestReceivedToRQueue), 
					     .oPin(mosi), .tFinish(_transmissionFinished));
endmodule

module spiSlave (input  bit rst, clk, 
					  input  logic[`DATAW_TOP:0] tData, input logic requestInsertToTQueue, output logic doneInsertToTQueue,
					  output logic[`DATAW_TOP:0] rData, output logic requestReceivedToRQueue, input logic doneSavedFromRQueue,
					  output logic overflowInTQueue, overflowInRQueue, isBusy,
					  input  logic mosi, 
					  output logic miso, 
					  input logic nCS, sck);
	
	logic _wordInTransmitQueue, _wordInReceiveQueue, _transmitFinished, _doneInsertToTQueue;
	
	logic[`DATAW_TOP:0] _tData;
	assign _tData = (_wordInTransmitQueue | requestInsertToTQueue) ? tData : '0;
	
	assign overflowInTQueue = _wordInTransmitQueue & requestInsertToTQueue;
	assign overflowInRQueue = _wordInReceiveQueue & requestReceivedToRQueue;
	assign doneInsertToTQueue = (_wordInTransmitQueue) ? _doneInsertToTQueue : 1'b0;
	assign isBusy = !nCS;
		
	always_ff @ (posedge clk) begin
		if(rst)
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
	
	spiCore	spi( .rst(rst), .clk(clk), .spiClk(sck), 
	             .tData(_tData), .rData(rData), .nCS(nCS), .iPin(mosi), 
					     .tDone(_doneInsertToTQueue), .rDone(requestReceivedToRQueue), 
					     .oPin(miso), .tFinish(_transmitFinished));
endmodule

`endif