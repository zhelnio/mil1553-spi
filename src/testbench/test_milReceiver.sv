`timescale 10 ns/ 1 ns

module test_milReceiver();
	bit rst, clk, ioClk; 
	logic line;
	
	logic tenable, tbusy, trequest;
	logic renable, rbusy;
	
	import milStd1553::*;
	
	IPushMil tpush();
	IPushMil rpush();
	
	IPushMilHelper pushHelper(clk, tpush);
	
	IMilStd mil();
	assign mil.RXin  = mil.TXout;
	assign mil.nRXin = mil.nTXout;
	
	milTransmitter t(rst, clk, ioClk, tenable, tpush, mil, tbusy, trequest);
	milReceiver r(rst, clk, mil, renable, rpush, rbusy);
	
	initial begin
		rst = 1; tenable = 1; renable = 1;
		@(posedge clk);
		@(posedge clk);
		rst = 0;
		
		fork
		  begin
		    pushHelper.doPush(WCOMMAND, 16'hEFAB);
		    pushHelper.doPush(WDATA, 16'h02A1);
		  end
		  begin
		    @(posedge rpush.request);
        assert( rpush.data.dataType == WCOMMAND);
        assert( rpush.data.dataWord == 16'hEFAB);
        @(posedge rpush.request);
        assert( rpush.data.dataType == WDATA);
        assert( rpush.data.dataWord == 16'h02A1);
		  end
		  
		  #10000 $stop;
		join
	end
	
	always #1 clk = !clk;
	always #100 ioClk = !ioClk;	
	
endmodule