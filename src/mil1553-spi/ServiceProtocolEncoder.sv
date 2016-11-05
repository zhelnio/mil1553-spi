`ifndef SP_ENCODER_INCLUDE
`define SP_ENCODER_INCLUDE

interface IServiceProtocolEControl();
	logic[7:0] 	addr;
	logic[15:0] size;
	ServiceProtocol::TCommandCode 	cmdCode;
	logic enable;
	
	modport slave(input addr, size, cmdCode, enable);
	modport master(output addr, size, cmdCode, enable);
endinterface

module ServiceProtocolEncoder(input bit nRst, clk,
										IPop.master 	data,
										IPush.master 	packet,
										IServiceProtocolEControl.slave control);
	
	enum logic [4:0] {WAIT, 
							PACKET_HEAD1_L, PACKET_HEAD1_W, 	
							PACKET_HEAD2_L, PACKET_HEAD2_W,
							PACKET_DATA_LR, PACKET_DATA_LW, PACKET_DATA_SR, PACKET_DATA_SW, 
							PACKET_CRC_L, PACKET_CRC_W,
							PACKET_NUM_L, PACKET_NUM_W,
							IDLE } State, Next;
			
	logic[15:0] cntr;
	logic[15:0] crc, num;

	import ServiceProtocol::*;
	ServiceProtocolHeaderPart headerPart;
	
	always_ff @ (posedge clk)
	if(!nRst)
		State <= WAIT;
	else
		State <= Next;

	always_ff @ (posedge clk) begin
		if(!nRst)
			num <= 0;
	
		if(Next == PACKET_HEAD1_L) begin
			crc <= '0;
			cntr <= control.size;
			{headerPart.part1, headerPart.part2} <= {control.addr, control.size, control.cmdCode};
		end
		
		if(State == PACKET_HEAD1_L)
			num <= num + 1;
		
		if(Next == PACKET_DATA_LR)
			cntr <= cntr - 1;
		
		if(State == PACKET_HEAD1_L || State == PACKET_HEAD2_L || State == PACKET_DATA_SR) 
			crc <= crc + packet.data;
	end

	
	always_comb begin
		case(State)
			WAIT:					{data.request, packet.request, packet.data} = '0;
			PACKET_HEAD1_L:	{data.request, packet.request, packet.data} = { 2'b01, headerPart.part1 };
			PACKET_HEAD1_W: 	{data.request, packet.request, packet.data} = { 2'b00, headerPart.part1 };
			PACKET_HEAD2_L:	{data.request, packet.request, packet.data} = { 2'b01, headerPart.part2 };
			PACKET_HEAD2_W:	{data.request, packet.request, packet.data} = { 2'b00, headerPart.part2 };
			PACKET_DATA_LR:	begin {data.request, packet.request} = 2'b10; packet.data = 'x; end
			PACKET_DATA_LW:	begin {data.request, packet.request} = 2'b00; packet.data = 'x; end
			PACKET_DATA_SR:	{data.request, packet.request, packet.data} = { 2'b01, data.data };
			PACKET_DATA_SW:	{data.request, packet.request, packet.data} = { 2'b00, data.data };
			PACKET_CRC_L:		{data.request, packet.request, packet.data} = { 2'b01, crc };
			PACKET_CRC_W:		{data.request, packet.request, packet.data} = { 2'b00, crc };
			PACKET_NUM_L:		{data.request, packet.request, packet.data} = { 2'b01, num };
			PACKET_NUM_W:		{data.request, packet.request, packet.data} = { 2'b00, num };
			IDLE:					{data.request, packet.request, packet.data} = '0;
		endcase
	end
	
	always_comb begin
		Next = State;
		if(!control.enable)
			Next = WAIT;
		else
			unique case(State)
				WAIT:					if(control.enable)Next = PACKET_HEAD1_L;
				PACKET_HEAD1_L:	Next = PACKET_HEAD1_W;
				PACKET_HEAD1_W:	if(packet.done) Next = PACKET_HEAD2_L;
				PACKET_HEAD2_L:	Next = PACKET_HEAD2_W;
				PACKET_HEAD2_W:	if(packet.done) Next = PACKET_DATA_LR;
				PACKET_DATA_LR:	Next = PACKET_DATA_LW;
				PACKET_DATA_LW:	if(data.done) Next = PACKET_DATA_SR;
				PACKET_DATA_SR:	Next = PACKET_DATA_SW;
				PACKET_DATA_SW:	if(packet.done) Next = (cntr == '0) ? PACKET_CRC_L : PACKET_DATA_LR;
				PACKET_CRC_L:		Next = PACKET_CRC_W;
				PACKET_CRC_W:		if(packet.done) Next = PACKET_NUM_L;
				PACKET_NUM_L:		Next = PACKET_NUM_W;
				PACKET_NUM_W:		if(packet.done) Next = IDLE;
				IDLE:	;
			endcase
	end

endmodule





`endif