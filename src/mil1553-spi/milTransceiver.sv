`ifndef MILTRANSCEIVER_INCLUDE
`define MILTRANSCEIVER_INCLUDE

interface IMilTransceiverControl();
	logic receiverBusy, transmitterBusy;
	logic packetStart, packetEnd;
	
	modport slave(output receiverBusy, transmitterBusy, packetStart, packetEnd);
	modport master(input receiverBusy, transmitterBusy, packetStart, packetEnd);

endinterface

module milTransceiver(	input bit rst, clk,
					             IPushMil.master rpush,
					 	           IPushMil.slave tpush,
					             IMilStd mil,
					             IMilTransceiverControl.slave control);
	
	parameter T2R_DELAY = 12;
	
	logic ioClk;
	logic [3:0] cntr, nextCntr;
	
	IMilTxControl tcontrol();
	milTransmitter t(rst, clk, ioClk, tpush, mil, tcontrol);
	
	IMilRxControl rcontrol();
	milReceiver r(rst, clk, mil, rpush, rcontrol);
	
	enum logic[1:0] {RECEIVE, TRANSMIT, WAIT} State, Next;

	ioClkGenerator ioClkGen(rst, clk, ioClk);

	assign control.receiverBusy = rcontrol.busy;
	assign control.transmitterBusy = tcontrol.busy;
	
	upFront		packetStartStrobe(rst, clk, rcontrol.busy, control.packetStart);
	downFront	packetEndStrobe(rst, clk, rcontrol.busy, control.packetEnd);
	
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