using System;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using System.Collections.Generic;
using System.IO;
using MilLight;

namespace MilTest
{
    class MainC
    {
        public static void Main()
        {
            var t = new ProtocolTest();
            t.DecodeTest();
        }
    }

    [TestClass]
    public class ProtocolTest
    {
        private SPPacket createSendPacket()
        {
            SPPacket p = new SPPacket()
            {
                Addr = 0xAB,
                Command = SPCommand.Send,
                Data = new List<IMilPacket>()
                {
                    new MilPacket() { Data = 0x0001, Header = MilType.WSERV },
                    new MilPacket() { Data = 0x0002 },
                    new MilPacket() { Data = 0xAB45 },
                    new MilPacket() { Data = 0xFFA1 }
                }
            };
            return p;
        }

        [TestMethod]
        public void EncodeTest()
        {
            SPPacket p = createSendPacket();

            MemoryStream stream = new MemoryStream();
            p.Serialize(stream);
            byte[] data = stream.ToArray();
        }

        [TestMethod]
        public void DecodeTest()
        {
            SPPacket p = createSendPacket();

            MemoryStream stream = new MemoryStream();
            p.Serialize(stream);
            byte[] data = stream.ToArray();

            MemoryStream iStream = new MemoryStream(data);
            SPPacket r = new SPPacket();
            r.Deserialize(iStream);
        }
    }
}
