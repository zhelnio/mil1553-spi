`ifndef MILTRANSCEIVER_INCLUDE
`define MILTRANSCEIVER_INCLUDE

interface IMilStdControl();
	logic receiverBusy, transmitterBusy;
	logic packetStart, packetEnd;
	
	modport slave(output receiverBusy, transmitterBusy, packetStart, packetEnd);
	modport master(input receiverBusy, transmitterBusy, packetStart, packetEnd);

endinterface

module MilStd(	input bit rst, clk,
					IPushMil.master rpush,
					IPushMil.slave tpush,
					IMilStd line,
					IMilStdControl.slave control);
	
	parameter T2R_DELAY = 12;
	
	enum logic[1:0] {RECEIVE, TRANSMIT, WAIT} State, Next;
	
	logic [3:0] cntr, nextCntr;
	logic rcvEnable, rcvBusy, trEnable, trBusy, trRequest;
	logic ioClk;
	
	ioClkGenerator ioClkGen(rst, clk, ioClk);

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
	
	milTransmitter t(rst, clk, ioClk, trEnable, tpush, line, trBusy, trRequest);
	milReceiver		r(rst, clk, line, rcvEnable, rpush, rcvBusy);
	
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

`endif