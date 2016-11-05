`ifndef AMW_INCLUDE
`define AMW_INCLUDE

//memory helper
module AlteraMemoryWrapper(	input bit rst, clk,
							IMemory.memory memBus);
	
	parameter ReadSimulationDelay = 3'd6;
	parameter WriteSimulationDelay = 3'd5;
									
	AlteraMemory mem(	clk, memBus.wr_data, 
						memBus.rd_addr[7:0], memBus.rd_enable, 
						memBus.wr_addr[7:0], memBus.wr_enable, 
						memBus.rd_data);					
					
	logic [2:0] _rcntr, _wcntr;	//delay simulation cntrs
	assign memBus.busy = (_wcntr != '0) || (_rcntr != '0);
	assign memBus.rd_ready = (_rcntr == 1);
	
	always_ff @ (posedge clk)
	if(rst)
		{_wcntr, _rcntr } <= '0;
	else begin
		if(memBus.wr_enable)
			_wcntr <= WriteSimulationDelay;
			
		if(_wcntr != 0)
			_wcntr <= _wcntr - 1;

		if(memBus.rd_enable)
			_rcntr <= ReadSimulationDelay;
	
		if(_rcntr != 0)
			_rcntr <= _rcntr - 1;
	end
	
endmodule

`endif 