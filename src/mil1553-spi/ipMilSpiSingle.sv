`ifndef MILSPISINGLE_INCLUDE
`define MILSPISINGLE_INCLUDE
    
module IpMilSpiSingle(input logic clk, rst,
                      ISpi spi,
                      IMilStd mil,
                      IMemory 	mbus);
  
  IPush spiToMem();
  IPush milToMem();
  IPop memToSpi();
  IPop memToMil();
  IRingBufferControl milToSpiRBControl();
  IRingBufferControl spiToMilRBControl();
  logic resetRequest, resetSignal;
  
  ResetGenerator  resetGenerator(.rst(rst), .clk(clk),
                                 .resetRequest(resetRequest),
                                 .resetSignal(resetSignal));
  
  MilSpiBlock milSpiBlock(.rst(resetSignal), .clk(clk),
                          .spi(spi), .mil(mil),
                          .pushFromMil(milToMem.master),
                          .pushFromSpi(spiToMem.master),
                          .popToSpi(memToSpi.master),
                          .popToMil(memToMil.master),
                          .rcontrolMS(milToSpiRBControl.master),
                          .rcontrolSM(spiToMilRBControl.master),
                          .resetRequest(resetRequest));
                          
  MemoryBlock memoryBlock(.rst(resetSignal), .clk(clk),
                          .push0(spiToMem.slave),
                          .push1(milToMem.slave),
                          .pop0(memToMil.slave),
                          .pop1(memToSpi.slave),
                          .rcontrol0(spiToMilRBControl.slave),
                          .rcontrol1(milToSpiRBControl.slave),
                          .mbus(mbus));
                          
endmodule



    
         


`endif