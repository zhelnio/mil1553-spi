`timescale 10 ns/ 1 ns

module test_serviceProtocolUnpacker();
  import ServiceProtocol::*;
	bit rst, clk;

	//debug spi transmitter
	ISpi spiBus();
	IPush spiPush();
	IPushHelper 		spiHelper(clk, spiPush);
	DebugSpiTransmitter 	spiTrans(rst, clk, spiPush, spiBus);
	
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
    clk = 0; rst = 1;
    #2 rst = 0; 
	
    fork
      begin
				$display("TransmitOverSpi Start");	
			
				spiHelper.doPush(16'hAB00);	
				spiHelper.doPush(16'h02A2); 
				spiHelper.doPush(16'hEFAB); 
				spiHelper.doPush(16'h0001); 
				spiHelper.doPush(16'h9D4E); 
				spiHelper.doPush(16'h0000);
			
				$display("TransmitOverSpi End");	
			end

      begin
        @(servProtoControl.packetStart);
        assert( servProtoControl.moduleAddr == 8'hAB ); 
        assert( servProtoControl.cmdCode == TCC_SEND_DATA ); //A2
      end
    
    join
  end
	
	always #1  clk =  ! clk;

endmodule
