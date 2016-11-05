/* MIL-STD-1553 <-> SPI converter
 * Copyright(c) 2016 Stanislav Zhelnio
 * Licensed under the MIT license (MIT)
 * https://github.com/zhelnio/mil1553-spi
 */

`timescale 10 ns/ 1 ns

module test_memoryBlock();
	bit nRst, clk;
	
	IMemory mbus();
	IRingBufferControl rcontrol0();
	IRingBufferControl rcontrol1();
	IPush	push0();
	IPush	push1();
	IPop	pop0();
	IPop	pop1();
	
	AlteraMemoryWrapper mem(nRst, clk, mbus.memory);
	MemoryBlock			  memBlock(nRst, clk, 
	                         push0, push1, 
	                         pop0, pop1, 
	                         rcontrol0, rcontrol1, mbus);
	                         
	//test helpers
	IPushHelper pushHelperA(clk, push0);
	IPushHelper pushHelperB(clk, push1);
	IPopHelper  popHelperA(clk, pop0);
	IPopHelper  popHelperB(clk, pop1);
	
	initial begin
    clk = '1;	nRst = '0;
    {rcontrol0.open, rcontrol0.commit, rcontrol0.rollback} = '0;
    {rcontrol1.open, rcontrol1.commit, rcontrol1.rollback} = '0;
    #2	nRst = '1;
	
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
    
    assert (pop0.data == 16'h1111);
    assert (pop1.data == 16'h7777);
    
    #10 $stop;
  end                       
             
	always #1  clk = !clk;

endmodule
