using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MilLight
{
    public class SPFrame : ExpirableObject, ISPFrame, IBinaryFrame
    {
        #region ISPPacket

        private byte addr;
        public byte Addr
        {
            get
            {
                Actualize();
                return addr;
            }
            set
            {
                addr = value;
                Expire();
            }
        }

        private byte command;
        public SPCommand Command
        {
            get
            {
                Actualize();
                return (SPCommand)command;
            }
            set
            {
                command = (byte)value;
                Expire();
            }
        }

        public UInt16 PackNum { get; set; }

        private UInt16 dataSize;
        public UInt16 DataSize
        {
            get
            {
                Actualize();
                return dataSize;
            }

            protected set { dataSize = value; }
        }

        private UInt16 checkSum;
        public UInt16 CheckSum
        {
            get
            {
                Actualize();
                return checkSum;
            }

            protected set { checkSum = value; }
        }

        protected override void Actualization()
        {
            dataSize = PayloadDataSize();
            checkSum = (UInt16)((addr << 8) + (dataSize >> 8));
            checkSum += (UInt16)((dataSize << 8) + ((byte)command));
            checkSum += PayloadCheckSum();
        }

        protected virtual UInt16 PayloadDataSize()
        {
            return 0;
        }

        protected virtual UInt16 PayloadCheckSum()
        {
            return 0;
        }

        #endregion ISPPacket

        #region Equality
        public override bool Equals(object obj)
        {
            SPFrame o = obj as SPFrame;
            if (o == null)
                return false;

            return o.Addr == Addr
                && o.CheckSum == CheckSum
                && o.Command == Command
                && o.DataSize == DataSize
                && PayloadEquals(obj);
        }

        protected virtual bool PayloadEquals(object obj)
        {
            return true;
        }

        public override int GetHashCode()
        {
            int hash = 11;
            hash = hash * 24 + Addr.GetHashCode();
            hash = hash * 24 + CheckSum.GetHashCode();
            hash = hash * 24 + Command.GetHashCode();
            hash = hash * 24 + DataSize.GetHashCode();
            hash = hash * 24 + PayloadHashCode();
            return hash;
        }

        protected virtual int PayloadHashCode()
        {
            return 0;
        }

        #endregion Equality

        #region IBinaryFrame

        //sizeof_in_words(addr + dataSize + command + CheckSum + PackNum)
        protected const UInt16 serialisedHeaderSize = 4;

        public UInt16 Serialize(Stream stream)
        {
            stream.WriteByte(Addr);
            stream.WriteUInt16(DataSize);
            stream.WriteByte((byte)Command);

            UInt16 osize = serialisedHeaderSize;
            osize += PayloadSerialize(stream);

            stream.WriteUInt16(CheckSum);
            stream.WriteUInt16(PackNum);
            return osize;
        }

        protected virtual UInt16 PayloadSerialize(Stream stream)
        {
            return 0;
        }

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
            Command = (SPCommand)stream.ReadByte();

            UInt16 osize = serialisedHeaderSize;
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

        public bool IsValid
        {
            get { return ((DeserializedCheckSum ?? CheckSum) == CheckSum); }
        }

        public bool WasDeserialised
        {
            get { return (DeserializedCheckSum != null); }
        }

        #endregion IBinaryFrame
    }
}
