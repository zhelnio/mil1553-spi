/* MIL-STD-1553 <-> SPI bridge
 * Copyright(c) 2016 Stanislav Zhelnio
 * Licensed under the MIT license (MIT)
 * https://github.com/zhelnio/mil1553-spi
 */

`timescale 10 ns/ 1 ns

module test_milTransmitter();
	bit nRst, clk, ioClk; 
	
	import milStd1553::*;
	
	IPushMil push();
	IPushMilHelper pushHelper(clk, push);
	IMilStd mil();
	IMilTxControl control();
	
	milTransmitter t(nRst, clk, ioClk, push, mil, control);
	
	initial begin
		nRst = 0; control.grant = 0;
		@(posedge clk);
		@(posedge clk);
		nRst = 1;
		
		fork
		  #600 control.grant = 1;
		  
		  begin
		    #100
		    pushHelper.doPush(WSERV, 16'h02A1);
		    pushHelper.doPush(WDATA, 16'h02A1);
		  end
		  
		  #10000 $stop;
		join
	end
	
	always #1 clk = !clk;
	always #100 ioClk = !ioClk;	
	
endmodule