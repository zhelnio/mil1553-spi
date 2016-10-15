`include "settings.sv"

`ifndef DEBUGHELP_INCLUDE
`define DEBUGHELP_INCLUDE

interface IPushHelper(input logic clk, IPush.master push);
    
    task automatic doPush(input logic [`DATAW_TOP:0] wdata);
		  @(posedge clk)	push.request <= '1; push.data <= wdata;
		  @(posedge clk)	push.request <= '0;
		
		  @(push.done);
		  $display("IPushMasterHelper %m <-- %h", wdata);	
	  endtask

endinterface

interface IPopHelper(input logic clk, IPop.master pop);
    
    task automatic doPop();
		  @(posedge clk)	pop.request <= '1;
		  @(posedge clk)	pop.request <= '0;
		
		  @(pop.done);
		  $display("IPopHelper %m --> %h", pop.data);	
	  endtask
    
endinterface

interface IMemoryReaderHelper(input logic clk, IMemoryReader.master reader);

    task automatic doRead(input logic [`ADDRW_TOP:0] addr);
        @(posedge clk)	reader.request <= '1; reader.addr <= addr;
        @(posedge clk)	reader.request <= '0;
        
        @(reader.done);
		    $display("IMemoryReaderHelper %m --> %h", reader.data);	
    endtask

endinterface

interface IMemoryWriterHelper(input logic clk, IMemoryWriter.master writer);

    task automatic doWrite(input logic [`ADDRW_TOP:0] addr, 
                           input logic [`DATAW_TOP:0]	data);
                          
        @(posedge clk)	writer.request <= '1; writer.addr <= addr; writer.data <= data;
        @(posedge clk)	writer.request <= '0;
        
        @(writer.done);
		    $display("IMemoryWriterHelper %m <-- %h", data);	
    endtask

endinterface





//////////////////////////////////////////////////////////

//SPI helper
interface IPushMasterDebug(input logic clk);
	logic request, done;
	logic [`DATAW_TOP:0]	data;
	
	task automatic doPush(input logic [`DATAW_TOP:0] wdata);
		@(posedge clk)	request <= '1; data <= wdata;
		@(posedge clk)	request <= '0;
		
		@(done);
		$display("IPushMasterDebug %m <-- %h", wdata);	
	endtask
	
	modport slave(input data, input request, output done);	
endinterface

module PushMasterDebugHelper(IPush push,
									  IPushMasterDebug debug);
	assign push.data = debug.data;
	assign push.request = debug.request;
	assign debug.done = push.done;
endmodule

module DebugSpiTransmitter(input bit rst, clk,
									IPushMasterDebug pushDebug,
									ISpi spi);

	IPush transmitterMosiBus();
	IPush transmitterMisoBus();
	ISpiTransmitterControl transmitterControl();
	
	spiTransmitter spiTrans(rst, clk,
									transmitterMosiBus, 
									transmitterMisoBus,
									transmitterControl,
									spi);
	
	PushMasterDebugHelper helper(transmitterMosiBus, pushDebug.slave);
	
	always_ff @ (posedge clk) begin
	
		if(transmitterMisoBus.request) begin
			$display("IPushMasterDebug %m --> %h", transmitterMisoBus.data);	
			transmitterMisoBus.done <= '1;
		end
		
		if(transmitterMisoBus.done)
			transmitterMisoBus.done <= '0;
	end

endmodule

//MIL helper
interface IPushMilMasterDebug(input logic clk);
	import milStd1553::*;

	logic request, done;
	MilDecodedData	data;
	
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


`endif 