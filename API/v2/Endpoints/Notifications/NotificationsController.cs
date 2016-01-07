using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Web;
using System.Web.Http;
using System.Web.Http.Description;

namespace API.Endpoints.Notifications
{
    /// <summary>
    /// Notification Controller
    /// </summary>
    [Gale.Security.Oauth.Jwt.Authorize]
    public class NotificationsController : Gale.REST.RestController
    {

        /// <summary>
        /// Retrieves all pendings notifications for the user
        /// </summary>
        /// <param name="timestamp">fecha de ultima actualización</param>
        /// <returns></returns>
        [Swashbuckle.Swagger.Annotations.SwaggerResponseRemoveDefaults]
        [Swashbuckle.Swagger.Annotations.SwaggerResponse(HttpStatusCode.OK, "", typeof(List<Models.Notification>))]
        public IHttpActionResult Get(DateTime timestamp)
        {
            //------------------------------------------------------------------------------------------------------
            // GUARD EXCEPTIONS
            Gale.Exception.RestException.Guard(() => timestamp == null, "EMPTY_TIMESTAMP", API.Errors.ResourceManager);
            //------------------------------------------------------------------------------------------------------

            return new Services.Get(timestamp, this.User.PrimarySid());
        }

        /// <summary>
        /// Mark's all notifications to readed according to the TimeStamp
        /// </summary>
        /// <param name="model"></param>
        /// <returns></returns>
        [Swashbuckle.Swagger.Annotations.SwaggerResponseRemoveDefaults]
        [Swashbuckle.Swagger.Annotations.SwaggerResponse(HttpStatusCode.PartialContent)]
        [HierarchicalRoute("/MarkAsReaded")]
        [HttpPut]
        public IHttpActionResult MarkAsReaded([FromBody]Models.MarkAsReaded model)
        {
            //------------------------------------------------------------------------------------------------------
            // GUARD EXCEPTIONS
            Gale.Exception.RestException.Guard(() => model == null, "EMPTY_BODY", API.Errors.ResourceManager);
            Gale.Exception.RestException.Guard(() => model.timestamp == null, "EMPTY_TIMESTAMP", API.Errors.ResourceManager);
            //------------------------------------------------------------------------------------------------------

            if (model.timestamp == DateTime.MinValue)
            {
                model.timestamp = DateTime.Now.AddYears(-1); //Default
            }
            return new Services.MarkAsReaded(this.User.PrimarySid(), model.timestamp);
        }
    }
}