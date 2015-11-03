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
    public class Post : Gale.REST.Http.HttpCreateActionResult<Models.HelloWorld>
    {
        public Post(Models.HelloWorld model) : base(model) { }

        public override System.Threading.Tasks.Task<System.Net.Http.HttpResponseMessage> ExecuteAsync(System.Threading.CancellationToken cancellationToken)
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
                StatusCode = System.Net.HttpStatusCode.Created
            });
        }
    }
}