using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web;

namespace API.Endpoints.Routes.Services
{
    /// <summary>
    /// Delete a Route
    /// </summary>
    public class Delete : Gale.REST.Http.HttpUpdateActionResult<String>
    {
     
        /// <summary>
        /// Constructor
        /// </summary>
        /// <param name="user">Current User</param>
        /// <param name="route">Route to delete</param>
        public Delete(String user, String route) : base(user, route) { }

        /// <summary>
        /// Async Process
        /// </summary>
        /// <param name="token"></param>
        /// <param name="cancellationToken"></param>
        /// <returns></returns>
        public override Task<HttpResponseMessage> ExecuteAsync(string token, System.Threading.CancellationToken cancellationToken)
        {
            using (Gale.Db.DataService svc = new Gale.Db.DataService("[PA_MOT_ELM_Ruta]"))
            {
                svc.Parameters.Add("ENTI_Token", token);
                svc.Parameters.Add("RUTA_Token", this.Model);

                this.ExecuteAction(svc);

                //----------------------------------------------------------------------------------------------------
                //Create Response
                var response = new HttpResponseMessage(System.Net.HttpStatusCode.OK);

                //Return Task
                return Task.FromResult(response);
                //----------------------------------------------------------------------------------------------------

            }
        }
    }
}