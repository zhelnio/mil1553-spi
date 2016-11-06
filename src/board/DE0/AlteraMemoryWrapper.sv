/* MIL-STD-1553 <-> SPI converter
 * Copyright(c) 2016 Stanislav Zhelnio
 * Licensed under the MIT license (MIT)
 * https://github.com/zhelnio/mil1553-spi
 */

`ifndef AMW_INCLUDE
`define AMW_INCLUDE

//memory helper
module AlteraMemoryWrapper(	input bit nRst, clk,
							IMemory.memory mem);
									
	AlteraMemory memory(	clk, mem.wr_data, 
								mem.rd_addr[7:0], mem.rd_enable, 
								mem.wr_addr[7:0], mem.wr_enable, 
								mem.rd_data);					

	logic we;
	logic re [1:0];
	assign mem.busy = we | mem.wr_enable | re[1] | re[0] | mem.rd_enable;
	
	always_ff @ (posedge clk) begin
		if(!nRst)
			{we, re[1], re[0]} <= '0;
		else
			{we, mem.rd_ready, re[1], re[0]} 
				<= {mem.wr_enable, re[1], re[0], mem.rd_enable};		
	end

endmodule

`endif 