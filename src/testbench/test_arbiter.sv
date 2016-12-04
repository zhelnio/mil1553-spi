/* MIL-STD-1553 <-> SPI bridge
 * Copyright(c) 2016 Stanislav Zhelnio
 * Licensed under the MIT license (MIT)
 * https://github.com/zhelnio/mil1553-spi
 */

`timescale 10 ns/ 1 ns

module test_arbiter();
	bit nRst, clk;
	
	IMemory mbus();
	IMemoryReader rBus();
	IMemoryWriter wBus();
	IArbiter abus[3:0]();

	MemoryHelper 	mem(nRst, clk, mbus.memory);
	MemoryReader	reader(nRst, clk, mbus.reader, rBus.slave, abus[1].client);
	MemoryWriter	writer(nRst, clk, mbus.writer, wBus.slave, abus[0].client);
	Arbiter			arbiter(nRst, clk, abus);
	
	//test helpers
	IMemoryReaderHelper r_helper(clk, rBus);
	IMemoryWriterHelper w_helper(clk, wBus);
	
initial begin
	clk = '1;	nRst = '0;
	#2	nRst = '1;
  
	fork
		begin
			#1000 //max test duration
			$stop();
		end
		fork
			r_helper.doRead(8'h02);
			w_helper.doWrite(8'h02, 16'hABCD);
		join
		begin
			@(posedge abus[0].request);
			assert(abus[1].request);
			@(posedge abus[0].grant);
			assert(1==1);
			@(negedge abus[0].request);
			assert(1==1);
			@(negedge abus[0].grant);
			assert(1==1);
			@(posedge abus[1].grant);
			assert(1==1);
			@(negedge abus[1].request);
			assert(1==1);
			@(negedge abus[1].grant);
			assert(1==1);
		end
	join
end

always #1  clk =  ! clk;

endmodule