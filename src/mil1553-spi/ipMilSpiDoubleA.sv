`ifndef MILSPIDOUBLE_INCLUDE
`define MILSPIDOUBLE_INCLUDE

module IpMilSpiDoubleA(input logic clk, nRst,
                      ISpi spi0,
                      ISpi spi1,
                      IMilStd mil0,
                      IMilStd mil1,
                      IMemory 	mbus);
  
  IPush spiToMem0();
  IPush milToMem0();
  IPop memToSpi0();
  IPop memToMil0();
  IRingBufferControl milToSpiRBControl0();
  IRingBufferControl spiToMilRBControl0();
  
  IPush spiToMem1();
  IPush milToMem1();
  IPop memToSpi1();
  IPop memToMil1();
  IRingBufferControl milToSpiRBControl1();
  IRingBufferControl spiToMilRBControl1();
  logic nResetRequest0, nResetRequest1, nResetSignal;
  
  ResetGenerator  resetGenerator(.nRst(nRst), .clk(clk),
                                 .nResetRequest(nResetRequest0 & nResetRequest1),
                                 .nResetSignal(nResetSignal));
  
  MilSpiBlock milSpiBlock0(.nRst(nResetSignal), .clk(clk),
                          .spi(spi0), .mil(mil0),
                          .pushFromMil(milToMem0.master),
                          .pushFromSpi(spiToMem0.master),
                          .popToSpi(memToSpi0.master),
                          .popToMil(memToMil0.master),
                          .rcontrolMS(milToSpiRBControl0.master),
                          .rcontrolSM(spiToMilRBControl0.master),
                          .nResetRequest(nResetRequest0));
                          
  MilSpiBlock milSpiBlock1(.nRst(nResetSignal), .clk(clk),
                          .spi(spi1), .mil(mil1),
                          .pushFromMil(milToMem1.master),
                          .pushFromSpi(spiToMem1.master),
                          .popToSpi(memToSpi1.master),
                          .popToMil(memToMil1.master),
                          .rcontrolMS(milToSpiRBControl1.master),
                          .rcontrolSM(spiToMilRBControl1.master),
                          .nResetRequest(nResetRequest1));
                      
  MemoryBlock2 memoryBlock(.nRst(nResetSignal), .clk(clk),
                          .push0(spiToMem0.slave),
                          .push1(spiToMem1.slave),
                          .push2(milToMem0.slave),
                          .push3(milToMem1.slave),
                          .pop0(memToMil0.slave),
                          .pop1(memToMil1.slave),
                          .pop2(memToSpi0.slave),
                          .pop3(memToSpi1.slave),
                          .rc0(spiToMilRBControl0.slave),
                          .rc1(spiToMilRBControl1.slave),
                          .rc2(milToSpiRBControl0.slave),
                          .rc3(milToSpiRBControl1.slave),
                          .mbus(mbus));
                     
endmodule

`endif