/* MIL-STD-1553 <-> SPI converter
 * Copyright(c) 2016 Stanislav Zhelnio
 * Licensed under the MIT license (MIT)
 * https://github.com/zhelnio/mil1553-spi
 */

`timescale 1 ns/ 100 ps

module test_IpMilSpiDoubleB();
	
	import milStd1553::*;
	
	bit nRst, clk;
	ISpi     spi();	// 2x milSpi are connected to one spi bus with different ServiceProtocol addrs
	IMilStd  mil0();
	IMilStd  mil1();
	IMilStd  mil2();
	IMemory  mem();

	MilConnectionPoint3 mcp(mil0,mil1,mil2);
	
	//debug spi transmitter
	IPush        		spiPush();
	IPush        		spiRcvd();
	IPushHelper 		spiDebug(clk, spiPush);
	DebugSpiTransmitter	spiTrans(nRst, clk, spiPush, spiRcvd, spi);
	
	//debug mil tranceiver
	IPushMil         	milPush();
	IPushMilHelper 	 	milDebug(clk, milPush);
	DebugMilTransmitter milTrans(nRst, clk, milPush, mil2);
	
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

	IpMilSpiDoubleB milSpi(.clk(clk), .nRst(nRst),
	                      .spi(spi), 
						  .mil0(mil0), .mil1(mil1),
	                      .mbus(mem));
	                      
	MemoryHelper	memory(.clk(clk), .nRst(nRst), 
	                           .mem(mem));
	initial begin
	
		nRst = 0;
	#20 nRst = 1;
		fork
			begin
				#300000 //max test duration
				$stop();
			end

			begin //tests sequence
				
				//get status of blank device
				begin
					$display("GetBlankStatus Start");	
				
					spiDebug.doPush(16'hAC00);	//addr = AB
					spiDebug.doPush(16'h00B0);  //size = 0000, cmd = B0				
					spiDebug.doPush(16'hACB0);	//check sum
					spiDebug.doPush(16'h0);		//word num
					spiDebug.doPush(16'h0);		//post packet blank data...
					spiDebug.doPush(16'h0);		
					spiDebug.doPush(16'h0);		
					spiDebug.doPush(16'h0);	
					spiDebug.doPush(16'h0);		
					spiDebug.doPush(16'h0);		
					spiDebug.doPush(16'h0);		
					spiDebug.doPush(16'h0);

					$display("GetBlankStatus End");	
				end	

				//send data to spi Mil
				begin
					$display("TransmitOverSpi Start");	

					spiDebug.doPush(16'hAB00);	//addr = AB
					spiDebug.doPush(16'h08A2);  //size = 0008, cmd = A2
					spiDebug.doPush(16'hFFA1);	//WSERV h0001
					spiDebug.doPush(16'h0001); 
					spiDebug.doPush(16'hFFA3);	//WDATA h0002
					spiDebug.doPush(16'h0002);
					spiDebug.doPush(16'hFFA3);	//WDATA hAB45
					spiDebug.doPush(16'hAB45);
					spiDebug.doPush(16'hFFA3);	//WDATA hFFA1
					spiDebug.doPush(16'hFFA1);
					spiDebug.doPush(16'h5D15);	//check sum
					spiDebug.doPush(16'h0);		//word num
					spiDebug.doPush(16'h0);		//blank postfix
					spiDebug.doPush(16'h0);
					spiDebug.doPush(16'h0);
					
					$display("TransmitOverSpi End");	
				end
				
				//wait for mil transmission end
				#80000
				
				//current status request
				fork
					begin
						$display("GetStatus Start");	
					
						spiDebug.doPush(16'hAC00);	//addr = AC
						spiDebug.doPush(16'h00B0);  //size = 0000, cmd = B0				
						spiDebug.doPush(16'hACB0);	//check sum
						spiDebug.doPush(16'h0);		//word num
						spiDebug.doPush(16'h0);		//blank postfix
						spiDebug.doPush(16'h0);
						spiDebug.doPush(16'h0);
						spiDebug.doPush(16'h0);
						spiDebug.doPush(16'h0);
						spiDebug.doPush(16'h0);		// blank word after the packet
					
						$display("GetStatus End");	
					end	
					begin
						@(spiRcvd.data == 16'h0);
						assert( 1 == 1);
						@(spiRcvd.data == 16'hAC00 && spiRcvd.request == 1);	//responce addr = AC
						assert( 1 == 1);
						@(posedge spiRcvd.request);
						assert(spiRcvd.data == 16'h02B0);	// responce size = 02, cmd = B0
						@(posedge spiRcvd.request);
						assert(spiRcvd.data > 0);	// input queue size
						@(posedge spiRcvd.request);
						assert(spiRcvd.data == 0);	// output queue	size
						@(posedge spiRcvd.request);	// check sum
						@(posedge spiRcvd.request); // packet num
						@(posedge spiRcvd.request);	// blank word after the packet
						assert(spiRcvd.data == '0);
						$display("GetStatus Ok");				
					end
				join
				
				fork //get data that was received from Mil
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
						spiDebug.doPush(16'h0);
						spiDebug.doPush(16'h0);
						spiDebug.doPush(16'h0);
						spiDebug.doPush(16'h0);
					
						$display("ReceiveOverSpi End");		
					end
					begin
						@(spiRcvd.data == 16'hAC00 && spiRcvd.request == 1);	//responce addr = AC
						assert( 1 == 1);
						@(posedge spiRcvd.request);
						assert(spiRcvd.data == 16'h08B2);	// responce size = 0006, cmd = B2
						@(posedge spiRcvd.request);
						assert(spiRcvd.data == 16'hFFA1);	//next word is WSERV
						@(posedge spiRcvd.request);
						assert(spiRcvd.data == 16'h0001);	//WSERV that was received from mil
						@(posedge spiRcvd.request);
						assert(spiRcvd.data == 16'hFFA3);	//next word is WDATA
						@(posedge spiRcvd.request);
						assert(spiRcvd.data == 16'h0002);	//WDATA received from mil
						@(posedge spiRcvd.request);
						assert(spiRcvd.data == 16'hFFA3);	//next word is WDATA
						@(posedge spiRcvd.request);
						assert(spiRcvd.data == 16'hAB45);	//WDATA received from mil
						@(posedge spiRcvd.request);
						assert(spiRcvd.data == 16'hFFA3);	//next word is ESC_WDATA
						@(posedge spiRcvd.request);
						assert(spiRcvd.data == 16'hFFA1);	//WDATA received from mil
						@(posedge spiRcvd.request);
						assert(spiRcvd.data == 16'h5E25);	//check sum
						@(posedge spiRcvd.request);
						assert(spiRcvd.data == 16'h0003);	//packet num
						@(posedge spiRcvd.request);	
						assert(spiRcvd.data == '0);			// blank word after the packet
						$display("ReceiveOverSpi Ok");
					end
				join
			end	//tests sequence
		join
	end

	always #5  clk =  ! clk;

endmodule
