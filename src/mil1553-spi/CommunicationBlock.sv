`ifndef COMBLOCK_INCLUDE
`define COMBLOCK_INCLUDE


interface ICommunicationBlockControl();
	//from IServiceProtocolUControl
	logic [7:0] moduleAddr, dataWordNum;
	ServiceProtocol::TCommandCode 	cmdCode;
	logic packetStart, packetErr, packetEnd, spiReceiverIsBusy;
	
	//from ISpiReceiverControl
	logic overflowInTQueue, overflowInRQueue;
	
	//from IServiceProtocolEControl
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

module CommunicationBlock(	input bit rst, clk, 
									ISpi.slave 		spiBus,
									IMilStd.device	milBus,
									
									IPush.master	pushFromSpi,
									IPush.master	pushFromMil,
									IPop.master		popToSpi,
									IPush.slave		pushToMil,

									ICommunicationBlockControl.slave control);
	
	IPush 							spiToMemPackedBus();
	ISpiReceiverControl 			spiReceiverControl();
	IServiceProtocolUControl 	servUnpackerControl();
	
	IPush								memToSpiPackedBus();
	
	spiReceiver spiR(rst, clk, 
						  memToSpiPackedBus, 
						  spiToMemPackedBus.master, 
						  spiReceiverControl.slave,
						  spiBus);	
	
	ServiceProtocolUnpacker serviceUnpacker(rst, clk, 
														 spiToMemPackedBus.slave,
														 pushFromSpi,
														 servUnpackerControl);						 

	assign servUnpackerControl.spiReceiverIsBusy	= 	spiReceiverControl.isBusy;	
	
	assign control.moduleAddr			= servUnpackerControl.moduleAddr;
	assign control.cmdCode 				= servUnpackerControl.cmdCode;
	assign control.dataWordNum 		= servUnpackerControl.dataWordNum;
	assign control.packetStart 		= servUnpackerControl.packetStart;
	assign control.packetErr 			= servUnpackerControl.packetErr;
	assign control.packetEnd 			= servUnpackerControl.packetEnd;
	assign control.spiReceiverIsBusy = spiReceiverControl.isBusy;
	assign control.overflowInTQueue 	= spiReceiverControl.overflowInTQueue;
	assign control.overflowInRQueue 	= spiReceiverControl.overflowInRQueue;
	
	IMilStdControl milControl();
	IPushMil milToMemEncodeBus();
	IPushMil memToMilEncodeBus();
	
	MilStd milStd(rst, clk,
					  milToMemEncodeBus.master,
					  memToMilEncodeBus.slave,
					  milBus,
					  milControl);
	
	milMemEncoder milToMemEncoder(rst, clk,
											milToMemEncodeBus.slave,
											pushFromMil);
	
	MemMilEncoder	memMilEncoder(rst, clk,
											 memToMilEncodeBus.master,
											 pushToMil);
	
	
	///
	IServiceProtocolDControl spDecoderControl();
	ServiceProtocolDecoder servProtDecoder(rst, clk, 
														popToSpi, memToSpiPackedBus, spEncoderControl);
														
	assign spDecoderControl.cmdCode 		= servUnpackerControl.cmdCode;
	assign spDecoderControl.moduleAddr 	= servUnpackerControl.moduleAddr;
	assign spDecoderControl.enable		= control.spiTransmitEnable;
	assign spDecoderControl.size			= control.spiTransmitDataSize;

endmodule
	
`endif