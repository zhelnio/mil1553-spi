`timescale 10 ns/ 1 ns

module test_ringBuffer();
	bit rst, clk;
	
	IMemory mbus();
	IMemoryReader rBus();
	IMemoryWriter wBus();
	IArbiter abus[3:0]();
	IRingBufferControl rcontrol();
	IPush	push();
	IPop	pop();

	AlteraMemoryWrapper mem(rst, clk, mbus.memory);
	MemoryReader	reader(rst, clk, mbus.reader, rBus.slave, abus[1].client);
	MemoryWriter	writer(rst, clk, mbus.writer, wBus.slave, abus[0].client);
	Arbiter			arbiter(rst, clk, abus);
	RingBuffer		ring(rst, clk, rcontrol.slave, push.slave, pop.slave, wBus.master, rBus.master);
	
	//test helpers
	IPushHelper pushHelper(clk, push);
	IPopHelper  popHelper(clk, pop);
	
	
initial begin
	clk = '1;	rst = '1; 
	{rcontrol.open, rcontrol.commit, rcontrol.rollback} = '0;
	
	#2	rst = '0;

	pushHelper.doPush(16'hABCD);
	pushHelper.doPush(16'h1234);
	pushHelper.doPush(16'h5678);
	
  popHelper.doPop();
  assert (pop.data == 16'hABCD);
  
	popHelper.doPop();
	assert (pop.data == 16'h1234);
	
	popHelper.doPop();
	assert (pop.data == 16'h5678);
	
	#10 $stop;

end

always #1  clk =  ! clk;

endmodule

module test_ringBufferOverflow();
	bit rst, clk;
	
	IMemory mbus();
	IMemoryReader rBus();
	IMemoryWriter wBus();
	IArbiter abus[3:0]();
	IRingBufferControl rcontrol();
	IPush	push();
	IPop	pop();

	AlteraMemoryWrapper mem(rst, clk, mbus.memory);
	MemoryReader	reader(rst, clk, mbus.reader, rBus.slave, abus[1].client);
	MemoryWriter	writer(rst, clk, mbus.writer, wBus.slave, abus[0].client);
	Arbiter			arbiter(rst, clk, abus);
	RingBuffer		ring(rst, clk, rcontrol.slave, push.slave, pop.slave, wBus.master, rBus.master);
	
task doPush(logic [15:0] data);
	@(posedge clk)	push.master.request = '1; push.master.data	= data;
	@(posedge clk)	push.master.request = '0;

	@(push.master.done);
endtask

task doPop();	
	@(posedge clk)	pop.master.request = '1;
	@(posedge clk)	pop.master.request = '0;

	@(pop.master.done);
endtask
	
initial begin

	@(posedge clk)
	clk = '1;	rst = '1; pop.master.request = '0;
	{rcontrol.open, rcontrol.commit, rcontrol.rollback} = '0;
	
	@(posedge clk)
	rst = '0;

	doPush(16'hABCD);
	doPush(16'hEF01);
	doPush(16'h2345);
	doPush(16'h6789);
	doPop();	
	doPop();	
end

always begin
	#1  clk =  ! clk;
end

endmodule

module test_ringBufferOverflow2();
	bit rst, clk;
	
	IMemory mbus();
	IMemoryReader rbus[1:0]();
	IMemoryWriter wbus[1:0]();
	IArbiter abus[3:0]();
	IRingBufferControl rcontrol[1:0]();
	IPush	push[1:0]();
	IPop	pop[1:0]();

	Arbiter			arbiter(rst, clk, abus);
	AlteraMemoryWrapper mem(rst, clk, mbus.memory);
	MemoryWriter	writerA(rst, clk, mbus.writer, wbus[0].slave, abus[0].client);
	MemoryWriter	writerB(rst, clk, mbus.writer, wbus[1].slave, abus[1].client);
	MemoryReader	readerA(rst, clk, mbus.reader, rbus[0].slave, abus[2].client);
	MemoryReader	readerB(rst, clk, mbus.reader, rbus[1].slave, abus[3].client);
	
	RingBuffer			#(.MEM_START_ADDR(16'h00), .MEM_END_ADDR(16'h02))
					ringA	 (rst, clk, rcontrol[0].slave, push[0].slave, pop[0].slave, wbus[0].master, rbus[0].master);

	RingBuffer			#(.MEM_START_ADDR(16'h10), .MEM_END_ADDR(16'h12))
					ringB	 (rst, clk, rcontrol[1].slave, push[1].slave, pop[1].slave, wbus[1].master, rbus[1].master);
	
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















