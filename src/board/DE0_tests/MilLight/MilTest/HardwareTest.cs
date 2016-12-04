/* MIL-STD-1553 <-> SPI bridge
 * Copyright(c) 2016 Stanislav Zhelnio
 * Licensed under the MIT license (MIT)
 * https://github.com/zhelnio/mil1553-spi
 */

using System;
using System.Text;
using System.Collections.Generic;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using System.Threading;
using System.Linq;
using MilTest.MilLight.ServiceProtocol;
using MilTest.MilLight.MilSpiBridge;

namespace MilTest
{
    class MainC
    {
        public static void Main()
        {
            var t = new HardwareErrorTest();
            t.SendErrorAndCheckStatus();
        }
    }

    [TestClass]
    public class HardwareTest
    {
        const byte transmitterAddr = 0xAB;
        const byte receiverAddr = 0xAC;
        const string mpsseDeviceSerialNum = "A";
        const int cycleTestCount = 100;

        [TestInitialize()]
        public void HardwareTestInitialize()
        {
            IMilSpiBridge bridge = new MilSpiBridge(mpsseDeviceSerialNum);
            bridge.DeviceReset(transmitterAddr);
        }

        [TestMethod]
        public void ResetAndStatusTest()
        {
            IMilSpiBridge bridge = new MilSpiBridge(mpsseDeviceSerialNum);

            List<IMilFrame> tdata = PacketGenerator.randomPacket(1);

            bridge.Transmit(transmitterAddr, tdata);

            Thread.Sleep(500);

            ISPStatus status = bridge.getDeviceStatus(receiverAddr);
            Assert.IsTrue(status.ReceivedQueueSize == 1);

            bridge.DeviceReset(transmitterAddr);

            Thread.Sleep(200);

            status = bridge.getDeviceStatus(receiverAddr);
            Assert.IsTrue(status.ReceivedQueueSize == 0);
        }



        [TestMethod]
        public void TransmissionFixedTest()
        {
            TransmissionTest(PacketGenerator.fixedPacket());
        }

        [TestMethod]
        public void TransmissionRandom1Test()
        {
            TransmissionTest(PacketGenerator.randomPacket(1));
        }

        [TestMethod]
        public void TransmissionRandomNTest()
        {
            TransmissionTest(PacketGenerator.randomPacket());
        }

        [TestMethod]
        public void TransmissionFixedCycleTest()
        {
            for (int i = 0; i < cycleTestCount; i++)
                TransmissionTest(PacketGenerator.fixedPacket());
        }

        [TestMethod]
        public void TransmissionRandom1CycleTest()
        {
            for (int i = 0; i < cycleTestCount; i++)
                TransmissionTest(PacketGenerator.randomPacket(1));
        }

        [TestMethod]
        public void TransmissionRandomNCycleTest()
        {
            for (int i = 0; i < cycleTestCount; i++)
                TransmissionTest(PacketGenerator.randomPacket());
        }

        void TransmissionTest(List<IMilFrame> tdata)
        {
            IMilSpiBridge bridge = new MilSpiBridge(mpsseDeviceSerialNum);

            bridge.Transmit(transmitterAddr, tdata);

            List<IMilFrame> rdata = bridge.WaitReceive(receiverAddr, (ushort)tdata.Count);

            Assert.IsTrue(Enumerable.SequenceEqual(rdata, tdata));
        }
    }
}
