using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MilTest
{
    class ServiceProtocol
    {
        public class SPCommand
        {
            public const byte Unknown = 0xFF;    // no reaction command
            public const byte Reset = 0xA0;      // device reset
            public const byte Send = 0xA2;       // send data to mil
            public const byte Status = 0xB0;     // get status info
            public const byte Receive = 0xB2;    // get all the data received from mil

            public byte Value { get; set; }

            public SPCommand(byte command)
            {
                Value = getCommand(command);
            }

            public SPCommand()
            {
                Value = Unknown;
            }

            protected virtual byte getCommand(byte command)
            {
                switch (command)
                {
                    default: return Unknown;
                    case Reset: return Reset;
                    case Send: return Send;
                    case Status: return Status;
                    case Receive: return Receive;
                }
            }

            public static implicit operator byte(SPCommand obj)
            {
                return obj.Value;
            }

            public static implicit operator SPCommand(byte obj)
            {
                return new SPCommand(obj);
            }
        }

        public class MilType
        {
            public const ushort WSERVERR = 0xFFA0;
            public const ushort WSERV = 0xFFA1;
            public const ushort WDATAERR = 0xFFA2;
            public const ushort WDATA = 0xFFA3;

            private ushort val;
            public ushort Value
            {
                get { return val; }
                set
                {
                    checkNewValue(value);
                    val = value;
                }
            }

            protected virtual void checkNewValue(ushort val)
            {
                if (val < 0xFFA0 || val > 0xFFA3)
                    throw new ArgumentOutOfRangeException();
            }

            public MilType()
            {
                Value = WDATA;
            }

            public static implicit operator ushort(MilType d)
            {
                return d.Value;
            }

            public static implicit operator MilType(ushort d)
            {
                return new MilType() { Value = d };
            }
        }

        public class MilPacket
        {        
            public MilType PType { get; set; }
            public UInt16 PData { get; set; }

            public MilPacket()
            {
                PType = MilType.WDATA;
            }
        }

        public class SPPacket
        {
            public byte Addr { get; set; }
            public SPCommand Command { get; set; }
            public ushort WordNum { get; set; }
            public MilPacket[] Data { get; set; }
            
            public SPPacket()
            {
                Addr = 0;
                Command = new SPCommand();
                WordNum = 0;
            }

            public byte[] RawData { get; set; }
            public byte[] RawPacket { get; }
            public UInt16 Size { get; }
            public UInt16 CheckSum { get; }

            protected virtual byte[] encodeData()
            {

            }

            protected virtual byte[] encodeMilPacket(MilPacket p)
            {
                if (p.PType != MilType.WDATA ||
                    p.PData == MilType.WDATAERR ||
                    p.PData == MilType.WSERV ||
                    p.PData == MilType.WSERVERR)
                    return new byte[] { (byte)(p.PType >> 8),
                                        (byte)(p.PType & 0xFF),
                                        (byte)(p.PData >> 8),
                                        (byte)(p.PData & 0xFF) };

                return new byte[] { (byte)(p.PData >> 8),
                                    (byte)(p.PData & 0xFF) };
            }
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
                
    spiDebug.doPush(16'h57CF); //контрольная сумма
    spiDebug.doPush(16'h0);        //номер слова 
    */

    class MilLight
    {

    }
}
