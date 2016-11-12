using System;
using System.Collections.Generic;
using System.Linq;
using System.Runtime.CompilerServices;
using System.Text;
using System.Threading.Tasks;

namespace MilLight
{
    public abstract class ExpirableObject
    {
        private bool isActual = false;
        public virtual bool IsActual
        {
            get { return isActual; }
        }

        protected void Expire()
        {
            isActual = false;
        }

        private bool inProgress = false;

        [MethodImpl(MethodImplOptions.Synchronized)]
        protected void Actualize()
        {
            if(inProgress)
                return;

            try
            {
                inProgress = true;

                if (IsActual)
                    return;

                Actualization();
                isActual = true;
            }
            finally
            {
                inProgress = false;
            }
        }

        protected virtual void Actualization() { }
    }
}
