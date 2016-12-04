/* MIL-STD-1553 <-> SPI bridge
 * Copyright(c) 2016 Stanislav Zhelnio
 * Licensed under the MIT license (MIT)
 * https://github.com/zhelnio/mil1553-spi
 */

`ifndef CONTROLSTATUS_INCLUDE
`define CONTROLSTATUS_INCLUDE

interface IStatusInfoControl();
	logic enable;
	logic [15:0] 	statusWord0;
	logic [15:0] 	statusWord1;
	logic [15:0] 	statusWord2;
	logic [1:0]   	statusSize;
	
	modport slave	(input enable, statusWord0, statusWord1, statusWord2,
	               	output statusSize);
	modport master(	output enable, statusWord0, statusWord1, statusWord2,
                 	input  statusSize);
endinterface

module StatusInfo(input bit nRst, clk,
						      IPop.slave			 out,
						      IStatusInfoControl.slave control);
	
	assign control.statusSize = 3;
	
	enum logic [2:0] {IDLE, SW0_L, SW0_S, SW1_L, SW1_S, SW2_L, SW2_S } Next, State;
	
	always_ff @ (posedge clk)
		if(!nRst | !control.enable)
			State <= IDLE;
		else
			State <= Next;
	
	assign out.done = (State == SW0_L || State == SW1_L || State == SW2_L);
	
	always_comb begin
		unique case(State)
			IDLE: 	out.data = 'x;
			SW0_L:	out.data = control.statusWord0;
			SW0_S:	out.data = control.statusWord0;
			SW1_L:	out.data = control.statusWord1;
			SW1_S:	out.data = control.statusWord1;
			SW2_L:	out.data = control.statusWord2;
			SW2_S:	out.data = control.statusWord2;
		endcase
	end
	
	always_comb begin
		Next = State;
		unique case(State)
			IDLE: 	if(out.request) Next = SW0_L;
			SW0_L:	Next = SW0_S;
			SW0_S:	if(out.request) Next = SW1_L;
			SW1_L:	Next = SW1_S;
			SW1_S:	if(out.request) Next = SW2_L;
			SW2_L:	Next = SW2_S;
			SW2_S:	;
		endcase
	end
		
endmodule

`endif
