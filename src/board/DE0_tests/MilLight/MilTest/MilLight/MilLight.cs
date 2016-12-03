using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO;
using System.Runtime.InteropServices;
using System.ComponentModel;
using MilLight;
using System.Runtime.CompilerServices;
using MPSSELight;
using System.Diagnostics;
using MilTest.MilLight.ServiceProtocol;
using static MPSSELight.MpsseDevice;
using System.Threading;

namespace MilLight
{
    public interface IMilSpiBridge
    {
        List<IMilFrame> Receive(byte addr, UInt16 size);
        List<IMilFrame> WaitReceive(byte addr, UInt16 size);
        void Transmit(byte addr, List<IMilFrame> data);
        void DeviceReset(byte addr);
        ISPStatus getDeviceStatus(byte addr);
    }

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

            //return new FT2232D(mpsseSerialNumber);
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
            public CheckSumException() :  base() { }
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

    public class MilSpiBridge : SeviceProtocolBrige, IMilSpiBridge
    {
        public class DeviceStatus : ISPStatus
        {
            public DeviceStatus(ushort receivedQueueSize, ushort transmitQueueSize)
            {
                ReceivedQueueSize = receivedQueueSize;
                TransmitQueueSize = transmitQueueSize;
            }
            public ushort ReceivedQueueSize { get; set; }
            public ushort TransmitQueueSize { get; set; }
        }

        public MilSpiBridge(string mpsseSerialNumber) : base (mpsseSerialNumber) { }

        private UInt16 packNum = 0;

        public void DeviceReset(byte addr)
        {
            transmitPacket(new SPResetRequest() { Addr = addr, PackNum = packNum++ });
        }

        public void Transmit(byte addr, List<IMilFrame> data)
        {
            var packet = new SPTransmitRequest() { Addr = addr, Data = data, PackNum = packNum++ };
            if (!packet.IsValid)
                throw new ArgumentException("Not valid frame data");

            transmitPacket(packet);
        }

        public ISPStatus getDeviceStatus(byte addr)
        {
            var reply = (ISPStatus)transmitPacket(   new SPStatusRequest() { Addr = addr, PackNum = packNum++ }, 
                                                     new SPStatusReply());

            return new DeviceStatus((ushort)(reply.ReceivedQueueSize / 2), 
                                    (ushort)(reply.TransmitQueueSize / 2));
        }

        public List<IMilFrame> Receive(byte addr, UInt16 size)
        {
            var reply = (ISPData)transmitPacket(new SPReceiveRequest() { Addr = addr, RequestedSize = (UInt16)(size * 2), PackNum = packNum++ },
                                                new SPReceiveReply());
            return reply.Data;
        }

        public List<IMilFrame> WaitReceive(byte addr, UInt16 size)
        {
            var cts = new CancellationTokenSource(3000);
            return Task<List<IMilFrame>>.Run(() =>
            {
                List<IMilFrame> result = new List<IMilFrame>();
                while (!cts.Token.IsCancellationRequested && result.Count < size)
                    result.AddRange(Receive(addr, (UInt16)(size - result.Count)));
                return result;

            }, cts.Token).Result;
        }
    }
}
