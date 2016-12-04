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
    public enum SPCommand : byte
    {
        Unknown = 0xFF,
        Reset = 0xA0,
        Send = 0xA2,
        Status = 0xB0,
        Receive = 0xB2
    }

    public enum MilType : UInt16
    {
        WSERVERR = 0xFFA0,
        WSERV = 0xFFA1,
        WDATAERR = 0xFFA2,
        WDATA = 0xFFA3
    }

    public interface IMilFrame
    {
        MilType Header { get; set; }
        UInt16 Data { get; set; }
        UInt16 CheckSum { get; }
        UInt16 Size { get; }
    }

    public interface ISPFrame
    {
        byte Addr { get; set; }
        UInt16 DataSize { get; }
        SPCommand Command { get; }
        UInt16 CheckSum { get; }
        UInt16 PackNum { get; set; }
    }

    public interface ISPData
    {
        List<IMilFrame> Data { get; set; }
    }

    public interface ISPStatus
    {
        UInt16 TransmitQueueSize { get; }
        UInt16 ReceivedQueueSize { get; }
    }

    public interface ISerializable
    {
        UInt16 Serialize(Stream stream);
    }

    public interface IDeserializable
    {
        UInt16 Deserialize(Stream stream);
        
    }

    public interface IValidate
    {
        bool IsValid { get; }
    }
}
