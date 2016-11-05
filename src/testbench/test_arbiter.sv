`timescale 10 ns/ 1 ns

module test_arbiter();
	bit nRst, clk;
	
	IMemory mbus();
	IMemoryReader rBus();
	IMemoryWriter wBus();
	IArbiter abus[3:0]();

	AlteraMemoryWrapper mem(nRst, clk, mbus.memory);
	MemoryReader	reader(nRst, clk, mbus.reader, rBus.slave, abus[1].client);
	MemoryWriter	writer(nRst, clk, mbus.writer, wBus.slave, abus[0].client);
	Arbiter			arbiter(nRst, clk, abus);
	
	//test helpers
	IMemoryReaderHelper r_helper(clk, rBus);
	IMemoryWriterHelper w_helper(clk, wBus);
	
initial begin
	clk = '1;	nRst = '0;
	#2	nRst = '1;
  
	fork
		r_helper.doRead(8'h02);
		w_helper.doWrite(8'h02, 16'hABCD);
	join
end

always #1  clk =  ! clk;

endmodule