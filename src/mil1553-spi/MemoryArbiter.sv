`ifndef ARBITER_INCLUDE
`define ARBITER_INCLUDE

module Arbiter(input bit rst, clk,
					IArbiter.arbiter client[3:0]);

	logic [3:0] requestedChannel, 
					grantedChannel, newGrantedChannel;
	
	assign {client[3].grant, client[2].grant, 
			  client[1].grant, client[0].grant} = grantedChannel;
			  
	assign requestedChannel = {client[3].request, client[2].request, 
										client[1].request, client[0].request};
	
	always_ff @ (posedge clk)
		if(rst)
			grantedChannel <= '0;
		else
			grantedChannel <= newGrantedChannel;

	always_comb begin
		newGrantedChannel = grantedChannel;

		if(!(requestedChannel & grantedChannel)) begin
			if(     requestedChannel & 4'b0001) newGrantedChannel = 4'b0001;
			else if(requestedChannel & 4'b0010) newGrantedChannel = 4'b0010;
			else if(requestedChannel & 4'b0100) newGrantedChannel = 4'b0100;
			else if(requestedChannel & 4'b1000) newGrantedChannel = 4'b1000;
			else newGrantedChannel = '0;
		end
	end
			
endmodule

module Arbiter8(input bit rst, clk,
				IArbiter.arbiter client[7:0]);

	logic [7:0] requestedChannel, 
					grantedChannel, newGrantedChannel;
	
	assign {client[7].grant, client[6].grant, client[5].grant, client[4].grant,
			  client[3].grant, client[2].grant, client[1].grant, client[0].grant } = grantedChannel;
			  
	assign requestedChannel = 
			 {client[7].request, client[6].request, client[5].request, client[4].request,
			  client[3].request, client[2].request, client[1].request, client[0].request};
	
	always_ff @ (posedge clk)
		if(rst)
			grantedChannel <= '0;
			//grantedChannel <= 8'b00000001;
		else
			grantedChannel <= newGrantedChannel;

	always_comb begin
		newGrantedChannel = grantedChannel;

		if(!(requestedChannel & grantedChannel)) begin
			if(     requestedChannel & 8'b00000001) newGrantedChannel = 8'b00000001;
			else if(requestedChannel & 8'b00000010) newGrantedChannel = 8'b00000010;
			else if(requestedChannel & 8'b00000100) newGrantedChannel = 8'b00000100;
			else if(requestedChannel & 8'b00001000) newGrantedChannel = 8'b00001000;
			else if(requestedChannel & 8'b00010000) newGrantedChannel = 8'b00010000;
			else if(requestedChannel & 8'b00100000) newGrantedChannel = 8'b00100000;
			else if(requestedChannel & 8'b01000000) newGrantedChannel = 8'b01000000;
			else if(requestedChannel & 8'b10000000) newGrantedChannel = 8'b10000000;
			else newGrantedChannel = '0;
			//else newGrantedChannel = 8'b00000001;
		end
	end
			
endmodule

`endif