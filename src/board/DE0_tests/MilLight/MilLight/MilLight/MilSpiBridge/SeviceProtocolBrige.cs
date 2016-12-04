/* MIL-STD-1553 <-> SPI bridge
 * Copyright(c) 2016 Stanislav Zhelnio
 * Licensed under the MIT license (MIT)
 * https://github.com/zhelnio/mil1553-spi
 */

using MilTest.MilLight.ServiceProtocol;
using MPSSELight;
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using static MPSSELight.MpsseDevice;

namespace MilTest.MilLight.MilSpiBridge
{
    public abstract class SeviceProtocolBrige
    {
        string mpsseSerialNumber;
        public SeviceProtocolBrige(string mpsseSerialNumber)
        {
            this.mpsseSerialNumber = mpsseSerialNumber;
        }

        MpsseDevice deviceConnect()
        {
            MpsseParams mp = new MpsseParams() { clockDevisor = 1 };
            return new FT2232D(mpsseSerialNumber, mp);
        }

        protected void spiWrite(byte[] data)
        {
            using (MpsseDevice mpsse = deviceConnect())
            {
                SpiDevice spi = new SpiDevice(mpsse);
                DebugWrite("transmitRaw:     ", data);
                spi.write(data);
            }
        }

        protected byte[] spiReadWrite(byte[] data)
        {
            using (MpsseDevice mpsse = deviceConnect())
            {
                SpiDevice spi = new SpiDevice(mpsse);

                DebugWrite("transmitRaw:     ", data);
                byte[] rcvd = spi.readWrite(data);
                DebugWrite("receivedRaw:     ", rcvd);
                return rcvd;
            }
        }

        protected object transmitPacket(ISerializable request, IDeserializable reply = null)
        {
            MemoryStream stream = new MemoryStream();
            request.Serialize(stream);
            byte[] rawRequest = stream.ToArray();

            if (reply == null)
            {
                DebugWrite("transmit:        ", request);
                spiWrite(rawRequest);
                return null;
            }
            else
            {
                byte[] rawReply = spiReadWrite(rawRequest);
                stream = new MemoryStream(rawReply);
                reply.Deserialize(stream);

                DebugWrite("received:        ", reply);

                if (!((IValidate)reply).IsValid)
                    throw new CheckSumException();

                return reply;
            }
        }

        public class CheckSumException : IOException
        {
            public CheckSumException() : base() { }
            public CheckSumException(string message) : base(message) { }
            public CheckSumException(string message, int hresult) : base(message, hresult) { }
            public CheckSumException(string message, Exception innerException) : base(message, innerException) { }
        }

        static void DebugWrite(string header, byte[] data)
        {
            Debug.Write(header);
            string hex = BitConverter.ToString(data).Replace("-", "");
            Debug.WriteLine(hex);
        }

        static void DebugWrite(string header, object data)
        {
            Debug.Write(header);
            Debug.WriteLine(data);
        }
    }
}
