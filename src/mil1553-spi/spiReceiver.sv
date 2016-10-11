`ifndef SPI_RECEIVER_INCLUDE
`define SPI_RECEIVER_INCLUDE

interface ISpiReceiverControl();
	logic overflowInTQueue, overflowInRQueue, isBusy;
	
	modport master (input overflowInTQueue, overflowInRQueue, isBusy);
	modport slave (output overflowInTQueue, overflowInRQueue, isBusy);
endinterface


module spiReceiver(input  bit rst, clk,
						 IPush.slave 	transmitBus,
						 IPush.master 	receiveBus,
						 ISpiReceiverControl.slave controlBus,
						 ISpi.slave spi);

	spiSlave spis(.rst(rst), .clk(clk),
					  .tData(transmitBus.data), 	.requestInsertToTQueue(transmitBus.request),	.doneInsertToTQueue(transmitBus.done),
					  .rData(receiveBus.data), 	.requestReceivedToRQueue(receiveBus.request),	.doneSavedFromRQueue(receiveBus.done),
					  .overflowInTQueue(controlBus.overflowInTQueue), .overflowInRQueue(controlBus.overflowInRQueue), .isBusy(controlBus.isBusy),
					  .mosi(spi.mosi), .miso(spi.miso), .nCS(spi.nCS), .sck(spi.sck));
endmodule

`endif