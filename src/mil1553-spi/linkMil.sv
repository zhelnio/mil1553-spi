/* MIL-STD-1553 <-> SPI bridge
 * Copyright(c) 2016 Stanislav Zhelnio
 * Licensed under the MIT license (MIT)
 * https://github.com/zhelnio/mil1553-spi
 */

`ifndef LINKMIL_INCLUDE
`define LINKMIL_INCLUDE

module LinkMil(input bit nRst, clk,
               IPush.master	pushFromMil,
               IPush.slave		pushToMil,
               IMilControl.slave milControl,
               IMilStd	mil);

    IPushMil rmpush();
    IPushMil tmpush();
	
    milTransceiver milStd(.nRst(nRst), .clk(clk),
					                .rpush(rmpush.master), .tpush(tmpush.slave),
					                .mil(mil), .control(milControl));

    milMemEncoder milToMemEncoder(.nRst(nRst), .clk(clk), 
                                  .mil(rmpush.slave), 
                                  .push(pushFromMil));
											
    memMilEncoder	memToMilEncoder(.nRst(nRst), .clk(clk), 
                                  .mil(tmpush.master), 
                                  .push(pushToMil));

endmodule
										 
`endif