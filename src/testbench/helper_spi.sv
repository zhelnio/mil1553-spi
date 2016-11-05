`include "settings.sv"

`ifndef HELPSPI_INCLUDE
`define HELPSPI_INCLUDE

module DebugSpiTransmitter(input bit nRst, clk,
									IPush.slave push,
									ISpi spi);
	
	IPush receiveBus();
	ISpiTransmitterControl control();
	
	spiTransmitter spiTrans(nRst, clk,
									        push, receiveBus,
									        control, spi);
	
	always_ff @ (posedge clk) begin
	  
		if(receiveBus.request) begin
			$display("IPushMasterDebug %m --> %h", receiveBus.data);	
			receiveBus.done <= '1;
		end
		
		if(receiveBus.done)
			receiveBus.done <= '0;
	end												
									
endmodule

interface ISpiTransmitterControl();
	logic overflowInTQueue, overflowInRQueue;
	
	modport master (input overflowInTQueue, overflowInRQueue);
	modport slave (output overflowInTQueue, overflowInRQueue);
endinterface

module spiTransmitter(	input  bit nRst, clk,
								IPush.slave 	transmitBus,
								IPush.master 	receiveBus,
								ISpiTransmitterControl.slave controlBus,
								ISpi.master 	spi);
	logic ioClk;
  
	spiIoClkGenerator	gen(nRst, clk, ioClk);
	
	spiMaster	spim(	.nRst(nRst), .clk(clk), .spiClk(ioClk),
							.tData(transmitBus.data), .requestInsertToTQueue(transmitBus.request),	.doneInsertToTQueue(transmitBus.done),
							.rData(receiveBus.data), 	.requestReceivedToRQueue(receiveBus.request),	.doneSavedFromRQueue(receiveBus.done),
							.overflowInTQueue(controlBus.overflowInTQueue), .overflowInRQueue(controlBus.overflowInRQueue),
							.miso(spi.miso), .mosi(spi.mosi), .nCS(spi.nCS), .sck(spi.sck));
endmodule

module spiIoClkGenerator(	input bit nRst, clk, 
							output logic ioClk);
		
		parameter period = 8;
		
		logic [5:0] cntr, nextCntr;
		
		assign nextCntr = (cntr == period) ? 0 : (cntr + 1);
		
		always_ff @ (posedge clk)
		if(!nRst) 
			{cntr, ioClk} <= '0;
		else begin
			cntr <= nextCntr;
			if(nextCntr == 0)
				ioClk = !ioClk;
		end
endmodule


`endif