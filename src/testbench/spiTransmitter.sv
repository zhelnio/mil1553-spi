`ifndef SPI_TRANSMITTER_INCLUDE
`define SPI_TRANSMITTER_INCLUDE



interface ISpiTransmitterControl();
	logic overflowInTQueue, overflowInRQueue;
	
	modport master (input overflowInTQueue, overflowInRQueue);
	modport slave (output overflowInTQueue, overflowInRQueue);
endinterface

module spiTransmitter(	input  bit rst, clk,
								IPush.slave 	transmitBus,
								IPush.master 	receiveBus,
								ISpiTransmitterControl.slave controlBus,
								ISpi.master 	spi);
	logic ioClk;
  
	spiIoClkGenerator	gen(rst, clk, ioClk);
	
	spiMaster	spim(	.rst(rst), .clk(clk), .spiClk(ioClk),
							.tData(transmitBus.data), .requestInsertToTQueue(transmitBus.request),	.doneInsertToTQueue(transmitBus.done),
							.rData(receiveBus.data), 	.requestReceivedToRQueue(receiveBus.request),	.doneSavedFromRQueue(receiveBus.done),
							.overflowInTQueue(controlBus.overflowInTQueue), .overflowInRQueue(controlBus.overflowInRQueue),
							.miso(spi.miso), .mosi(spi.mosi), .nCS(spi.nCS), .sck(spi.sck));
endmodule

module spiIoClkGenerator(input bit rst, clk, 
								 output logic ioClk);
		
		parameter period = 8;
		
		logic [5:0] cntr, nextCntr;
		
		assign nextCntr = (cntr == period) ? 0 : (cntr + 1);
		
		always_ff @ (posedge clk)
		if(rst) 
			{cntr, ioClk} <= '0;
		else begin
			cntr <= nextCntr;
			if(nextCntr == 0)
				ioClk = !ioClk;
		end
endmodule

`endif