`ifndef COMMON_INCLUDE
`define COMMON_INCLUDE

module signalChange(	input 	bit	nRst,
							input 	bit	clk,
							input 	bit 	signal,
							output 	bit	strobe);
	logic [1:0] buffer;
	assign strobe = buffer[1] ^ buffer[0];
	
	always_ff @ (posedge clk)
		if(!nRst)
			buffer <= 0;
		else	
			buffer <= {buffer[0], signal};
endmodule

module upFront(input 	bit	nRst,
					input 	bit	clk,
					input 	bit 	signal,
					output 	bit	strobe);
					
	logic [1:0] buffer;
	assign strobe = !buffer[1] & buffer[0];
	
	always_ff @ (posedge clk)
		if(!nRst)
			buffer <= 0;
		else	
			buffer <= {buffer[0], signal};
endmodule

module downFront(	input 	bit	nRst,
						input 	bit	clk,
						input 	bit 	signal,
						output 	bit	strobe);
					
	logic [1:0] buffer;
	assign strobe = buffer[1] & !buffer[0];
	
	always_ff @ (posedge clk)
		if(!nRst)
			buffer <= 0;
		else	
			buffer <= {buffer[0], signal};
endmodule

module inputFilter(	input 	bit	nRst,
							input 	bit	clk,
							input 	bit 	signal,
							output 	bit	out);
	logic [1:0] buffer;
	assign out = buffer[1];
	
	always_ff @ (posedge clk)
		if(!nRst)
			buffer <= 0;
		else	
			buffer <= {buffer[0], signal};
endmodule

`endif 