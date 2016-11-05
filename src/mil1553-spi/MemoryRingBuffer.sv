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
										taddr, nextTaddr;
	
	logic [`ADDRW_TOP:0] 	used;
	
	assign wbus.addr = waddr;
	assign wbus.data = push.data;
	assign rbus.addr = raddr;
	assign pop.data = rbus.data;
	assign wbus.request = push.request;
	assign rbus.request = (used == '0) ? 0 : pop.request;
	assign control.memUsed = used;
	
	assign used = (taddr >= raddr) ? (taddr - raddr)
											 : (MEM_END_ADDR - MEM_START_ADDR + taddr - raddr + 1);
	
	logic debug;
	assign debug = (taddr >= raddr);
											
	logic isInTransaction;
	logic isInTransactionFlag;
	assign isInTransaction = control.open | isInTransactionFlag;
	
	always_ff @ (posedge clk)
		if(!nRst) begin
			waddr <= MEM_START_ADDR;
			raddr <= MEM_START_ADDR;
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
		nextWaddr = waddr;
		nextRaddr = raddr;
		nextTaddr = taddr;
		
		optWaddr = (waddr == MEM_END_ADDR) ? MEM_START_ADDR : waddr + 1;
		optRaddr = (raddr == MEM_END_ADDR) ? MEM_START_ADDR : raddr + 1;
		
		if(rbus.done) begin
			if(used > 0) nextRaddr = optRaddr;
		end
		
		if(wbus.done) begin
			nextWaddr = optWaddr;
			if(!isInTransaction) nextTaddr = optWaddr;
			
			if(optWaddr == raddr)
				nextRaddr = optRaddr;
			if(optWaddr == taddr)
				nextTaddr = optWaddr;
		end
		
		if(control.rollback)
			nextWaddr = nextTaddr;
		else if(control.commit)
			nextTaddr = nextWaddr;
	end
endmodule

`endif
