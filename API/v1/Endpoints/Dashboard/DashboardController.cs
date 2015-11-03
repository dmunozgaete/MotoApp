using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;

namespace API.Endpoints.Dashboard
{
    /// <summary>
    /// Dashboard & Indicators Controller
    /// </summary>
    public class DashboardController : Gale.REST.RestController
    {


        public object Get()
        {
            return new
            {
                counters = new
                {
                    treated = new
                    {
                        total = 30,
                        inTime = 20,
                        outOfTime = 10
                    },

                    untreated = new
                    {
                        total = 25,
                        annulled = 10,
                        contacted = 15
                    }
                }

            };
        }
    }
}