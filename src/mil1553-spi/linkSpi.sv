`ifndef LINKSPI_INCLUDE
`define LINKSPI_INCLUDE


interface ILinkSpiControl();
  //from ISpiReceiverControl
	logic overflowInTQueue, overflowInRQueue, spiReceiverIsBusy;

	//from IServiceProtocolDControl
	logic [7:0] inputAddr, dataWordNum;
	ServiceProtocol::TCommandCode 	cmdCode;
	logic packetStart, packetErr, packetEnd;
	
	//from IServiceProtocolEControl
	logic [7:0] moduleAddr;
	logic spiTransmitEnable;
	logic[15:0] spiTransmitDataSize;	
	
	modport slave(output moduleAddr, cmdCode, dataWordNum, packetStart, 
								packetErr, packetEnd, spiReceiverIsBusy, 
								overflowInTQueue, overflowInRQueue,
						input spiTransmitEnable, spiTransmitDataSize);
								
	modport master(input moduleAddr, cmdCode, dataWordNum, packetStart, 
								packetErr, packetEnd, spiReceiverIsBusy, 
								overflowInTQueue, overflowInRQueue,
					  output spiTransmitEnable, spiTransmitDataSize);
endinterface

module LinkSpi(	input bit rst, clk, 
								ISpi.slave 		spi,
								IPush.master	pushFromSpi,
								IPop.master		popToSpi,
                ILinkSpiControl.slave control);
	
	IPush rspi();
	IPush tspi();
	ISpiReceiverControl spiControl();
	SpiReceiver spiReceiver(.rst(rst), .clk(clk),
	                        .transmitBus(tspi.slave), .receiveBus(rspi.master),
	                        .controlBus(spiControl.slave), .spi(spi));
	
	IServiceProtocolDControl decoderControl();
	ServiceProtocolDecoder(.rst(rst), .clk(clk),
	                       .receivedData(rspi.slave), .decodedBus(pushFromSpi),
	                       .control(decoderControl.slave));
  
  IServiceProtocolEControl encoderControl();
  ServiceProtocolEncoder(.rst(rst), .clk(clk),
                         .data(popToSpi), .packet(tspi.master),
                         .control(encoderControl.slave));
  
  //ISpiReceiverControl
  assign control.spiReceiverIsBusy = spiControl.isBusy;
	assign control.overflowInTQueue 	= spiControl.overflowInTQueue;
	assign control.overflowInRQueue 	= spiControl.overflowInRQueue; 
  
  //IServiceProtocolDControl
 	assign control.inputAddr			= decoderControl.moduleAddr;
	assign control.cmdCode 				= decoderControl.cmdCode;
	assign control.dataWordNum 		= decoderControl.dataWordNum;
	assign control.packetStart 		= decoderControl.packetStart;
	assign control.packetErr 			= decoderControl.packetErr;
	assign control.packetEnd 			= decoderControl.packetEnd;
	assign decoderControl.spiReceiverIsBusy = spiControl.isBusy;
	
	//IServiceProtocolEControl
	assign encoderControl.cmdCode 		= decoderControl.cmdCode;
	assign encoderControl.moduleAddr 	= control.moduleAddr;
	assign encoderControl.enable		= control.spiTransmitEnable;
	assign encoderControl.size			= control.spiTransmitDataSize;

endmodule
	
`endif
