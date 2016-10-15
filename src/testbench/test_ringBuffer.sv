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
	
    popHelper.doPop();
    assert (pop.data == 16'hABCD);
  
    popHelper.doPop();
    assert (pop.data == 16'h1234);
    
    #10 $stop;
  end

  always #1  clk =  !clk;
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
	
	RingBuffer	#(.MEM_START_ADDR(16'h00), .MEM_END_ADDR(16'h02))	
	           ring(rst, clk, rcontrol.slave, push.slave, pop.slave, wBus.master, rBus.master);
     
	//test helpers
	IPushHelper pushHelper(clk, push);
	IPopHelper  popHelper(clk, pop);
	
  initial begin
    clk = '1;	rst = '1; 
    {rcontrol.open, rcontrol.commit, rcontrol.rollback} = '0;
	
	  #2	rst = '0;
    pushHelper.doPush(16'hABCD);
    pushHelper.doPush(16'hEF01);
    pushHelper.doPush(16'h2345);
    pushHelper.doPush(16'h6789);
    
    popHelper.doPop();	
    assert (pop.data == 16'h2345);
    
    popHelper.doPop();	
    assert (pop.data == 16'h6789);
    
    #10 $stop;
  end

  always #1  clk =  ! clk;

endmodule


module test_ringBufferConcurentOverflow();
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
					
	//test helpers
	IPushHelper pushHelperA(clk, push[0]);
	IPushHelper pushHelperB(clk, push[1]);
	IPopHelper  popHelperA(clk, pop[0]);
	IPopHelper  popHelperB(clk, pop[1]);
	
	initial begin
    clk = '1;	rst = '1;
    {rcontrol[0].open, rcontrol[0].commit, rcontrol[0].rollback} = '0;
    {rcontrol[1].open, rcontrol[1].commit, rcontrol[1].rollback} = '0;
    #2	rst = '0;
	
    fork
      begin
        pushHelperA.doPush(16'h1111);
        pushHelperA.doPush(16'h2222);
        pushHelperA.doPush(16'h3333);
        pushHelperA.doPush(16'h4444);
        pushHelperA.doPush(16'h5555);
        pushHelperA.doPush(16'h6666);
      end
      begin
        pushHelperB.doPush(16'h7777);
        pushHelperB.doPush(16'h8888);
      end
    join
    
    fork
      popHelperA.doPop();	
      popHelperB.doPop();	
    join
    
    assert (pop[0].data == 16'h5555);
    assert (pop[1].data == 16'h7777);
    
    #10 $stop;
  end

  always #1 clk = !clk;

endmodule















