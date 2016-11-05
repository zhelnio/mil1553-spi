/* MIL-STD-1553 <-> SPI converter
 * Copyright(c) 2016 Stanislav Zhelnio
 * Licensed under the MIT license (MIT)
 * https://github.com/zhelnio/mil1553-spi
 */

`timescale 1 ns/ 100 ps

module test_linkSpi();
	
	import milStd1553::*;
	import ServiceProtocol::*;
	
	bit nRst, clk;
	ISpi     spi();
	
	//debug spi transmitter
	IPush        	spiPush();
	IPush        	spiRcvd();
	IPushHelper 	spiDebug(clk, spiPush);
	DebugSpiTransmitter	spiTrans(nRst, clk, spiPush, spiRcvd, spi);
	
	//DUT modules
	IPush pushFromSpi();
	IPop popToSpi();
	ILinkSpiControl  control();
	
	LinkSpi linkSpi(.nRst(nRst), .clk(clk),
	                .spi(spi), 
	                .pushFromSpi(pushFromSpi),
	                .popToSpi(popToSpi),
	                .control(control));
  
	assign control.outEnable 	= 0;
	assign control.outAddr	= 8'hAB;

	initial begin
	
		nRst = 0;
	#20 nRst = 1;
	fork
		begin
			#160000 //max test duration
			$stop();
		end

		begin //tests sequence
			fork //send data to spi Mil
				begin
					$display("TransmitOverSpi Start");	
				
					spiDebug.doPush(16'hAB00);	//addr = AB
					spiDebug.doPush(16'h06A2);  //size = 0006, cmd = A2
					spiDebug.doPush(16'hFFA1); 
					spiDebug.doPush(16'h0001); 
					
					spiDebug.doPush(16'h0002);
					spiDebug.doPush(16'hAB45);
					spiDebug.doPush(16'hFFA3);
					spiDebug.doPush(16'hFFA1);
					
					spiDebug.doPush(16'h5BCF);	//check sum
					spiDebug.doPush(16'h0);		//word num
					
					$display("TransmitOverSpi End");	
				end

				begin
					assert( control.inCmdCode == TCC_UNKNOWN);
					@(posedge control.inPacketStart);
					assert( control.inAddr == 8'hAB);
					assert( control.inCmdCode == TCC_SEND_DATA);
					@(posedge control.inPacketEnd);
					assert( 1 == 1);
					@(control.inCmdCode == TCC_UNKNOWN);
					assert( 1 == 1);
					$display("TransmitOverSpi command decode Ok");
				end

				begin
					@(posedge pushFromSpi.request);
					assert( control.inWordNum == 8'd0);
					assert( pushFromSpi.data == 16'hFFA1);
					@(posedge pushFromSpi.request);
					assert( control.inWordNum == 8'd1);
					assert( pushFromSpi.data == 16'h0001);
					@(posedge pushFromSpi.request);
					assert( control.inWordNum == 8'd2);
					assert( pushFromSpi.data == 16'h0002);
					@(posedge pushFromSpi.request);
					assert( control.inWordNum == 8'd3);
					assert( pushFromSpi.data == 16'hAB45);
					@(posedge pushFromSpi.request);
					assert( control.inWordNum == 8'd4);
					assert( pushFromSpi.data == 16'hFFA3);
					@(posedge pushFromSpi.request);
					assert( control.inWordNum == 8'd5);
					assert( pushFromSpi.data == 16'hFFA1);
					$display("TransmitOverSpi data decode Ok");
				end
			join //send data to spi Mil
				
			fork //current status request
				begin
					$display("GetStatus Start");	
				
					spiDebug.doPush(16'hAB00);	//addr = AB
					spiDebug.doPush(16'h0AB0);  //size = 000A, cmd = B0				
					spiDebug.doPush(16'h0);		//blank data to receive reply
					spiDebug.doPush(16'h0);		
					spiDebug.doPush(16'h0);		
					spiDebug.doPush(16'h0);		
					spiDebug.doPush(16'h0);		
					spiDebug.doPush(16'h0);	
					spiDebug.doPush(16'h0);		
					spiDebug.doPush(16'h0);		
					spiDebug.doPush(16'h0);		
					spiDebug.doPush(16'h0);
					spiDebug.doPush(16'hB5B0);	//check sum
					spiDebug.doPush(16'h0);		//word num
				
					$display("GetStatus End");		
				end

				begin
					assert( control.inCmdCode == TCC_UNKNOWN)
					@(posedge control.inPacketStart);
					assert( control.inAddr == 8'hAB);
					assert( control.inCmdCode == TCC_RECEIVE_STS);
					@(posedge control.inPacketEnd);
					assert( 1 == 1);
					@(control.inCmdCode == TCC_UNKNOWN);
					assert( 1 == 1);
					$display("GetStatus command decode Ok");
				end
			join //current status request
				
			fork //get data that was received from Mil
				begin
					$display("ReceiveOverSpi Start");	
				
					spiDebug.doPush(16'hAB00);	//addr = AB
					spiDebug.doPush(16'h0AB2);	//size = 000A, cmd = B2				
					spiDebug.doPush(16'h0);		//blank data to receive reply
					spiDebug.doPush(16'h0);		
					spiDebug.doPush(16'h0);		
					spiDebug.doPush(16'h0);		
					spiDebug.doPush(16'h0);		
					spiDebug.doPush(16'h0);	
					spiDebug.doPush(16'h0);		
					spiDebug.doPush(16'h0);		
					spiDebug.doPush(16'h0);		
					spiDebug.doPush(16'h0);
					spiDebug.doPush(16'hB5B2);	//check sum
					spiDebug.doPush(16'h0);		//word num
				
					$display("ReceiveOverSpi End");		
				end

				begin
					assert( control.inCmdCode == TCC_UNKNOWN);
					@(posedge control.inPacketStart);
					assert( control.inAddr == 8'hAB);
					assert( control.inCmdCode == TCC_RECEIVE_DATA);
					@(posedge control.inPacketEnd);
					assert( 1 == 1);
					@(control.inCmdCode == TCC_UNKNOWN);
					assert( 1 == 1);
					$display("ReceiveOverSpi command decode Ok");
				end
			join //get data that was received from Mil
				
			fork //system reset, incorrect addr, the cmd should be ignored
				begin
					$display("Reset1 Start");	
				
					spiDebug.doPush(16'h0100);	//addr = 01
					spiDebug.doPush(16'h00A0);	//size = 0000, cmd = A2				
					spiDebug.doPush(16'h01A0);	//check sum
					spiDebug.doPush(16'h0);		//word num
				
					$display("Reset1 End");		
				end

				begin
					assert( control.inCmdCode == TCC_UNKNOWN);
					@(posedge control.inPacketStart);
					assert( control.inAddr == 8'h01);
					assert( control.inCmdCode == TCC_RESET);
					@(posedge control.inPacketEnd);
					assert( 1 == 1);
					@(control.inCmdCode == TCC_UNKNOWN);
					assert( 1 == 1);
					$display("Reset1 command decode Ok");
				end
			join //system reset, incorrect addr, the cmd should be ignored
				
			fork //system reset
				begin
					$display("Reset2 Start");	
				
					spiDebug.doPush(16'hAB00);	//addr = AB
					spiDebug.doPush(16'h00A0);	//size = 0000, cmd = A2	
					spiDebug.doPush(16'hABA0);	//check sum
					spiDebug.doPush(16'h0);		//word num	
				
					$display("Reset2 End");		
				end
				begin
					assert( control.inCmdCode == TCC_UNKNOWN);
					@(posedge control.inPacketStart);
					assert( control.inAddr == 8'hAB);
					assert( control.inCmdCode == TCC_RESET);
					@(posedge control.inPacketEnd);
					assert( 1 == 1);
					@(control.inCmdCode == TCC_UNKNOWN);
					assert( 1 == 1);
					$display("Reset2 command decode Ok");
				end
			join //system reset
		end //tests sequence
	join
	end

	always #5  clk =  ! clk;

endmodule
