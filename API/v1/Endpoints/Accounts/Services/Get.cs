using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web;

namespace API.Endpoints.Accounts.Services
{
    /// <summary>
    /// Retrieve a Target User
    /// </summary>
    public class Get : Gale.REST.Http.HttpReadActionResult<String>
    {
        /// <summary>
        /// Constructor
        /// </summary>
        /// <param name="token"></param>
        public Get(String token) : base(token) { }

        /// <summary>
        /// Async Process
        /// </summary>
        /// <param name="cancellationToken"></param>
        /// <returns></returns>
        public override System.Threading.Tasks.Task<System.Net.Http.HttpResponseMessage> ExecuteAsync(System.Threading.CancellationToken cancellationToken)
        {
            using (Gale.Db.DataService svc = new Gale.Db.DataService("PA_MAE_OBT_InformacionUsuario"))
            {
                svc.Parameters.Add("USUA_Token", this.Model);

                Gale.Db.EntityRepository rep = this.ExecuteQuery(svc);

                Models.VT_Users account = rep.GetModel<Models.VT_Users>().FirstOrDefault();
                List<Models.Profile> profiles = rep.GetModel<Models.Profile>(1);

                //----------------------------------------------------------------------------------------------------
                //Guard Exception's
                Gale.Exception.RestException.Guard(() => account == null, "ACCOUNT_DONT_EXISTS", API.Errors.ResourceManager);
                //----------------------------------------------------------------------------------------------------

                //----------------------------------------------------------------------------------------------------
                //Create Response
                var response = new HttpResponseMessage(System.Net.HttpStatusCode.OK)
                {
                    Content = new ObjectContent<Object>(
                        new
                        {
                            token = account.token,
                            email = account.email,
                            fullName = account.fullname,
                            identifier = account.identifier,
                            avatar = (account.photo == System.Guid.Empty ? null : account.photo.ToString()),
                            lastConnection = account.lastConnection,
                            roles = (from role in profiles
                                     select new
                                     {
                                         identifier = role.identifier,
                                         token = role.token,
                                         name = role.name
                                     })
                        },
                        System.Web.Http.GlobalConfiguration.Configuration.Formatters.JsonFormatter
                    )
                };

                //Return Task
                return Task.FromResult(response);
                //----------------------------------------------------------------------------------------------------

            }
        }
    }
}