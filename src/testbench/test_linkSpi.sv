`timescale 1 ns/ 100 ps

module test_linkSpi();
	
	import milStd1553::*;
	
	bit nRst, clk;
	ISpi     spi();
	
	//debug spi transmitter
	IPush        spiPush();
	IPushHelper 	spiDebug(clk, spiPush);
	DebugSpiTransmitter 	spiTrans(nRst, clk, spiPush, spi);
	
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

			//send data to spi Mil
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
			
			//current status request
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
			
			//get data that was received from Mil
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
			
			//system reset, incorrect addr, the cmd should be ignored
			begin
				$display("Reset Start");	
			
				spiDebug.doPush(16'h0100);	//addr = 01
				spiDebug.doPush(16'h00A0);	//size = 0000, cmd = A2				
				spiDebug.doPush(16'h01A0);	//check sum
				spiDebug.doPush(16'h0);		//word num
			
				$display("Reset End");		
			end
			
			//system rest
			begin
				$display("Reset Start");	
			
				spiDebug.doPush(16'hAB00);	//addr = AB
				spiDebug.doPush(16'h00A0);	//size = 0000, cmd = A2	
				spiDebug.doPush(16'hABA0);	//check sum
				spiDebug.doPush(16'h0);		//word num	
			
				$display("Reset End");		
			end

	end
	
	always #5  clk =  ! clk;

endmodule
