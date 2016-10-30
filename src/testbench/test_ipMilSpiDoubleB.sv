`timescale 1 ns/ 100 ps

module test_IpMilSpiDoubleB();
	
	import milStd1553::*;
	
	bit rst, clk;
	ISpi     spi();	// 2x milSpi are connected to one spi bus with different ServiceProtocol addrs
	IMilStd  mil();
	IMemory  mem();

	assign mil.RXin  = mil.TXout;
	assign mil.nRXin = mil.nTXout;
	
	//debug spi transmitter
	IPush        		spiPush();
	IPushHelper 		spiDebug(clk, spiPush);
	DebugSpiTransmitter	spiTrans(rst, clk, spiPush, spi);
	
	//debug mil tranceiver
	IPushMil         	milPush();
	IPushMilHelper 	 	milDebug(clk, milPush);
	DebugMilTransmitter milTrans(rst, clk, milPush, mil);
	
	//DUT modules
	defparam milSpi.milSpiBlock.SPI_BLOCK_ADDR0 	= 8'hAB;
	defparam milSpi.milSpiBlock.SPI_BLOCK_ADDR1 	= 8'hAC;

	defparam milSpi.memoryBlock.RING2_0_MEM_START	= 16'h00;
	defparam milSpi.memoryBlock.RING2_0_MEM_END		= 16'h3F;
	defparam milSpi.memoryBlock.RING2_1_MEM_START	= 16'h40;
	defparam milSpi.memoryBlock.RING2_1_MEM_END		= 16'h7F;
	defparam milSpi.memoryBlock.RING2_2_MEM_START	= 16'h80;
	defparam milSpi.memoryBlock.RING2_2_MEM_END		= 16'hBF;
	defparam milSpi.memoryBlock.RING2_3_MEM_START	= 16'hC0;
	defparam milSpi.memoryBlock.RING2_3_MEM_END		= 16'hFF;

	IpMilSpiDoubleB milSpi(.clk(clk), .rst(rst),
	                      .spi(spi), 
						  .mil0(mil), .mil1(mil),
	                      .mbus(mem));
	                      
	AlteraMemoryWrapper memory(.clk(clk), .rst(rst), 
	                           .memBus(mem));
	initial begin
	
		rst = 1;
	#20 rst = 0;
		
			//send data to spi Mil
			begin
				$display("TransmitOverSpi Start");	
			
				spiDebug.doPush(16'hAB00);	//addr = AB
				spiDebug.doPush(16'h06A2);  //size = 0006, cmd = A2 (send data to mil)
				spiDebug.doPush(16'hFFA1);  //next word is WCOMMAND
				spiDebug.doPush(16'h0001);	//WCOMMAND h0001
				
				spiDebug.doPush(16'h0002);	//WDATA h0002
				spiDebug.doPush(16'hAB45);	//WDATA hAB45
				spiDebug.doPush(16'hFFA3);	//next word is ESC_WDATA
				spiDebug.doPush(16'hFFA1);	//WDATA hFFA1
				
				spiDebug.doPush(16'h5BCF);	//check sum
				spiDebug.doPush(16'h0);	//word num
				
				$display("TransmitOverSpi End");	
			end
			
			//wait for mil transmission end
			#80000

			//get data that was received from Mil
			begin
				$display("ReceiveOverSpi Start");	
			
				spiDebug.doPush(16'hAC00);	//addr = AC
				spiDebug.doPush(16'h0AB2);  //size = 000A, cmd = B2				
				spiDebug.doPush(16'h0);	//blank data to receive reply
				spiDebug.doPush(16'h0);		
				spiDebug.doPush(16'h0);		
				spiDebug.doPush(16'h0);		
				spiDebug.doPush(16'h0);		
				spiDebug.doPush(16'h0);	
				spiDebug.doPush(16'h0);		
				spiDebug.doPush(16'h0);		
				spiDebug.doPush(16'h0);		
				spiDebug.doPush(16'h0);
				spiDebug.doPush(16'hB6B2);	//check sum
				spiDebug.doPush(16'h0);		//word num
			
				$display("ReceiveOverSpi End");		
			end
	end
	
	always #5  clk =  ! clk;

endmodule
