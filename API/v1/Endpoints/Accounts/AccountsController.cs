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
        /// Pre-Register an account in the system
        /// </summary>
        /// <param name="account">Account information</param>
        /// <param name="host">Application Entry Point</param>
        /// <returns></returns>
        [Swashbuckle.Swagger.Annotations.SwaggerResponseRemoveDefaults]
        [Swashbuckle.Swagger.Annotations.SwaggerResponse(HttpStatusCode.Created)]
        [Swashbuckle.Swagger.Annotations.SwaggerResponse(HttpStatusCode.BadRequest)]
        public IHttpActionResult Post([FromBody]Models.Create account, string host)
        {
            return new Services.Create(account, host);
        }

        /// <summary>
        /// Update the target Account
        /// </summary>
        /// <param name="id">Account Token</param>
        /// <param name="account">Account information</param>
        /// <returns></returns>
        [Swashbuckle.Swagger.Annotations.SwaggerResponseRemoveDefaults]
        [Swashbuckle.Swagger.Annotations.SwaggerResponse(HttpStatusCode.NoContent)]
        [Swashbuckle.Swagger.Annotations.SwaggerResponse(HttpStatusCode.BadRequest)]
        public IHttpActionResult Put([FromUri]String id, [FromBody]Models.Update account)
        {

            return new Services.Update(id, account);
        }

        /// <summary>
        /// Reset the current password
        /// </summary>
        /// <param name="currentPassword">Current Password</param>
        /// <param name="newPassword">New Password</param>
        /// <returns></returns>
        [HttpPut]
        [Swashbuckle.Swagger.Annotations.SwaggerResponseRemoveDefaults]
        [Swashbuckle.Swagger.Annotations.SwaggerResponse(HttpStatusCode.NoContent)]
        [Swashbuckle.Swagger.Annotations.SwaggerResponse(HttpStatusCode.BadRequest)]
        public IHttpActionResult ResetPassword(string currentPassword, string newPassword)
        {
            throw new NotImplementedException();
        }

    }
}