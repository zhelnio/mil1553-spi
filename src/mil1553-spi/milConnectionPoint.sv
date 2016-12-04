/* MIL-STD-1553 <-> SPI bridge
 * Copyright(c) 2016 Stanislav Zhelnio
 * Licensed under the MIT license (MIT)
 * https://github.com/zhelnio/mil1553-spi
 */

`ifndef MILCONNPOINT_INCLUDE
`define MILCONNPOINT_INCLUDE

module MilConnectionPoint(  IMilStd.line mil0, 
                            IMilStd.line mil1);

    assign mil0.RXin  	= mil0.TXout	| mil1.TXout;
    assign mil0.nRXin 	= mil0.nTXout	| mil1.nTXout;
    assign mil1.RXin  	= mil0.RXin;
    assign mil1.nRXin 	= mil0.nRXin;

endmodule

module MilConnectionPoint3( IMilStd.line mil0, 
                            IMilStd.line mil1,
                            IMilStd.line mil2);

    assign mil0.RXin  	= mil0.TXout	| mil1.TXout    | mil2.TXout;
    assign mil0.nRXin 	= mil0.nTXout	| mil1.nTXout   | mil2.nTXout;
    assign mil1.RXin  	= mil0.RXin;
    assign mil1.nRXin 	= mil0.nRXin;
    assign mil2.RXin  	= mil0.RXin;
    assign mil2.nRXin 	= mil0.nRXin;

endmodule

`endif