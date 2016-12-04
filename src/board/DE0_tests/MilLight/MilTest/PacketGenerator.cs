/* MIL-STD-1553 <-> SPI bridge
 * Copyright(c) 2016 Stanislav Zhelnio
 * Licensed under the MIT license (MIT)
 * https://github.com/zhelnio/mil1553-spi
 */

using MilTest.MilLight.ServiceProtocol;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MilTest
{
    static class PacketGenerator
    {
        private static Random rnd = new Random();

        public static List<IMilFrame> randomPacket(int size)
        {
            if (size == 0)
                throw new ArgumentException("packet size should be greater then 0");

            List<IMilFrame> result = new List<IMilFrame>();

            //header
            result.Add(new MilFrame() { Header = MilType.WSERV, Data = (ushort)rnd.Next() });

            //body
            for (int i = 1; i < size; i++)
                result.Add(new MilFrame() { Header = MilType.WDATA, Data = (ushort)rnd.Next() });

            return result;
        }

        public static List<IMilFrame> randomPacket()
        {
            const int maxPacketSize = 30;
            return randomPacket(rnd.Next(1, maxPacketSize));
        }

        public static List<IMilFrame> fixedPacket()
        {
            return new List<IMilFrame>()
            {
                new MilFrame() { Data = 0x0001, Header = MilType.WSERV },
                new MilFrame() { Data = 0x0002 },
                new MilFrame() { Data = 0xAB45 },
                new MilFrame() { Data = 0xFFA1 }
            };
        }
    }

}
