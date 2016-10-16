`timescale 1 ns/ 100 ps

module test_milTransceiver();
  import milStd1553::*;
  
  bit rst, clk;
  IMilStd mil();
  assign mil.RXin  = mil.TXout;
	assign mil.nRXin = mil.nTXout;

  IPushMil rpush0();
  IPushMil tpush0();
  IMilTransceiverControl control0();
  milTransceiver tr0(rst, clk, rpush0, tpush0, mil, control0);
  
  IPushMil rpush1();
  IPushMil tpush1();
  IMilTransceiverControl control1();
  milTransceiver tr1(rst, clk, rpush1, tpush1, mil, control1);
  
  IPushMilHelper pushHelper0(clk, tpush0);
  IPushMilHelper pushHelper1(clk, tpush1);
  
	initial begin
		rst = 1; 
		@(posedge clk);
		@(posedge clk);
		rst = 0;
		
		fork	
		
		  begin
		    pushHelper0.doPush(WCOMMAND, 16'h1111);
		    pushHelper0.doPush(WDATA, 16'h2222);
		  end
		  
		  
		  begin
		    #600
		    pushHelper1.doPush(WCOMMAND, 16'hAAAA);
		    pushHelper1.doPush(WDATA, 16'hBBBB);
		  end
		  
		  begin
		    @(posedge rpush0.request);
        assert( rpush0.data.dataType == WCOMMAND);
        assert( rpush0.data.dataWord == 16'hAAAA);
        @(posedge rpush0.request);
        assert( rpush0.data.dataType == WDATA);
        assert( rpush0.data.dataWord == 16'hBBBB);
		  end
		  
		  begin
		    @(posedge rpush1.request);
        assert( rpush1.data.dataType == WSTATUS);
        assert( rpush1.data.dataWord == 16'h1111);
        @(posedge rpush1.request);
        assert( rpush1.data.dataType == WDATA);
        assert( rpush1.data.dataWord == 16'h2222);
		  end
		  
		  #150000 $stop;
		join
	end
	
	always #5 clk = !clk;
	
endmodule
