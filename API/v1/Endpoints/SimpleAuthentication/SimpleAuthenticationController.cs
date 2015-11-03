using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Http;

namespace API.Endpoints.SimpleAuthentication
{
    /// <summary>
    /// SImple Authentication Example
    /// </summary>
    public class SimpleAuthenticationController : Gale.REST.RestController
    {
        /// <summary>
        /// Restricted Operation (Authentication Required)
        /// </summary>
        /// <returns></returns>
        [HttpGet]
        [Gale.Security.Oauth.Jwt.Authorize]
        [Swashbuckle.Swagger.Annotations.SwaggerResponseRemoveDefaults]
        [Swashbuckle.Swagger.Annotations.SwaggerResponse(System.Net.HttpStatusCode.OK)]
        [Swashbuckle.Swagger.Annotations.SwaggerResponse(System.Net.HttpStatusCode.Unauthorized)]
        [Swashbuckle.Swagger.Annotations.SwaggerResponse(System.Net.HttpStatusCode.BadRequest)]
        [HierarchicalRoute("MySuperSecretOperation")]
        public String SecretOperation()
        {
            return "Top Secret Operation: You must keep it secret :)";
        }


        /// <summary>
        /// Get an Access Token for retrieve the "SuperSecretOperation"
        /// </summary>
        /// <param name="credentials">Any credentials</param>
        /// <returns></returns>
        [HttpPost]
        [Swashbuckle.Swagger.Annotations.SwaggerResponseRemoveDefaults]
        [Swashbuckle.Swagger.Annotations.SwaggerResponse(System.Net.HttpStatusCode.OK)]
        public IHttpActionResult Post(Models.Authenitcation credentials)
        {
            //--------------------------------------------------
            //Some Check's
            Gale.Exception.RestException.Guard(() => credentials == null, "EMPTY_BODY", API.Errors.ResourceManager);
            Gale.Exception.RestException.Guard(() => credentials.email == null, "EMAIL_REQUIRED", API.Errors.ResourceManager);
            Gale.Exception.RestException.Guard(() => credentials.password == null, "PASSWORD_REQUIRED", API.Errors.ResourceManager);
            //--------------------------------------------------

            return new Services.Authenticate(credentials);
        }
    }
}