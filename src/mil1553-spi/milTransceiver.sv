`ifndef MILTRANSCEIVER_INCLUDE
`define MILTRANSCEIVER_INCLUDE

interface IMilControl();
	logic receiverBusy, transmitterBusy;
	logic packetStart, packetEnd;
	
	modport slave(output receiverBusy, transmitterBusy, packetStart, packetEnd);
	modport master(input receiverBusy, transmitterBusy, packetStart, packetEnd);

endinterface

module milTransceiver(	input bit nRst, clk,
					             IPushMil.master rpush,
					 	           IPushMil.slave tpush,
					             IMilStd mil,
					             IMilControl.slave control);
	
	parameter T2R_DELAY = 12;
	
	logic ioClk;
	logic [3:0] cntr, nextCntr;
	
	IMilTxControl tcontrol();
	milTransmitter t(nRst, clk, ioClk, tpush, mil, tcontrol);
	
	IMilRxControl rcontrol();
	milReceiver r(nRst, clk, mil, rpush, rcontrol);
	
	enum logic[1:0] {RECEIVE, TRANSMIT, WAIT} State, Next;

	ioClkGenerator ioClkGen(nRst, clk, ioClk);

	assign control.receiverBusy = rcontrol.busy;
	assign control.transmitterBusy = tcontrol.busy;
	
	upFront		packetStartStrobe(nRst, clk, rcontrol.busy, control.packetStart);
	downFront	packetEndStrobe(nRst, clk, rcontrol.busy, control.packetEnd);
	
	logic upIoClk;
	upFront		upIoClkStrobe(nRst, clk, ioClk, upIoClk);
	
	always_ff @ (posedge clk) begin
		if(!nRst) begin
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
			RECEIVE:		if(!rcontrol.busy && tcontrol.request) Next = TRANSMIT;
			TRANSMIT:	if(!tcontrol.request) Next = WAIT;
			WAIT:			if(cntr == T2R_DELAY || rcontrol.busy) Next = RECEIVE;
		endcase
		
		unique case(State)
			RECEIVE:		{rcontrol.grant, tcontrol.grant} = 2'b10;
			TRANSMIT:	{rcontrol.grant, tcontrol.grant} = 2'b01;
			WAIT:			{rcontrol.grant, tcontrol.grant} = 2'b10;
		endcase
		
		nextCntr = (State == WAIT) ? (cntr + 1) : 0;
	end

endmodule	

module ioClkGenerator(input bit nRst, clk, 
							 output logic ioClk);
	parameter period = 49;
	logic [5:0] cntr, nextCntr;
	
	assign nextCntr = (cntr == period) ? 0 : (cntr + 1);
	
	always_ff @ (posedge clk)
	if(!nRst) begin
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