using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Web;
using System.Web.Http;

namespace API.Endpoints.Dashboard
{
    /// <summary>
    /// Dashboard & Indicators Controller
    /// </summary>
    [Gale.Security.Oauth.Jwt.Authorize]
    public class DashboardController : Gale.REST.RestController
    {

        /// <summary>
        /// Retrieve Dashboard Data
        /// </summary>
        /// <param name="range">Range Mode</param>
        /// <param name="start">Start Range Date</param>
        /// <param name="end">End Range Date</param>
        /// <returns></returns>
        [Swashbuckle.Swagger.Annotations.SwaggerResponseRemoveDefaults]
        [Swashbuckle.Swagger.Annotations.SwaggerResponse(HttpStatusCode.OK)]
        [HierarchicalRoute("/{range}/")]
        public IHttpActionResult Get(string range, DateTime start, DateTime end)
        {
            //PD: Not send Models because the weird problem with GET date in Web API's

            //------------------------------------------------------------------------------------------------------
            // GUARD EXCEPTIONS
            Gale.Exception.RestException.Guard(() => start == null, "EMPTY_START_RANGE", API.Errors.ResourceManager);
            Gale.Exception.RestException.Guard(() => end == null, "EMPTY_END_RANGE", API.Errors.ResourceManager);
            Gale.Exception.RestException.Guard(() => String.IsNullOrEmpty(range), "EMPTY_RANGE_MODE", API.Errors.ResourceManager);
            //------------------------------------------------------------------------------------------------------

            var filter = new Models.Filter()
            {
                end = end.AddDays(1).Date,
                start = start.Date,
                range = range
            };
            return new Services.Get(filter, this.User.PrimarySid());
        }
    }
}