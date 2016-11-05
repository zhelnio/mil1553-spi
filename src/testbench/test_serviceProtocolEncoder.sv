`timescale 10 ns/ 1 ns

module test_serviceProtocolEncoder();
	bit nRst, clk;

	//debug spi transmitter
	ISpi spiBus();
	IPushMasterDebug 		spiDebug(clk);
	DebugSpiTransmitter 	spiTrans(nRst, clk, spiDebug, spiBus);
	
	//receiver and unpacker
	IPush spiSlaveOut();
	IPush spiSlaveIn();
	ISpiReceiverControl spiReceiverControl();
	
	SpiReceiver spiR(nRst, clk, 
						  spiSlaveOut.slave, 
						  spiSlaveIn.master, 
						  spiReceiverControl.slave,
						  spiBus.slave);	
				  
	IPush decodedBus();
	IServiceProtocolDControl servProtoControl();
				  
/*
module ServiceProtocolDecoder(input bit nRst, clk,
										IPush.slave receivedData,
										IPush.master decodedBus,
										IServiceProtocolDControl.slave control);
*/				  
				  
	ServiceProtocolDecoder serviceDecoder(nRst, clk, 
															spiSlaveIn.slave,
															decodedBus.master,
															servProtoControl.slave);
															
	IPushMil decodeBus();
	IServiceProtocolEControl servEncoderControl();
	
/*
module ServiceProtocolEncoder(input bit nRst, clk,
										IPop.master 	data,
										IPush.master 	packet,
										IServiceProtocolEControl control);
*/
	
	ServiceProtocolEncoder serviceEncoder(	nRst, clk, 
														decodedBus.slave,
														decodeBus.master,
														servEncoderControl.slave);
	
	assign servDecoderControl.master.cmdCode = servUnpackerControl.master.cmdCode;
	assign servDecoderControl.master.dataWordNum = servUnpackerControl.master.dataWordNum;
	
	//testbench
	initial begin
	clk = 0;
	nRst = 1;
	
	#2 nRst = 0; 
	  
	begin
				$display("TransmitOverSpi Start");	
			
				spiDebug.doPush(16'hAB00);	
				spiDebug.doPush(16'h02A2); 
				spiDebug.doPush(16'hEFAB); 
				spiDebug.doPush(16'h0001); 
				spiDebug.doPush(16'h9D4E); 
				spiDebug.doPush(16'h0000);
			
				$display("TransmitOverSpi End");	
			end
	end
	
	always #1  clk =  ! clk;

endmodule
