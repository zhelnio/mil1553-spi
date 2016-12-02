using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MilTest.MilLight.ServiceProtocol
{
    public class SPReceiveRequest : SPRequest
    {
        public override SPCommand Command
        {
            get { return SPCommand.Receive; }
        }

        private UInt16 requestedSize = 0;
        public UInt16 RequestedSize
        {
            get
            {
                Actualize();
                return requestedSize;
            }
            set
            {
                requestedSize = value;
                Expire();
            }
        }

        protected override ushort PayloadDataSize()
        {
            return RequestedSize;
        }

        protected override ushort PayloadCheckSum()
        {
            return RequestedSize;
        }

        protected override bool PayloadEquals(object obj)
        {
            SPReceiveRequest o = obj as SPReceiveRequest;
            if (o == null)
                return false;

            return RequestedSize == o.RequestedSize;
        }

        protected override int PayloadHashCode()
        {
            return RequestedSize.GetHashCode();
        }

        protected override ushort PayloadSerialize(Stream stream)
        {
            for (int i = 0; i < RequestedSize; i++)
                stream.WriteUInt16(0);
            return RequestedSize;
        }
    }
}
