`ifndef COMBLOCK_INCLUDE
`define COMBLOCK_INCLUDE


interface ICommunicationBlockControl();
	//from IServiceProtocolUControl
	logic [7:0] moduleAddr, dataWordNum;
	ServiceProtocol::TCommandCode 	cmdCode;
	logic packetStart, packetErr, packetEnd, spiReceiverIsBusy;
	
	//from ISpiReceiverControl
	logic overflowInTQueue, overflowInRQueue;
	
	//from IServiceProtocolEControl
	logic spiTransmitEnable;
	logic[15:0] spiTransmitDataSize;	
	
	modport slave(output moduleAddr, cmdCode, dataWordNum, packetStart, 
								packetErr, packetEnd, spiReceiverIsBusy, 
								overflowInTQueue, overflowInRQueue,
						input spiTransmitEnable, spiTransmitDataSize);
								
	modport master(input moduleAddr, cmdCode, dataWordNum, packetStart, 
								packetErr, packetEnd, spiReceiverIsBusy, 
								overflowInTQueue, overflowInRQueue,
					  output spiTransmitEnable, spiTransmitDataSize);
endinterface

module CommunicationBlock(	input bit rst, clk, 
									ISpi.slave 		spiBus,
									IMilStd.device	milBus,
									
									IPush.master	pushFromSpi,
									IPush.master	pushFromMil,
									IPop.master		popToSpi,
									IPush.slave		pushToMil,

									ICommunicationBlockControl.slave control);
	
	IPush 							spiToMemPackedBus();
	ISpiReceiverControl 			spiReceiverControl();
	IServiceProtocolUControl 	servUnpackerControl();
	
	IPush								memToSpiPackedBus();
	
	spiReceiver spiR(rst, clk, 
						  memToSpiPackedBus, 
						  spiToMemPackedBus.master, 
						  spiReceiverControl.slave,
						  spiBus);	
	
	ServiceProtocolUnpacker serviceUnpacker(rst, clk, 
														 spiToMemPackedBus.slave,
														 pushFromSpi,
														 servUnpackerControl);						 

	assign servUnpackerControl.spiReceiverIsBusy	= 	spiReceiverControl.isBusy;	
	
	assign control.moduleAddr			= servUnpackerControl.moduleAddr;
	assign control.cmdCode 				= servUnpackerControl.cmdCode;
	assign control.dataWordNum 		= servUnpackerControl.dataWordNum;
	assign control.packetStart 		= servUnpackerControl.packetStart;
	assign control.packetErr 			= servUnpackerControl.packetErr;
	assign control.packetEnd 			= servUnpackerControl.packetEnd;
	assign control.spiReceiverIsBusy = spiReceiverControl.isBusy;
	assign control.overflowInTQueue 	= spiReceiverControl.overflowInTQueue;
	assign control.overflowInRQueue 	= spiReceiverControl.overflowInRQueue;
	
	IMilStdControl milControl();
	IPushMil milToMemEncodeBus();
	IPushMil memToMilEncodeBus();
	
	MilStd milStd(rst, clk,
					  milToMemEncodeBus.master,
					  memToMilEncodeBus.slave,
					  milBus,
					  milControl);
	
	milMemEncoder milToMemEncoder(rst, clk,
											milToMemEncodeBus.slave,
											pushFromMil);
	
	MemMilEncoder	memMilEncoder(rst, clk,
											 memToMilEncodeBus.master,
											 pushToMil);
	
	
	///
	IServiceProtocolDControl spDecoderControl();
	ServiceProtocolDecoder servProtDecoder(rst, clk, 
														popToSpi, memToSpiPackedBus, spEncoderControl);
														
	assign spDecoderControl.cmdCode 		= servUnpackerControl.cmdCode;
	assign spDecoderControl.moduleAddr 	= servUnpackerControl.moduleAddr;
	assign spDecoderControl.enable		= control.spiTransmitEnable;
	assign spDecoderControl.size			= control.spiTransmitDataSize;

endmodule

