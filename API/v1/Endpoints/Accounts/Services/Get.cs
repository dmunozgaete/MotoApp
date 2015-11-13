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
            using (Gale.Db.DataService svc = new Gale.Db.DataService("PA_MOT_OBT_Perfl"))
            {
                svc.Parameters.Add("USUA_Token", this.Model);

                Gale.Db.EntityRepository rep = this.ExecuteQuery(svc);

                Models.Account account = rep.GetModel<Models.Account>().FirstOrDefault();
                List<Models.Role> roles = rep.GetModel<Models.Role>(1);
                Models.SocialProfile counter = rep.GetModel<Models.SocialProfile>(2).FirstOrDefault();
                Models.Sport sport = rep.GetModel<Models.Sport>(3).FirstOrDefault();

                //----------------------------------------------------------------------------------------------------
                //Guard Exception's
                Gale.Exception.RestException.Guard(() => account == null, "ACCOUNT_DONT_EXISTS", API.Errors.ResourceManager);
                //----------------------------------------------------------------------------------------------------

                account.photo = (account.photo == System.Guid.Empty ? null : account.photo);

                //----------------------------------------------------------------------------------------------------
                //Create Response
                var response = new HttpResponseMessage(System.Net.HttpStatusCode.OK)
                {
                    Content = new ObjectContent<Object>(
                        new
                        {
                            account = account,
                            roles = roles,
                            sport = sport,
                            social = counter
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