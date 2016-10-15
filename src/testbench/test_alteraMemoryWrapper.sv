`timescale 10 ns/ 1 ns

module test_alteraMemoryWrapper();
	bit rst, clk;
	
	IMemory membus();
	AlteraMemoryWrapper mem(rst, clk, membus.memory);

  initial begin
		  clk = '1;	rst = '1;
		
  #2		rst = '0;
		  force membus.wr_addr	= 8'h02; 
		  force membus.wr_data	= 16'hABCD; 
	   	force membus.wr_enable = '1;
  		  force membus.rd_enable = '0;
		
  #2		force membus.wr_enable = '0;
	
  #10	force membus.rd_addr	= 8'h02; 
	   	force membus.rd_enable = '1;

  #2		force membus.rd_enable = '0;	

  #30 
  
  r_isEqual_w: assert (membus.wr_data == membus.rd_data)
  $stop;	
	
  end

  always #1  clk =  ! clk;
endmodule