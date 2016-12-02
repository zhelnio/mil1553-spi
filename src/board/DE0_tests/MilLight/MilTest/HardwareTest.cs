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
            t.TransmissionTest();
        }
    }


    [TestClass]
    public class HardwareTest
    {
        private Random rnd = new Random();

        MilFrame randomFrame()
        {
            MilFrame frame = new MilFrame();

            frame.Header = (rnd.Next(2) == 0) ? MilType.WSERV : MilType.WDATA;
            frame.Data = (ushort)rnd.Next();

            return frame;
        }

        [TestMethod]
        public void TransmissionTest()
        {
            IMilSpiBridge bridge = new MilSpiBridge("A");

            List<IMilFrame> tdata = new List<IMilFrame>()
            {
                new MilFrame() { Data = 0x0001, Header = MilType.WSERV },
                new MilFrame() { Data = 0x0002 },
                new MilFrame() { Data = 0xAB45 },
                new MilFrame() { Data = 0xFFA1 }
            };

            bridge.Transmit(0xAB, tdata);

            Thread.Sleep(200);

            List<IMilFrame> rdata = bridge.WaitReceive(0xAC, 4);

            Assert.IsTrue(Enumerable.SequenceEqual(rdata, tdata));
        }

        [TestMethod]
        public void RandomTransmissionTest()
        {
            IMilSpiBridge bridge = new MilSpiBridge("A");

            List<IMilFrame> tdata = new List<IMilFrame>()
            {
                randomFrame()
            };

            bridge.Transmit(0xAB, tdata);

            List<IMilFrame> rdata = bridge.WaitReceive(0xAC, 1);

            Assert.IsTrue(Enumerable.SequenceEqual(rdata, tdata));
        }

        //[TestMethod]
        //public void HardwareRandomRepeat()
        //{
        //    IMilSpiBridge bridge = new MilSpiBridge("A");

        //    for (int i = 0; i < 10; i++)
        //    {
        //        List<IMilFrame> tdata = new List<IMilFrame>()
        //        {
        //            randomFrame(),
        //            randomFrame(),
        //            randomFrame(),
        //            randomFrame(),
        //        };

        //        bridge.Transmit(0xAB, tdata);

        //        Thread.Sleep(200);

        //        List<IMilFrame> rdata = bridge.Receive(0xAC, 4);

        //        Assert.IsTrue(Enumerable.SequenceEqual(rdata, tdata));
        //    }
        //}

        //[TestMethod]
        //public void HardwareRandomTransmissionTest()
        //{
        //    IMilSpiBridge bridge = new MilSpiBridge("A");

        //    List<IMilFrame> tdata = new List<IMilFrame>()
        //    {
        //        randomFrame(),
        //        randomFrame(),
        //        randomFrame(),
        //        randomFrame(),
        //    };

        //    bridge.Transmit(0xAB, tdata);

        //    Thread.Sleep(200);

        //    List<IMilFrame> rdata = bridge.Receive(0xAC, 4);

        //    Assert.IsTrue(Enumerable.SequenceEqual(rdata, tdata));
        //}

        //[TestMethod]
        //public void EmptyReceiveTest()
        //{
        //    IMilSpiBridge bridge = new MilSpiBridge("A");


        //    List<IMilFrame> rdata = bridge.Receive(0xAC, 4);

        //    // Assert.IsTrue(Enumerable.SequenceEqual(rdata, tdata));
        //}

    }
}
