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
    public abstract class SPRequest : SPFrame, ISerializable
    {
        public UInt16 Serialize(Stream stream)
        {
            stream.WriteByte(Addr);
            stream.WriteUInt16(DataSize);
            stream.WriteByte((byte)Command);

            UInt16 osize = HeaderSize;
            osize += PayloadSerialize(stream);

            stream.WriteUInt16(CheckSum);
            stream.WriteUInt16(PackNum);

            for (int i = 0; i < PostfixSize(); i++)
                stream.WriteUInt16(0);

            return osize;
        }

        protected virtual UInt16 PayloadSerialize(Stream stream)
        {
            return 0;
        }

        protected virtual UInt16 PostfixSize()
        {
            return 3;
        }
    }
}
