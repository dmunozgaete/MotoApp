using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web;

namespace API.Endpoints.Notifications.Services
{
    /// <summary>
    /// Mark All Notifications from the user to Readed accord to timestamp
    /// </summary>
    public class MarkAsReaded : Gale.REST.Http.HttpCreateActionResult<String>
    {
        DateTime _timestamp;

        /// <summary>
        /// Constructor
        /// </summary>
        /// <param name="user">User Token</param>
        /// <param name="timestamp">Time Stamp</param>
        public MarkAsReaded(String user, DateTime timestamp)
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
            using (Gale.Db.DataService svc = new Gale.Db.DataService("[PA_MOT_UPD_MarcarNotificacionesComoLeidas]"))
            {
                svc.Parameters.Add("USUA_Token", this.Model);
                svc.Parameters.Add("MarcaTiempo", _timestamp);

                this.ExecuteAction(svc);

                //----------------------------------------------------------------------------------------------------
                //Create Response
                var response = new HttpResponseMessage(System.Net.HttpStatusCode.PartialContent);

                //Return Task
                return Task.FromResult(response);
                //----------------------------------------------------------------------------------------------------

            }
        }
    }
}