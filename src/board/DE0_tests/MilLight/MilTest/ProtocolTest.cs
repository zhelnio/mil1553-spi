/* MIL-STD-1553 <-> SPI bridge
 * Copyright(c) 2016 Stanislav Zhelnio
 * Licensed under the MIT license (MIT)
 * https://github.com/zhelnio/mil1553-spi
 */

using System;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using MilTest.MilLight.ServiceProtocol;

namespace MilTest
{
    
    [TestClass]
    public abstract class SerializeTestCase
    {
        public abstract ISerializable getPacket();
        public abstract byte[] getReferenceRawData();

        [TestMethod]
        public void EncodeTest()
        {
            ISerializable t = getPacket();

            MemoryStream stream = new MemoryStream();
            t.Serialize(stream);
            byte[] data = stream.ToArray();

            byte[] normalData = getReferenceRawData();

            Assert.IsTrue(Enumerable.SequenceEqual(data, normalData));
        }
    }

    [TestClass]
    public class ProtocolReset : SerializeTestCase
    {
        public override ISerializable getPacket()
        {
            return new SPResetRequest() { Addr = 0xab, PackNum = 1 };
        }

        public override byte[] getReferenceRawData()
        {
            return new byte[] {
                0xab, 0x00, 0x00, 0xa0,
                0xab, 0xa0, 0x00, 0x01,
                0x00, 0x00, 0x00, 0x00, 0x00, 0x00
            };
        }
    }

    [TestClass]
    public class ProtocolStatusRequest : SerializeTestCase
    {
        public override ISerializable getPacket()
        {
            return new SPStatusRequest() { Addr = 0xab, PackNum = 1 };
        }

        public override byte[] getReferenceRawData()
        {
            return new byte[] {
                0xab, 0x00, 0x00, 0xb0,
                0xab, 0xb0, 0x00, 0x01,
                0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
            };
        }
    }

    [TestClass]
    public class ProtocolTransmitRequest : SerializeTestCase
    {
        public override ISerializable getPacket()
        {
            return new SPTransmitRequest()
            {
                Addr = 0xab,
                PackNum = 1,
                Data = new List<IMilFrame>()
                    {
                        new MilFrame() { Data = 0x0001, Header = MilType.WSERV },
                        new MilFrame() { Data = 0x0002 },
                        new MilFrame() { Data = 0xAB45 },
                        new MilFrame() { Data = 0xFFA1 }
                    }
            };
        }

        public override byte[] getReferenceRawData()
        {
            return new byte[] {
                0xab, 0x00, 0x08, 0xa2,
                0xff, 0xa1, 0x00, 0x01, 0xff, 0xa3, 0x00, 0x02,
                0xff, 0xa3, 0xab, 0x45, 0xff, 0xa3, 0xff, 0xa1,
                0x5d, 0x15, 0x00, 0x01,
                0x00, 0x00, 0x00, 0x00, 0x00, 0x00
            };
        }
    }

    [TestClass]
    public class ProtocolReceiveRequest : SerializeTestCase
    {
        public override ISerializable getPacket()
        {
            return new SPReceiveRequest()
            {
                Addr = 0xab,
                PackNum = 1,
                RequestedSize = 8
            };
        }

        public override byte[] getReferenceRawData()
        {
            return new byte[] {
                0xab, 0x00, 0x08, 0xb2,
                0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                0xb3, 0xba, 0x00, 0x01,
                0x00, 0x00, 0x00, 0x00, 0x00, 0x00
            };
        }
    }

    [TestClass]
    public abstract class DeserializeTestCase
    {
        public abstract SPReply createPacket();
        public abstract SPReply getReferencePacket();
        public abstract byte[] getRawData();

        [TestMethod]
        public void DecodeTest()
        {
            MemoryStream iStream = new MemoryStream(getRawData());
            SPReply r = createPacket();
            r.Deserialize(iStream);

            SPReply t = getReferencePacket();

            Assert.IsTrue(r.Equals(t));
            Assert.IsTrue(r.IsActual);
            Assert.IsTrue(r.IsValid);
        }
    }

    [TestClass]
    public class ProtocolStatusReplyCase : DeserializeTestCase
    {
        public override SPReply createPacket()
        {
            return new SPStatusReply();
        }

        public override byte[] getRawData()
        {
            return new byte[] {
                0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                0xab, 0x00, 0x03, 0xb0,
                0x00, 0x01, 0x00, 0x02, 0x00, 0x03,
                0xae, 0xb6, 0x00, 0x02
            };
        }

        public override SPReply getReferencePacket()
        {
            return new SPStatusReply()
            {
                Addr = 0xAB,
                ReceivedQueueSize = 1,
                TransmitQueueSize = 2,
                SpiErrorCount = 3,
                PackNum = 2
            };
        }
    }

    [TestClass]
    public class ProtocolReceiveReplyCase : DeserializeTestCase
    {
        public override SPReply createPacket()
        {
            return new SPReceiveReply();
        }

        public override byte[] getRawData()
        {
            return new byte[] {
                0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
                0xab, 0x00, 0x08, 0xb2,
                0xff, 0xa1, 0x00, 0x01, 0xff, 0xa3, 0x00, 0x02,
                0xff, 0xa3, 0xab, 0x45, 0xff, 0xa3, 0xff, 0xa1,
                0x5d, 0x25, 0x00, 0x01
            };
        }

        public override SPReply getReferencePacket()
        {
            return new SPReceiveReply()
            {
                Addr = 0xab,
                PackNum = 1,
                Data = new List<IMilFrame>()
                {
                    new MilFrame() { Data = 0x0001, Header = MilType.WSERV },
                    new MilFrame() { Data = 0x0002 },
                    new MilFrame() { Data = 0xAB45 },
                    new MilFrame() { Data = 0xFFA1 }
                }
            };
        }
    }
}
