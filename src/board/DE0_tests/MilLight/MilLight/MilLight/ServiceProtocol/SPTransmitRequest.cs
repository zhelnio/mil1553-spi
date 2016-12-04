using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MilTest.MilLight.ServiceProtocol
{
    public class SPTransmitRequest : SPRequest, ISPData, IValidate
    {
        public override SPCommand Command
        {
            get { return SPCommand.Send; }
        }

        public override bool IsActual
        {
            get { return base.IsActual && !Data.Exists(a => !((ExpirableObject)a).IsActual); }
        }

        private List<IMilFrame> data = new List<IMilFrame>();
        public List<IMilFrame> Data
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

        public bool IsValid
        {
            get
            {
                return data.Count > 0
                    && data[0].Header == MilType.WSERV
                    && data.Count(a => a.Header == MilType.WDATA) == data.Count - 1;
            }
        }

        protected override ushort PayloadDataSize()
        {
            return (UInt16)(data.Sum(a => a.Size));
        }

        protected override ushort PayloadCheckSum()
        {
            return (UInt16)(data.Sum(a => a.CheckSum));
        }

        protected override bool PayloadEquals(object obj)
        {
            ISPData o = obj as ISPData;
            if (o == null)
                return false;

            return Enumerable.SequenceEqual(o.Data, Data);
        }

        protected override int PayloadHashCode()
        {
            return Data.GetHashCode();
        }

        protected override UInt16 PayloadSerialize(Stream stream)
        {
            ushort size = 0;
            Data.ForEach(a => size += ((ISerializable)a).Serialize(stream));
            return size;
        }

        public override string ToString()
        {
            return string.Format("{0} data:{1}", base.ToString(), string.Join(", ", Data));
        }
    }
}
