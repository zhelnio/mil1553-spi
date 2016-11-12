using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MilLight
{
    public class MilPacket : MilPacketData, IBinarySerializable
    {
        public UInt16 Serialize(Stream stream)
        {
            if (HeaderTransfer)
            {
                stream.WriteUInt16((UInt16)Header);
                stream.WriteUInt16(Data);
                return 2;
            }

            stream.WriteUInt16(Data);
            return 1;
        }

        public UInt16 Deserialize(Stream stream)
        {
            UInt16 value = stream.ReadUInt16();
            if (value == (UInt16)MilType.WSERVERR || value == (UInt16)MilType.WSERV ||
               value == (UInt16)MilType.WDATAERR || value == (UInt16)MilType.WDATA)
            {
                Header = (MilType)value;
                Data = stream.ReadUInt16();
                return 2;
            }
            Header = MilType.WDATA;
            Data = value;
            return 1;
        }
    }
}
