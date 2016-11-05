/* MIL-STD-1553 <-> SPI converter
 * Copyright(c) 2016 Stanislav Zhelnio
 * Licensed under the MIT license (MIT)
 * https://github.com/zhelnio/mil1553-spi
 */

`timescale 1 ns/ 100 ps

module test_IpMilSpiDoubleA();
	
	import milStd1553::*;
	
	bit nRst, clk;
	ISpi     spi0();	
	ISpi     spi1();
	IMilStd  mil0();	
	IMilStd  mil1();
	IMilStd  mil2();
	IMemory  mem();

	MilConnectionPoint3 mcp(mil0,mil1,mil2);
	
	//debug spi transmitter
	IPush        		spiPush0();
	IPush        		spiRcvd0();
	IPushHelper 		spiDebug0(clk, spiPush0);
	DebugSpiTransmitter	spiTrans0(nRst, clk, spiPush0, spiRcvd0, spi0);

	IPush        		spiPush1();
	IPush        		spiRcvd1();
	IPushHelper 		spiDebug1(clk, spiPush1);
	DebugSpiTransmitter	spiTrans1(nRst, clk, spiPush1, spiRcvd1, spi1);
	
	//debug mil tranceiver
	IPushMil         	milPush();
	IPushMilHelper 	 	milDebug(clk, milPush);
	DebugMilTransmitter milTrans(nRst, clk, milPush, mil2);
	
	//DUT modules
	defparam milSpi.milSpiBlock0.SPI_BLOCK_ADDR 	= 8'hAB;
	defparam milSpi.milSpiBlock1.SPI_BLOCK_ADDR 	= 8'hAC;

	defparam milSpi.memoryBlock.RING2_0_MEM_START	= 16'h00;
	defparam milSpi.memoryBlock.RING2_0_MEM_END		= 16'h3F;
	defparam milSpi.memoryBlock.RING2_1_MEM_START	= 16'h40;
	defparam milSpi.memoryBlock.RING2_1_MEM_END		= 16'h7F;
	defparam milSpi.memoryBlock.RING2_2_MEM_START	= 16'h80;
	defparam milSpi.memoryBlock.RING2_2_MEM_END		= 16'hBF;
	defparam milSpi.memoryBlock.RING2_3_MEM_START	= 16'hC0;
	defparam milSpi.memoryBlock.RING2_3_MEM_END		= 16'hFF;

	IpMilSpiDoubleA milSpi(.clk(clk), .nRst(nRst),
	                      .spi0(spi0), .spi1(spi1), 
						  .mil0(mil0), .mil1(mil1),
	                      .mbus(mem));
	                      
	AlteraMemoryWrapper memory(.clk(clk), .nRst(nRst), 
	                           .memBus(mem));
	initial begin
	
		nRst = 0;
	#20 nRst = 1;
		fork
			begin
				#150000 //max test duration
				$stop();
			end

			begin
				//send data to spi Mil
				begin
					$display("TransmitOverSpi Start");	
				
					spiDebug0.doPush(16'hAB00);	//addr = AB
					spiDebug0.doPush(16'h06A2);  //size = 0006, cmd = A2 (send data to mil)
					spiDebug0.doPush(16'hFFA1);  //next word is WSERV
					spiDebug0.doPush(16'h0001);	//WSERV h0001
					
					spiDebug0.doPush(16'h0002);	//WDATA h0002
					spiDebug0.doPush(16'hAB45);	//WDATA hAB45
					spiDebug0.doPush(16'hFFA3);	//next word is ESC_WDATA
					spiDebug0.doPush(16'hFFA1);	//WDATA hFFA1
					
					spiDebug0.doPush(16'h5BCF);	//check sum
					spiDebug0.doPush(16'h0);	//word num
					
					$display("TransmitOverSpi End");	
				end
				
				//wait for mil transmission end
				#80000

				//get data that was received from Mil
				fork
					begin
						$display("ReceiveOverSpi Start");	
					
						spiDebug1.doPush(16'hAC00);	//addr = AC
						spiDebug1.doPush(16'h0AB2);  //size = 000A, cmd = B2				
						spiDebug1.doPush(16'h0);	//blank data to receive reply
						spiDebug1.doPush(16'h0);		
						spiDebug1.doPush(16'h0);		
						spiDebug1.doPush(16'h0);		
						spiDebug1.doPush(16'h0);		
						spiDebug1.doPush(16'h0);	
						spiDebug1.doPush(16'h0);		
						spiDebug1.doPush(16'h0);		
						spiDebug1.doPush(16'h0);		
						spiDebug1.doPush(16'h0);
						spiDebug1.doPush(16'hB6B2);	//check sum
						spiDebug1.doPush(16'h0);		//word num
					
						$display("ReceiveOverSpi End");		
					end
					begin
						@(spiRcvd1.data == 16'hAC00 && spiRcvd1.request == 1);	//responce addr = AC
						assert( 1 == 1);
						@(posedge spiRcvd1.request);
						assert(spiRcvd1.data == 16'h06B2);	// responce size = 0006, cmd = B2
						@(posedge spiRcvd1.request);
						assert(spiRcvd1.data == 16'hFFA1);	//next word is WSERV
						@(posedge spiRcvd1.request);
						assert(spiRcvd1.data == 16'h0001);	//WSERV that was received from mil
						@(posedge spiRcvd1.request);
						assert(spiRcvd1.data == 16'h0002);	//WDATA received from mil
						@(posedge spiRcvd1.request);
						assert(spiRcvd1.data == 16'hAB45);	//WDATA received from mil
						@(posedge spiRcvd1.request);
						assert(spiRcvd1.data == 16'hFFA3);	//next word is ESC_WDATA
						@(posedge spiRcvd1.request);
						assert(spiRcvd1.data == 16'hFFA1);	//WDATA received from mil
						@(posedge spiRcvd1.request);
						assert(spiRcvd1.data == 16'h5CDF);	//check sum
						@(posedge spiRcvd1.request);
						assert(spiRcvd1.data == 16'h0001);	//packet num
						@(posedge spiRcvd1.request);	
						assert(spiRcvd1.data == '0);			// blank word after the packet
						$display("ReceiveOverSpi Ok");
					end
				join
			end
		join
	end
	
	always #5  clk =  ! clk;

endmodule
