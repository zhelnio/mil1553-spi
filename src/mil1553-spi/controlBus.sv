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
					IPop.slave	in,
					IPop.master	out0,
					IPop.master	out1);
	
	always_comb begin	
		case(key)
			2'b00: begin
						{in.data, in.done, out0.request} = {out0.data, out0.done, in.request};
						out1.request = '0;
					 end
			2'b01: begin
						{in.data, in.done, out1.request} = {out1.data, out1.done, in.request};
						out0.request = '0;
					 end
			default: begin
					{in.done, out0.request, out1.request} = '0;
					in.data = 'x;
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
