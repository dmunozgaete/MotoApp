using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Web;
using System.Web.Http;

namespace API.Endpoints.Ambassadors
{
    /// <summary>
    /// Ambassador Controller
    /// </summary>
    [Gale.Security.Oauth.Jwt.Authorize]
    public class AmbassadorsController : Gale.REST.RestController
    {
        /// <summary>
        /// Retrieve Ambassador's
        /// </summary>
        /// <returns></returns>
        [HttpGet]
        [Swashbuckle.Swagger.Annotations.SwaggerResponseRemoveDefaults]
        [Swashbuckle.Swagger.Annotations.SwaggerResponse(HttpStatusCode.OK)]
        public IHttpActionResult Get()
        {
            return new Services.Get(this.User.PrimarySid());
        }


        /// <summary>
        /// Follow Ambassador
        /// </summary>
        /// <returns></returns>
        [HttpPost]
        [Swashbuckle.Swagger.Annotations.SwaggerResponseRemoveDefaults]
        [Swashbuckle.Swagger.Annotations.SwaggerResponse(HttpStatusCode.Created)]
        [HierarchicalRoute("/{ambassador}/Follow")]
        public IHttpActionResult Follow(String ambassador)
        {
            //------------------------------------------------------------------------------------------------------
            // GUARD EXCEPTIONS
            Gale.Exception.RestException.Guard(() => ambassador == null, "EMPTY_AMBASSADOR", API.Errors.ResourceManager);
            //------------------------------------------------------------------------------------------------------

            return new Services.Follow(this.User.PrimarySid(), ambassador);
        }

        /// <summary>
        /// UnFollow Ambassador
        /// </summary>
        /// <returns></returns>
        [HttpDelete]
        [Swashbuckle.Swagger.Annotations.SwaggerResponseRemoveDefaults]
        [Swashbuckle.Swagger.Annotations.SwaggerResponse(HttpStatusCode.OK)]
        [HierarchicalRoute("/{ambassador}/Follow")]
        public IHttpActionResult Unfollow(String ambassador)
        {
            //------------------------------------------------------------------------------------------------------
            // GUARD EXCEPTIONS
            Gale.Exception.RestException.Guard(() => ambassador == null, "EMPTY_AMBASSADOR", API.Errors.ResourceManager);
            //------------------------------------------------------------------------------------------------------

            return new Services.Unfollow(this.User.PrimarySid(), ambassador);
        }
    }
}