/* MIL-STD-1553 <-> SPI bridge
 * Copyright(c) 2016 Stanislav Zhelnio
 * Licensed under the MIT license (MIT)
 * https://github.com/zhelnio/mil1553-spi
 */

using MilTest.MilLight.ServiceProtocol;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MilTest.MilLight.MilSpiBridge
{
    public interface IMilSpiBridge
    {
        List<IMilFrame> Receive(byte addr, UInt16 size);
        List<IMilFrame> WaitReceive(byte addr, UInt16 size);
        void Transmit(byte addr, List<IMilFrame> data);
        void DeviceReset(byte addr);
        ISPStatus getDeviceStatus(byte addr);
    }
}
