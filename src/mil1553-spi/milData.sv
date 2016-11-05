`ifndef MILDATA_INCLUDE
`define MILDATA_INCLUDE

package milStd1553;
 
	typedef enum logic[1:0] {
		WSERVERR 	= 2'b00, 
		WSERV		= 2'b01, 
		WDATAERR	= 2'b10, 
		WDATA		= 2'b11
	} WordType;
	
	typedef struct packed {
		WordType		dataType;
		logic	[15:0]	dataWord;
	} MilData;

endpackage 

`endif