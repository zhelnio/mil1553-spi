/* MIL-STD-1553 <-> SPI converter
 * Copyright(c) 2016 Stanislav Zhelnio
 * Licensed under the MIT license (MIT)
 * https://github.com/zhelnio/mil1553-spi
 */

`ifndef SETTINGS_INCLUDE
`define SETTINGS_INCLUDE

`define DATAW_SIZE	16
`define DATAC_SIZE	4
`define DATAW_TOP		(`DATAW_SIZE - 1)	
`define DATAC_TOP		(`DATAC_SIZE - 1)

`define ADDRW_SIZE	8
`define ADDRW_TOP		(`ADDRW_SIZE - 1)	


`endif
