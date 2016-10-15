`include "settings.sv"

`ifndef RINGBUFFER_INCLUDE
`define RINGBUFFER_INCLUDE

module MemoryReader(input bit rst, clk, 
						  IMemory.reader mbus,			//memory side
						  IMemoryReader.slave cbus,	//reader data side
						  IArbiter.client abus			//arbiter side
);
	enum {IDLE, WAIT_ACTION, PRE_ACTION, ACTION, POST_ACTION } State, Next;
	
	always_ff @ (posedge clk)
		if(rst)
			State <= IDLE;
		else begin
			State <= Next;
			if(State == ACTION && Next == POST_ACTION)
				cbus.data <= mbus.rd_data;
		end
	
	always_comb begin
		Next = State;
		unique case(State)
			IDLE:			       if(cbus.request) Next = WAIT_ACTION;
			WAIT_ACTION:   if(abus.grant) Next = PRE_ACTION;
			PRE_ACTION:	   if(mbus.busy) Next = ACTION;
			ACTION:		      if(!mbus.busy) Next = POST_ACTION;
			POST_ACTION:   Next = (cbus.request) ? WAIT_ACTION : IDLE;
		endcase
	end
	
	logic [2:0] out;
	assign {mbus.rd_enable, cbus.done, abus.request} = out;
	
	assign mbus.rd_addr = (State == PRE_ACTION || State == ACTION) ? cbus.addr : 'z;
	
	always_comb begin
		unique case(State)
			IDLE:				      out=3'bz00;
			WAIT_ACTION:	  out=3'bz01;
			PRE_ACTION:		  out=3'b101;
			ACTION:			     out=3'b001;
			POST_ACTION: 	 out=3'bz10;
		endcase
	end
endmodule


module MemoryWriter(input bit rst, clk, 
						  IMemory.writer mbus,
						  IMemoryWriter.slave cbus,
						  IArbiter.client abus
);
	enum {IDLE, WAIT_ACTION, PRE_ACTION, ACTION, POST_ACTION } State, Next;
	
	always_ff @ (posedge clk)
		if(rst)
			State <= IDLE;
		else
			State <= Next;
	
	always_comb begin
		Next = State;
		unique case(State)
			IDLE:				if(cbus.request) Next = WAIT_ACTION;
			WAIT_ACTION:	if(abus.grant) Next = PRE_ACTION;
			PRE_ACTION:		if(mbus.busy) Next = ACTION;
			ACTION:			if(!mbus.busy) Next = POST_ACTION;
			POST_ACTION: 	Next = (cbus.request) ? WAIT_ACTION : IDLE;
		endcase
	end
	
	logic [2:0] out;
	assign {mbus.wr_enable, cbus.done, abus.request} = out;
	
	assign mbus.wr_addr = (State == PRE_ACTION || State == ACTION) ? cbus.addr : 'z;
	assign mbus.wr_data = (State == PRE_ACTION || State == ACTION) ? cbus.data : 'z;
	
	always_comb begin
		unique case(State)
			IDLE:				out=3'bz00;
			WAIT_ACTION:	out=3'bz01;
			PRE_ACTION:		out=3'b101;
			ACTION:			out=3'b001;
			POST_ACTION:	out=3'bz10;
		endcase
	end

endmodule


interface IRingBufferControl();
	logic [`ADDRW_TOP:0]	memUsed;
	logic open, commit, rollback;
	
	modport master(input memUsed, output open, commit, rollback);
	modport slave(output memUsed, input open, commit, rollback);
endinterface

module RingBuffer(input bit rst, clk, 
						IRingBufferControl.slave control,
						IPush.slave push,
						IPop.slave pop,
						IMemoryWriter.master wbus,
						IMemoryReader.master rbus
);
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
	assign push.done = wbus.done;
	assign pop.done = rbus.done;
	
	assign used = (taddr >= raddr) ? (taddr - raddr)
											 : (MEM_END_ADDR - MEM_START_ADDR + taddr - raddr);
	
	logic debug;
	assign debug = (taddr >= raddr);
											
	logic isInTransaction;
	logic isInTransactionFlag;
	assign isInTransaction = control.open | isInTransactionFlag;
	
	always_ff @ (posedge clk)
		if(rst) begin
			waddr <= MEM_START_ADDR;
			raddr <= MEM_START_ADDR;
			taddr <= MEM_START_ADDR;
			isInTransactionFlag <= 0;
			end
		else begin
			raddr <= nextRaddr;
			waddr <= nextWaddr;
			taddr <= nextTaddr;
			
			if(control.open)
				isInTransactionFlag <= 1;
			else if(control.commit | control.rollback)
				isInTransactionFlag <= 0;
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
