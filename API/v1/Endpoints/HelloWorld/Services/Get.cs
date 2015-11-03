using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web;

namespace API.Endpoints.HelloWorld.Services
{
    public class Get : Gale.REST.Http.HttpReadActionResult<String>
    {
        public Get(string name) : base(name) { }

        public override System.Threading.Tasks.Task<System.Net.Http.HttpResponseMessage> ExecuteAsync(System.Threading.CancellationToken cancellationToken)
        {
            return Task.FromResult(new HttpResponseMessage()
            {
                Content = new StringContent(String.Format("Hello World {0}", this.Model)),
                StatusCode = System.Net.HttpStatusCode.OK
            });
        }
    }
}