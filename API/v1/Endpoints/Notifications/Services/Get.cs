using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web;

namespace API.Endpoints.Notifications.Services
{
    /// <summary>
    /// Retrieve a Target User
    /// </summary>
    public class Get : Gale.REST.Http.HttpReadActionResult<String>
    {
        DateTime _timestamp;

        /// <summary>
        /// Constructor
        /// </summary>
        /// <param name="token"></param>
        public Get(DateTime timestamp, String user)
            : base(user)
        {
            this._timestamp = timestamp;
        }

        /// <summary>
        /// Async Process
        /// </summary>
        /// <param name="cancellationToken"></param>
        /// <returns></returns>
        public override System.Threading.Tasks.Task<System.Net.Http.HttpResponseMessage> ExecuteAsync(System.Threading.CancellationToken cancellationToken)
        {
            using (Gale.Db.DataService svc = new Gale.Db.DataService("[PA_MOT_OBT_Notificaciones]"))
            {
                svc.Parameters.Add("USUA_Token", this.Model);
                svc.Parameters.Add("MarcaTiempo", _timestamp);

                Gale.Db.EntityRepository rep = this.ExecuteQuery(svc);

                List<Models.Notification> items = rep.GetModel<Models.Notification>();

                DateTime stamp = items.Count>0 ? items.Max((a)=>a.createdAt) : _timestamp;
                //----------------------------------------------------------------------------------------------------
                //Create Response
                var response = new HttpResponseMessage(System.Net.HttpStatusCode.OK)
                {
                    Content = new ObjectContent<Object>(
                        new
                        {
                            timestamp = stamp,
                            total = items.Count,
                            items = items
                        },
                        System.Web.Http.GlobalConfiguration.Configuration.Formatters.KqlFormatter()
                    )
                };

                //Return Task
                return Task.FromResult(response);
                //----------------------------------------------------------------------------------------------------

            }
        }
    }
}