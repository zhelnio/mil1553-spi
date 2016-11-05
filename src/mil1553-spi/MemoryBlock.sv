`ifndef MEMORYBLOCK_INCLUDE
`define MEMORYBLOCK_INCLUDE
 
 module MemoryBlock(	input bit rst, clk, 
							IPush.slave	push0,
							IPush.slave	push1,
							IPop.slave	pop0,
							IPop.slave	pop1,	
							IRingBufferControl.slave rcontrol0,
							IRingBufferControl.slave rcontrol1,
							IMemory 	mbus);
							
	parameter RING1_MEM_START	= 16'h00;
	parameter RING1_MEM_END	   	= 16'h7F;
  	parameter RING2_MEM_START	= 16'h80;
  	parameter RING2_MEM_END		= 16'hFF;
	
	IMemoryReader rbus0();
	IMemoryReader rbus1();
	IMemoryWriter wbus0();
	IMemoryWriter wbus1();
	IArbiter abus[3:0]();

	Arbiter			arbiter(rst, clk, abus);
	MemoryWriter	writerA(rst, clk, mbus.writer, wbus0.slave, abus[0].client);
	MemoryWriter	writerB(rst, clk, mbus.writer, wbus1.slave, abus[1].client);
	MemoryReader	readerA(rst, clk, mbus.reader, rbus0.slave, abus[2].client);
	MemoryReader	readerB(rst, clk, mbus.reader, rbus1.slave, abus[3].client);
	
	RingBuffer			#(.MEM_START_ADDR(RING1_MEM_START), .MEM_END_ADDR(RING1_MEM_END))
					ringA	 (rst, clk, rcontrol0, push0, pop0, wbus0.master, rbus0.master);

	RingBuffer			#(.MEM_START_ADDR(RING2_MEM_START), .MEM_END_ADDR(RING2_MEM_END))
					ringB	 (rst, clk, rcontrol1, push1, pop1, wbus1.master, rbus1.master);

	assign mbus.wr_enable = ( abus[0].grant | abus[1].grant) ? 'z : '0;
	assign mbus.rd_enable = ( abus[2].grant | abus[3].grant) ? 'z : '0;

 endmodule
 
 

 
module MemoryBlock2(	input bit rst, clk, 
							IPush.slave	push0, push1, push2, push3,
							IPop.slave	pop0, pop1, pop2, pop3,
							IRingBufferControl.slave rc0, rc1, rc2, rc3,
							IMemory 	mbus);
	
	parameter RING2_0_MEM_START	= 16'h0000;
	parameter RING2_0_MEM_END	= 16'h007F;
	parameter RING2_1_MEM_START	= 16'h0080;
	parameter RING2_1_MEM_END	= 16'h00FF;
	parameter RING2_2_MEM_START	= 16'h0100;
	parameter RING2_2_MEM_END	= 16'h017F;
	parameter RING2_3_MEM_START	= 16'h0180;
	parameter RING2_3_MEM_END	= 16'h01FF;
	
	IMemoryReader rbus[3:0]();
	IMemoryWriter wbus[3:0]();
	IArbiter abus[7:0]();

	Arbiter8		arbiter(rst, clk, abus);
	MemoryWriter	writer0(rst, clk, mbus.writer, wbus[0].slave, abus[0].client);
	MemoryWriter	writer1(rst, clk, mbus.writer, wbus[1].slave, abus[1].client);
	MemoryWriter	writer2(rst, clk, mbus.writer, wbus[2].slave, abus[2].client);
	MemoryWriter	writer3(rst, clk, mbus.writer, wbus[3].slave, abus[3].client);
	MemoryReader	reader0(rst, clk, mbus.reader, rbus[0].slave, abus[4].client);
	MemoryReader	reader1(rst, clk, mbus.reader, rbus[1].slave, abus[5].client);
	MemoryReader	reader2(rst, clk, mbus.reader, rbus[2].slave, abus[6].client);
	MemoryReader	reader3(rst, clk, mbus.reader, rbus[3].slave, abus[7].client);
	
	RingBuffer			#(.MEM_START_ADDR(RING2_0_MEM_START), .MEM_END_ADDR(RING2_0_MEM_END))
					ring0	 (rst, clk, rc0, push0, pop0, wbus[0].master, rbus[0].master);

	RingBuffer			#(.MEM_START_ADDR(RING2_1_MEM_START), .MEM_END_ADDR(RING2_1_MEM_END))
					ring1	 (rst, clk, rc1, push1, pop1, wbus[1].master, rbus[1].master);
					
	RingBuffer			#(.MEM_START_ADDR(RING2_2_MEM_START), .MEM_END_ADDR(RING2_2_MEM_END))
					ring2	 (rst, clk, rc2, push2, pop2, wbus[2].master, rbus[2].master);

	RingBuffer			#(.MEM_START_ADDR(RING2_3_MEM_START), .MEM_END_ADDR(RING2_3_MEM_END))
					ring3	 (rst, clk, rc3, push3, pop3, wbus[3].master, rbus[3].master);
	
	assign mbus.wr_enable = ( abus[0].grant | abus[1].grant 
							| abus[2].grant | abus[3].grant) ? 'z : '0;
	assign mbus.rd_enable = ( abus[4].grant | abus[5].grant 
							| abus[6].grant | abus[7].grant) ? 'z : '0;

 endmodule



`endif
