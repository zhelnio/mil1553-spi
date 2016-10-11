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



`endif