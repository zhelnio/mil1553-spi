/* MIL-STD-1553 <-> SPI bridge
 * Copyright(c) 2016 Stanislav Zhelnio
 * Licensed under the MIT license (MIT)
 * https://github.com/zhelnio/mil1553-spi
 */

`ifndef MEMORYREADER_INCLUDE
`define MEMORYREADER_INCLUDE

module MemoryReader(input bit nRst, clk, 
						  IMemory.reader mbus,			//memory side
						  IMemoryReader.slave cbus,	//reader data side
						  IArbiter.client abus			//arbiter side
);
	enum {IDLE, WAIT_ACTION, PRE_ACTION, ACTION, POST_ACTION } State, Next;
	
	always_ff @ (posedge clk)
		if(!nRst)
			State <= IDLE;
		else begin
			State <= Next;
			if(State == ACTION && Next == POST_ACTION)
				cbus.data <= mbus.rd_data;
		end
	
	always_comb begin
		Next = State;
		unique case(State)
			IDLE:			if(cbus.request)	Next = WAIT_ACTION;
			WAIT_ACTION:	if(abus.grant)		Next = PRE_ACTION;
			PRE_ACTION:		if(mbus.busy)		Next = ACTION;
			ACTION:			if(mbus.rd_ready)	Next = POST_ACTION;
			POST_ACTION:	Next = (cbus.request) ? WAIT_ACTION : IDLE;
		endcase
	end
	
	logic [1:0] out;
	assign {cbus.done, abus.request} = out;
	
	assign mbus.rd_addr 	= (State == PRE_ACTION || State == ACTION) ? cbus.addr : 'z;
	assign mbus.rd_enable	 = (!abus.grant)	? 'bz
												: ((State == PRE_ACTION) ? 'b1 : 'b0);
	
	always_comb begin
		unique case(State)
			IDLE:			out=2'b00;
			WAIT_ACTION:	out=2'b01;
			PRE_ACTION:		out=2'b01;
			ACTION:			out=2'b01;
			POST_ACTION:	out=2'b10;
		endcase
	end
endmodule

`endif