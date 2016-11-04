`ifndef MILTRANSMITTER_INCLUDE
`define MILTRANSMITTER_INCLUDE

interface IMilTxControl();
	logic grant, busy, request;

	modport slave(input grant, output busy, request);
	modport master(output grant, input busy, request);

endinterface

module milTransmitter(input bit rst, clk, ioClk, 
						          IPushMil.slave push,
						          IMilStd.tx mil,
						          IMilTxControl.slave control);
  import milStd1553::*;
	
	logic upIoClk, downIoClk;
	upFront		up(rst, clk, ioClk, upIoClk);
	downFront 	down(rst, clk, ioClk, downIoClk);
	
	enum logic[3:0] {IDLE, LOAD, DATA, PARITY, POSTFIX1, POSTFIX2,
						  L01, L02, H11, H12, H01, H02, L11, L12} State, Next;
	
	logic line;
	assign mil.TXout = (State != IDLE) ? line : 1'b0;
	assign mil.nTXout = (State != IDLE) ? !line : 1'b0;
	assign control.busy = (State != IDLE);
	assign push.done = (State == LOAD);
	
	logic dataInQueue, parityBit;
	logic [3:0] cntr, nextCntr;
	MilData	data;
	
	assign control.request = dataInQueue || control.busy;
	
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
			IDLE:	if(dataInQueue && upIoClk && control.grant) Next = LOAD;
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