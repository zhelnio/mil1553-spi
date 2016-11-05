`ifndef CONTROLRESET_INCLUDE
`define CONTROLRESET_INCLUDE

module ResetGenerator(	input bit nRst, clk, 
						input logic nResetRequest,
						output logic nResetSignal);

	parameter pause = 16;
	logic [3:0] pauseCntr, nextCntr;
	logic [2:0] buffer;
	
	assign nResetSignal = (pauseCntr == '0) & nRst;
	
	always_ff @ (posedge clk) begin
		if(!nRst) begin
			buffer		<= '1;
			pauseCntr	<= '0;
			end
		else begin
			buffer		<= {buffer[1:0], nResetRequest};
			pauseCntr 	<= nextCntr;
		end
	end
	
	always_comb begin
		nextCntr = pauseCntr;
		if(buffer == '0)
			nextCntr = 1;
		else if(pauseCntr != '0)
			nextCntr = pauseCntr + 1;
	end
	
endmodule

`endif