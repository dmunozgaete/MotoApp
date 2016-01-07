using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Web;
using System.Web.Http;

namespace API.Endpoints.Redirect
{
    /// <summary>
    /// Redirects to dynamic URLS
    /// </summary>
    public class RedirectController : Gale.REST.RestController
    {
        /// <summary>
        /// Redirect to the landing page (when is ready :P), and track ^^
        /// </summary>
        /// <param name="device"></param>
        /// <returns></returns>
        [HttpGet]
        [HierarchicalRoute("/GetTheApp")]
        public IHttpActionResult GetTheApp()
        {
            return new Services.Redirect();

        }
    }
}