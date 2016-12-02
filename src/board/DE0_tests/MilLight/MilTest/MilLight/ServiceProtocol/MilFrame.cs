using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MilTest.MilLight.ServiceProtocol
{
    public class MilFrame : ExpirableObject, IMilFrame, ISerializable, IDeserializable
    {
        #region IMilFrame

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

        public UInt16 Size
        {
            get { return 2; } //header + data 
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

        public bool IsValid
        {
            get
            {
                return true;
            }
        }

        protected override void Actualization()
        {
            checkSum = (UInt16)((UInt16)header + data);
        }

        public override bool Equals(object obj)
        {
            MilFrame o = obj as MilFrame;
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

        #endregion IMilData

        #region IBinaryFrame

        public UInt16 Serialize(Stream stream)
        {
            stream.WriteUInt16((UInt16)Header);
            stream.WriteUInt16(Data);
            return Size;
        }

        public UInt16 Deserialize(Stream stream)
        {
            Header = (MilType)stream.ReadUInt16();
            Data = stream.ReadUInt16();
            return Size;
        }

        #endregion
    }
}
