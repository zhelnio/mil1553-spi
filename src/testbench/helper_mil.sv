`include "settings.sv"

`ifndef HELPMIL_INCLUDE
`define HELPMIL_INCLUDE

module DebugMilTransmitter(input bit rst, clk,
									         IPushMil.slave push,
									         IMilStd mil);
							   
  IPushMil rpush();
  IMilTransceiverControl control();
  milTransceiver tr(rst, clk, rpush, push, mil, control);
  
  always_ff @ (posedge clk) begin
		if(rpush.request) begin
			$display("DebugMilTransmitter %m --> %h", rpush.data);	
			rpush.done <= '1;
		end
		
		if(rpush.done)
			rpush.done <= '0;
	end

endmodule

`endif 

