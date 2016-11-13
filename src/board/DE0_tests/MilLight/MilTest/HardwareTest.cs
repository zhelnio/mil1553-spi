using System;
using System.Text;
using System.Collections.Generic;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using MilLight;
using System.Threading;
using System.Linq;

namespace MilTest
{
    class MainC
    {
        public static void Main()
        {
            //var t = new HardwareTest();
            //t.HardwareTransmissionTest();
        }
    }

    //[TestClass]
    //public class HardwareTest
    //{
    //    [TestMethod]
    //    public void HardwareTransmissionTest()
    //    {
    //        IMilSpiBridge bridge = new MilSpiBridge("A");

    //        List<IMilFrame> tdata = new List<IMilFrame>()
    //        {
    //            new MilFrame() { Data = 0x0001, Header = MilType.WSERV },
    //            new MilFrame() { Data = 0x0002 },
    //            new MilFrame() { Data = 0xAB45 },
    //            new MilFrame() { Data = 0xFFA1 }
    //        };

    //        bridge.Transmit(0xAB, tdata);

    //        Thread.Sleep(100);



    //        List<IMilFrame> rdata = bridge.Receive(0xAC, 4);

    //        Assert.IsTrue(Enumerable.SequenceEqual(rdata, tdata));
    //    }

    //    [TestMethod]
    //    public void EmptyReceiveTest()
    //    {
    //        IMilSpiBridge bridge = new MilSpiBridge("A");


    //        List<IMilFrame> rdata = bridge.Receive(0xAC, 4);

    //       // Assert.IsTrue(Enumerable.SequenceEqual(rdata, tdata));
    //    }

    //}
        //public HardwareTest()
        //{
        //    //
        //    // TODO: Add constructor logic here
        //    //
        //}

        //private TestContext testContextInstance;

        ///// <summary>
        /////Gets or sets the test context which provides
        /////information about and functionality for the current test run.
        /////</summary>
        //public TestContext TestContext
        //{
        //    get
        //    {
        //        return testContextInstance;
        //    }
        //    set
        //    {
        //        testContextInstance = value;
        //    }
        //}

        //#region Additional test attributes
        ////
        //// You can use the following additional attributes as you write your tests:
        ////
        //// Use ClassInitialize to run code before running the first test in the class
        //// [ClassInitialize()]
        //// public static void MyClassInitialize(TestContext testContext) { }
        ////
        //// Use ClassCleanup to run code after all tests in a class have run
        //// [ClassCleanup()]
        //// public static void MyClassCleanup() { }
        ////
        //// Use TestInitialize to run code before running each test 
        //// [TestInitialize()]
        //// public void MyTestInitialize() { }
        ////
        //// Use TestCleanup to run code after each test has run
        //// [TestCleanup()]
        //// public void MyTestCleanup() { }
        ////
        //#endregion

        //[TestMethod]
        //public void TestMethod1()
        //{
        //    //
        //    // TODO: Add test logic here
        //    //
        //}
   
}
