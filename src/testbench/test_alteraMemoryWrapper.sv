/* MIL-STD-1553 <-> SPI converter
 * Copyright(c) 2016 Stanislav Zhelnio
 * Licensed under the MIT license (MIT)
 * https://github.com/zhelnio/mil1553-spi
 */

`timescale 10 ns/ 1 ns

module test_alteraMemoryWrapper();
	bit nRst, clk;
	
	IMemory membus();
	AlteraMemoryWrapper mem(nRst, clk, membus.memory);

  initial begin
		  clk = '1;	nRst = '0;
		
  #2	nRst = '1;
		  force membus.wr_addr	= 8'h02; 
		  force membus.wr_data	= 16'hABCD; 
	   	force membus.wr_enable = '1;
  		force membus.rd_enable = '0;
		
  #2	force membus.wr_enable = '0;
	
  #10	force membus.rd_addr	= 8'h02; 
	   	force membus.rd_enable = '1;

  #2	force membus.rd_enable = '0;	

  #30 
  
  r_isEqual_w: assert (membus.wr_data == membus.rd_data)
  $stop;	
	
  end

  always #1  clk =  ! clk;
endmodule