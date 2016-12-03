/* MIL-STD-1553 <-> SPI converter
 * Copyright(c) 2016 Stanislav Zhelnio
 * Licensed under the MIT license (MIT)
 * https://github.com/zhelnio/mil1553-spi
 */

`include "settings.sv"

`ifndef RINGBUFFER_INCLUDE
`define RINGBUFFER_INCLUDE

interface IRingBufferControl();
	logic [`ADDRW_TOP:0]	memUsed;
	logic open, commit, rollback;
	
	modport master(input memUsed, output open, commit, rollback);
	modport slave(output memUsed, input open, commit, rollback);
endinterface

module RingBuffer(input bit nRst, clk, 
						IRingBufferControl.slave control,
						IPush.slave push,
						IPop.slave pop,
						IMemoryWriter.master wbus,
						IMemoryReader.master rbus
						);
  // real max used space = MEM_END_ADDR - MEM_START_ADDR
  // one memory cell is always unused
	parameter MEM_START_ADDR 	= 16'd0;
	parameter MEM_END_ADDR 		= 16'd2;

	logic [`ADDRW_TOP:0] 	waddr, nextWaddr, optWaddr, 
							raddr, nextRaddr, optRaddr,
							taddr, nextTaddr, optTaddr;
	
	logic [`ADDRW_TOP:0] 	used;
	
	assign wbus.addr = waddr;
	assign wbus.data = push.data;
	assign rbus.addr = raddr;
	assign pop.data = rbus.data;
	assign wbus.request = push.request;
	assign rbus.request = (used == '0) ? 0 : pop.request;
	assign control.memUsed = used;
	
	assign used = (taddr >= raddr) 	? (taddr - raddr)
									: (MEM_END_ADDR - MEM_START_ADDR + taddr - raddr + 1);
											
	logic isInTransaction;
	logic isInTransactionFlag;
	assign isInTransaction =   (control.open | isInTransactionFlag);
	
	always_ff @ (posedge clk)
		if(!nRst) begin
			raddr <= MEM_START_ADDR;
			waddr <= MEM_START_ADDR;
			taddr <= MEM_START_ADDR;
			isInTransactionFlag <= 0;
			push.done <= 0;
			pop.done <= 0;
			end
		else begin
			raddr <= nextRaddr;
			waddr <= nextWaddr;
			taddr <= nextTaddr;
			
			if(control.open)
				isInTransactionFlag <= 1;
			else if(control.commit | control.rollback)
				isInTransactionFlag <= 0;
				
			push.done <= wbus.done;
			pop.done <= rbus.done;
		end
		
	always_comb begin
		
		optWaddr = (waddr == MEM_END_ADDR) ? MEM_START_ADDR : waddr + 1;
		optRaddr = (raddr == MEM_END_ADDR) ? MEM_START_ADDR : raddr + 1;
		optTaddr = (taddr == MEM_END_ADDR) ? MEM_START_ADDR : taddr + 1;
		
		nextRaddr = (rbus.done && used > 0) || 
					(wbus.done && optWaddr == raddr) ? optRaddr : raddr;

		nextWaddr = (control.rollback) ? taddr : (wbus.done ? optWaddr : waddr);
		
		nextTaddr = (!isInTransaction) || 
					(isInTransaction && control.commit) ? nextWaddr :
					(isInTransaction && rbus.done && taddr == nextRaddr) ||
					(isInTransaction && wbus.done && taddr == nextWaddr) ? optTaddr : taddr;
	end
endmodule

`endif
