/* MIL-STD-1553 <-> SPI bridge
 * Copyright(c) 2016 Stanislav Zhelnio
 * Licensed under the MIT license (MIT)
 * https://github.com/zhelnio/mil1553-spi
 */

`timescale 1 ns/ 100 ps

module test_milTransceiver();
  import milStd1553::*;
  
  bit nRst, clk;

	IMilStd  mil0();
	IMilStd  mil1();
	MilConnectionPoint mcp(mil0, mil1);

  IPushMil rpush0();
  IPushMil tpush0();
  IMilControl control0();
  milTransceiver tr0(nRst, clk, rpush0, tpush0, mil0, control0);
  
  IPushMil rpush1();
  IPushMil tpush1();
  IMilControl control1();
  milTransceiver tr1(nRst, clk, rpush1, tpush1, mil1, control1);
  
  IPushMilHelper pushHelper0(clk, tpush0);
  IPushMilHelper pushHelper1(clk, tpush1);
  
	initial begin
		nRst = 0; 
		@(posedge clk);
		@(posedge clk);
		nRst = 1;
		
		fork	
		
		  begin
		    pushHelper0.doPush(WSERV, 16'h1111);
		    pushHelper0.doPush(WDATA, 16'h2222);
		  end
		  
		  
		  begin
		    #600
		    pushHelper1.doPush(WSERV, 16'hAAAA);
		    pushHelper1.doPush(WDATA, 16'hBBBB);
		  end
		  
		  begin
		    @(posedge rpush0.request);
        assert( rpush0.data.dataType == WSERV);
        assert( rpush0.data.dataWord == 16'hAAAA);
        @(posedge rpush0.request);
        assert( rpush0.data.dataType == WDATA);
        assert( rpush0.data.dataWord == 16'hBBBB);
		  end
		  
		  begin
		    @(posedge rpush1.request);
        assert( rpush1.data.dataType == WSERV);
        assert( rpush1.data.dataWord == 16'h1111);
        @(posedge rpush1.request);
        assert( rpush1.data.dataType == WDATA);
        assert( rpush1.data.dataWord == 16'h2222);
		  end
		  
		  #150000 $stop;
		join
	end
	
	always #5 clk = !clk;
	
endmodule
