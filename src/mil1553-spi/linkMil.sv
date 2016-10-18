`ifndef LINKMIL_INCLUDE
`define LINKMIL_INCLUDE

module LinkMil(input bit rst, clk,
               IPush.master	pushFromMil,
               IPush.slave		pushToMil,
               IMilControl.slave milControl,
               IMilStd	mil);

    IPushMil rmpush();
    IPushMil tmpush();
	
    milTransceiver milStd(.rst(rst), .clk(clk),
					                .rpush(rmpush.master), .tpush(tmpush.slave),
					                .mil(mil), .control(milControl));

    milMemEncoder milToMemEncoder(.rst(rst), .clk(clk), 
                                  .mil(rmpush.slave), 
                                  .push(pushFromMil));
											
    memMilEncoder	memToMilEncoder(.rst(rst), .clk(clk), 
                                  .mil(tmpush.master), 
                                  .push(pushToMil));

endmodule
										 
`endif