//берем данные из pop и проталкиваем в push
module BusPusher(	input bit rst, clk,
						input logic enable,
						IPush.master push,
						IPop.master pop);
		
		logic beginEnabled;
		upFront beginEnabledStrobe(rst, clk, enable, beginEnabled);
		
		enum logic [2:0] {IDLE, READ_REQ, READ_WAIT, WRITE_REQ, WRITE_WAIT } State, Next;
		
		assign push.data 		= pop.data;
		assign push.request 	= (State == WRITE_REQ);
		assign pop.request	= (State == READ_REQ);
		
		always_ff @ (posedge clk)
			if(rst)
				State <= IDLE;
			else
				State <= Next;
		
		always_comb begin
			Next = State;
			unique case(State)
				IDLE:	 		if(beginEnabled) Next = READ_REQ;
				READ_REQ:	Next = READ_WAIT;
				READ_WAIT:	if(pop.done) Next = WRITE_REQ;
				WRITE_REQ: 	Next = WRITE_WAIT;
				WRITE_WAIT:	if(push.done)
									Next = (enable) ? READ_REQ : IDLE;
			endcase
		end
endmodule	

module BusMux( input bit rst, clk,
					input logic	[1:0] key,
					IPop.slave	in,
					IPop.master	out0,
					IPop.master	out1);
	
	always_comb begin	
		case(key)
			2'b00: begin
						{in.data, in.done, out0.request} = {out0.data, out0.done, in.request};
						out1.request = '0;
					 end
			2'b01: begin
						{in.data, in.done, out1.request} = {out1.data, out1.done, in.request};
						out0.request = '0;
					 end
			default: begin
					{in.done, out0.request, out1.request} = '0;
					in.data = 'x;
					end
		endcase
	end
endmodule	
					

module BusGate(input bit rst, clk,
					input logic 	enable,
					IPush.slave		in,
					IPush.master 	out);
	always_comb begin		
		if(enable)
			{out.data, out.request, in.done} = {in.data, in.request, out.done};
		else
			{out.data, out.request, in.done} = '0;
	end
endmodule

interface IStatusInfoControl();
	logic enable;
	logic [15:0] 	statusWord0;
	logic [15:0] 	statusWord1;
	
	modport slave	(input enable, statusWord0, statusWord1 );
	modport master(output enable, statusWord0, statusWord1 );

endinterface

module StatusInfo(input bit rst, clk,
						IPop.slave			 out,
						IStatusInfoControl control);
	
	enum logic [2:0] {IDLE, SW0_L, SW0_S, SW1_L, SW1_S } Next, State;
	
	always_ff @ (posedge clk)
		if(rst | !control.enable)
			State <= IDLE;
		else
			State <= Next;
	
	assign out.done = (State == SW0_L || State == SW1_L );
	
	always_comb begin
		unique case(State)
			IDLE: 	out.data = 'x;
			SW0_L:	out.data = control.statusWord0;
			SW0_S:	out.data = control.statusWord0;
			SW1_L:	out.data = control.statusWord1;
			SW1_S:	out.data = control.statusWord1;
		endcase
	end
	
	always_comb begin
		Next = State;
		unique case(State)
			IDLE: 	if(out.request) Next = SW0_L;
			SW0_L:	Next = SW0_S;
			SW0_S:	if(out.request) Next = SW1_L;
			SW1_L:	Next = SW1_S;
			SW1_S:	;
		endcase
	end
		
endmodule


module ResetGenerator(input bit rst, clk, 
							 input logic rst0,
							 output logic orst);
	parameter pause = 16;
	logic [3:0] pauseCntr, nextCntr;
	logic [2:0] buffer;
	
	assign orst = (pauseCntr != '0) | rst;
	
	always_ff @ (posedge clk) begin
		if(rst) begin
			buffer		<= '0;
			pauseCntr	<= '0;
			end
		else begin
			buffer		<= {buffer[1:0], rst0};
			pauseCntr 	<= nextCntr;
		end
	end
	
	always_comb begin
		nextCntr = pauseCntr;
		if(buffer == '1)
			nextCntr = 1;
		else if(pauseCntr != '0)
			nextCntr = pauseCntr + 1;
	end
	
endmodule








		
`endif