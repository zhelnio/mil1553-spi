`timescale 10 ns/ 1 ns

module milStdBlockTest(input bit rst, clk,
							  output bit out);
	assign out = clk;

	milStdBlockTest_transmitter 	test1();
	milStdBlockTest_receiver		test2();
endmodule


module milStdBlockTest_transmitter();
	bit rst, clk, ioClk; 
	bit enable, line, busy;
	
	import milStd1553::*;
	
	IPushMil push();
	
	transmitter t(rst, clk, ioClk, enable, push.slave, line, busy);
	
	task doPush(WordType t, logic [15:0] data);
		@(posedge clk)	push.request = '1; push.data.dataType	= t; push.data.dataWord = data;
		@(posedge clk)	push.request = '0;

		@(push.done);
	endtask
	
	initial begin
		rst = 1; enable = 1;
		@(posedge clk);
		@(posedge clk);
		rst = 0;
		
		doPush(WSTATUS, 16'h02A1);
		doPush(WDATA, 16'h02A1);
	end
	
	always #1 clk = !clk;
	always #100 ioClk = !ioClk;	
	
endmodule

module milStdBlockTest_receiver();
	bit rst, clk, ioClk; 
	logic line;
	
	logic tenable, tbusy;
	logic renable, rbusy;
	
	import milStd1553::*;
	
	IPushMil tpush();
	IPushMil rpush();
	
	transmitter t(rst, clk, ioClk, tenable, tpush.slave, line, tbusy);
	receiver r(rst, clk, line, renable, rpush, rbusy);
	
	task doPush(WordType t, logic [15:0] data);
		@(posedge clk)	tpush.request = '1; tpush.data.dataType	= t; tpush.data.dataWord = data;
		@(posedge clk)	tpush.request = '0;

		@(tpush.done);
	endtask
	
	initial begin
		rst = 1; tenable = 1; renable = 1;
		@(posedge clk);
		@(posedge clk);
		rst = 0;
		
		doPush(WSTATUS, 16'h02A1);
		doPush(WDATA, 16'h02A1);
	end
	
	always #1 clk = !clk;
	always #100 ioClk = !ioClk;	
	
endmodule

