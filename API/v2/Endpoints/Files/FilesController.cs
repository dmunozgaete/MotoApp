using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Web.Http;
using System.Net.Http;
using System.Web.Http.Description;
using System.Web;

namespace API.Endpoints.Files
{

    /// <summary>
    /// File API
    /// </summary>
    [Gale.Security.Oauth.Jwt.Authorize]
    public class FilesController : Gale.REST.RestController
    {

        /// <summary>
        /// Retrieves a File Content
        /// </summary>
        /// <returns></returns>
        public IHttpActionResult Get(string id)
        {
            return new Services.View(id);
        }


        /// <summary>
        /// Create a Temporary File  (Must be Change the flag to permanently after)
        /// </summary>
        /// <returns></returns>
        public IHttpActionResult Post()
        {
            return new Services.Upload(this.Request, User.PrimarySid());
        }



    }

}