using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MilLight
{
    public class MilPacketData : ExpirableObject, IMilPacket
    {
        private MilType header = MilType.WDATA;
        public MilType Header
        {
            get
            {
                Actualize();
                return header;
            }
            set
            {
                header = value;
                Expire();
            }
        }

        private UInt16 data;
        public UInt16 Data
        {
            get
            {
                Actualize();
                return data;
            }
            set
            {
                data = value;
                Expire();
            }
        }

        private UInt16 size;
        public UInt16 Size
        {
            get
            {
                Actualize();
                return size;
            }
        }

        private UInt16 checkSum;
        public UInt16 CheckSum
        {
            get
            {
                Actualize();
                return checkSum;
            }
        }

        protected bool HeaderTransfer
        {
            get
            {
                return header != MilType.WDATA ||
                    data == (UInt16)MilType.WSERVERR || data == (UInt16)MilType.WSERV ||
                    data == (UInt16)MilType.WDATAERR || data == (UInt16)MilType.WDATA;
            }
        }

        protected override void Actualization()
        {
            if (HeaderTransfer)
            {
                size = 2;
                checkSum = (UInt16)((UInt16)header + data);
            }
            else
            {
                size = 1;
                checkSum = data;
            }
        }

        public override bool Equals(object obj)
        {
            MilPacketData o = obj as MilPacketData;
            if (o == null)
                return false;

            return o.Header == Header
                && o.Data == Data;
        }

        public override int GetHashCode()
        {
            int hash = 35;
            hash = hash * 28 + Header.GetHashCode();
            hash = hash * 28 + Data.GetHashCode();
            return hash;
        }
    }
}
