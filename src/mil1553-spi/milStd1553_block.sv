`ifndef MILSTD1553_BLOCK
`define MILSTD1553_BLOCK



interface IMilStdControl();
	logic receiverBusy, transmitterBusy;
	logic packetStart, packetEnd;
	
	modport slave(output receiverBusy, transmitterBusy, packetStart, packetEnd);
	modport master(input receiverBusy, transmitterBusy, packetStart, packetEnd);

endinterface

interface IMilStd();
	logic TXout, nTXout, RXin, nRXin;
	
	modport device(input RXin, nRXin, output TXout, nTXout);
	modport line(output RXin, nRXin, input TXout, nTXout);
	
endinterface

module MilStd(	input bit rst, clk,
					IPushMil.master rpush,
					IPushMil.slave tpush,
					IMilStd.device line,
					IMilStdControl control);
	
	parameter T2R_DELAY = 12;
	
	enum logic[1:0] {RECEIVE, TRANSMIT, WAIT} State, Next;
	
	logic [3:0] cntr, nextCntr;
	logic rcvEnable, rcvBusy, trEnable, trBusy, trRequest;
	logic iline, oline;
	logic ioClk;
	
	ioClkGenerator ioClkGen(rst, clk, ioClk);
	
	assign line.TXout = (State == TRANSMIT) ? oline : 1'b0;
	assign line.nTXout = (State == TRANSMIT) ? !oline : 1'b0;
	assign iline = line.RXin;
	assign control.receiverBusy = rcvBusy;
	assign control.transmitterBusy = trBusy;
	
	upFront		packetStartStrobe(rst, clk, rcvBusy, control.packetStart);
	downFront	packetEndStrobe(rst, clk, rcvBusy, control.packetEnd);
	
	logic upIoClk;
	upFront		upIoClkStrobe(rst, clk, ioClk, upIoClk);
	
	always_ff @ (posedge clk) begin
		if(rst) begin
			State <= RECEIVE;
			cntr <= 0;
			end
		else begin
			State <= Next;
			if(upIoClk) cntr <= nextCntr;
		end
	end
	
	always_comb begin
		Next = State;
		unique case(State)
			RECEIVE:		if(!rcvBusy && trRequest) Next = TRANSMIT;
			TRANSMIT:	if(!trBusy && !trRequest) Next = WAIT;
			WAIT:			if(cntr == T2R_DELAY || rcvBusy) Next = RECEIVE;
		endcase
		
		unique case(State)
			RECEIVE:		{rcvEnable, trEnable} = 2'b10;
			TRANSMIT:	{rcvEnable, trEnable} = 2'b01;
			WAIT:			{rcvEnable, trEnable} = 2'b10;
		endcase
		
		nextCntr = (State == WAIT) ? (cntr + 1) : 0;
	end
	
	transmitter t(rst, clk, ioClk, trEnable, tpush, oline, trBusy, trRequest);
	receiver		r(rst, clk, iline, rcvEnable, rpush, rcvBusy);
	
endmodule	

module ioClkGenerator(input bit rst, clk, 
							 output logic ioClk);
	parameter period = 49;
	logic [5:0] cntr, nextCntr;
	
	assign nextCntr = (cntr == period) ? 0 : (cntr + 1);
	
	always_ff @ (posedge clk)
	if(rst) begin
		cntr <= '0;
		ioClk <= 1'b0;
		end
	else begin
		cntr <= nextCntr;
		if(nextCntr == 0)
			ioClk = !ioClk;
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

module receiver(input bit rst, clk,
					 input tri0 line, enable,
					 IPushMil.master push,
					 output logic isBusy);
	
	import milStd1553::*;
	
	logic signal;
	assign signal = (enable) ? line : 1'b0;
	
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
	MilDecodedData data;
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

module transmitter(input bit rst, clk, ioClk, 
						 input logic enable, 
						 IPushMil.slave push,
						 output logic line, isBusy, request);
						 
	import milStd1553::*;
	
	logic upIoClk, downIoClk;
	upFront		up(rst, clk, ioClk, upIoClk);
	downFront 	down(rst, clk, ioClk, downIoClk);
	
	enum logic[3:0] {IDLE, LOAD, DATA, PARITY, POSTFIX1, POSTFIX2,
						  L01, L02, H11, H12, H01, H02, L11, L12} State, Next;
	
	assign isBusy = (State != IDLE);
	assign push.done = (State == LOAD);
	
	logic dataInQueue, parityBit;
	logic [3:0] cntr, nextCntr;
	MilDecodedData	data;
	
	assign request = dataInQueue;
	
	always_ff @ (posedge clk) begin
		if(rst)
			State <= IDLE;
		else
			State <= Next;
	end
	
	always_ff @ (posedge clk) begin
		if(rst)
			dataInQueue <= 0;
		else begin
			if(push.request & !dataInQueue)
				dataInQueue <= 1;
			if(!push.request && State == LOAD)
				dataInQueue <= 0;
		end
	end
					
	always_ff @ (posedge clk) begin
		unique case(Next)
			IDLE:	line <= 1'b0;
			LOAD:	begin data <= push.data; parityBit <= '1; end
			L01:	line <= 1'b0;
			L02:	line <= 1'b0;
			H11:	line <= 1'b1;
			H12:	line <= 1'b1;
			H01:	line <= 1'b1;
			H02:	line <= 1'b1;
			L11:	line <= 1'b0;
			L12:	line <= 1'b0;
			DATA: begin	
						if(upIoClk) begin
							line <= data.dataWord[nextCntr];
							parityBit <= parityBit ^ data.dataWord[nextCntr];
							end
						
						if(downIoClk)
							line <= !data.dataWord[cntr];
					end
			PARITY: begin	
						if(upIoClk)
							line <= parityBit;
						if(downIoClk)
							line <= !parityBit;
					end
			POSTFIX1: line <= 1'b0;
			POSTFIX2: line <= 1'b0;
		endcase
		
		if(upIoClk)
			cntr <= nextCntr;
	end

	always_comb begin
		nextCntr = (State == DATA) ? cntr - 1 : 15;
	
		Next = State;
		unique case(State)
			IDLE:	if(dataInQueue && upIoClk && enable) Next = LOAD;
			LOAD:	unique case(data.dataType)
						WERROR:		Next = IDLE;
						WDATA: 		Next = L01;
						WCOMMAND:	Next = H01;
						WSTATUS:		Next = H01;
					endcase
			L01:	if(downIoClk) 	Next = L02;
			L02:	if(downIoClk) 	Next = H11;
			H11:	if(upIoClk)		Next = H12;
			H12:	if(upIoClk)		Next = DATA;
			H01:	if(downIoClk) 	Next = H02;
			H02:	if(downIoClk) 	Next = L11;
			L11:	if(upIoClk)		Next = L12;
			L12:	if(upIoClk)		Next = DATA;
			DATA:	if(upIoClk && nextCntr == 15) Next = PARITY;
			PARITY: if(upIoClk) 		Next = (dataInQueue) ? LOAD : POSTFIX1;
			POSTFIX1: if(upIoClk) 	Next = POSTFIX2;
			POSTFIX2: if(downIoClk)	Next = IDLE;
		endcase
	end
	
endmodule












































`endif