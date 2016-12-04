/* MIL-STD-1553 <-> SPI bridge
 * Copyright(c) 2016 Stanislav Zhelnio
 * Licensed under the MIT license (MIT)
 * https://github.com/zhelnio/mil1553-spi
 */

`ifndef LINKSPI_INCLUDE
`define LINKSPI_INCLUDE


interface ILinkSpiControl();
 	//from ISpiReceiverControl
	logic outQueueOverflow, inQueueOverflow, spiIsBusy;

	//from IServiceProtocolDControl
	logic [7:0] inAddr;
	logic [7:0] inWordNum;
	logic [15:0] inSize;
	ServiceProtocol::TCommandCode 	inCmdCode;
	logic inPacketStart, inPacketErr, inPacketEnd;
	
	//from IServiceProtocolEControl
	logic [7:0] outAddr;
	logic outEnable;
	logic [15:0] outDataSize;	
	ServiceProtocol::TCommandCode 	outCmdCode;
	
	modport slave(	output	inCmdCode, inWordNum, inAddr, inSize,
						 	inPacketStart, inPacketErr, inPacketEnd, 
						 	spiIsBusy, outQueueOverflow, inQueueOverflow,
				  	input  	outEnable, outCmdCode, outDataSize, outAddr);
								
	modport master(	input 	inCmdCode, inWordNum, inAddr, inSize,
							inPacketStart, inPacketErr, inPacketEnd, 
							spiIsBusy, outQueueOverflow, inQueueOverflow,
				  	output 	outEnable, outCmdCode, outDataSize, outAddr);
endinterface

module LinkSpi(	input bit 		nRst, clk, 
				ISpi.slave 		spi,
				IPush.master	pushFromSpi,
				IPop.master		popToSpi,
				ILinkSpiControl.slave control);
	
	IPush rspi();
	IPush tspi();
	ISpiReceiverControl spiControl();
	SpiReceiver spiReceiver(.nRst(nRst), .clk(clk),
	                        .transmitBus(tspi.slave), .receiveBus(rspi.master),
	                        .controlBus(spiControl.slave), .spi(spi));
	
	IServiceProtocolDControl decoderControl();
	ServiceProtocolDecoder spDecoder(.nRst(nRst), .clk(clk),
	                                 .receivedData(rspi.slave), .decodedBus(pushFromSpi),
	                                 .control(decoderControl.slave));
  
	IServiceProtocolEControl encoderControl();
	ServiceProtocolEncoder spEncoder(.nRst(nRst), .clk(clk),
									 .data(popToSpi), .packet(tspi.master),
									 .control(encoderControl.slave));
  
	//ISpiReceiverControl
	assign control.spiIsBusy 		= spiControl.isBusy;
	assign control.outQueueOverflow = spiControl.overflowInTQueue;
	assign control.inQueueOverflow 	= spiControl.overflowInRQueue; 

	//IServiceProtocolDControl
	assign control.inCmdCode 		= decoderControl.cmdCode;
	assign control.inWordNum 		= decoderControl.wordNum;
	assign control.inPacketStart 	= decoderControl.packetStart;
	assign control.inPacketErr 		= decoderControl.packetErr;
	assign control.inPacketEnd 		= decoderControl.packetEnd;
	assign control.inAddr			= decoderControl.addr;
	assign control.inSize			= decoderControl.size;
	assign decoderControl.enable	= spiControl.isBusy;

	//IServiceProtocolEControl
	assign encoderControl.cmdCode	= control.outCmdCode;
	assign encoderControl.addr 		= control.outAddr;
	assign encoderControl.enable	= control.outEnable;
	assign encoderControl.size		= control.outDataSize;

endmodule
	
`endif
