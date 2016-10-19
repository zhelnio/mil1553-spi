`ifndef CONTROLRESET_INCLUDE
`define CONTROLRESET_INCLUDE

module ResetGenerator(input bit rst, clk, 
							 input logic resetRequest,
							 output logic resetSignal);
	parameter pause = 16;
	logic [3:0] pauseCntr, nextCntr;
	logic [2:0] buffer;
	
	assign resetSignal = (pauseCntr != '0) | rst;
	
	always_ff @ (posedge clk) begin
		if(rst) begin
			buffer		<= '0;
			pauseCntr	<= '0;
			end
		else begin
			buffer		<= {buffer[1:0], resetRequest};
			pauseCntr 	<= nextCntr;
		end
	end
	
	always_comb begin
		nextCntr = pauseCntr;
		if(buffer == '1)
			nextCntr = 1;
		else if(pauseCntr != '0)
			nextCntr = pauseCntr + 1;
	end
	
endmodule

`endif