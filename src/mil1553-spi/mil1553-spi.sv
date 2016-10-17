`ifndef MILSPICORE_INCLUDE
`define MILSPICORE_INCLUDE

module MilSpiCore	(	input logic rst, clk,							ISpi spi,	IMilStd mil,
							IPush.master 	pushToMem0, 	pushToMem1,
							IPop.master		popFromMem0, 	popFromMem1,
							IRingBufferControl.master rcontrol0, rcontrol1,
							output logic resetRequest);

	parameter blockAddr = 8'hAB;
	
	import ServiceProtocol::*;

	IPush		pushFromSpi();	
	IPush		pushFromMil();	
	IPop		popToSpi();
	IPush		pushToMil();	
	
	ICommunicationBlockControl cbc();
	
	CommunicationBlock	cb(rst, clk, 
									spi.slave, 
									mil.device,
									pushFromSpi, pushToMem1, 
									popToSpi, pushToMil,
									cbc.slave);
	
	//spi -> mem
	logic spiToMemEnable;
	BusGate	spiToMemGate(	rst, clk, 
									spiToMemEnable,
									pushFromSpi,
									pushToMem0);
	//mem -> mil
	BusPusher memToMilPusher(rst, clk, 
									 (rcontrol0.memUsed != '0),
									 pushToMil,
									 popFromMem0);
	
	//mem 		-> mil - connected directly
	//mem, stat -> spi
	logic	[1:0] toSpiMuxKey;
	IPop	popFromStat();
	
	IStatusInfoControl statusInfoControl();
	assign statusInfoControl.statusWord0 = rcontrol0.memUsed;
	assign statusInfoControl.statusWord1 = rcontrol1.memUsed;
	
	StatusInfo	statusPopper(rst, clk,
									 popFromStat,
									 statusInfoControl);
	
	BusMux	toSpiDataMux(	rst, clk,
									toSpiMuxKey,
									popToSpi,
									popFromMem1, popFromStat);
	
	//command processing 
	logic [4:0] conf;
	
	//module addr filter
	ServiceProtocol::TCommandCode commandCode;
	assign commandCode = (cbc.moduleAddr == blockAddr) ? cbc.cmdCode : TCC_UNKNOWN;
	
	assign {	spiToMemEnable, toSpiMuxKey, cbc.spiTransmitEnable, statusInfoControl.enable} = conf;
				
	always_ff @ (posedge clk) begin
		if(rst) begin
			resetRequest <= 0;
			{rcontrol0.open, rcontrol0.commit, rcontrol0.rollback} = '0;
			{rcontrol1.open, rcontrol1.commit, rcontrol1.rollback} = '0;
		end
			
		if(commandCode == TCC_RESET)
			resetRequest <= 1;
	end
		
	always_comb begin
		case(commandCode)
			default: 			       conf = 5'b01100;
			TCC_UNKNOWN:		     conf = 5'b01100;
			TCC_RESET:			      conf = 5'b01100;	// device reset
			TCC_SEND_DATA:		   conf = 5'b11100;	// send data to mil
			TCC_RECEIVE_STS:	  conf = 5'b00111;	// send status to spi
			TCC_RECEIVE_DATA:  conf = 5'b00010;	// send all the received data to spi
		endcase
	end
	
	always_comb begin
		case(commandCode)
			default:				cbc.spiTransmitDataSize = '0;
			TCC_RECEIVE_STS:	cbc.spiTransmitDataSize = 2;
			TCC_RECEIVE_DATA:	cbc.spiTransmitDataSize = rcontrol1.memUsed;	
		endcase
	end

endmodule

`endif 