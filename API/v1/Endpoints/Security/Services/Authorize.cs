using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web;

namespace API.Endpoints.Security.Services
{
    /// <summary>
    /// Authorize an User by Credentials
    /// </summary>
    public class Authorize : Gale.REST.Http.Generic.HttpActionResult<Models.Credentials>
    {
        HttpRequestMessage _request;    //Only for Content Negotiation

        /// <summary>
        /// Constructor
        /// </summary>
        /// <param name="request"></param>
        /// <param name="credentials"></param>
        public Authorize(HttpRequestMessage request, Models.Credentials credentials)
            : base(credentials)
        {
            _request = request;
        }

        /// <summary>
        /// Async Process
        /// </summary>
        /// <param name="cancellationToken"></param>
        /// <returns></returns>
        public override Task<HttpResponseMessage> ExecuteAsync(System.Threading.CancellationToken cancellationToken)
        {

            using (Gale.Db.DataService svc = new Gale.Db.DataService("PA_MAE_OBT_AutenticarUsuario"))
            {
                svc.Parameters.Add("USUA_NombreUsuario", Model.username);
                svc.Parameters.Add("USUA_Contrasena", Gale.Security.Cryptography.MD5.GenerateHash(Model.password));
                Gale.Db.EntityRepository rep = this.ExecuteQuery(svc);

                Models.User user = rep.GetModel<Models.User>(0).FirstOrDefault();
                Gale.Db.EntityTable<Models.Profile> profiles = rep.GetModel<Models.Profile>(1);

                //------------------------------------------------------------------------------------------------------------------------
                //GUARD EXCEPTION
                Gale.Exception.RestException.Guard(() => user == null, "USERNAME_OR_PASSWORD_INCORRECT", Resources.Security.ResourceManager);
                //------------------------------------------------------------------------------------------------------------------------

                List<System.Security.Claims.Claim> claims = new List<System.Security.Claims.Claim>();

                claims.Add(new System.Security.Claims.Claim(System.Security.Claims.ClaimTypes.Email, user.email));
                claims.Add(new System.Security.Claims.Claim(System.Security.Claims.ClaimTypes.PrimarySid, user.token.ToString()));
                claims.Add(new System.Security.Claims.Claim(System.Security.Claims.ClaimTypes.Name, user.fullname));
                claims.Add(new System.Security.Claims.Claim("photo", user.photo.ToString()));
                profiles.ForEach((perfil) =>
                {
                    claims.Add(new System.Security.Claims.Claim(System.Security.Claims.ClaimTypes.Role, perfil.identifier));
                });

                int expiration = Convert.ToInt32(System.Configuration.ConfigurationManager.AppSettings["Gale:Security:TokenTmeout"]);

                //RETURN TOKEN
                return Task.FromResult(_request.CreateResponse<Gale.Security.Oauth.Jwt.Wrapper>(
                    Gale.Security.Oauth.Jwt.Manager.CreateToken(claims, DateTime.Now.AddMinutes(expiration))
                ));
            }

        }

    }
}