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
            var t = new HardwareTest();
            t.TransmissionFixedTest();
        }
    }

    static class PacketGenerator
    {
        private static Random rnd = new Random();

        public static List<IMilFrame> randomPacket(int size)
        {
            if (size == 0)
                throw new ArgumentException("packet size should be greater then 0");

            List<IMilFrame> result = new List<IMilFrame>();

            //header
            result.Add(new MilFrame() { Header = MilType.WSERV, Data = (ushort)rnd.Next() });

            //body
            for (int i = 1; i < size; i++)
                result.Add(new MilFrame() { Header = MilType.WDATA, Data = (ushort)rnd.Next() });

            return result;
        }

        public static List<IMilFrame> randomPacket()
        {
            const int maxPacketSize = 30;
            return randomPacket(rnd.Next(1, maxPacketSize));
        }

        public static List<IMilFrame> fixedPacket()
        {
            return new List<IMilFrame>()
            {
                new MilFrame() { Data = 0x0001, Header = MilType.WSERV },
                new MilFrame() { Data = 0x0002 },
                new MilFrame() { Data = 0xAB45 },
                new MilFrame() { Data = 0xFFA1 }
            };
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
        public void HardwareTestTestInitialize()
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
