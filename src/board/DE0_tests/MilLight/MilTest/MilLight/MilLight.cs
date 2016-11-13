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



    




    /*
    public interface IBridgeStatus
    {
        UInt16 TransmitQueueSize { get; }
        UInt16 ReceivedQueueSize { get; }
    }

    public interface IMilServiceProtocol
    {
        List<IMilPacket> Receive(byte addr, int size);
        void Transmit(byte addr, List<IMilPacket> data);
        void DeviceReset(byte addr);
        IBridgeStatus getDeviceStatus(byte addr);
    }

    public class MilSpiBridge : IMilServiceProtocol
    {
        private string mpsseSerialNumber;

        public MilSpiBridge(String mpsseSerialNumber)
        {
            this.mpsseSerialNumber = mpsseSerialNumber;
        }

        protected byte[] encodePacket(SPPacket packet)
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

        protected void bridgeWrite(SPPacket packet)
        {
            byte[] data = encodePacket(packet);
            spiWrite(data);
        }

        protected void bridgeReadWrite(SPPacket packet)
        {

        }

        public void DeviceReset(byte addr)
        {
            SPPacket resetPacket = new SPPacket() { Addr = addr, Command = SPCommand.Reset };
            byte[] data = encodePacket(resetPacket);

            using (MpsseDevice mpsse = new FT2232D("A"))
            {
                SpiDevice spi = new SpiDevice(mpsse);
                spi.write(data);
            }
        }

        public IBridgeStatus getDeviceStatus(byte addr)
        {
            throw new NotImplementedException();
        }

        public List<IMilPacket> Receive(byte addr, int size)
        {
            throw new NotImplementedException();
        }

        public void Transmit(byte addr, List<IMilPacket> data)
        {
            throw new NotImplementedException();
        }
    }
    */

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
