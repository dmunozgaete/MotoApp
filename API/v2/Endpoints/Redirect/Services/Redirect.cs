using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web;

namespace API.Endpoints.Redirect.Services
{
    /// <summary>
    /// Retrieve a Target User
    /// </summary>
    public class Redirect : Gale.REST.Http.HttpBaseActionResult
    {
        /// <summary>
        /// Async Process
        /// </summary>
        /// <param name="cancellationToken"></param>
        /// <returns></returns>
        public override System.Threading.Tasks.Task<System.Net.Http.HttpResponseMessage> ExecuteAsync(System.Threading.CancellationToken cancellationToken)
        {
            string url = System.Configuration.ConfigurationManager.AppSettings["GetTheApp:Url"];

            //----------------------------------------------------------------------------------------------------
            //Create Response
            var response = new HttpResponseMessage(System.Net.HttpStatusCode.Redirect);

            //Comming Soon Image
            response.Headers.Add("Location", url);
            //Return Task
            return Task.FromResult(response);
            //----------------------------------------------------------------------------------------------------

        }
    }
}