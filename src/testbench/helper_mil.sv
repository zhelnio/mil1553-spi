`include "settings.sv"

`ifndef HELPMIL_INCLUDE
`define HELPMIL_INCLUDE

module DebugMilTransmitter(input bit rst, clk,
									         IPushMil.slave push,
									         IMilStd line);
  
  IPushMil rpush();
  IMilStdControl	control();
  
  MilStd	milStd(	rst, clk,
							   rpush.master,
							   push,
							   line,
							   control);
  
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

