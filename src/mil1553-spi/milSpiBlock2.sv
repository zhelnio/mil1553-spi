`ifndef MILSPIBLOCK2_INCLUDE
`define MILSPIBLOCK2_INCLUDE

module MilSpiBlock2	(	input logic rst, clk,							
						ISpi			spi,	
						IMilStd			mil,
						IPush.master 	pushFromMil,	//from mil
						IPush.master 	pushFromSpi,	//from spi
						IPop.master		popToSpi,		//to spi
						IPop.master		popToMil,		//to mil
						IRingBufferControl.master rcontrolMS,	// mil -> spi
						IRingBufferControl.master rcontrolSM,	// spi -> mil
						output logic resetRequest);

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
	LinkMil linkMil(.rst(rst), .clk(clk),
					.pushFromMil(pushFromMil),     
					.pushToMil(tMilPush),         
					.milControl(milControl.slave),
					.mil(mil));

	//mil <- busPusher(enablePushToMil) <- mem
	BusPusher busPusher(.rst(rst), .clk(clk),
						.enable(enablePushToMil),
						.push(tMilPush.master),
						.pop(popToMil));                
	
	LinkSpi linkSpi(.rst(rst), .clk(clk),
					.spi(spi.slave),
					.pushFromSpi(rSpiPush.master),
					.popToSpi(tSpiPop.master),
					.control(spiControl.slave));
					
	//spi -> busGate(enablePushFromSpi) -> mem
	BusGate busGate(.rst(rst), .clk(clk),
					.enable(enablePushFromSpi),
					.in(rSpiPush.slave),
					.out(pushFromSpi));
					
	//spi <- busMux(muxKeyPopToSpi) <= mem, status
	BusMux busMus(	.rst(rst), .clk(clk),
					.key(muxKeyPopToSpi),
					.out(tSpiPop.slave),
					.in0(popToSpi),
					.in1(tStatPop.master));
	
	//status word generator
	StatusInfo statusInfo(	.rst(rst), .clk(clk),
							.out(tStatPop.slave),
							.control(statusControl));
	
	//control interfaces
	assign statusControl.statusWord0 = rcontrolMS.memUsed;
	assign statusControl.statusWord1 = rcontrolSM.memUsed;

	//command processing 
	logic [4:0] conf;
	
	//module addr filter
	TCommandCode commandCode;
	assign commandCode = (spiControl.inAddr == SPI_BLOCK_ADDR) ? spiControl.inCmdCode : TCC_UNKNOWN;
	assign spiControl.outAddr 		= SPI_BLOCK_ADDR;
	assign spiControl.outCmdCode	= commandCode;
	
	assign {	enablePushFromSpi, muxKeyPopToSpi, 
	         spiControl.outEnable, statusControl.enable} = conf;

	assign enablePushToMil = (rcontrolSM.memUsed != 0);
				
	always_ff @ (posedge clk) begin
		if(rst) begin
			resetRequest <= 0;
			{rcontrolMS.open, rcontrolMS.commit, rcontrolMS.rollback} = '0;
			{rcontrolSM.open, rcontrolSM.commit, rcontrolSM.rollback} = '0;
		end
			
		if(commandCode == TCC_RESET)
			resetRequest <= 1;
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
			TCC_RECEIVE_DATA:	spiControl.outDataSize = rcontrolMS.memUsed;	
		endcase
	end

endmodule

`endif 