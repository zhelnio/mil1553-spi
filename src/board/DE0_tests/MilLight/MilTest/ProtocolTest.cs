using System;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using System.Collections.Generic;
using System.IO;
using MilLight;
using System.Linq;

namespace MilTest
{
    class MainC
    {
        public static void Main()
        {
            var t = new ProtocolStatusResponceCase();
            t.DecodeTest();
        }
    }

    [TestClass]
    public abstract class ProtocolTestCase
    {
        public abstract SPFrame getPacket();
        public abstract byte[] getRawData();

        [TestMethod]
        public void EncodeTest()
        {
            SPFrame t = getPacket();

            MemoryStream stream = new MemoryStream();
            t.Serialize(stream);
            byte[] data = stream.ToArray();

            byte[] normalData = getRawData();

            Assert.IsTrue(Enumerable.SequenceEqual(data, normalData));
        }

        [TestMethod]
        public void DecodeTest()
        {
            SPFrame p = getPacket();

            MemoryStream stream = new MemoryStream();
            p.Serialize(stream);
            byte[] data = stream.ToArray();

            MemoryStream iStream = new MemoryStream(data);
            SPFrame r = createPacket();
            r.Deserialize(iStream);

            bool s = r.Equals(p);

            Assert.IsTrue(r.Equals(p));
            Assert.IsTrue(r.IsActual);
            Assert.IsTrue(r.IsValid);
        }

        protected virtual SPFrame createPacket()
        {
            return new SPFrame();
        }
    }

    [TestClass]
    public class ProtocolSendCase : ProtocolTestCase
    {
        public override SPFrame getPacket()
        {
            SPData p = new SPData()
            {
                Addr = 0xAB,
                Command = SPCommand.Send,
                Data = new List<IMilFrame>()
                    {
                        new MilFrame() { Data = 0x0001, Header = MilType.WSERV },
                        new MilFrame() { Data = 0x0002 },
                        new MilFrame() { Data = 0xAB45 },
                        new MilFrame() { Data = 0xFFA1 }
                    }
            };
            return p;
        }

        public override byte[] getRawData()
        {
            return new byte[] {
                0xab, 0x00, 0x06, 0xa2,
                0xff, 0xa1, 0x00, 0x01, 0x00, 0x02, 0xab, 0x45,
                0xff, 0xa3, 0xff, 0xa1, 0x5b, 0xcf, 0x00, 0x00 };
        }

        protected override SPFrame createPacket()
        {
            return new SPData(); ;
        }
    }

    [TestClass]
    public class ProtocolReceiveCase : ProtocolTestCase
    {
        public override SPFrame getPacket()
        {
            SPData p = new SPData()
            {
                Addr = 0xAB,
                Command = SPCommand.Receive,
                Data = new List<IMilFrame>()
                    {
                        new MilFrame() { Data = 0x0000 },
                        new MilFrame() { Data = 0x0000 },
                        new MilFrame() { Data = 0x0000 },
                        new MilFrame() { Data = 0x0000 },
                        new MilFrame() { Data = 0x0000 },
                        new MilFrame() { Data = 0x0000 },
                        new MilFrame() { Data = 0x0000 },
                        new MilFrame() { Data = 0x0000 },
                        new MilFrame() { Data = 0x0000 },
                        new MilFrame() { Data = 0x0000 },
                        new MilFrame() { Data = 0x0000 },
                        new MilFrame() { Data = 0x0000 }
                    }
            };
            return p;
        }

        public override byte[] getRawData()
        {
            return new byte[] {
                0xab, 0x00, 0x0c, 0xb2,
                0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                0xb7, 0xb2, 0x00, 0x00 };
        }

        protected override SPFrame createPacket()
        {
            return new SPData(); ;
        }
    }

    [TestClass]
    public class ProtocolStatusRequestCase : ProtocolTestCase
    {
        public override SPFrame getPacket()
        {
            SPData p = new SPData()
            {
                Addr = 0xAB,
                Command = SPCommand.Status,
                Data = new List<IMilFrame>()
                {
                    new MilFrame() { Data = 0x0000 },
                    new MilFrame() { Data = 0x0000 },
                    new MilFrame() { Data = 0x0000 },
                    new MilFrame() { Data = 0x0000 },
                    new MilFrame() { Data = 0x0000 },
                    new MilFrame() { Data = 0x0000 },
                    new MilFrame() { Data = 0x0000 },
                    new MilFrame() { Data = 0x0000 },
                    new MilFrame() { Data = 0x0000 },
                    new MilFrame() { Data = 0x0000 },
                    new MilFrame() { Data = 0x0000 },
                    new MilFrame() { Data = 0x0000 }
                }
            };
            return p;
        }

        public override byte[] getRawData()
        {
            return new byte[] {
            0xab, 0x00, 0x0c, 0xb0,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0xb7, 0xb0, 0x00, 0x00 };
        }

        protected override SPFrame createPacket()
        {
            return new SPData(); ;
        }
    }

    [TestClass]
    public class ProtocolResetCase : ProtocolTestCase
    {
        public override SPFrame getPacket()
        {
            SPFrame p = new SPFrame()
            {
                Addr = 0xAB,
                Command = SPCommand.Reset,
            };
            return p;
        }

        public override byte[] getRawData()
        {
            return new byte[] {
            0xab, 0x00, 0x00, 0xa0,
            0xab, 0xa0, 0x00, 0x00 };
        }
    }

    [TestClass]
    public class ProtocolStatusResponceCase : ProtocolTestCase
    {
        public override SPFrame getPacket()
        {
            SPStatus p = new SPStatus()
            {
                Addr = 0xAB,
                Command = SPCommand.Status,
                ReceivedQueueSize = 1,
                TransmitQueueSize = 2
            };
            return p;
        }

        public override byte[] getRawData()
        {
            return new byte[] {
            0xab, 0x00, 0x02, 0xb0,
            0x00, 0x01, 0x00, 0x02,
            0xad, 0xb3, 0x00, 0x00 };
        }

        protected override SPFrame createPacket()
        {
            return new SPStatus(); ;
        }
    }
}
