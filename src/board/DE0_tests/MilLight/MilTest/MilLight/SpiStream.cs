using MPSSELight;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using static MPSSELight.MpsseDevice;
using static MPSSELight.SpiDevice;

namespace MilTest.MilLight
{
    class SpiStream : Stream
    {
        private bool _writeOnly;
        private static object _lockObject = new object();

        protected MemoryStream inputData = new MemoryStream();
        protected SpiParams spiParams;
        protected MpsseParams mpsseParams;
        protected string serialNumber;

        public Action<SpiDevice> afterSpiInit;

        public SpiStream(string serialNumber, bool writeOnly = false, 
                         SpiParams sparam = null, MpsseParams mparam = null)
        {
            _writeOnly = writeOnly;

            spiParams = sparam ?? new SpiParams();
            mpsseParams = mparam ?? new MpsseParams();
            this.serialNumber = serialNumber;
        }

        public override bool CanRead
        {
            get { return !_writeOnly; }
        }

        public override bool CanWrite
        {
            get { return true; }
        }

        public override int Read(byte[] buffer, int offset, int count)
        {
            lock(_lockObject)
            {
                return inputData.Read(buffer, offset, count);
            }
        }

        public override void Write(byte[] buffer, int offset, int count)
        {
            lock (_lockObject)
            {
                byte[] data = new byte[count];
                Array.Copy(buffer, offset, data, 0, count);
                using (var mpsse = new FT2232D(serialNumber, mpsseParams))
                {
                    var spi = new SpiDevice(mpsse, spiParams);

                    afterSpiInit(spi);

                    if (_writeOnly)
                        spi.write(data);
                    else
                    {
                        byte[] rcvd = spi.readWrite(data);
                        inputData.Write(rcvd, 0, rcvd.Length);
                    }
                }
            }
        }

        protected override void Dispose(bool disposing)
        {
            //false - for only unmanaged resources
            if (!disposing)
                return;

            inputData.Dispose();

            base.Dispose(disposing);
        }

        #region Not supported

        public override void Flush() { }

        public override bool CanSeek
        {
            get { return false; }
        }

        public override long Length
        {
            get { throw new NotSupportedException(); }
        }

        public override long Position
        {
            get { throw new NotSupportedException(); }
            set { throw new NotSupportedException(); }
        }

        public override long Seek(long offset, SeekOrigin origin)
        {
            throw new NotSupportedException();
        }

        public override void SetLength(long value)
        {
            throw new NotSupportedException();
        }

        #endregion
    }
}
