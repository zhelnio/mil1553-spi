/* MIL-STD-1553 <-> SPI converter
 * Copyright(c) 2016 Stanislav Zhelnio
 * Licensed under the MIT license (MIT)
 * https://github.com/zhelnio/mil1553-spi
 */

`ifndef SERVICE_PROTOCOL_INCLUDE
`define SERVICE_PROTOCOL_INCLUDE

package ServiceProtocol;

	typedef enum logic[7:0] {	TCC_UNKNOWN			= 8'hFF, 
								TCC_RESET			= 8'hA0, 	// device reset
								TCC_SEND_DATA		= 8'hA2, 	// send data to mil
								TCC_RECEIVE_STS		= 8'hB0, 	// send status info to spi
								TCC_RECEIVE_DATA	= 8'hB2		// send to spi all the data received from mil
								} TCommandCode;
	
	typedef struct packed {
		logic[7:0]  	addr;
		logic[15:0] 	size;
		TCommandCode	cmdcode;
		logic[15:0] 	crc;
		logic[15:0] 	num;
	} ServiceProtocolHeader;

	typedef struct packed {
		logic[15:0] part1;
		logic[15:0] part2;
	} ServiceProtocolHeaderPart;
	
	
	function TCommandCode decodeTccCommand(byte cmdCode);
		priority case (cmdCode)
			default:			return TCC_UNKNOWN;
			TCC_RESET:			return TCC_RESET;
			TCC_SEND_DATA:		return TCC_SEND_DATA;
			TCC_RECEIVE_STS:	return TCC_RECEIVE_STS;
			TCC_RECEIVE_DATA:	return TCC_RECEIVE_DATA;
		endcase
	endfunction
	
endpackage

`endif 