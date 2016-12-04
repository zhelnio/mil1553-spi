/* MIL-STD-1553 <-> SPI bridge
 * Copyright(c) 2016 Stanislav Zhelnio
 * Licensed under the MIT license (MIT)
 * https://github.com/zhelnio/mil1553-spi
 */

using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MilTest.MilLight.ServiceProtocol
{
    public class SPStatusReply : SPReply, ISPStatus
    {
        public override SPCommand Command
        {
            get { return SPCommand.Status; }
        }

        protected const UInt16 statusPayloadSize = 3;

        private ushort transmitQueueSize;
        public ushort TransmitQueueSize
        {
            get
            {
                Actualize();
                return transmitQueueSize;
            }
            set
            {
                transmitQueueSize = value;
                Expire();
            }
        }

        private ushort receivedQueueSize;
        public ushort ReceivedQueueSize
        {
            get
            {
                Actualize();
                return receivedQueueSize;
            }
            set
            {
                receivedQueueSize = value;
                Expire();
            }
        }

        private ushort spiErrorCount;
        public ushort SpiErrorCount
        {
            get
            {
                Actualize();
                return spiErrorCount;
            }
            set
            {
                spiErrorCount = value;
                Expire();
            }
        }

        protected override ushort PayloadDataSize()
        {
            return statusPayloadSize;
        }

        protected override ushort PayloadCheckSum()
        {
            return (UInt16)(transmitQueueSize + receivedQueueSize + spiErrorCount);
        }

        protected override bool PayloadEquals(object obj)
        {
            SPStatusReply o = obj as SPStatusReply;
            if (o == null)
                return false;

            return o.receivedQueueSize == receivedQueueSize
                && o.transmitQueueSize == transmitQueueSize
                && o.spiErrorCount == spiErrorCount;
        }

        protected override int PayloadHashCode()
        {
            int hash = 56;
            hash = hash * 23 + receivedQueueSize.GetHashCode();
            hash = hash * 23 + transmitQueueSize.GetHashCode();
            hash = hash * 23 + spiErrorCount.GetHashCode();
            return hash;
        }

        protected override ushort PayloadDeserialize(Stream stream, ushort payloadSize)
        {
            if (payloadSize != statusPayloadSize)
                throw new ArgumentException("Illegal payloadSize. It should be identical to statusPayloadSize");

            receivedQueueSize = stream.ReadUInt16();
            transmitQueueSize = stream.ReadUInt16();
            spiErrorCount     = stream.ReadUInt16();

            return statusPayloadSize;
        }

        public override string ToString()
        {
            return string.Format("{0} ReceivedQueueSize:{1:X4} TransmitQueueSize:{2:X4} SpiErrorCount:{3:X4}", 
                                base.ToString(), ReceivedQueueSize, TransmitQueueSize, SpiErrorCount);
        }
    }
}
