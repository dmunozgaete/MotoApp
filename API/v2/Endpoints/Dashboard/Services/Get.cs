using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web;

namespace API.Endpoints.Dashboard.Services
{
    /// <summary>
    /// Retrieve a Target User
    /// </summary>
    public class Get : Gale.REST.Http.HttpReadActionResult<Models.Filter>
    {
        string _user = null;

        /// <summary>
        /// Constructor
        /// </summary>
        /// <param name="token"></param>
        public Get(Models.Filter filter, String user)
            : base(filter)
        {
            this._user = user;
        }

        /// <summary>
        /// Async Process
        /// </summary>
        /// <param name="cancellationToken"></param>
        /// <returns></returns>
        public override System.Threading.Tasks.Task<System.Net.Http.HttpResponseMessage> ExecuteAsync(System.Threading.CancellationToken cancellationToken)
        {
            using (Gale.Db.DataService svc = new Gale.Db.DataService("PA_MOT_OBT_Escritorio"))
            {
                svc.Parameters.Add("USUA_Token", _user);

                svc.Parameters.Add("Rango", this.Model.range);
                svc.Parameters.Add("Fecha_Inicio", this.Model.start);
                svc.Parameters.Add("Fecha_Fin", this.Model.end);

                Gale.Db.EntityRepository rep = this.ExecuteQuery(svc);

                Models.Counters counters = rep.GetModel<Models.Counters>().FirstOrDefault();
                List<Models.GraphItem> items = rep.GetModel<Models.GraphItem>(1);

                //----------------------------------------------------------------------------------------------------
                //Create Response
                var response = new HttpResponseMessage(System.Net.HttpStatusCode.OK)
                {
                    Content = new ObjectContent<Object>(
                        new
                        {
                            timestamp = DateTime.Now.ToString("s"),
                            counters = counters,
                            graph = items
                        },
                        System.Web.Http.GlobalConfiguration.Configuration.Formatters.JsonFormatter
                    )
                };

                //Return Task
                return Task.FromResult(response);
                //----------------------------------------------------------------------------------------------------

            }
        }
    }
}