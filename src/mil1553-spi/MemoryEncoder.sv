`include "settings.sv"

`ifndef MEMENCODER_INCLUDE
`define MEMENCODER_INCLUDE

`define ESC_WERROR	16'hFFA0
`define ESC_WCOMMAND	16'hFFA1
`define ESC_WSTATUS	16'hFFA2
`define ESC_WDATA		16'hFFA3
`define ESC_MASK		(14'hFFA << 2)

module milMemEncoder(input bit rst, clk,
							IPushMil.slave mil,
							IPush.master push);
	
	import milStd1553::*;
	
	logic [`DATAW_TOP:0]	data, nextData, escData;
	assign push.data = data;
	
	enum {IDLE, WORD1_LOAD, WORD1_WAIT, WORD2_LOAD, WORD2_WAIT, REPORT } State, Next;
	
	assign push.request = (State == WORD1_LOAD || State == WORD2_LOAD);
	assign mil.done = (State == REPORT);
	
	always_ff @ (posedge clk)
		if(rst)
			State = IDLE;
		else 
			State = Next;
			
	always_ff @ (posedge clk) begin
		data <= nextData;
	end
	
	always_comb begin
		escData = '0;
		unique case(mil.data.dataType)
			WERROR:		escData = `ESC_WERROR;
			WCOMMAND:	escData = `ESC_WCOMMAND;
			WSTATUS:		escData = `ESC_WSTATUS;
			WDATA:		if(mil.data.dataWord[15:2] == `ESC_MASK)
								escData = `ESC_WDATA;
		endcase
		
		Next = State;
		unique case(State)
			IDLE:			if(mil.request)
								Next = (escData == '0) ? WORD2_LOAD : WORD1_LOAD;
			WORD1_LOAD:	Next = WORD1_WAIT;
			WORD1_WAIT:	if(push.done) Next = WORD2_LOAD;
			WORD2_LOAD:	Next = WORD2_WAIT;
			WORD2_WAIT: if(push.done) Next = REPORT;
			REPORT:		Next = IDLE;
		endcase
		
		nextData = 'z;	
		unique case(Next)
			IDLE:			;
			WORD1_LOAD:	nextData = escData;
			WORD1_WAIT:	nextData = escData;
			WORD2_LOAD:	nextData = mil.data.dataWord;
			WORD2_WAIT:	nextData = mil.data.dataWord;
			REPORT:		;
		endcase
	end

endmodule


module MemMilEncoder(input bit rst, clk,
							IPushMil.master mil,
							IPush.slave push);
	
	import milStd1553::*;
	WordType	dataType, nextDataType;
	
	enum {IDLE, WORD1_DONE, WORD2_LOAD, WORD2_SEND, WORD2_WAIT, WORD2_DONE } State, Next;
	
	assign mil.request = (State == WORD2_SEND);
	assign push.done = (State == WORD1_DONE || State == WORD2_DONE);
	
	always_ff @ (posedge clk)
		if(rst)
			State = IDLE;
		else 
			State = Next;
	
	logic isEscData;
	assign isEscData = (push.data[15:2] == `ESC_MASK);
	
	logic idleState;	//непонятный баг, без этого не работает
	assign idleState = (State == IDLE);	
	
	always_ff @ (posedge clk) begin		
		if(idleState)
			dataType <= nextDataType;
		if(State == WORD2_SEND) begin
			mil.data.dataWord <= push.data;
			mil.data.dataType <= dataType;
		end
	end
	
	always_comb begin
		nextDataType = WDATA;
		priority case(push.data)
			`ESC_WERROR:	nextDataType = WERROR;
			`ESC_WCOMMAND:	nextDataType = WCOMMAND;
			`ESC_WSTATUS: 	nextDataType = WSTATUS;
			`ESC_WDATA:		nextDataType = WDATA;
			default:			nextDataType = WDATA;
		endcase
	end
	
	always_comb begin
		Next = State;
		unique case(State)
			IDLE:			if(push.request) Next = (isEscData) ? WORD1_DONE : WORD2_SEND;
			WORD1_DONE:	Next = WORD2_LOAD;
			WORD2_LOAD:	if(push.request) Next = WORD2_SEND;	
			WORD2_SEND: Next = WORD2_WAIT;
			WORD2_WAIT: if(mil.done) Next = WORD2_DONE;
			WORD2_DONE:	Next = IDLE;
		endcase
	end

endmodule

`endif
