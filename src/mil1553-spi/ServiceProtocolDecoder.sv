/* MIL-STD-1553 <-> SPI bridge
 * Copyright(c) 2016 Stanislav Zhelnio
 * Licensed under the MIT license (MIT)
 * https://github.com/zhelnio/mil1553-spi
 */

`ifndef SP_DECODER_INCLUDE
`define SP_DECODER_INCLUDE

interface IServiceProtocolDControl();
	logic[7:0] 	addr, wordNum;
	logic[15:0]	size;
	ServiceProtocol::TCommandCode 	cmdCode;
	
	logic packetStart, packetErr, packetEnd, enable;
	
	modport slave(	output	addr, cmdCode, wordNum, size,
							packetStart, packetErr, packetEnd, 
					input   enable);
	modport master(	input	addr, cmdCode, wordNum, size,
							packetStart, packetErr, packetEnd,
					output 	enable);
endinterface

module ServiceProtocolDecoder(input bit nRst, clk,
										IPush.slave receivedData,
										IPush.master decodedBus,
										IServiceProtocolDControl.slave control);
	import ServiceProtocol::*;
	
	assign receivedData.done = decodedBus.done;
	
	ServiceProtocolHeader receivedHeader;
	ServiceProtocolHeaderPart headerPart;

	assign {receivedHeader.addr, receivedHeader.size, receivedHeader.cmdcode} 
		  = {headerPart.part1, headerPart.part2[15:8], decodeTccCommand(headerPart.part2[7:0])};
		  
	logic[15:0] receivedWordsCntr;
	logic[15:0] crc;
	
	enum {WAIT, PACKET_HEAD1, PACKET_HEAD2, 
			PACKET_DATA, PACKET_CRC, PACKET_NUM, PACKET_POST} State, Next;
	
	always_ff @ (posedge clk) begin
		if(!nRst | !control.enable)
			State <= WAIT;
		else if(receivedData.request) 
			State <= Next;
	end

	logic dataParseEnable;
	assign dataParseEnable = (State == PACKET_DATA || State == PACKET_CRC || 
							  State == PACKET_NUM  || State == PACKET_POST);
	
	assign decodedBus.data = (State == PACKET_DATA) ? receivedData.data : 'z;
	assign control.wordNum = (State == PACKET_DATA ) ? receivedWordsCntr : 'z;
	assign control.addr = (dataParseEnable) ? receivedHeader.addr : 'z;
	assign control.size = (dataParseEnable) ? receivedHeader.size : 'z;
	assign control.cmdCode = (dataParseEnable) ? receivedHeader.cmdcode : TCC_UNKNOWN;
	
	always_ff @ (posedge clk) begin
		if(receivedData.request) begin
			unique case(Next)
				WAIT:			crc <= '0; 							
				PACKET_HEAD1:	begin 
									headerPart.part1 <= receivedData.data; 
									crc <= receivedData.data; 
									receivedWordsCntr <= 0; 
								end

				PACKET_HEAD2:	begin 
									headerPart.part2 <= receivedData.data; 
									crc <= crc + receivedData.data; 
								end
				
				PACKET_DATA:	begin
									if(State == PACKET_HEAD2) 										
										control.packetStart <= 1;
									else
										receivedWordsCntr <= receivedWordsCntr + 1;

									decodedBus.request <= 1;
									crc <= crc + receivedData.data;
								end
										
				PACKET_CRC:		begin
									receivedHeader.crc = receivedData.data;
									if(receivedWordsCntr != 0) begin
										if(crc == receivedData.data)
											control.packetEnd <= 1;
										else
											control.packetErr <= 1;
									end
								end
				PACKET_NUM:		receivedHeader.num <= receivedData.data;
			endcase
		end
		
		if(State == WAIT)
			{control.packetStart, control.packetEnd, control.packetErr, decodedBus.request} <= '0; 
		
		if({control.packetStart, control.packetEnd, control.packetErr, decodedBus.request} != '0)
			{control.packetStart, control.packetEnd, control.packetErr, decodedBus.request} <= '0;
		
	end
	
	always_comb begin
		Next = State;
		unique case(State)
			WAIT:			Next = PACKET_HEAD1;
			PACKET_HEAD1:	Next = PACKET_HEAD2;
			PACKET_HEAD2:	if(receivedHeader == TCC_UNKNOWN) Next = WAIT;
								else if(receivedHeader.size == 0) Next = PACKET_CRC;
								else Next = PACKET_DATA;

			PACKET_DATA:	if(receivedWordsCntr == (receivedHeader.size - 1)) Next = PACKET_CRC;
			PACKET_CRC:		Next = PACKET_NUM;
			PACKET_NUM:		Next = PACKET_POST;
			PACKET_POST:	if(receivedData.data != '0) Next = PACKET_HEAD1;
		endcase
	end

endmodule 

`endif