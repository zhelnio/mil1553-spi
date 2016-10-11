`ifndef SP_UNPACKER_INCLUDE
`define SP_UNPACKER_INCLUDE

interface IServiceProtocolUControl();
	logic[7:0] 	moduleAddr, dataWordNum;
	ServiceProtocol::TCommandCode 	cmdCode;
	
	logic packetStart, packetErr, packetEnd, spiReceiverIsBusy;
	
	modport slave(output  moduleAddr, cmdCode, dataWordNum, 
								 packetStart, packetErr, packetEnd, 
					  input   spiReceiverIsBusy);
	modport master(input  moduleAddr, cmdCode, dataWordNum, 
								 packetStart, packetErr, packetEnd,
						output spiReceiverIsBusy);
endinterface

module ServiceProtocolUnpacker(input bit rst, clk,
										IPush.slave receivedData,
										IPush.master unpackBus,
										IServiceProtocolUControl.slave control);
	import ServiceProtocol::*;
	
	assign receivedData.done = unpackBus.done;
	
	ServiceProtocolHeader receivedHeader;
	ServiceProtocolHeaderPart headerPart;

	assign {receivedHeader.addr, receivedHeader.size, receivedHeader.cmdcode} 
		  = {headerPart.part1, headerPart.part2[15:8], decodeTccCommand(headerPart.part2[7:0])};
		  
	shortint unsigned receivedWordsCntr;
	shortint unsigned crc;
	
	enum {WAIT, PACKET_HEAD1, PACKET_HEAD2, 
			PACKET_DATA, PACKET_CRC, PACKET_NUM} State, Next;
	
	always_ff @ (posedge clk) begin
		if(rst | !control.spiReceiverIsBusy)
			State <= WAIT;
		else if(receivedData.request) 
			State <= Next;
	end
	
	
	
	assign unpackBus.data = (State == PACKET_DATA) ? receivedData.data : 'z;
	assign control.dataWordNum = (State == PACKET_DATA || State == PACKET_CRC) ? receivedWordsCntr : 'z;
	assign control.moduleAddr = (State == PACKET_DATA || State == PACKET_CRC) ? receivedHeader.addr : 'z;
	assign control.cmdCode = (State == PACKET_DATA || State == PACKET_CRC) ? receivedHeader.cmdcode : TCC_UNKNOWN;
	
	always_ff @ (posedge clk) begin
		if(receivedData.request) begin
			unique case(Next)
				WAIT:				crc <= '0; 							
				PACKET_HEAD1:	begin headerPart.part1 <= receivedData.data; crc <= crc + receivedData.data; end
				PACKET_HEAD2:	begin headerPart.part2 <= receivedData.data; crc <= crc + receivedData.data; end
				
				PACKET_DATA:	begin
										if(State == PACKET_HEAD2) begin
											receivedWordsCntr <= 0;
											control.packetStart <= 1;
											end
										else
											receivedWordsCntr <= receivedWordsCntr + 1;

										unpackBus.request <= 1;
										crc <= crc + receivedData.data;
									end
										
				PACKET_CRC:		begin
										receivedHeader.crc = receivedData.data;
										if(crc == receivedData.data)
											control.packetEnd <= 1;
										else
											control.packetErr <= 1;
									end
				PACKET_NUM:		receivedHeader.num <= receivedData.data;
			endcase
		end
		
		if(State == WAIT)
			{control.packetStart, control.packetEnd, control.packetErr, unpackBus.request} <= '0; 
		
		if({control.packetStart, control.packetEnd, control.packetErr, unpackBus.request} != '0)
			{control.packetStart, control.packetEnd, control.packetErr, unpackBus.request} <= '0;
		
	end
	
	always_comb begin
		Next = State;
		unique case(State)
			WAIT:				Next = PACKET_HEAD1;
			PACKET_HEAD1:	Next = PACKET_HEAD2;
			PACKET_HEAD2:	if(receivedHeader == TCC_UNKNOWN) Next = WAIT;
								else if(receivedHeader.size == 0) Next = PACKET_CRC;
								else Next = PACKET_DATA;

			PACKET_DATA:	if(receivedWordsCntr == (receivedHeader.size - 1)) Next = PACKET_CRC;
			PACKET_CRC:		Next = PACKET_NUM;
			PACKET_NUM:		Next = PACKET_HEAD1;
		endcase
	end

endmodule 

`endif