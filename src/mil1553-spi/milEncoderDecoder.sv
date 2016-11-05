/* MIL-STD-1553 <-> SPI converter
 * Copyright(c) 2016 Stanislav Zhelnio
 * Licensed under the MIT license (MIT)
 * https://github.com/zhelnio/mil1553-spi
 */

`include "settings.sv"

`ifndef MILENDECODER_INCLUDE
`define MILENDECODER_INCLUDE

`define ESC_WSERVERR	16'hFFA0
`define ESC_WSERV		16'hFFA1
`define ESC_WDATAERR	16'hFFA2
`define ESC_WDATA		16'hFFA3
`define ESC_MASK		(14'hFFA << 2)

module milMemEncoder(input bit nRst, clk,
							IPushMil.slave mil,
							IPush.master push);
	
	import milStd1553::*;
	
	logic [`DATAW_TOP:0]	data, nextData, escData;
	assign push.data = data;
	
	enum logic[2:0] {IDLE = 3'd0, WORD1_LOAD = 3'd1, WORD1_WAIT = 3'd2, 
					WORD2_LOAD = 3'd3, WORD2_WAIT = 3'd4, REPORT  = 3'd5 } State, Next;
	
	assign push.request = (State == WORD1_LOAD || State == WORD2_LOAD);
	assign mil.done = (State == REPORT);
	
	always_ff @ (posedge clk)
		if(!nRst)
			State = IDLE;
		else 
			State = Next;
			
	always_ff @ (posedge clk) begin
		data <= nextData;
	end
	
	always_comb begin
		escData = '0;
		unique case(mil.data.dataType)
			WSERVERR:	escData = `ESC_WSERVERR;
			WSERV:		escData = `ESC_WSERV;
			WDATAERR:	escData = `ESC_WDATAERR;
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


module memMilEncoder(input bit nRst, clk,
							IPushMil.master mil,
							IPush.slave push);
	
	import milStd1553::*;
	WordType	dataType, nextDataType;
	
	enum logic[2:0] {IDLE = 3'd0, WORD1_DONE = 3'd1, WORD2_LOAD = 3'd2, 
					 WORD2_SEND = 3'd3, WORD2_WAIT = 3'd4, WORD2_DONE = 3'd5} State, Next;
	
	assign mil.request = (State == WORD2_SEND);
	assign push.done = (State == WORD1_DONE || State == WORD2_DONE);
	
	always_ff @ (posedge clk)
		if(!nRst)
			State = IDLE;
		else 
			State = Next;
	
	logic isEscData;
	assign isEscData = (push.data[15:2] == `ESC_MASK);
	
	logic idleState;	//strange bug, not working wout this
	assign idleState = (State == IDLE);	
	
	always_ff @ (posedge clk) begin		
		if(idleState)
			dataType <= nextDataType;
		if(Next == WORD2_SEND) begin
			mil.data.dataWord <= push.data;
			mil.data.dataType <= dataType;
		end
	end
	
	always_comb begin
		nextDataType = WDATA;
		priority case(push.data)
			`ESC_WSERVERR:	nextDataType = WSERVERR;
			`ESC_WSERV:		nextDataType = WSERV;
			`ESC_WDATAERR: 	nextDataType = WDATAERR;
			`ESC_WDATA:		nextDataType = WDATA;
			default:		nextDataType = WDATA;
		endcase
	end
	
	always_comb begin
		Next = State;
		unique case(State)
			IDLE:		if(push.request) Next = (isEscData) ? WORD1_DONE : WORD2_SEND;
			WORD1_DONE:	Next = WORD2_LOAD;
			WORD2_LOAD:	if(push.request) Next = WORD2_SEND;	
			WORD2_SEND: Next = WORD2_WAIT;
			WORD2_WAIT: if(mil.done) Next = WORD2_DONE;
			WORD2_DONE:	Next = IDLE;
		endcase
	end

endmodule

`endif
