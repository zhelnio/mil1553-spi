/* MIL-STD-1553 <-> SPI bridge
 * Copyright(c) 2016 Stanislav Zhelnio
 * Licensed under the MIT license (MIT)
 * https://github.com/zhelnio/mil1553-spi
 */

`timescale 10 ns/ 1 ns

module test_ringBuffer();
	bit nRst, clk;
	
	IMemory mbus();
	IMemoryReader rBus();
	IMemoryWriter wBus();
	IArbiter abus[3:0]();
	IRingBufferControl rcontrol();
	IPush	push();
	IPop	pop();

	MemoryHelper  mem(nRst, clk, mbus.memory);
	MemoryReader	reader(nRst, clk, mbus.reader, rBus.slave, abus[1].client);
	MemoryWriter	writer(nRst, clk, mbus.writer, wBus.slave, abus[0].client);
	Arbiter			arbiter(nRst, clk, abus);
	RingBuffer		ring(nRst, clk, rcontrol.slave, push.slave, pop.slave, wBus.master, rBus.master);
	
	//test helpers
	IPushHelper pushHelper(clk, push);
	IPopHelper  popHelper(clk, pop);
	
	
  initial begin
    clk = '1;	nRst = '0; 
    {rcontrol.open, rcontrol.commit, rcontrol.rollback} = '0;
	
	  #2	nRst = '1;

    assert (rcontrol.memUsed == 0);
    
	  pushHelper.doPush(16'hABCD);
	  assert (rcontrol.memUsed == 1);
	  
	  pushHelper.doPush(16'h1234);
	  assert (rcontrol.memUsed == 2);
	
    popHelper.doPop();
    assert (pop.data == 16'hABCD);
    assert (rcontrol.memUsed == 1);
  
    popHelper.doPop();
    assert (pop.data == 16'h1234);
    assert (rcontrol.memUsed == 0);
    
    #10 $stop;
  end

  always #1  clk =  !clk;
endmodule

module test_ringBufferOverflow();
	bit nRst, clk;
	
	IMemory mbus();
	IMemoryReader rBus();
	IMemoryWriter wBus();
	IArbiter abus[3:0]();
	IRingBufferControl rcontrol();
	IPush	push();
	IPop	pop();

	MemoryHelper  mem(nRst, clk, mbus.memory);
	MemoryReader	reader(nRst, clk, mbus.reader, rBus.slave, abus[1].client);
	MemoryWriter	writer(nRst, clk, mbus.writer, wBus.slave, abus[0].client);
	Arbiter			arbiter(nRst, clk, abus);
	
	RingBuffer	#(.MEM_START_ADDR(16'h00), .MEM_END_ADDR(16'h02))	
	           ring(nRst, clk, rcontrol.slave, push.slave, pop.slave, wBus.master, rBus.master);
     
	//test helpers
	IPushHelper pushHelper(clk, push);
	IPopHelper  popHelper(clk, pop);
	
  initial begin
    clk = '1;	nRst = '0; 
    {rcontrol.open, rcontrol.commit, rcontrol.rollback} = '0;
	
	  #2	nRst = '1;
	  assert (rcontrol.memUsed == 0);
    pushHelper.doPush(16'hABCD);
    assert (rcontrol.memUsed == 1);
    pushHelper.doPush(16'hEF01);
    assert (rcontrol.memUsed == 2);
    pushHelper.doPush(16'h2345);
    assert (rcontrol.memUsed == 2);
    pushHelper.doPush(16'h6789);
    assert (rcontrol.memUsed == 2);
    
    popHelper.doPop();	
    assert (pop.data == 16'h2345);
    assert (rcontrol.memUsed == 1);
    
    popHelper.doPop();	
    assert (pop.data == 16'h6789);
    assert (rcontrol.memUsed == 0);
    
    #10 $stop;
  end

  always #1  clk =  ! clk;

endmodule


module test_ringBufferConcurentOverflow();
	bit nRst, clk;
	
	IMemory mbus();
	IMemoryReader rbus[1:0]();
	IMemoryWriter wbus[1:0]();
	IArbiter abus[3:0]();
	IRingBufferControl rcontrol[1:0]();
	IPush	push[1:0]();
	IPop	pop[1:0]();

	Arbiter			arbiter(nRst, clk, abus);
	MemoryHelper  mem(nRst, clk, mbus.memory);
	MemoryWriter	writerA(nRst, clk, mbus.writer, wbus[0].slave, abus[0].client);
	MemoryWriter	writerB(nRst, clk, mbus.writer, wbus[1].slave, abus[1].client);
	MemoryReader	readerA(nRst, clk, mbus.reader, rbus[0].slave, abus[2].client);
	MemoryReader	readerB(nRst, clk, mbus.reader, rbus[1].slave, abus[3].client);
	
	RingBuffer			#(.MEM_START_ADDR(16'h00), .MEM_END_ADDR(16'h02))
					ringA	 (nRst, clk, rcontrol[0].slave, push[0].slave, pop[0].slave, wbus[0].master, rbus[0].master);

	RingBuffer			#(.MEM_START_ADDR(16'h10), .MEM_END_ADDR(16'h12))
					ringB	 (nRst, clk, rcontrol[1].slave, push[1].slave, pop[1].slave, wbus[1].master, rbus[1].master);
					
	//test helpers
	IPushHelper pushHelperA(clk, push[0]);
	IPushHelper pushHelperB(clk, push[1]);
	IPopHelper  popHelperA(clk, pop[0]);
	IPopHelper  popHelperB(clk, pop[1]);
	
	initial begin
    clk = '1;	nRst = '0;
    {rcontrol[0].open, rcontrol[0].commit, rcontrol[0].rollback} = '0;
    {rcontrol[1].open, rcontrol[1].commit, rcontrol[1].rollback} = '0;
    #2	nRst = '1;
	
    fork
      begin
        assert (rcontrol[0].memUsed == 0);
        pushHelperA.doPush(16'h1111);
        assert (rcontrol[0].memUsed == 1);
        pushHelperA.doPush(16'h2222);
        assert (rcontrol[0].memUsed == 2);
        pushHelperA.doPush(16'h3333);
        assert (rcontrol[0].memUsed == 2);
        pushHelperA.doPush(16'h4444);
        assert (rcontrol[0].memUsed == 2);
        pushHelperA.doPush(16'h5555);
        assert (rcontrol[0].memUsed == 2);
        pushHelperA.doPush(16'h6666);
        assert (rcontrol[0].memUsed == 2);
      end
      begin
        assert (rcontrol[1].memUsed == 0);
        pushHelperB.doPush(16'h7777);
        assert (rcontrol[1].memUsed == 1);
        pushHelperB.doPush(16'h8888);
        assert (rcontrol[1].memUsed == 2);
      end
    join
    
    fork
      begin
        popHelperA.doPop();	
        assert (rcontrol[0].memUsed == 1);
        assert (pop[0].data == 16'h5555);
      end
      
      begin
        popHelperB.doPop();	
        assert (rcontrol[1].memUsed == 1);
        assert (pop[1].data == 16'h7777);
      end
    join

    #10 $stop;
  end

  always #1 clk = !clk;

endmodule

module test_ringBufferCommitRollback();
	bit nRst, clk;
	
	IMemory mbus();
	IMemoryReader rBus();
	IMemoryWriter wBus();
	IArbiter abus[3:0]();
	IRingBufferControl rcontrol();
	IPush	push();
	IPop	pop();

	MemoryHelper  mem(nRst, clk, mbus.memory);
	MemoryReader	reader(nRst, clk, mbus.reader, rBus.slave, abus[1].client);
	MemoryWriter	writer(nRst, clk, mbus.writer, wBus.slave, abus[0].client);
	Arbiter			arbiter(nRst, clk, abus);
	RingBuffer		ring(nRst, clk, rcontrol.slave, push.slave, pop.slave, wBus.master, rBus.master);
	
	//test helpers
	IPushHelper pushHelper(clk, push);
	IPopHelper  popHelper(clk, pop);
  IRingBufferHelper rbHelper(clk, rcontrol);
	
	
  initial begin
    clk = '1;	nRst = '0; 
    rbHelper.doInit();
	
	  #2	nRst = '1;

    assert (rcontrol.memUsed == 0);

    rbHelper.doOpen();
   
	  pushHelper.doPush(16'hABCD);
	  assert (rcontrol.memUsed == 0);

    rbHelper.doCommit();
    #1 assert (rcontrol.memUsed == 1);
	  
	  pushHelper.doPush(16'h1234);
    assert (rcontrol.memUsed == 2);

    popHelper.doPop();
    assert (pop.data == 16'hABCD);
    assert (rcontrol.memUsed == 1);
  
    popHelper.doPop();
    assert (pop.data == 16'h1234);
    assert (rcontrol.memUsed == 0);

    rbHelper.doOpen();
   
	  pushHelper.doPush(16'hABCD);
	  assert (rcontrol.memUsed == 0);

    rbHelper.doRollback();
    #1 assert (rcontrol.memUsed == 0);
    
    #10 $stop;
  end

  always #1  clk =  !clk;
endmodule


module test_ringBufferOverflowCommitRollback();
	bit nRst, clk;
	
	IMemory mbus();
	IMemoryReader rBus();
	IMemoryWriter wBus();
	IArbiter abus[3:0]();
	IRingBufferControl rcontrol();
	IPush	push();
	IPop	pop();

	MemoryHelper  mem(nRst, clk, mbus.memory);
	MemoryReader	reader(nRst, clk, mbus.reader, rBus.slave, abus[1].client);
	MemoryWriter	writer(nRst, clk, mbus.writer, wBus.slave, abus[0].client);
	Arbiter			arbiter(nRst, clk, abus);
	
	RingBuffer	#(.MEM_START_ADDR(16'h00), .MEM_END_ADDR(16'h02))	
	           ring(nRst, clk, rcontrol.slave, push.slave, pop.slave, wBus.master, rBus.master);
     
	//test helpers
	IPushHelper pushHelper(clk, push);
	IPopHelper  popHelper(clk, pop);
  IRingBufferHelper rbHelper(clk, rcontrol);
	
  initial begin
    clk = '1;	nRst = '0; 
    rbHelper.doInit();
	
	  #2	nRst = '1;

    assert (rcontrol.memUsed == 0);
    pushHelper.doPush(16'hABCD);
    assert (rcontrol.memUsed == 1);

    rbHelper.doOpen();
	  
    pushHelper.doPush(16'hEF01);
    assert (rcontrol.memUsed == 1);
    pushHelper.doPush(16'h2345);
    assert (rcontrol.memUsed == 0);
    pushHelper.doPush(16'h6789);
    assert (rcontrol.memUsed == 0);

    rbHelper.doCommit();
    #1 assert (rcontrol.memUsed == 2);
    
    popHelper.doPop();	
    assert (pop.data == 16'h2345);
    assert (rcontrol.memUsed == 1);
    popHelper.doPop();	
    assert (pop.data == 16'h6789);
    assert (rcontrol.memUsed == 0);

    pushHelper.doPush(16'hABCD);
    assert (rcontrol.memUsed == 1);

    rbHelper.doOpen();

    pushHelper.doPush(16'h0123);
    assert (rcontrol.memUsed == 1);
    
    rbHelper.doRollback();
    #1 assert (rcontrol.memUsed == 1);

    popHelper.doPop();	
    assert (pop.data == 16'hABCD);
    assert (rcontrol.memUsed == 0);

    #10 
    $stop;
  end

  always #1  clk =  ! clk;

endmodule











