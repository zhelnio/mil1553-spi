using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MilTest.MilLight.ServiceProtocol
{
    public abstract class SPReply : SPFrame, IDeserializable, IValidate
    {
        public UInt16 Deserialize(Stream stream)
        {
            byte firstSeqByte = 0;
            do
            {
                int data = stream.ReadByte();
                firstSeqByte = (byte)data;
            }
            while (firstSeqByte == 0);

            Addr = firstSeqByte;

            UInt16 payloadSize = stream.ReadUInt16();
            DeserializedCommand = (SPCommand)stream.ReadByte();

            UInt16 osize = HeaderSize;
            osize += PayloadDeserialize(stream, payloadSize);

            DeserializedCheckSum = stream.ReadUInt16();
            PackNum = stream.ReadUInt16();

            return osize;
        }

        protected virtual UInt16 PayloadDeserialize(Stream stream, ushort payloadSize)
        {
            return 0;
        }

        private UInt16? DeserializedCheckSum = null;
        private SPCommand? DeserializedCommand = null;

        public bool IsValid
        {
            get
            {
                return ((DeserializedCheckSum ?? CheckSum) == CheckSum)
                    && ((DeserializedCommand ?? Command) == Command);
            }
        }

        public bool WasDeserialised
        {
            get { return (DeserializedCheckSum != null); }
        }
    }
}
