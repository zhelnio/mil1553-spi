`ifndef MILSPICORE_INCLUDE
`define MILSPICORE_INCLUDE

module MilSpiCore	(	input logic rst, clk,							
                    ISpi spi,	
                    IMilStd mil,
							      IPush.master pushToMem0, 	 //from mil
							      IPush.master pushToMem1,   //from spi
							      IPop.master		popFromMem0, 	//to spi
							      IPop.master  popFromMem1,  //to mil
							      IRingBufferControl.master rcontrol0,
							      IRingBufferControl.master rcontrol1,
							      output logic resetRequest);

	parameter blockAddr = 8'hAB;
	
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
                  .pushFromMil(pushToMem0),     
                  .pushToMil(tMilPush),         
                  .milControl(milControl.slave),
                  .mil(mil));

  //mil <- busPusher(enablePushToMil) <- mem
  BusPusher busPusher(.rst(rst), .clk(clk),
                      .enable(enablePushToMil),
                      .push(tMilPush.master),
                      .pop(popFromMem1));                
  
  LinkSpi linkSpi(.rst(rst), .clk(clk),
                  .spi(spi.slave),
                  .pushFromSpi(rSpiPush.master),
                  .popToSpi(tSpiPop.master),
                  .control(spiControl.slave));
                  
  //spi -> busGate(enablePushFromSpi) -> mem
  BusGate busGate(.rst(rst), .clk(clk),
                  .enable(enablePushFromSpi),
                  .in(rSpiPush.slave),
                  .out(pushToMem1));
                  
  //spi <- busMux(muxKeyPopToSpi) <= mem, status
  BusMux busMus(.rst(rst), .clk(clk),
                .key(muxKeyPopToSpi),
                .out(tSpiPop.slave),
                .in0(popFromMem0),
                .in1(tStatPop.master));
  
  //status word generator
  StatusInfo statusInfo(.rst(rst), .clk(clk),
                        .out(tStatPop.slave),
                        .control(statusControl));
  
  //control interfaces
  assign statusControl.statusWord0 = rcontrol0.memUsed;
	assign statusControl.statusWord1 = rcontrol1.memUsed;

	//command processing 
	logic [4:0] conf;
	
	//module addr filter
	TCommandCode commandCode;
	assign commandCode = (spiControl.moduleAddr == blockAddr) ? spiControl.cmdCode : TCC_UNKNOWN;
	
	assign {	enablePushFromSpi, muxKeyPopToSpi, 
	         spiControl.spiTransmitEnable, statusControl.enable} = conf;
				
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
			default:				       spiControl.spiTransmitDataSize = '0;
			TCC_RECEIVE_STS:	  spiControl.spiTransmitDataSize = statusControl.statusSize;
			TCC_RECEIVE_DATA:	 spiControl.spiTransmitDataSize = rcontrol0.memUsed;	
		endcase
	end

endmodule

`endif 