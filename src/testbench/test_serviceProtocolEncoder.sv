`timescale 10 ns/ 1 ns

module test_serviceProtocolEncoder();
	bit rst, clk;

	//debug spi transmitter
	ISpi spiBus();
	IPushMasterDebug 		spiDebug(clk);
	DebugSpiTransmitter 	spiTrans(rst, clk, spiDebug, spiBus);
	
	//receiver and unpacker
	IPush spiSlaveOut();
	IPush spiSlaveIn();
	ISpiReceiverControl spiReceiverControl();
	
	SpiReceiver spiR(rst, clk, 
						  spiSlaveOut.slave, 
						  spiSlaveIn.master, 
						  spiReceiverControl.slave,
						  spiBus.slave);	
				  
	IPush decodedBus();
	IServiceProtocolDControl servProtoControl();
				  
/*
module ServiceProtocolDecoder(input bit rst, clk,
										IPush.slave receivedData,
										IPush.master decodedBus,
										IServiceProtocolDControl.slave control);
*/				  
				  
	ServiceProtocolDecoder serviceDecoder(rst, clk, 
															spiSlaveIn.slave,
															decodedBus.master,
															servProtoControl.slave);
															
	IPushMil decodeBus();
	IServiceProtocolEControl servEncoderControl();
	
/*
module ServiceProtocolEncoder(input bit rst, clk,
										IPop.master 	data,
										IPush.master 	packet,
										IServiceProtocolEControl control);
*/
	
	ServiceProtocolEncoder serviceEncoder(	rst, clk, 
														decodedBus.slave,
														decodeBus.master,
														servEncoderControl.slave);
	
	assign servDecoderControl.master.cmdCode = servUnpackerControl.master.cmdCode;
	assign servDecoderControl.master.dataWordNum = servUnpackerControl.master.dataWordNum;
	
	//testbench
	initial begin
	clk = 0;
	rst = 1;
	
	#2 rst = 0; 
	  
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
