/* MIL-STD-1553 <-> SPI bridge
 * Copyright(c) 2016 Stanislav Zhelnio
 * Licensed under the MIT license (MIT)
 * https://github.com/zhelnio/mil1553-spi
 */

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
            public DeviceStatus(ushort receivedQueueSize, ushort transmitQueueSize, ushort spiErrorCount)
            {
                ReceivedQueueSize = receivedQueueSize;
                TransmitQueueSize = transmitQueueSize;
                SpiErrorCount = spiErrorCount;
            }
            public ushort ReceivedQueueSize { get; set; }
            public ushort TransmitQueueSize { get; set; }
            public ushort SpiErrorCount { get; set; }
        }

        public MilSpiBridge(string mpsseSerialNumber) : base(mpsseSerialNumber) { }

        const byte MilFrameSizeInWords = 2;

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

            return new DeviceStatus((ushort)(reply.ReceivedQueueSize / MilFrameSizeInWords),
                                    (ushort)(reply.TransmitQueueSize / MilFrameSizeInWords),
                                    reply.SpiErrorCount);
        }

        public List<IMilFrame> Receive(byte addr, UInt16 size)
        {
            var reply = (ISPData)transmitPacket(new SPReceiveRequest()
                                                {
                                                    Addr = addr,
                                                    RequestedSize = (UInt16)(size * MilFrameSizeInWords),
                                                    PackNum = packNum++
                                                },
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
