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
using MPSSELight;

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
        SPCommand Command { get; set; }
        UInt16 CheckSum { get; }
        UInt16 PackNum { get; set; }
    }

    public interface ISPData : ISPFrame
    {
        List<IMilFrame> Data { get; set; }
    }

    public interface ISPStatus : ISPFrame
    {
        UInt16 TransmitQueueSize { get; }
        UInt16 ReceivedQueueSize { get; }
    }

    public interface IBinaryFrame
    {
        UInt16 Serialize(Stream stream);
        UInt16 Deserialize(Stream stream);
    }





    public interface IMilSpiBridge
    {
        List<IMilFrame> Receive(byte addr, int size);
        void Transmit(byte addr, List<IMilFrame> data);
        void DeviceReset(byte addr);
        ISPStatus getDeviceStatus(byte addr);
    }

    public class MilSpiBridge : IMilSpiBridge
    {
        private string mpsseSerialNumber;

        public MilSpiBridge(String mpsseSerialNumber)
        {
            this.mpsseSerialNumber = mpsseSerialNumber;
        }

        protected byte[] encodePacket(IBinaryFrame packet)
        {
            MemoryStream stream = new MemoryStream();
            packet.Serialize(stream);
            return stream.ToArray();
        }

        protected void spiWrite(byte[] data)
        {
            using (MpsseDevice mpsse = new FT2232D(mpsseSerialNumber))
            {
                SpiDevice spi = new SpiDevice(mpsse);
                spi.write(data);
            }
        }

        protected byte[] spiReadWrite(byte[] data)
        {
            using (MpsseDevice mpsse = new FT2232D(mpsseSerialNumber))
            {
                SpiDevice spi = new SpiDevice(mpsse);
                return spi.readWrite(data);
            }
        }

        public void DeviceReset(byte addr)
        {
            SPFrame resetPacket = new SPFrame() { Addr = addr, Command = SPCommand.Reset };
            byte[] raw = encodePacket(resetPacket);
            spiWrite(raw);
        }

        public void Transmit(byte addr, List<IMilFrame> data)
        {
            SPFrame transmitPacket = new SPData() { Addr = addr, Command = SPCommand.Send, Data = data };
            byte[] raw = encodePacket(transmitPacket);
            spiWrite(raw);
        }

        protected const int packetReceiveDelay = 5;

        public ISPStatus getDeviceStatus(byte addr)
        {
            SPData requestPacket = new SPData() { Addr = addr, Command = SPCommand.Status };
            for (int i = 0; i < packetReceiveDelay; i++)
                requestPacket.Data.Add(new MilFrame());
            byte[] oraw = encodePacket(requestPacket);

            byte[] iraw = spiReadWrite(oraw);

            MemoryStream stream = new MemoryStream(iraw);
            SPStatus responcePacket = new SPStatus();
            responcePacket.Deserialize(stream);
            return responcePacket;
        }

        public List<IMilFrame> Receive(byte addr, int size)
        {
            SPData requestPacket = new SPData() { Addr = addr, Command = SPCommand.Receive };
            for (int i = 0; i < packetReceiveDelay + size; i++)
                requestPacket.Data.Add(new MilFrame());
            byte[] oraw = encodePacket(requestPacket);

            byte[] iraw = spiReadWrite(oraw);

            MemoryStream stream = new MemoryStream(iraw);
            SPData responcePacket = new SPData();
            responcePacket.Deserialize(stream);
            return responcePacket.Data;
        }
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
