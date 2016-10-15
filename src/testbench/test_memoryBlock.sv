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
    
    assert (pop[0].data == 16'h1111);
    assert (pop[1].data == 16'h7777);
    
    #10 $stop;
  end                       
             
	always #1  clk = !clk;

endmodule
