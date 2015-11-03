using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web;

namespace API.Endpoints.HelloWorld.Services
{
    /// <summary>
    /// Create a "Virtual" new Resource
    /// </summary>
    public class Put : Gale.REST.Http.HttpUpdateActionResult<Models.HelloWorld>
    {
        public Put(string token, Models.HelloWorld model) : base(token, model) { }


        public override Task<HttpResponseMessage> ExecuteAsync(string token, System.Threading.CancellationToken cancellationToken)
        {
            return Task.FromResult(new HttpResponseMessage()
            {
                Content = new ObjectContent<Object>(new
                {
                    token = System.Guid.NewGuid(),
                    country = this.Model.country,
                    name = this.Model.name
                },
                System.Web.Http.GlobalConfiguration.Configuration.Formatters.JsonFormatter),
                StatusCode = System.Net.HttpStatusCode.NoContent
            });
        }
    }
}