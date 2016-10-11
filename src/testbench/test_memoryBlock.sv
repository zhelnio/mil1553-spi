`timescale 10 ns/ 1 ns

module test_memoryBlock();
	bit rst, clk;
	
	IMemory mbus();
	IRingBufferControl rcontrol[1:0]();
	IPush	push[1:0]();
	IPop	pop[1:0]();
	
	AlteraMemoryWrapper mem(rst, clk, mbus.memory);
	MemoryBlock			  memBlock(rst, clk, 
	                         push[0], push[1], 
	                         pop[0], pop[1], 
	                         rcontrol, mbus);
 

task doPushA(logic [15:0] data);
	@(posedge clk)	push[0].request = '1; push[0].data	= data;
	@(posedge clk)	push[0].request = '0;

	@(push[0].done);
endtask

task doPopA();	
	@(posedge clk)	pop[0].request = '1;
	@(posedge clk)	pop[0].request = '0;

	@(pop[0].done);
endtask

task doPushB(logic [15:0] data);
	@(posedge clk)	push[1].request = '1; push[1].data	= data;
	@(posedge clk)	push[1].request = '0;

	@(push[1].done);
endtask

task doPopB();	
	@(posedge clk)	pop[1].request = '1;
	@(posedge clk)	pop[1].request = '0;

	@(pop[1].done);
endtask

task doPushAB(logic [15:0] dataA, logic [15:0] dataB);
	@(posedge clk)	push[0].request = '1; push[0].data	= dataA;
						push[1].request = '1; push[1].data	= dataB;
	@(posedge clk)	push[0].request = '0;
						push[1].request = '0;

	@(push[0].done);
	@(push[1].done);
endtask
	
initial begin

	@(posedge clk)
	clk = '1;	rst = '1; 
	
	pop[0].request = '0;
	{rcontrol[0].open, rcontrol[0].commit, rcontrol[0].rollback} = '0;
	pop[1].request = '0;
	{rcontrol[1].open, rcontrol[1].commit, rcontrol[1].rollback} = '0;
	
	@(posedge clk)
	rst = '0;
	
	doPushAB(16'hABCD,16'h2222);
	doPushA(16'hEF01);
	doPushA(16'h2345);
	doPushB(16'h6789);
	doPopA();	
	doPopB();	
end

always begin
	#1  clk =  ! clk;
end

endmodule
