`ifndef MILRECEIVER_INCLUDE
`define MILRECEIVER_INCLUDE

module milReceiver(input bit rst, clk,
					 IMilStd.rx mil,
					 input tri0 enable,
					 IPushMil.master push,
					 output logic isBusy);
	
	import milStd1553::*;
	
	logic signal;
	assign signal = (enable) ? mil.RXin : 1'b0;
	
	logic readStrobe;
	readStrobeGenerator strobeGen(rst, clk, signal, readStrobe);
	
	struct packed {
		logic [1:0]		prev;
		logic [5:0]  	sync;
		logic [31:0] 	content;
		logic [1:0] 	parity;
		logic [2:0]		next;
	} buffer;
	
	assign isBusy = | buffer[7:0];
	
	logic wordReceived, parityBit;
	MilData data;
	logic [16:0] error;
	
	upFront wordReceivedUp(rst, clk, wordReceived, push.request);
	
	always_ff @ (posedge clk) begin
		if(rst)
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
		
		parityBit = buffer.parity[1];
		error[16] = !(^buffer.parity);
		
		wordReceived = 1'b0;
		
		if(error == '0) begin
			if(buffer.sync == 6'b111000 && (buffer.next == 3'b000 || buffer.next == 3'b111))
				begin data.dataType = WSTATUS; wordReceived = 1'b1; end
			if(buffer.sync == 6'b000111 && (buffer.next == 3'b000 || buffer.next == 3'b111) && buffer.prev != 2'b00)
				begin data.dataType = WDATA; wordReceived = 1'b1; end
			
			if(data.dataType == WSTATUS && data.dataWord[9] == 1'b1)
				data.dataType = WCOMMAND;
				
			if(parityBit == (^data.dataWord))
				data.dataType = WERROR;
		end
	end


endmodule

module readStrobeGenerator(input bit rst, clk,
									input logic line, 
									output logic strobe);
	parameter period = 49;
	parameter start = 25;
	
	logic changeStrobe;
	logic [5:0] cntr, nextCntr;
	
	assign strobe = (cntr == 0);

	signalChange schange(rst, clk, line, changeStrobe);
	
	always_ff @ (posedge clk)
		cntr <= nextCntr;		
		
	always_comb begin
		if(rst | changeStrobe)	nextCntr = start;
		else if(cntr == period)	nextCntr = 0;
		else							nextCntr = cntr + 1;
	end		
endmodule

`endif