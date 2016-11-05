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