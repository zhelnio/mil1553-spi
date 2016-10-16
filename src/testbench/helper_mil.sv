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

/*
//MIL helper
interface IPushMilMasterDebug(input logic clk);
	import milStd1553::*;

	logic request, done;
	MilData	data;
	
	task automatic doPush(input WordType dtype, input logic [15:0] word);
		@(posedge clk)	request <= '1; data.dataType <= dtype; data.dataWord <= word;
		@(posedge clk)	request <= '0;
		
		@(done);
		$display("IPushMilMasterDebug %m <-- %h", data);	
	endtask
	
	modport slave(input data, input request, output done);	
endinterface

module PushMilMasterDebugHelper(IPushMil push,
										  IPushMilMasterDebug debug);
	assign push.data = debug.data;
	assign push.request = debug.request;
	assign debug.done = push.done;
endmodule

module DebugMilTransmitter(input bit rst, clk,
									IPushMilMasterDebug pushDebug,
									IMilStd line);
	
	IPushMil rpush();
	IPushMil tpush();
	IMilStdControl	control();
	IMilStd debugLine();
	
	assign line.RXin 			= debugLine.TXout; 
	assign line.nRXin			= debugLine.nTXout;	
	assign debugLine.RXin 	= line.TXout;
	assign debugLine.nRXin	= line.nTXout;
	
	MilStd	milStd(	rst, clk,
							rpush.master,
							tpush.slave,
							debugLine.device,
							control);
							
	PushMilMasterDebugHelper helper(tpush, pushDebug.slave);
	
	always_ff @ (posedge clk) begin
	
		if(rpush.request) begin
			$display("IPushMilMasterDebug %m --> %h", rpush.data);	
			rpush.done <= '1;
		end
		
		if(rpush.done)
			rpush.done <= '0;
	end
	

endmodule
*/

`endif 

