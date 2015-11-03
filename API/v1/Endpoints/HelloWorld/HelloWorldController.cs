using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.Http;

namespace API.Endpoints.HelloWorld
{
    /// <summary>
    /// Hello World Example Controller
    /// </summary>
    public class HelloWorldController : Gale.REST.RestController
    {
        /// <summary>
        /// Return a String like "Hello World {YourName}"
        /// </summary>
        /// <param name="name">Your Name</param>
        /// <returns></returns>
        [HttpGet]
        [Swashbuckle.Swagger.Annotations.SwaggerResponse(System.Net.HttpStatusCode.OK)]
        public IHttpActionResult Get(string name)
        {
            return new Services.Get(name);
        }

        /// <summary>
        /// Create a newly Resource
        /// </summary>
        /// <returns>newly created resource</returns>
        [HttpPost]
        [Swashbuckle.Swagger.Annotations.SwaggerResponseRemoveDefaults]
        [Swashbuckle.Swagger.Annotations.SwaggerResponse(System.Net.HttpStatusCode.Created)]
        [Swashbuckle.Swagger.Annotations.SwaggerResponse(System.Net.HttpStatusCode.BadRequest)]
        public IHttpActionResult Post(Models.HelloWorld model)
        {
            //--------------------------------------------------
            //Some Check's
            Gale.Exception.RestException.Guard(() => model == null, "EMPTY_BODY", API.Errors.ResourceManager);
            Gale.Exception.RestException.Guard(() => model.country == null, "COUNTRY_REQUIRED", API.Errors.ResourceManager);
            Gale.Exception.RestException.Guard(() => model.name == null, "NAME_REQUIRED", API.Errors.ResourceManager);
            //--------------------------------------------------

            return new Services.Post(model);
        }


        /// <summary>
        /// Update a resource by his identifier
        /// </summary>
        /// <param name="token">Token identifier</param>
        /// <param name="model">HelloWorld Account</param>
        /// <returns></returns>
        [HttpPut]
        [Swashbuckle.Swagger.Annotations.SwaggerResponseRemoveDefaults]
        [Swashbuckle.Swagger.Annotations.SwaggerResponse(System.Net.HttpStatusCode.NoContent)]
        [Swashbuckle.Swagger.Annotations.SwaggerResponse(System.Net.HttpStatusCode.BadRequest)]
        public IHttpActionResult Put(string token, Models.HelloWorld model)
        {
            //--------------------------------------------------
            //Some Check's
            Gale.Exception.RestException.Guard(() => model == null, "EMPTY_BODY", API.Errors.ResourceManager);
            Gale.Exception.RestException.Guard(() => model.country == null, "COUNTRY_REQUIRED", API.Errors.ResourceManager);
            Gale.Exception.RestException.Guard(() => model.name == null, "NAME_REQUIRED", API.Errors.ResourceManager);
            //--------------------------------------------------

            return new Services.Put(token, model);
        }

        /// <summary>
        /// Delete a resource (Throw Not Implemented)
        /// </summary>
        /// <param name="token">Resource Identifier</param>
        /// <returns></returns>
        [HttpDelete]
        [Swashbuckle.Swagger.Annotations.SwaggerResponseRemoveDefaults]
        [Swashbuckle.Swagger.Annotations.SwaggerResponse(System.Net.HttpStatusCode.NoContent)]
        [Swashbuckle.Swagger.Annotations.SwaggerResponse(System.Net.HttpStatusCode.InternalServerError)]
        public IHttpActionResult Delete(string token)
        {
            throw new NotImplementedException();
        }

    }
}