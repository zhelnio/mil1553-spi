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
    public class SPReceiveReply : SPReply, ISPData
    {
        public override SPCommand Command
        {
            get { return SPCommand.Receive; }
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

        protected override ushort PayloadDeserialize(Stream stream, ushort payloadSize)
        {
            Data = new List<IMilFrame>();

            for (int i = 0; i < payloadSize;)
            {
                MilFrame mp = new MilFrame();
                UInt16 s = mp.Deserialize(stream);
                i += s;
                Data.Add(mp);
            }

            return payloadSize;
        }

        public override string ToString()
        {
            return string.Format("{0} data:{1}", base.ToString(), string.Join(", ", Data));
        }
    }
}
