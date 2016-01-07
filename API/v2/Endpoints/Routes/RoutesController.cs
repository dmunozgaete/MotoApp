using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Web;
using System.Web.Http;

namespace API.Endpoints.Routes
{
    /// <summary>
    /// Route Controller
    /// </summary>
    [Gale.Security.Oauth.Jwt.Authorize]
    public class RoutesController : Gale.REST.RestController
    {

        /// <summary>
        /// Retrieve Popular Shared Routes
        /// </summary>
        /// <returns></returns>
        [HttpGet]
        [HierarchicalRoute("/Popular")]
        [Swashbuckle.Swagger.Annotations.SwaggerResponseRemoveDefaults]
        [Swashbuckle.Swagger.Annotations.SwaggerResponse(HttpStatusCode.OK)]
        public IHttpActionResult Populars()
        {
            return new Gale.REST.Http.HttpQueryableActionResult<Models.PopularRoute>(this.Request);
        }


        /// <summary>
        /// Discover New Route , by Geo 
        /// </summary>
        /// <returns></returns>
        [HttpGet]
        [HierarchicalRoute("/@{latitude:decimal},{longitude:decimal},{distance}km/Discover")]
        [Swashbuckle.Swagger.Annotations.SwaggerResponseRemoveDefaults]
        [Swashbuckle.Swagger.Annotations.SwaggerResponse(HttpStatusCode.OK)]
        public IHttpActionResult Discover(decimal latitude, decimal longitude, int distance, String route = null, int limit = 10, int offset = 0)
        {
            return new Services.Discover(latitude, longitude, distance, route , limit, offset);
        }


        /// <summary>
        /// Retrieve Detailed Route
        /// </summary>
        /// <returns></returns>
        [HttpGet]
        [Swashbuckle.Swagger.Annotations.SwaggerResponseRemoveDefaults]
        [Swashbuckle.Swagger.Annotations.SwaggerResponse(HttpStatusCode.OK)]
        [HierarchicalRoute("/{route:Guid}")]
        public IHttpActionResult Get(string route)
        {
            return new Services.Get(route);
        }

        /// <summary>
        /// Like Route
        /// </summary>
        /// <returns></returns>
        [HttpPost]
        [Swashbuckle.Swagger.Annotations.SwaggerResponseRemoveDefaults]
        [Swashbuckle.Swagger.Annotations.SwaggerResponse(HttpStatusCode.Created)]
        [HierarchicalRoute("/{route}/Like")]
        public IHttpActionResult Like(String route)
        {
            //------------------------------------------------------------------------------------------------------
            // GUARD EXCEPTIONS
            Gale.Exception.RestException.Guard(() => route == null, "EMPTY_ROUTE", API.Errors.ResourceManager);
            //------------------------------------------------------------------------------------------------------

            return new Services.Like(this.User.PrimarySid(), route);
        }

        /// <summary>
        /// Unlike Route
        /// </summary>
        /// <returns></returns>
        [HttpDelete]
        [Swashbuckle.Swagger.Annotations.SwaggerResponseRemoveDefaults]
        [Swashbuckle.Swagger.Annotations.SwaggerResponse(HttpStatusCode.Created)]
        [HierarchicalRoute("/{route}/Unlike")]
        public IHttpActionResult Unlike(String route)
        {
            //------------------------------------------------------------------------------------------------------
            // GUARD EXCEPTIONS
            Gale.Exception.RestException.Guard(() => route == null, "EMPTY_ROUTE", API.Errors.ResourceManager);
            //------------------------------------------------------------------------------------------------------

            return new Services.Unlike(this.User.PrimarySid(), route);
        }

        /// <summary>
        /// Retrieve Current Routes specified by timestamp (for syncing)
        /// </summary>
        /// <param name="timestamp">Time Stamp</param>
        /// <returns></returns>
        [HttpGet]
        [HierarchicalRoute("/Me")]
        [Swashbuckle.Swagger.Annotations.SwaggerResponseRemoveDefaults]
        [Swashbuckle.Swagger.Annotations.SwaggerResponse(HttpStatusCode.OK)]
        public IHttpActionResult Current(DateTime timestamp)
        {
            //------------------------------------------------------------------------------------------------------
            // GUARD EXCEPTIONS
            Gale.Exception.RestException.Guard(() => timestamp == null, "EMPTY_TIMESTAMP", API.Errors.ResourceManager);
            //------------------------------------------------------------------------------------------------------

            return new Services.MyRoutes(timestamp, this.User.PrimarySid());
        }

        /// <summary>
        /// Create a new Route for the user (without sharing)
        /// </summary>
        /// <param name="route">Newly Route</param>
        /// <returns></returns>
        [Swashbuckle.Swagger.Annotations.SwaggerResponseRemoveDefaults]
        [Swashbuckle.Swagger.Annotations.SwaggerResponse(HttpStatusCode.Created)]
        [Swashbuckle.Swagger.Annotations.SwaggerResponse(HttpStatusCode.BadRequest)]
        public IHttpActionResult Post([FromBody]Models.NewRoute route)
        {
            return new Services.Create(route, this.User.PrimarySid());
        }


        /// <summary>
        /// Share a Route with the users
        /// </summary>
        /// <param name="route">Route Identifier</param>
        /// <param name="information">Shared Information</param>
        /// <returns></returns>
        [Swashbuckle.Swagger.Annotations.SwaggerResponseRemoveDefaults]
        [Swashbuckle.Swagger.Annotations.SwaggerResponse(HttpStatusCode.Created)]
        [Swashbuckle.Swagger.Annotations.SwaggerResponse(HttpStatusCode.BadRequest)]
        [HierarchicalRoute("/Share/{route:Guid}")]
        public IHttpActionResult Post(string route, [FromBody]Models.newSharedRoute information)
        {
            return new Services.Share(route, information);
        }

        /// <summary>
        /// Delete Route
        /// </summary>
        /// <returns></returns>
        [HttpDelete]
        [Swashbuckle.Swagger.Annotations.SwaggerResponseRemoveDefaults]
        [Swashbuckle.Swagger.Annotations.SwaggerResponse(HttpStatusCode.OK)]
        [HierarchicalRoute("/{route}")]
        public IHttpActionResult Delete(String route)
        {
            //------------------------------------------------------------------------------------------------------
            // GUARD EXCEPTIONS
            Gale.Exception.RestException.Guard(() => route == null, "EMPTY_ROUTE", API.Errors.ResourceManager);
            //------------------------------------------------------------------------------------------------------

            return new Services.Delete(this.User.PrimarySid(), route);
        }

        /// <summary>
        /// Save Route Photo
        /// </summary>
        /// <param name="route"></param>
        /// <param name="photo"></param>
        /// <returns></returns>
        [Swashbuckle.Swagger.Annotations.SwaggerResponseRemoveDefaults]
        [Swashbuckle.Swagger.Annotations.SwaggerResponse(HttpStatusCode.Created)]
        [Swashbuckle.Swagger.Annotations.SwaggerResponse(HttpStatusCode.BadRequest)]
        [HierarchicalRoute("/Photo/{route:Guid}")]
        public IHttpActionResult Post(string route, [FromBody]Models.RoutePhoto photo)
        {
            return new Services.SavePhoto(photo, route);
        }
    }
}