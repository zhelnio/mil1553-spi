`timescale 10 ns/ 1 ns

module test_milTransmitter();
	bit rst, clk, ioClk; 
	
	import milStd1553::*;
	
	IPushMil push();
	IPushMilHelper pushHelper(clk, push);
	IMilStd mil();
	IMilTxControl control();
	
	milTransmitter t(rst, clk, ioClk, push, mil, control);
	
	initial begin
		rst = 1; control.grant = 0;
		@(posedge clk);
		@(posedge clk);
		rst = 0;
		
		fork
		  #600 control.grant = 1;
		  
		  begin
		    #100
		    pushHelper.doPush(WCOMMAND, 16'h02A1);
		    pushHelper.doPush(WDATA, 16'h02A1);
		  end
		  
		  #10000 $stop;
		join
	end
	
	always #1 clk = !clk;
	always #100 ioClk = !ioClk;	
	
endmodule