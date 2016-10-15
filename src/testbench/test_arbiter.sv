`timescale 10 ns/ 1 ns

module test_arbiter();
	bit rst, clk;
	
	IMemory mbus();
	IMemoryReader rBus();
	IMemoryWriter wBus();
	IArbiter abus[3:0]();

	AlteraMemoryWrapper mem(rst, clk, mbus.memory);
	MemoryReader	reader(rst, clk, mbus.reader, rBus.slave, abus[1].client);
	MemoryWriter	writer(rst, clk, mbus.writer, wBus.slave, abus[0].client);
	Arbiter			arbiter(rst, clk, abus);
	
	//test helpers
	IMemoryReaderHelper r_helper(clk, rBus);
	IMemoryWriterHelper w_helper(clk, wBus);
	
initial begin
	clk = '1;	rst = '1;
  #2	rst = '0;
  
  fork
      r_helper.doRead(8'h02);
      w_helper.doWrite(8'h02, 16'hABCD);
  join

end

always #1  clk =  ! clk;

endmodule