`ifndef RINGBUFFER_INCLUDE
`define RINGBUFFER_INCLUDE


`define RING_ADDR_SIZE	10

interface IMemory();
	tri0 wr_enable, rd_enable;
	tri0 [`IMEM_ADDR_SIZE:0] 	rd_addr;
	tri0 [`IMEM_ADDR_SIZE:0] 	wr_addr;
	tri0 [`IMEM_WORD_SIZE:0]	wr_data;

	logic rd_ready, busy;
	logic [`IMEM_WORD_SIZE:0]	rd_data;
	
	modport writer(output wr_addr, wr_data, wr_enable,
						input  busy);
	
	modport reader(output rd_addr, rd_enable, 
						input  rd_data, rd_ready, busy);		
	
	modport memory(input  wr_addr, wr_data, wr_enable,
						input  rd_addr, rd_enable, 
						output rd_data, rd_ready, busy);
endinterface

interface IArbiter();
	logic request, grant;
	
	modport client(output request, input grant);
	modport arbiter(input request, output grant);
endinterface

interface IMemoryReader();
	logic request, done;
	
	logic [`IMEM_ADDR_SIZE:0] 	addr;
	logic [`IMEM_WORD_SIZE:0]	data;

	modport master(output addr, input data, output request, input done);
	modport slave(input addr, output  data, input request, output done);				
endinterface

interface IMemoryWriter();
	logic request, done;

	logic [`IMEM_ADDR_SIZE:0] 	addr;
	logic [`IMEM_WORD_SIZE:0]	data;

	modport master(output addr, output data, output request, input done);
	modport slave(input addr, input data, input request, output done);
endinterface

typedef enum {IDLE, WAIT_ACTION, PRE_ACTION, ACTION, POST_ACTION } ArbiterClientState;


module MemoryReader(input bit rst, clk, 
						  IMemory.reader mbus,			//memory side
						  IMemoryReader.slave cbus,	//reader data side
						  IArbiter.client abus			//arbiter side
);
	ArbiterClientState State, Next;
	
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
			IDLE:			if(cbus.request) Next = WAIT_ACTION;
			WAIT_ACTION:if(abus.grant) Next = PRE_ACTION;
			PRE_ACTION:	if(mbus.busy) Next = ACTION;
			ACTION:		if(!mbus.busy) Next = POST_ACTION;
			POST_ACTION: Next = (cbus.request) ? WAIT_ACTION : IDLE;
		endcase
	end
	
	logic [2:0] out;
	assign {mbus.rd_enable, cbus.done, abus.request} = out;
	
	assign mbus.rd_addr = (State == PRE_ACTION || State == ACTION) ? cbus.addr : 'z;
	
	always_comb begin
		unique case(State)
			IDLE:				out=3'bz00;
			WAIT_ACTION:	out=3'bz01;
			PRE_ACTION:		out=3'b101;
			ACTION:			out=3'b001;
			POST_ACTION: 	out=3'bz10;
		endcase
	end
endmodule


module MemoryWriter(input bit rst, clk, 
						  IMemory.writer mbus,
						  IMemoryWriter.slave cbus,
						  IArbiter.client abus
);
	ArbiterClientState State, Next;
	
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
	logic [`RING_ADDR_SIZE:0]	memUsed;
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

	logic [`IMEM_ADDR_SIZE:0] 	waddr, nextWaddr, optWaddr, 
										raddr, nextRaddr, optRaddr,
										taddr, nextTaddr;
	
	logic [`RING_ADDR_SIZE:0] 	used;
	
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



module Arbiter(input bit rst, clk,
					IArbiter.arbiter client[3:0]);

	logic [3:0] requestedChannel, 
					grantedChannel, newGrantedChannel;
	
	assign {client[3].grant, client[2].grant, 
			  client[1].grant, client[0].grant} = grantedChannel;
			  
	assign requestedChannel = {client[3].request, client[2].request, 
										client[1].request, client[0].request};
	
	always_ff @ (posedge clk)
		if(rst)
			grantedChannel <= '0;
		else
			grantedChannel <= newGrantedChannel;

	always_comb begin
		newGrantedChannel = grantedChannel;

		if(!(requestedChannel & grantedChannel)) begin
			if(     requestedChannel & 4'b0001) newGrantedChannel = 4'b0001;
			else if(requestedChannel & 4'b0010) newGrantedChannel = 4'b0010;
			else if(requestedChannel & 4'b0100) newGrantedChannel = 4'b0100;
			else if(requestedChannel & 4'b1000) newGrantedChannel = 4'b1000;
			else newGrantedChannel = '0;
		end
	end
			
endmodule

module Arbiter8(input bit rst, clk,
					IArbiter.arbiter client[7:0]);

	logic [7:0] requestedChannel, 
					grantedChannel, newGrantedChannel;
	
	assign {client[7].grant, client[6].grant, client[5].grant, client[4].grant,
			  client[3].grant, client[2].grant, client[1].grant, client[0].grant } = grantedChannel;
			  
	assign requestedChannel = 
			 {client[7].request, client[6].request, client[5].request, client[4].request,
			  client[3].request, client[2].request, client[1].request, client[0].request};
	
	always_ff @ (posedge clk)
		if(rst)
			grantedChannel <= '0;
		else
			grantedChannel <= newGrantedChannel;

	always_comb begin
		newGrantedChannel = grantedChannel;

		if(!(requestedChannel & grantedChannel)) begin
			if(     requestedChannel & 8'b00000001) newGrantedChannel = 8'b00000001;
			else if(requestedChannel & 8'b00000010) newGrantedChannel = 8'b00000010;
			else if(requestedChannel & 8'b00000100) newGrantedChannel = 8'b00000100;
			else if(requestedChannel & 8'b00001000) newGrantedChannel = 8'b00001000;
			else if(requestedChannel & 8'b00010000) newGrantedChannel = 8'b00010000;
			else if(requestedChannel & 8'b00100000) newGrantedChannel = 8'b00100000;
			else if(requestedChannel & 8'b01000000) newGrantedChannel = 8'b01000000;
			else if(requestedChannel & 8'b10000000) newGrantedChannel = 8'b10000000;
			else newGrantedChannel = '0;
		end
	end
			
endmodule


`endif
