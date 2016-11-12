using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO;
using System.Runtime.InteropServices;
using System.ComponentModel;
using MilLight;
using System.Runtime.CompilerServices;

namespace MilLight
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

    public interface IMilPacket
    {
        MilType Header { get; set; }
        UInt16 Data { get; set; }
        UInt16 CheckSum { get; }
        UInt16 Size { get; }
    }

    public interface ISPPacket
    {
        byte Addr { get; set; }
        UInt16 DataSize { get; }
        SPCommand Command { get; set; }
        List<IMilPacket> Data { get; set; }
        UInt16 CheckSum { get; }
        UInt16 PackNum { get; set; }
    }

    public interface IBinarySerializable
    {
        UInt16 Serialize(Stream stream);
        UInt16 Deserialize(Stream stream);
    }

    /*
    `define ESC_WSERVERR	16'hFFA0
    `define ESC_WSERV		16'hFFA1
    `define ESC_WDATAERR	16'hFFA2
    `define ESC_WDATA		16'hFFA3 
      
     
    spiDebug.doPush(16'hAB00);    //адрес mil-spi конвертера  + 2 старших байта размера пакета
    spiDebug.doPush(16'h06A2);    //размер пакета 0006, команда A2 - отправить в Mil данные
    spiDebug.doPush(16'hFFA1);    //экранирующий символ, следующие 16 бит  д.б. отправлены как командное слово
    spiDebug.doPush(16'h0001);    // командное слово (1 слово, которое уходит в mil)
                
    spiDebug.doPush(16'h0002);    //слово данных (2 слово, которое уходит в mil)
    spiDebug.doPush(16'hAB45);   //слово данных (3 слово, которое уходит в mil)
    spiDebug.doPush(16'hFFA3);   //экранирующий символ, следующие 16 бит д.б. отправлены как слово данных
    spiDebug.doPush(16'hFFA1);    //слово данных (4 слово, которое уходит в mil)
                
    spiDebug.doPush(16'h5BCF); //контрольная сумма
    spiDebug.doPush(16'h0);        //номер слова 
    */
}
