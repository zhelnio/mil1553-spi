using MilTest.MilLight.ServiceProtocol;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

namespace MilTest.MilLight.MilSpiBridge
{
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

        public MilSpiBridge(string mpsseSerialNumber) : base(mpsseSerialNumber) { }

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
            var reply = (ISPStatus)transmitPacket(new SPStatusRequest() { Addr = addr, PackNum = packNum++ },
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
            const int maxWaitTime = 3000;
            const int recheckPeriod = 300;

            var cts = new CancellationTokenSource(maxWaitTime);

            return Task<List<IMilFrame>>.Run(() =>
            {
                List<IMilFrame> result = new List<IMilFrame>();
                while (!cts.Token.IsCancellationRequested)
                {
                    result.AddRange(Receive(addr, (UInt16)(size - result.Count)));

                    if (result.Count == size)
                        break;

                    Task.Delay(recheckPeriod);
                }

                return result;

            }, cts.Token).Result;
        }
    }
}
