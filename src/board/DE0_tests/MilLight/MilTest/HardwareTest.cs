using System;
using System.Text;
using System.Collections.Generic;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using MilLight;
using System.Threading;
using System.Linq;
using MilTest.MilLight.ServiceProtocol;

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
        

        [TestInitialize()]
        public void HardwareTestTestInitialize()
        {
            IMilSpiBridge bridge = new MilSpiBridge("A");
            bridge.DeviceReset(0xAB);
        }

        [TestMethod]
        public void ResetAndStatusTest()
        {
            IMilSpiBridge bridge = new MilSpiBridge("A");

            List<IMilFrame> tdata = PacketGenerator.randomPacket(1);

            bridge.Transmit(0xAB, tdata);

            Thread.Sleep(500);

            ISPStatus status = bridge.getDeviceStatus(0xAC);
            Assert.IsTrue(status.ReceivedQueueSize == 1);

            bridge.DeviceReset(0xAB);

            Thread.Sleep(200);

            status = bridge.getDeviceStatus(0xAC);
            Assert.IsTrue(status.ReceivedQueueSize == 0);
        }

        [TestMethod]
        public void TransmissionFixedTest()
        {
            IMilSpiBridge bridge = new MilSpiBridge("A");

            List<IMilFrame> tdata = PacketGenerator.fixedPacket();

            bridge.Transmit(0xAB, tdata);

            List<IMilFrame> rdata = bridge.WaitReceive(0xAC, (ushort)tdata.Count);

            Assert.IsTrue(Enumerable.SequenceEqual(rdata, tdata));
        }

        [TestMethod]
        public void TransmissionRandom1Test()
        {
            IMilSpiBridge bridge = new MilSpiBridge("A");

            List<IMilFrame> tdata = PacketGenerator.randomPacket(1);

            bridge.Transmit(0xAB, tdata);

            List<IMilFrame> rdata = bridge.WaitReceive(0xAC, 1);

            Assert.IsTrue(Enumerable.SequenceEqual(rdata, tdata));
        }

        [TestMethod]
        public void TransmissionRandomNTest()
        {
            IMilSpiBridge bridge = new MilSpiBridge("A");

            List<IMilFrame> tdata = PacketGenerator.randomPacket();

            bridge.Transmit(0xAB, tdata);

            List<IMilFrame> rdata = bridge.WaitReceive(0xAC, (ushort)tdata.Count);

            Assert.IsTrue(Enumerable.SequenceEqual(rdata, tdata));
        }

        [TestMethod]
        public void TransmissionFixedCycleTest()
        {
            for (int i = 0; i < 100; i++)
                TransmissionFixedTest();
        }

        [TestMethod]
        public void TransmissionRandom1CycleTest()
        {
            for (int i = 0; i < 100; i++)
                TransmissionRandom1Test();
        }

        [TestMethod]
        public void TransmissionRandomNCycleTest()
        {
            for (int i = 0; i < 100; i++)
                TransmissionRandomNTest();
        }
    }
}
