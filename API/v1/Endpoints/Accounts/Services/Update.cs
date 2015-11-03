using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Threading.Tasks;
using System.Net.Http;

namespace API.Endpoints.Accounts.Services
{
    /// <summary>
    /// Update User in DB
    /// </summary>
    public class Update : Gale.REST.Http.HttpUpdateActionResult<Models.Update>
    {
        /// <summary>
        /// Constructor
        /// </summary>
        /// <param name="token">User Token</param>
        /// <param name="user">Target Model</param>
        public Update(string token, Models.Update user) : base(token, user) { }

       /// <summary>
       ///  Update User
       /// </summary>
       /// <param name="token"></param>
       /// <param name="cancellationToken"></param>
       /// <returns></returns>
        public override Task<System.Net.Http.HttpResponseMessage> ExecuteAsync(string token, System.Threading.CancellationToken cancellationToken)
        {
            //------------------------------------------------------------------------------------------------------
            // GUARD EXCEPTIONS
            Gale.Exception.RestException.Guard(() => Model == null, "BODY_EMPTY", API.Errors.ResourceManager);
            Gale.Exception.RestException.Guard(() => Model.fullname == String.Empty, "NAME_EMPTY", API.Errors.ResourceManager);
            Gale.Exception.RestException.Guard(() => Model.email == String.Empty, "EMAIL_EMPTY", API.Errors.ResourceManager);
            //------------------------------------------------------------------------------------------------------

            //------------------------------------------------------------------------------------------------------
            // DB Execution
            using (Gale.Db.DataService svc = new Gale.Db.DataService("PA_MAE_ACT_Usuario"))
            {
                svc.Parameters.Add("ENTI_Token", HttpContext.Current.User.PrimarySid());
                svc.Parameters.Add("ENTI_Nombre", Model.fullname);
                svc.Parameters.Add("USUA_Token", token);
                svc.Parameters.Add("USUA_Email", Model.email);
                svc.Parameters.Add("USUA_Activo", Model.active);

                if (Model.photo != null && Model.photo != System.Guid.Empty)
                {
                    svc.Parameters.Add("ARCH_Token", Model.photo);
                }

               svc.Parameters.Add("PRF_Tokens", String.Join(",", Model.profiles));

                this.ExecuteAction(svc);
            }
            //------------------------------------------------------------------------------------------------------

            HttpResponseMessage response = new HttpResponseMessage(System.Net.HttpStatusCode.PartialContent);

            return Task.FromResult(response);
        }
    }
}