using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO;
using System.Runtime.InteropServices;

namespace MilTest
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



    public interface IBinaryTransferable
    {
        UInt16 CheckSum { get; }
        UInt16 Size { get; }
    }

    public interface IBinarySerializable
    {
        UInt16 Serialize(Stream stream);
        UInt16 Deserialize(Stream stream);
    }

    public class MilPacket : IBinarySerializable, IBinaryTransferable
    {
        private MilType header = MilType.WDATA;
        public MilType Header
        {
            get
            {
                Actualize();
                return header;
            }
            set
            {
                isActual = false;
                header = value;
            }
        }

        private UInt16 data;
        public UInt16 Data
        {
            get
            {
                Actualize();
                return data;
            }
            set
            {
                data = value;
                isActual = false;
            }
        }

        private UInt16 size;
        public UInt16 Size
        {
            get
            {
                Actualize();
                return size;
            }
        }

        private UInt16 checkSum;
        public UInt16 CheckSum
        {
            get
            {
                Actualize();
                return checkSum;
            }
        }

        private bool isActual = false;
        public bool IsActual
        {
            get { return isActual; }
        }

        private void Actualize()
        {
            if (isActual)
                return;

            if(needToTransferHeader())
            {
                size = 2;
                checkSum = (UInt16)((UInt16)header + data);
            }
            else
            {
                size = 1;
                checkSum = data;
            }

            isActual = true;
        }

        private bool needToTransferHeader()
        {
            return header != MilType.WDATA ||
                    data == (UInt16)MilType.WSERVERR || data == (UInt16)MilType.WSERV ||
                    data == (UInt16)MilType.WDATAERR || data == (UInt16)MilType.WDATA;
        }


        public UInt16 Serialize(Stream stream)
        {
            if (needToTransferHeader())
            {
                stream.WriteUInt16((UInt16)Header);
                stream.WriteUInt16(Data);
                return 2;
            }

            stream.WriteUInt16(Data);
            return 1;
        }

        public UInt16 Deserialize(Stream stream)
        {
            UInt16 value = stream.ReadUInt16();
            if(value == (UInt16)MilType.WSERVERR || value == (UInt16)MilType.WSERV ||
               value == (UInt16)MilType.WDATAERR || value == (UInt16)MilType.WDATA)
            {
                Header = (MilType)value;
                Data = stream.ReadUInt16();
                return 2;
            }
            Header = MilType.WDATA;
            Data = value;
            return 1;
        }
    }

    public static class StreamExtensions
    {
        public static void WriteUInt16(this Stream stream, UInt16 value)
        {
            stream.WriteByte((byte)(value >> 8));
            stream.WriteByte((byte)(value & 0xFF));
        }

        public static UInt16 ReadUInt16(this Stream stream)
        {
            UInt16 result;
            byte[] buffer = new byte[2];

            stream.Read(buffer, 0, 2);

            result = (UInt16)(buffer[0] << 8);
            result += buffer[1];

            return result;
        }
    }

    public class SPPacket : IBinarySerializable
    {
        private bool isActual = false;
        public bool IsActual
        {
            get { return isActual && !Data.Exists(a => !a.IsActual); }
        }

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
                isActual = false;
            }
        }

        private byte command;
        public SPCommand Command
        {
            get
            {
                Actualize();
                return (SPCommand)command;
            }
            set
            {
                command = (byte)value;
                isActual = false;
            }
        }

        private List<MilPacket> data = new List<MilPacket>();
        public List<MilPacket> Data
        {
            get
            {
                Actualize();
                return data;
            }
            set
            {
                data = value;
                isActual = false;
            }
        }

        public UInt16 PackNum { get; set; }

        private UInt16 dataSize;
        public UInt16 DataSize
        {
            get
            {
                Actualize();
                return dataSize;
            }
        }

        private UInt16 checkSum;
        public UInt16 CheckSum {
            get
            {
                Actualize();
                return checkSum;
            }
        }

        private void Actualize()
        {
            if (isActual)
                return;

            dataSize = (UInt16)(data.Sum(a => a.Size));
            checkSum  = (UInt16)((addr << 8) + (dataSize >> 8));
            checkSum += (UInt16)((dataSize << 8) + ((byte)command));
            checkSum += (UInt16)(data.Sum(a => a.CheckSum));

            isActual = true;
        }

        public UInt16 Serialize(Stream stream)
        {
            UInt16 osize = 4;
            stream.WriteByte(Addr);
            stream.WriteUInt16(DataSize);
            stream.WriteByte((byte)Command);
            Data.ForEach(a => osize += a.Serialize(stream));
            stream.WriteUInt16(CheckSum);
            stream.WriteUInt16(PackNum);
            return osize;
        }

        public UInt16 Deserialize(Stream stream)
        {
            do
            {
                int data = stream.ReadByte();
                addr = (byte)data;
            }
            while (addr == 0);
            int rCataSize = stream.ReadUInt16();
            command = (byte)stream.ReadByte();

            UInt16 osize = 4;
            for (int i = 0; i < rCataSize;)
            {
                MilPacket mp = new MilPacket();
                UInt16 s = mp.Deserialize(stream);
                osize += s;
                i += s;
                data.Add(mp);
            }
            UInt16 rCheckSum = stream.ReadUInt16();
            UInt16 rPackNum = stream.ReadUInt16();

            return osize;
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
