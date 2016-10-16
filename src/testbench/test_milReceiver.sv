`timescale 10 ns/ 1 ns

module test_milReceiver();
	bit rst, clk, ioClk; 

	import milStd1553::*;
	
	IPushMil tpush();
	IPushMil rpush();
	
	IPushMilHelper pushHelper(clk, tpush);
	
	IMilStd mil();
	assign mil.RXin  = mil.TXout;
	assign mil.nRXin = mil.nTXout;
	
	IMilTxControl tcontrol();
	milTransmitter t(rst, clk, ioClk, tpush, mil, tcontrol);
	
	IMilRxControl rcontrol();
	milReceiver r(rst, clk, mil, rpush, rcontrol);
	
	initial begin
		rst = 1; 
		@(posedge clk);
		@(posedge clk);
		rst = 0;
		
		fork
		  #300 rcontrol.grant = 1;
		  #600 tcontrol.grant = 1;
		
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
		  
		  #11000 $stop;
		join
	end
	
	always #1 clk = !clk;
	always #100 ioClk = !ioClk;	
	
endmodule