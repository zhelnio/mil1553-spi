/* MIL-STD-1553 <-> SPI bridge
 * Copyright(c) 2016 Stanislav Zhelnio
 * Licensed under the MIT license (MIT)
 * https://github.com/zhelnio/mil1553-spi
 */

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