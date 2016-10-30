`include "settings.sv"

`ifndef HELPINTERFACES_INCLUDE
`define HELPINTERFACES_INCLUDE

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

`endif