using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Web.Http;

namespace API.Endpoints.Security
{
    /// <summary>
    /// Security Controller to grant JWT to Valid User's
    /// </summary>
    public class SecurityController : Gale.REST.RestController
    {

        /// <summary>
        /// Authorize user by credentials
        /// </summary>
        /// <param name="credentials">Credentials</param>
        /// <returns></returns>
        /// <response code="200">Authorized</response>
        /// <response code="500">Incorrect Username or Password</response>
        [HttpPost]
        [HierarchicalRoute("/Authorize")]
        public IHttpActionResult Authorize([FromBody]Models.Credentials credentials)
        {

            //------------------------------------------------------------------------------------------------------------------------
            //GUARD EXCEPTION
            Gale.Exception.RestException.Guard(() => credentials == null, "EMPTY_BODY", API.Errors.ResourceManager);
            Gale.Exception.RestException.Guard(() => credentials.username == null, "EMPTY_USERNAME", API.Errors.ResourceManager);
            Gale.Exception.RestException.Guard(() => credentials.password == null, "EMPTY_PASSWORD", API.Errors.ResourceManager);
            //------------------------------------------------------------------------------------------------------------------------

            return new Services.Authorize(this.Request, credentials);

        }

        /// <summary>
        /// BPM - Request Access for a Identity (enrollment)
        /// </summary>
        /// <param name="model">Model</param>
        /// <returns></returns>
        /// <response code="201">Request created</response>
        /// <response code="500">Internal Server Error</response>
        [HttpPost]
        [HierarchicalRoute("/Request/Access")]
        public IHttpActionResult RequestAccess([FromBody]Models.RequestAccess model)
        {

            //------------------------------------------------------------------------------------------------------------------------
            //GUARD EXCEPTION
            Gale.Exception.RestException.Guard(() => model.email == null, "EMPTY_EMAIL", API.Errors.ResourceManager);
            //------------------------------------------------------------------------------------------------------------------------

            return new Services.RequestAccess(model);

        }

    }
}