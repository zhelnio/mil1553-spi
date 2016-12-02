using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace MilTest.MilLight.ServiceProtocol
{
    public class SPResetRequest : SPRequest
    {
        public override SPCommand Command
        {
            get { return SPCommand.Reset; }
        }
    }
}
