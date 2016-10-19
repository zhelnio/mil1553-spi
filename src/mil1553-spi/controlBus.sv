`ifndef CONTROLBUS_INCLUDE
`define CONTROLBUS_INCLUDE

//get from IPop and push to IPush
module BusPusher(	input bit rst, clk,
						input logic enable,
						IPush.master push,
						IPop.master pop);
		
		logic beginEnabled;
		upFront beginEnabledStrobe(rst, clk, enable, beginEnabled);
		
		enum logic [2:0] {IDLE, READ_REQ, READ_WAIT, WRITE_REQ, WRITE_WAIT } State, Next;
		
		assign push.data 		= pop.data;
		assign push.request 	= (State == WRITE_REQ);
		assign pop.request	= (State == READ_REQ);
		
		always_ff @ (posedge clk)
			if(rst)
				State <= IDLE;
			else
				State <= Next;
		
		always_comb begin
			Next = State;
			unique case(State)
				IDLE:	 		if(beginEnabled) Next = READ_REQ;
				READ_REQ:	Next = READ_WAIT;
				READ_WAIT:	if(pop.done) Next = WRITE_REQ;
				WRITE_REQ: 	Next = WRITE_WAIT;
				WRITE_WAIT:	if(push.done)
									Next = (enable) ? READ_REQ : IDLE;
			endcase
		end
endmodule	

module BusMux( input bit rst, clk,
					input logic	[1:0] key,
					IPop.slave	out,
					IPop.master	in0,
					IPop.master	in1);
	
	always_comb begin	
		case(key)
			2'b00: begin
						{out.data, out.done, in0.request} = {in0.data, in0.done, out.request};
						in1.request = '0;
					 end
			2'b01: begin
						{out.data, out.done, in1.request} = {in1.data, in1.done, out.request};
						in0.request = '0;
					 end
			default: begin
					{out.done, in0.request, in1.request} = '0;
					out.data = 'x;
					end
		endcase
	end
endmodule	
					

module BusGate(input bit rst, clk,
					input logic 	enable,
					IPush.slave		in,
					IPush.master 	out);
	always_comb begin		
		if(enable)
			{out.data, out.request, in.done} = {in.data, in.request, out.done};
		else
			{out.data, out.request, in.done} = '0;
	end
endmodule

`endif
