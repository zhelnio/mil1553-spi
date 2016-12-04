/* MIL-STD-1553 <-> SPI bridge
 * Copyright(c) 2016 Stanislav Zhelnio
 * Licensed under the MIT license (MIT)
 * https://github.com/zhelnio/mil1553-spi
 */

`ifndef MILSPIDOUBLE_INCLUDE
`define MILSPIDOUBLE_INCLUDE

module IpMilSpiDoubleB(input logic clk, nRst,
                      ISpi spi,
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
    logic nResetRequest, nResetSignal;

    ResetGenerator  resetGenerator( .nRst(nRst), .clk(clk),
                                    .nResetRequest(nResetRequest),
                                    .nResetSignal(nResetSignal));

    MilSpiBlock2 milSpiBlock(   .nRst(nResetSignal), .clk(clk),
                                .spi(spi),
                                .mil0(mil0),
                                .mil1(mil1),
                                .pushFromMil0(milToMem0.master),
                                .pushFromMil1(milToMem1.master),
                                .pushFromSpi0(spiToMem0.master),
                                .pushFromSpi1(spiToMem1.master),
                                .popToSpi0(memToSpi0.master),
                                .popToSpi1(memToSpi1.master),
                                .popToMil0(memToMil0.master),
                                .popToMil1(memToMil1.master),
                                .rcontrolMS0(milToSpiRBControl0.master),
                                .rcontrolSM0(spiToMilRBControl0.master),
                                .rcontrolMS1(milToSpiRBControl1.master),
                                .rcontrolSM1(spiToMilRBControl1.master),
                                .nResetRequest(nResetRequest));
                 
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