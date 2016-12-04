/* MIL-STD-1553 <-> SPI bridge
 * Copyright(c) 2016 Stanislav Zhelnio
 * Licensed under the MIT license (MIT)
 * https://github.com/zhelnio/mil1553-spi
 */

`ifndef MILSPIBLOCK_INCLUDE
`define MILSPIBLOCK_INCLUDE

module MilSpiBlock	(	input logic nRst, clk,							
						ISpi			spi,	
						IMilStd			mil,
						IPush.master 	pushFromMil,	//from mil
						IPush.master 	pushFromSpi,	//from spi
						IPop.master		popToSpi,		//to spi
						IPop.master		popToMil,		//to mil
						IRingBufferControl.master rcontrolMS,	// mil -> spi
						IRingBufferControl.master rcontrolSM,	// spi -> mil
						output logic nResetRequest);

	parameter SPI_BLOCK_ADDR = 8'hAB;

	import ServiceProtocol::*;

	logic enablePushToMil, enablePushFromSpi;
	logic [1:0] muxKeyPopToSpi;
	
	IPush tMilPush();
	IPush rSpiPush();
	IPop  tSpiPop();
	IPop  tStatPop();

	IMilControl milControl();
	ILinkSpiControl spiControl();
	IStatusInfoControl statusControl();
  
	//mil -> mem
	LinkMil linkMil(.nRst(nRst), .clk(clk),
					.pushFromMil(pushFromMil),     
					.pushToMil(tMilPush),         
					.milControl(milControl.slave),
					.mil(mil));

	//mil <- busPusher(enablePushToMil) <- mem
	BusPusher busPusher(.nRst(nRst), .clk(clk),
						.enable(enablePushToMil),
						.push(tMilPush.master),
						.pop(popToMil));                
	
	LinkSpi linkSpi(.nRst(nRst), .clk(clk),
					.spi(spi.slave),
					.pushFromSpi(rSpiPush.master),
					.popToSpi(tSpiPop.master),
					.control(spiControl.slave));
					
	//spi -> busGate(enablePushFromSpi) -> mem
	BusGate busGate(.nRst(nRst), .clk(clk),
					.enable(enablePushFromSpi),
					.in(rSpiPush.slave),
					.out(pushFromSpi));
					
	//spi <- busMux(muxKeyPopToSpi) <= mem, status
	BusMux busMus(	.nRst(nRst), .clk(clk),
					.key(muxKeyPopToSpi),
					.out(tSpiPop.slave),
					.in0(popToSpi),
					.in1(tStatPop.master));
	
	//status word generator
	StatusInfo statusInfo(	.nRst(nRst), .clk(clk),
							.out(tStatPop.slave),
							.control(statusControl));
	
	//error counter
	logic [15:0] errorCounter;
	always_ff @ (posedge clk) begin
		if(!nRst)
			errorCounter <= 0;
		else
			errorCounter <= errorCounter + rcontrolSM.rollback;
	end

	//control interfaces
	assign statusControl.statusWord0 = rcontrolMS.memUsed;
	assign statusControl.statusWord1 = rcontrolSM.memUsed;
	assign statusControl.statusWord2 = errorCounter;

	//module addr filter
	logic  addrCorrect;
	assign addrCorrect = (spiControl.inAddr == SPI_BLOCK_ADDR);

	//command processing 
	logic [4:0] conf;

	TCommandCode commandCode;
	assign commandCode 				= addrCorrect ? spiControl.inCmdCode : TCC_UNKNOWN;
	assign spiControl.outAddr 		= SPI_BLOCK_ADDR;
	assign spiControl.outCmdCode	= commandCode;
	assign rcontrolSM.open			= addrCorrect ? spiControl.inPacketStart : 0;
	assign rcontrolSM.commit		= addrCorrect ? spiControl.inPacketEnd : 0;
	assign rcontrolSM.rollback		= addrCorrect ? spiControl.inPacketErr : 0;

	assign { rcontrolMS.open, rcontrolMS.commit, rcontrolMS.rollback } = '0;
	
	assign { enablePushFromSpi, muxKeyPopToSpi, 
	         spiControl.outEnable, statusControl.enable } = conf;

	assign enablePushToMil = (rcontrolSM.memUsed != 0);
				
	always_ff @ (posedge clk) begin
		if(!nRst)
			nResetRequest <= 1;

		if(commandCode == TCC_RESET)
			nResetRequest <= 0;
	end
		
	always_comb begin
		case(commandCode)
			default:			conf = 5'b01100;
			TCC_UNKNOWN:		conf = 5'b01100;
			TCC_RESET:			conf = 5'b01100;	// device reset
			TCC_SEND_DATA:		conf = 5'b11100;	// send data to mil
			TCC_RECEIVE_STS:	conf = 5'b00111;	// send status to spi
			TCC_RECEIVE_DATA:	conf = 5'b00010;	// send all the received data to spi
		endcase
	end
	
	always_comb begin
		case(commandCode)
			default:			spiControl.outDataSize = '0;
			TCC_RECEIVE_STS:	spiControl.outDataSize = statusControl.statusSize;
			TCC_RECEIVE_DATA:	spiControl.outDataSize = (spiControl.inSize < rcontrolMS.memUsed) ? 
															spiControl.inSize : rcontrolMS.memUsed; 
		endcase
	end

endmodule

`endif 