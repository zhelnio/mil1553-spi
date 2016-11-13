using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MilLight
{
    public class SPStatus : SPFrame, ISPStatus
    {
        protected const UInt16 statusPayloadSize = 2;

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

        protected override ushort PayloadDataSize()
        {
            return statusPayloadSize;
        }

        protected override ushort PayloadCheckSum()
        {
            return (UInt16)(transmitQueueSize + receivedQueueSize);
        }

        protected override bool PayloadEquals(object obj)
        {
            SPStatus o = obj as SPStatus;
            if (o == null)
                return false;

            return o.receivedQueueSize == receivedQueueSize
                && o.transmitQueueSize == transmitQueueSize;
        }

        protected override int PayloadHashCode()
        {
            int hash = 56;
            hash = hash * 23 + receivedQueueSize.GetHashCode();
            hash = hash * 23 + transmitQueueSize.GetHashCode();
            return hash;
        }

        protected override ushort PayloadSerialize(Stream stream)
        {
            stream.WriteUInt16(receivedQueueSize);
            stream.WriteUInt16(transmitQueueSize);

            return statusPayloadSize;
        }

        protected override ushort PayloadDeserialize(Stream stream, ushort payloadSize)
        {
            if (payloadSize != statusPayloadSize)
                throw new ArgumentException("Illegal payloadSize. It should be identical to statusPayloadSize");

            receivedQueueSize = stream.ReadUInt16();
            transmitQueueSize = stream.ReadUInt16();

            return statusPayloadSize;
        }
    }
}
