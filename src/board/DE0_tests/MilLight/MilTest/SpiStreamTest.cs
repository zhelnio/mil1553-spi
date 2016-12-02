using System;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using MilTest.MilLight;

namespace MilTest
{
    

    [TestClass]
    public class SpiStreamTest
    {
        

        [TestMethod]
        public void SpiTest()
        {
            using (var spiStream = new SpiStream("A"))
            {
                spiStream.afterSpiInit = (spi) => 
                {
                    spi.LoopbackEnabled = true;

                };

                spiStream.WriteByte(0xFA);
            }
        }
    }
}
