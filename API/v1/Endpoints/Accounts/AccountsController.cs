using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Web.Http;
using System.Web.Http.Description;

namespace API.Endpoints.Accounts
{
    /// <summary>
    /// Account API
    /// </summary>
    [Gale.Security.Oauth.Jwt.Authorize]
    public class AccountsController : Gale.REST.RestController
    {

        /// <summary>
        /// Retrieve Account's
        /// </summary>
        /// <returns></returns>
        [Swashbuckle.Swagger.Annotations.SwaggerResponseRemoveDefaults]
        [Swashbuckle.Swagger.Annotations.SwaggerResponse(HttpStatusCode.OK)]
        [Gale.Security.Oauth.Jwt.Authorize(Roles = API.WebApiConfig.RootRoles)]
        public IHttpActionResult Get()
        {
            return new Gale.REST.Http.HttpQueryableActionResult<Models.VT_Users>(this.Request);
        }

        /// <summary>
        /// Retrieve Target Account Information
        /// </summary>
        /// <param name="id">Account Token</param>
        /// <returns></returns>
        [HttpGet]
        [Swashbuckle.Swagger.Annotations.SwaggerResponseRemoveDefaults]
        [Swashbuckle.Swagger.Annotations.SwaggerResponse(HttpStatusCode.OK)]
        public IHttpActionResult Get(String id)
        {
            //------------------------------------------------------------------------------------------------------
            // GUARD EXCEPTIONS
            Gale.Exception.RestException.Guard(() => !id.isGuid(), "ID_INVALID_GUID", API.Errors.ResourceManager);
            //------------------------------------------------------------------------------------------------------
            return new Services.Get(id);
        }

        /// <summary>
        /// Retrieve Current Account Information
        /// </summary>
        /// <returns></returns>
        [HttpGet]
        [HierarchicalRoute("/Me")]
        [Swashbuckle.Swagger.Annotations.SwaggerResponseRemoveDefaults]
        [Swashbuckle.Swagger.Annotations.SwaggerResponse(HttpStatusCode.OK)]
        public IHttpActionResult Current()
        {
            return new Services.Get(this.User.PrimarySid());
        }

        /// <summary>
        /// Save User Personal Data
        /// </summary>
        /// <returns></returns>
        [HttpPut]
        [HierarchicalRoute("/Me")]
        [Swashbuckle.Swagger.Annotations.SwaggerResponseRemoveDefaults]
        [Swashbuckle.Swagger.Annotations.SwaggerResponse(HttpStatusCode.PartialContent)]
        public IHttpActionResult SaveCurrent(Models.UpdatePersonalData data)
        {
            return new Services.Update(this.User.PrimarySid(), data);
        }


    }
}