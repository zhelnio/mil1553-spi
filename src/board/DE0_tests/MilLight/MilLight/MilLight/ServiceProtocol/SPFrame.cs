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
    public abstract class SPFrame : ExpirableObject, ISPFrame
    {
        #region ISPPacket

        protected const UInt16 HeaderSize = 4;

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

        public abstract SPCommand Command { get; }

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
            checkSum += (UInt16)((dataSize << 8) + ((byte)Command));
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

        public override string ToString()
        {
            return string.Format("cmd:{0} size:{1:X4} crc:{2:X4} num:{3:X4}", Command, DataSize, CheckSum, PackNum);
        }
    }
}
