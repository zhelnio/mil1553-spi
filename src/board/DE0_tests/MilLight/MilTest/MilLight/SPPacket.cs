using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MilLight
{
    public class SPPacket : SPPacketData, IBinarySerializable
    {
        public UInt16 Serialize(Stream stream)
        {
            UInt16 osize = 4;
            stream.WriteByte(Addr);
            stream.WriteUInt16(DataSize);
            stream.WriteByte((byte)Command);
            Data.ForEach(a => osize += ((IBinarySerializable)a).Serialize(stream));
            stream.WriteUInt16(CheckSum);
            stream.WriteUInt16(PackNum);
            return osize;
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

            int rCataSize = stream.ReadUInt16();
            Command = (SPCommand)stream.ReadByte();
            Data = new List<IMilPacket>();

            UInt16 osize = 4;
            for (int i = 0; i < rCataSize;)
            {
                MilPacket mp = new MilPacket();
                UInt16 s = mp.Deserialize(stream);
                osize += s;
                i += s;
                Data.Add(mp);
            }
            DeserializedCheckSum = stream.ReadUInt16();
            PackNum = stream.ReadUInt16();

            return osize;
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

    }
}
