`timescale 10 ns/ 1 ns

module test_serviceProtocolUnpacker();
	bit rst, clk;

	//debug spi transmitter
	ISpi spiBus();
	IPushMasterDebug 		spiDebug(clk);
	DebugSpiTransmitter 	spiTrans(rst, clk, spiDebug, spiBus);
	
	//receiver and unpacker
	IPush spiSlaveOut();
	IPush spiSlaveIn();
	ISpiReceiverControl spiReceiverControl();
	
	spiReceiver spiR(rst, clk, 
						  spiSlaveOut.slave, 
						  spiSlaveIn.master, 
						  spiReceiverControl.slave,
						  spiBus.slave);	
				  
	IPush milBusDecoded();
	IServiceProtocolUControl servProtoControl();
				  
	ServiceProtocolUnpacker serviceUnpacker(rst, clk, 
															spiSlaveIn.slave,
															milBusDecoded.master,
															servProtoControl.slave);
	
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
