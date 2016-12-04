# mil1553-spi
MIL-STD-1553 &lt;-> SPI bridge with internal memory buffer support.

Available commands:
- transmit data to mil interface
- get data, received from mil interface
- status request
- device reset

**Attention**: it was not tested with real MIL-STD-1553 devices

## IP core block diagram
![Alt text](/readme/mil1553-spi_diagram.png?raw=true "diagram")
## Directory structure
| Folder | Description |
| --- | --- |
| [/doc](/doc) | project documentation |
| [/src/board/DE0](/src/board/DE0) | Altera and Terasic board specific code for hardware tests |
| [/src/board/DE0_tests/batch_tests](/src/board/DE0_tests/batch_tests) | simple batch data transfer tests (SpiLight is used) |
| [/src/board/DE0_tests/MilLight](/src/board/DE0_tests/MilLight) | bridge communication .NET library, Unit Test Project for automatic hardware testing |
| [/src/mil1553-spi](/src/mil1553-spi) | mil1553-spi bridge IP cores SystemVerilog source code |
| [/src/testbench](/src/testbench) | mil1553-spi bridge IP cores SystemVerilog testbenches |

## Hardware test configuration
![Alt text](/readme/mil1553-spi_test.png?raw=true "test diagram")


