`include "settings.sv"

`ifndef INTERFACES_INCLUDE
`define INTERFACES_INCLUDE

interface IPush();
	logic request, done;
	logic [`DATAW_TOP:0]	data;
	
	modport master(output data, output request, input done);
	modport slave(input data, input request, output done);
endinterface

interface IPop();
	logic request, done;
	logic [`DATAW_TOP:0]	data;
	
	modport master(input data, output request, input done);
	modport slave(output data, input request, output done);
endinterface

interface IPushMil();
	logic request, done;
	milStd1553::MilDecodedData	data;
	
	modport master(output data, output request, input done);
	modport slave(input data, input request, output done);
endinterface

interface IPopMil();
	logic request, done;
	milStd1553::MilDecodedData	data;
	
	modport master(input data, output request, input done);
	modport slave(output data, input request, output done);
endinterface

interface ISpi();
	tri1 nCS;
	tri0 mosi, sck, miso;
	
	modport master(output nCS, mosi, sck, input miso);
	modport slave(input nCS, mosi, sck, output miso);
endinterface

interface IMemory();
	tri0 wr_enable, rd_enable;
	tri0 [`ADDRW_TOP:0] rd_addr;
	tri0 [`ADDRW_TOP:0] wr_addr;
	tri0 [`DATAW_TOP:0]	wr_data;

	logic rd_ready, busy;
	logic [`DATAW_TOP:0]	rd_data;
	
	modport writer(output wr_addr, wr_data, wr_enable,
						input  busy);
	
	modport reader(output rd_addr, rd_enable, 
						input  rd_data, rd_ready, busy);		
	
	modport memory(input  wr_addr, wr_data, wr_enable,
						input  rd_addr, rd_enable, 
						output rd_data, rd_ready, busy);
endinterface

interface IArbiter();
	logic request, grant;
	
	modport client(output request, input grant);
	modport arbiter(input request, output grant);
endinterface

interface IMemoryReader();
	logic request, done;
	
	logic [`ADDRW_TOP:0] addr;
	logic [`DATAW_TOP:0]	data;

	modport master(output addr, input data, output request, input done);
	modport slave(input addr, output  data, input request, output done);				
endinterface

interface IMemoryWriter();
	logic request, done;

	logic [`ADDRW_TOP:0] addr;
	logic [`DATAW_TOP:0]	data;

	modport master(output addr, output data, output request, input done);
	modport slave(input addr, input data, input request, output done);
endinterface

`endif