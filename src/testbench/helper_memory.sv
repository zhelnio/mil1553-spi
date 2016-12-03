/* MIL-STD-1553 <-> SPI converter
 * Copyright(c) 2016 Stanislav Zhelnio
 * Licensed under the MIT license (MIT)
 * https://github.com/zhelnio/mil1553-spi
 */

`include "settings.sv"

`ifndef HELPMEMORY_INCLUDE
`define HELPMEMORY_INCLUDE

//memory helper
module MemoryHelper(    input bit nRst, clk,
						IMemory.memory mem);
	
    parameter memSize = 8'hFF;
	parameter readSimulationDelay = 8'd3;
	parameter writeSimulationDelay = 8'd3;

    logic [`DATAW_TOP:0]	data [(memSize-1):0];
	logic [`DATAW_TOP:0]	wdata [(writeSimulationDelay-1):0];
	logic [`ADDRW_TOP:0]	waddr [(writeSimulationDelay-1):0];
	logic we [(writeSimulationDelay-1):0];

	logic [`ADDRW_TOP:0]	raddr [(writeSimulationDelay-1):0];
	logic re [(writeSimulationDelay-1):0];

	assign mem.busy = we.or() | re.or() | mem.wr_enable | mem.rd_enable;

	always_ff @ (posedge clk) begin
		if(!nRst) begin
			for(int i=0; i < writeSimulationDelay; i++)
				we[i] <= '0;
			for(int i=0; i < readSimulationDelay; i++)
				re[i] <= '0;
			mem.rd_ready <= '0;
			end
		else begin
			//write register chain
			wdata[0] <= mem.wr_data;
			waddr[0] <= mem.wr_addr;
			we[0]	 <= mem.wr_enable;
			for(int i=1; i < writeSimulationDelay; i++) begin
				wdata[i] <= wdata[i-1];
				waddr[i] <= waddr[i-1];
				we[i] 	 <= we[i-1];
			end
			if(we[(writeSimulationDelay-1)])
				data[waddr[(writeSimulationDelay-1)]] <= wdata[(writeSimulationDelay-1)];

			//read register chain
			raddr[0] <= mem.rd_addr;
			re[0]	 <= mem.rd_enable;
			for(int i=1; i < readSimulationDelay; i++) begin
				raddr[i] <= raddr[i-1];
				re[i] 	 <= re[i-1];
			end
			mem.rd_data <= (re[(readSimulationDelay-1)]) ? data[raddr[(readSimulationDelay-1)]] : 'bz;
			mem.rd_ready <= re[(readSimulationDelay-1)];
		end
	end
	
endmodule


`endif
