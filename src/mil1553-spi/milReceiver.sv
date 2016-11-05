/* MIL-STD-1553 <-> SPI converter
 * Copyright(c) 2016 Stanislav Zhelnio
 * Licensed under the MIT license (MIT)
 * https://github.com/zhelnio/mil1553-spi
 */

`ifndef MILRECEIVER_INCLUDE
`define MILRECEIVER_INCLUDE

interface IMilRxControl();
	logic grant, busy;

	modport slave(	input grant, output busy);
	modport master(	output grant, input busy);

endinterface

module milReceiver(	input bit nRst, clk,
					 IMilStd.rx mil,
					 IPushMil.master push,
					 IMilRxControl.slave control);
	
	import milStd1553::*;
	
	logic signal;
	assign signal = (control.grant) ? mil.RXin : 1'b0;
	
	logic readStrobe;
	readStrobeGenerator strobeGen(nRst, clk, signal, readStrobe);
	
	struct packed {
		logic [1:0]		prev;
		logic [5:0]  	sync;
		logic [31:0] 	content;
		logic [1:0] 	parity;
		logic [2:0]		next;
	} buffer;
	
	assign control.busy = mil.RXin | mil.nRXin;
	
	logic wordReceived, parityIsIncorrect;
	MilData data;
	logic [16:0] error;
	
	upFront wordReceivedUp(nRst, clk, wordReceived, push.request);
	
	always_ff @ (posedge clk) begin
		if(!nRst)
			buffer <= '0;
		else begin
			if(readStrobe)
				buffer <= {buffer[($bits(buffer) - 2):0], signal};
			if(wordReceived)
				push.data <= data;
		end
	end
	
	always_comb begin

		for(int i = 0; i != 16; i++) begin
			data.dataWord[i] = buffer.content[i * 2 + 1];
			error[i] = !(buffer.content[i * 2] ^ buffer.content[i * 2 + 1]);
		end
		error[16] = !(^buffer.parity);
		
		wordReceived = 1'b0;
		parityIsIncorrect = (buffer.parity[1] == (^data.dataWord));
		
		if(error == '0) begin
			if(	buffer.sync == 6'b111000 && (buffer.next == 3'b000 || buffer.next == 3'b111)) begin
				data.dataType = parityIsIncorrect ? WSERVERR : WSERV; 
				wordReceived = 1'b1; 
			end
			if(	buffer.sync == 6'b000111 && (buffer.next == 3'b000 || buffer.next == 3'b111) && buffer.prev != 2'b00) begin
				data.dataType = parityIsIncorrect? WDATAERR : WDATA; 
				wordReceived = 1'b1; 
			end
		end
	end

endmodule

module readStrobeGenerator(	input bit nRst, clk,
							input logic line, 
							output logic strobe);
	parameter period = 49;
	parameter start = 25;
	
	logic changeStrobe;
	logic [5:0] cntr, nextCntr;
	
	assign strobe = (cntr == 0);

	signalChange schange(nRst, clk, line, changeStrobe);
	
	always_ff @ (posedge clk)
		cntr <= nextCntr;		
		
	always_comb begin
		if(!nRst | changeStrobe)	nextCntr = start;
		else if(cntr == period)	nextCntr = 0;
		else							nextCntr = cntr + 1;
	end		
endmodule

`endif