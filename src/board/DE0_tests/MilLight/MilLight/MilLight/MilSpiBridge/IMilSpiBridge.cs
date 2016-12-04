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
