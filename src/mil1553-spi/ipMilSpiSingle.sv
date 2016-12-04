/* MIL-STD-1553 <-> SPI bridge
 * Copyright(c) 2016 Stanislav Zhelnio
 * Licensed under the MIT license (MIT)
 * https://github.com/zhelnio/mil1553-spi
 */

`ifndef MILSPISINGLE_INCLUDE
`define MILSPISINGLE_INCLUDE
    
module IpMilSpiSingle(input logic clk, nRst,
                      ISpi spi,
                      IMilStd mil,
                      IMemory 	mbus);
  
  IPush spiToMem();
  IPush milToMem();
  IPop memToSpi();
  IPop memToMil();
  IRingBufferControl milToSpiRBControl();
  IRingBufferControl spiToMilRBControl();
  logic nResetRequest, nResetSignal;
  
  ResetGenerator  resetGenerator(.nRst(nRst), .clk(clk),
                                 .nResetRequest(nResetRequest),
                                 .nResetSignal(nResetSignal));
  
  MilSpiBlock milSpiBlock(.nRst(nResetSignal), .clk(clk),
                          .spi(spi), .mil(mil),
                          .pushFromMil(milToMem.master),
                          .pushFromSpi(spiToMem.master),
                          .popToSpi(memToSpi.master),
                          .popToMil(memToMil.master),
                          .rcontrolMS(milToSpiRBControl.master),
                          .rcontrolSM(spiToMilRBControl.master),
                          .nResetRequest(nResetRequest));
                          
  MemoryBlock memoryBlock(.nRst(nResetSignal), .clk(clk),
                          .push0(spiToMem.slave),
                          .push1(milToMem.slave),
                          .pop0(memToMil.slave),
                          .pop1(memToSpi.slave),
                          .rcontrol0(spiToMilRBControl.slave),
                          .rcontrol1(milToSpiRBControl.slave),
                          .mbus(mbus));
                          
endmodule



    
         


`endif