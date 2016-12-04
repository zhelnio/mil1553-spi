/* MIL-STD-1553 <-> SPI bridge
 * Copyright(c) 2016 Stanislav Zhelnio
 * Licensed under the MIT license (MIT)
 * https://github.com/zhelnio/mil1553-spi
 */

`timescale 1 ns/ 100 ps

module test_IpMilSpiSingle();
	
	import milStd1553::*;
	
	bit nRst, clk;
	ISpi     spi();
	IMilStd  mil0();
	IMilStd  mil1();
	IMemory  mem();

	MilConnectionPoint mcp(mil0, mil1);
	
	//debug spi transmitter
	IPush        		spiPush();
	IPush        		spiRcvd();
	IPushHelper 		spiDebug(clk, spiPush);
	DebugSpiTransmitter	spiTrans(nRst, clk, spiPush, spiRcvd, spi);
	
	//debug mil tranceiver
	IPushMil         	milPush();
	IPushMilHelper 	 	milDebug(clk, milPush);
	DebugMilTransmitter milTrans(nRst, clk, milPush, mil0);
	
	//DUT modules
	defparam milSpi.milSpiBlock.SPI_BLOCK_ADDR 	= 8'hAB;
	defparam milSpi.memoryBlock.RING1_MEM_START	= 16'h00;
	defparam milSpi.memoryBlock.RING1_MEM_END	= 16'h7F;
  	defparam milSpi.memoryBlock.RING2_MEM_START	= 16'h80;
  	defparam milSpi.memoryBlock.RING2_MEM_END	= 16'hFF;

	IpMilSpiSingle milSpi(.clk(clk), .nRst(nRst),
	                      .spi(spi), .mil(mil1),
	                      .mbus(mem));
	                      
	MemoryHelper 	memory(.clk(clk), .nRst(nRst), 
	                           .mem(mem));
	initial begin
	
		nRst = 0;
	#20 nRst = 1;
	fork
		begin
			#250000 //max test duration
			$stop();
		end

		begin //tests sequence
			fork // send data to mil and spi
				//send some random data to Mil
				begin
					$display("TransmitOverMil Start");	
					
					milDebug.doPush(WSERV,	16'hAB00);
					milDebug.doPush(WDATA,	16'hEFAB);
					milDebug.doPush(WDATA,	16'h9D4D);
					
					$display("TransmitOverMil End");	
				end
			
				//send data to spi Mil
				begin
					$display("TransmitOverSpi Start");	
				
					spiDebug.doPush(16'hAB00);	//addr = AB
					spiDebug.doPush(16'h08A2);  //size = 0008, cmd = A2
					spiDebug.doPush(16'hFFA1); 
					spiDebug.doPush(16'h0001); 
					spiDebug.doPush(16'hFFA3);
					spiDebug.doPush(16'h0002);
					spiDebug.doPush(16'hFFA3);
					spiDebug.doPush(16'hAB45);
					spiDebug.doPush(16'hFFA3);
					spiDebug.doPush(16'hFFA1);
					spiDebug.doPush(16'h5D15);	//check sum
					spiDebug.doPush(16'h0);		//word num
					spiDebug.doPush(16'h0);		//blank postfix
					spiDebug.doPush(16'h0);
					spiDebug.doPush(16'h0);
					
					$display("TransmitOverSpi End");	
				end
			join
			//current status request
			fork
				begin
					$display("GetStatus Start");	
				
					spiDebug.doPush(16'hAB00);	//addr = AB
					spiDebug.doPush(16'h00B0);  //size = 000A, cmd = B0				
					spiDebug.doPush(16'hABB0);	//check sum
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
					@(spiRcvd.data == 16'hAB00 && spiRcvd.request == 1);	//responce addr = AB
					assert( 1 == 1);
					@(posedge spiRcvd.request);
					assert(spiRcvd.data == 16'h02B0);	// responce size = 02, cmd = B0
					@(posedge spiRcvd.request);
					assert(spiRcvd.data > 0);	// input queue size
					@(posedge spiRcvd.request);
					assert(spiRcvd.data > 0);	// output queue	size
					@(posedge spiRcvd.request);	// check sum
					@(posedge spiRcvd.request); // packet num
					@(posedge spiRcvd.request);	// blank word after the packet
					assert(spiRcvd.data == '0);
					$display("GetStatus Ok");				
				end
			join
			
			//get data that was received from Mil
			fork
				begin
					$display("ReceiveOverSpi Start");	
				
					spiDebug.doPush(16'hAB00);	//addr = AB
					spiDebug.doPush(16'h0AB2);  //size = 000A, cmd = B2				
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
					spiDebug.doPush(16'h0);		//blank postfix
					spiDebug.doPush(16'h0);
					spiDebug.doPush(16'h0);
					spiDebug.doPush(16'h0);		// blank word after the packet
				
					$display("ReceiveOverSpi End");		
				end
				begin
					@(spiRcvd.data == 16'hAB00 && spiRcvd.request == 1);	//responce addr = AB
					assert( 1 == 1);
					@(posedge spiRcvd.request);
					assert(spiRcvd.data == 16'h06B2);	// responce size = 06, cmd = B2
					@(posedge spiRcvd.request);
					assert(spiRcvd.data == 16'hFFA1);	//next word is WSERV
					@(posedge spiRcvd.request);
					assert(spiRcvd.data == 16'hAB00);	//WSERV that was received from mil
					@(posedge spiRcvd.request);
					assert(spiRcvd.data == 16'hFFA3);	//next word is WDATA
					@(posedge spiRcvd.request);
					assert(spiRcvd.data == 16'hEFAB);	//WDATA received from mil
					@(posedge spiRcvd.request);
					assert(spiRcvd.data == 16'hFFA3);	//next word is WDATA
					@(posedge spiRcvd.request);
					assert(spiRcvd.data == 16'h9D4D);	//WDATA received from mil
					@(posedge spiRcvd.request);
					assert(spiRcvd.data == 16'hE891);	//check sum
					@(posedge spiRcvd.request);
					assert(spiRcvd.data == 16'h0002);	//packet num
					@(posedge spiRcvd.request);	
					assert(spiRcvd.data == '0);			// blank word after the packet
					$display("ReceiveOverSpi Ok");	
				end
			join
			
			//system reset, incorrect addr, the cmd should be ignored
			begin
				$display("Reset Start");	
			
				spiDebug.doPush(16'h0100);	//addr = 01
				spiDebug.doPush(16'h00A0);  //size = 0000, cmd = A2				
				spiDebug.doPush(16'h01A0);  //check sum
				spiDebug.doPush(16'h0);		//word num
				spiDebug.doPush(16'h0);		//blank postfix
				spiDebug.doPush(16'h0);
				spiDebug.doPush(16'h0);
				spiDebug.doPush(16'h0);		// blank word after the packet
			
				$display("Reset End");		
			end
			
			//system rest
			begin
				$display("Reset Start");	
			
				spiDebug.doPush(16'hAB00);	//addr = AB
				spiDebug.doPush(16'h00A0);  //size = 0000, cmd = A2	
				spiDebug.doPush(16'hABA0);  //check sum
				spiDebug.doPush(16'h0);		//word num	
				spiDebug.doPush(16'h0);		//blank postfix
				spiDebug.doPush(16'h0);
				spiDebug.doPush(16'h0);
				spiDebug.doPush(16'h0);		// blank word after the packet
			
				$display("Reset End");		
			end
			
			//wait for spi-master release after reset
			#10000

			//current status request
			fork
				begin
					$display("GetStatusAfterReset Start");	
				
					spiDebug.doPush(16'hAB00);	//addr = AB
					spiDebug.doPush(16'h00B0);  //size = 000A, cmd = B0				
					spiDebug.doPush(16'hB5B0);	//check sum
					spiDebug.doPush(16'h0);		//word num
					spiDebug.doPush(16'h0);		//blank postfix
					spiDebug.doPush(16'h0);
					spiDebug.doPush(16'h0);
					spiDebug.doPush(16'h0);
					spiDebug.doPush(16'h0);
					spiDebug.doPush(16'h0);		// blank word after the packet
				
					$display("GetStatusAfterReset End");		
				end
				begin
					@(spiRcvd.data == 16'h0);
					assert( 1 == 1);
					@(spiRcvd.data == 16'hAB00 && spiRcvd.request == 1);	//responce addr = AB
					assert( 1 == 1);
					@(posedge spiRcvd.request);
					assert(spiRcvd.data == 16'h02B0);	// responce size = 02, cmd = B0
					@(posedge spiRcvd.request);
					assert(spiRcvd.data == '0);	// input queue size
					@(posedge spiRcvd.request);
					assert(spiRcvd.data == '0);	// output queue	size
					@(posedge spiRcvd.request);
					assert(spiRcvd.data == 16'hADB0);	// check sum
					@(posedge spiRcvd.request);
					assert(spiRcvd.data == 16'h0001);	// packet num
					@(posedge spiRcvd.request);
					assert(spiRcvd.data == '0);	// blank word after the packet
					$display("GetStatus after reset Ok");	
				end
			join
		end //tests sequence
	join
	end
	
	always #5  clk =  ! clk;

endmodule
