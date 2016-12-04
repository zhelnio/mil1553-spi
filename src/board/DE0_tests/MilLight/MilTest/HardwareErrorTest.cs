using Microsoft.VisualStudio.TestTools.UnitTesting;
using MilTest.MilLight.MilSpiBridge;
using MilTest.MilLight.ServiceProtocol;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

namespace MilTest
{
    [TestClass]
    public class HardwareErrorTest
    {
        const byte transmitterAddr = 0xAB;
        const byte receiverAddr = 0xAC;
        const string mpsseDeviceSerialNum = "A";

        [TestInitialize()]
        public void HardwareErrorTestInitialize()
        {
            IMilSpiBridge bridge = new MilSpiBridge(mpsseDeviceSerialNum);
            bridge.DeviceReset(transmitterAddr);
        }

        [TestMethod]
        public void SendErrorAndCheckStatus()
        {
            ErrorBridgeTransmitter bridge = new ErrorBridgeTransmitter(mpsseDeviceSerialNum);

            List<IMilFrame> tdata = new List<IMilFrame>() { new MilFrame() { Header = MilType.WSERV, Data = 1 } };

            bridge.Transmit(transmitterAddr, tdata);

            Thread.Sleep(500);

            ISPStatus status = bridge.getDeviceStatus(transmitterAddr);
            Assert.IsTrue(status.SpiErrorCount == 1);

            status = bridge.getDeviceStatus(receiverAddr);
            Assert.IsTrue(status.ReceivedQueueSize == 0);
        }

        class SPErrorCheckSumTransmitRequest : SPTransmitRequest
        {
            protected override ushort PayloadCheckSum()
            {
                //adding error to packet checksum
                return (ushort)(base.PayloadCheckSum() + 1);
            }
        }

        class ErrorBridgeTransmitter : MilSpiBridge
        {
            public ErrorBridgeTransmitter(string mpsseSerialNumber) : base(mpsseSerialNumber) { }

            public new void Transmit(byte addr, List<IMilFrame> data)
            {
                var packet = new SPErrorCheckSumTransmitRequest() { Addr = addr, Data = data, PackNum = 0 };
                if (!packet.IsValid)
                    throw new ArgumentException("Not valid frame data");

                transmitPacket(packet);
            }

        }
    }
}
