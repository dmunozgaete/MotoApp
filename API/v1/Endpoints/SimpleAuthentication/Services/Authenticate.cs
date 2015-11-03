using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web;

namespace API.Endpoints.SimpleAuthentication.Services
{
    /// <summary>
    /// Simple Authentication Service
    /// </summary>
    public class Authenticate : Gale.REST.Http.HttpReadActionResult<Models.Authenitcation>
    {
        public Authenticate(Models.Authenitcation credentials) : base(credentials) { }

        /// <summary>
        /// Async Process
        /// </summary>
        /// <param name="cancellationToken">Cancellation Token</param>
        /// <returns></returns>
        public override Task<HttpResponseMessage> ExecuteAsync(System.Threading.CancellationToken cancellationToken)
        {
            List<System.Security.Claims.Claim> claims = new List<System.Security.Claims.Claim>();

            claims.Add(new System.Security.Claims.Claim(System.Security.Claims.ClaimTypes.Email,this.Model.email));
            claims.Add(new System.Security.Claims.Claim(System.Security.Claims.ClaimTypes.PrimarySid, System.Guid.NewGuid().ToString()));
            claims.Add(new System.Security.Claims.Claim(System.Security.Claims.ClaimTypes.Name, this.Model.email));
            claims.Add(new System.Security.Claims.Claim("customvalue", "CUSTOM_VALUE"));

            //A list of the roles :P
            claims.Add(new System.Security.Claims.Claim(System.Security.Claims.ClaimTypes.Role, "JOKER"));
            claims.Add(new System.Security.Claims.Claim(System.Security.Claims.ClaimTypes.Role, "ENGINEER"));
            claims.Add(new System.Security.Claims.Claim(System.Security.Claims.ClaimTypes.Role, "PROGRAMMER"));


            int expiration = Convert.ToInt32(System.Configuration.ConfigurationManager.AppSettings["Gale:Security:TokenTmeout"]);

            //RETURN TOKEN
            return Task.FromResult(new HttpResponseMessage()
            {
                Content = new ObjectContent<Gale.Security.Oauth.Jwt.Wrapper>(
                Gale.Security.Oauth.Jwt.Manager.CreateToken(claims, DateTime.Now.AddMinutes(expiration)),
                System.Web.Http.GlobalConfiguration.Configuration.Formatters.JsonFormatter),
                StatusCode = System.Net.HttpStatusCode.OK
            });
        }
    }
}