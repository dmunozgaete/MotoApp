using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Web;
using System.Web.Http;

namespace API.Endpoints.Medals
{
    /// <summary>
    /// Medals Rewards Controller
    /// </summary>
    [Gale.Security.Oauth.Jwt.Authorize]
    public class MedalsController: Gale.REST.RestController
    {

        /// <summary>
        /// Retrieve Medal's
        /// </summary>
        /// <returns></returns>
        [Swashbuckle.Swagger.Annotations.SwaggerResponseRemoveDefaults]
        [Swashbuckle.Swagger.Annotations.SwaggerResponse(HttpStatusCode.OK)]
        public IHttpActionResult Get()
        {
            return new Gale.REST.Http.HttpQueryableActionResult<Models.VT_Medal>(this.Request);
        }

    }
}