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
        /// Retrieve Current Routes
        /// </summary>
        /// <returns></returns>
        [HttpGet]
        [Swashbuckle.Swagger.Annotations.SwaggerResponseRemoveDefaults]
        [Swashbuckle.Swagger.Annotations.SwaggerResponse(HttpStatusCode.OK)]
        public IHttpActionResult Get(string token)
        {
            //Only My Routes
            var config = new Gale.REST.Queryable.OData.Builders.GQLConfiguration();
            config.filters.Add(new Gale.REST.Queryable.OData.Builders.GQLConfiguration.Filter
            {
                field = "user_token",
                operatorAlias = "eq",
                value = token
            });
            return new Gale.REST.Http.HttpQueryableActionResult<Models.Route>(this.Request, config);
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

            return new Services.Get(timestamp, this.User.PrimarySid());
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