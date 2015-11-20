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
    public class Update : Gale.REST.Http.HttpUpdateActionResult<Models.UpdatePersonalData>
    {
        /// <summary>
        /// Constructor
        /// </summary>
        /// <param name="token">User Token</param>
        /// <param name="user">Target Model</param>
        public Update(string token, Models.UpdatePersonalData user) : base(token, user) { }

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
            Gale.Exception.RestException.Guard(() => Model.sport == String.Empty, "SPORT_EMPTY", API.Errors.ResourceManager);
            Gale.Exception.RestException.Guard(() => Model.weight < 30, "WEIGHT_EMPTY", API.Errors.ResourceManager);
            //------------------------------------------------------------------------------------------------------

            //------------------------------------------------------------------------------------------------------
            // DB Execution
            using (Gale.Db.DataService svc = new Gale.Db.DataService("PA_MOT_UPD_Perfil"))
            {
                svc.Parameters.Add("USUA_Token", token);
                svc.Parameters.Add("USUA_Peso", Model.weight);
                svc.Parameters.Add("TIDE_Identificador", Model.sport);
                if (Model.emergencyPhones != null)
                {
                   
                    svc.Parameters.Add("Telefonos", String.Join(",", Model.emergencyPhones));
                }

                this.ExecuteAction(svc);
            }
            //------------------------------------------------------------------------------------------------------

            HttpResponseMessage response = new HttpResponseMessage(System.Net.HttpStatusCode.PartialContent);

            return Task.FromResult(response);
        }
    }
}