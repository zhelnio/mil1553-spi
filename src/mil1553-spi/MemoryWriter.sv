/* MIL-STD-1553 <-> SPI converter
 * Copyright(c) 2016 Stanislav Zhelnio
 * Licensed under the MIT license (MIT)
 * https://github.com/zhelnio/mil1553-spi
 */

`ifndef MEMORYWRITER_INCLUDE
`define MEMORYWRITER_INCLUDE

module MemoryWriter(input bit nRst, clk, 
						  IMemory.writer mbus,
						  IMemoryWriter.slave cbus,
						  IArbiter.client abus
);
	enum {IDLE, WAIT_ACTION, PRE_ACTION, ACTION, POST_ACTION } State, Next;
	
	always_ff @ (posedge clk)
		if(!nRst)
			State <= IDLE;
		else
			State <= Next;
	
	always_comb begin
		Next = State;
		unique case(State)
			IDLE:			if(cbus.request) Next = WAIT_ACTION;
			WAIT_ACTION:	if(abus.grant) Next = PRE_ACTION;
			PRE_ACTION:		if(mbus.busy) Next = ACTION;
			ACTION:			if(!mbus.busy) Next = POST_ACTION;
			POST_ACTION:	Next = (cbus.request) ? WAIT_ACTION : IDLE;
		endcase
	end
	
	logic [1:0] out;
	assign {cbus.done, abus.request} = out;
	
	assign mbus.wr_addr = (State == PRE_ACTION || State == ACTION) ? cbus.addr : 'z;
	assign mbus.wr_data = (State == PRE_ACTION || State == ACTION) ? cbus.data : 'z;	
	assign mbus.wr_enable = (!abus.grant)	? 'bz
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