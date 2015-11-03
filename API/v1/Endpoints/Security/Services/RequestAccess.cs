using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web;

namespace API.Endpoints.Security.Services
{
    /// <summary>
    /// Request Access for a User
    /// </summary>
    public class RequestAccess : Gale.REST.Http.Generic.HttpActionResult<Models.RequestAccess>
    {

        /// <summary>
        /// Constructor
        /// </summary>
        /// <param name="model">Model</param>
        public RequestAccess(Models.RequestAccess model)
            : base(model)
        {

        }

        /// <summary>
        /// Async Process
        /// </summary>
        /// <param name="cancellationToken"></param>
        /// <returns></returns>
        public override System.Threading.Tasks.Task<System.Net.Http.HttpResponseMessage> ExecuteAsync(System.Threading.CancellationToken cancellationToken)
        {
            using (Gale.Db.DataService svc = new Gale.Db.DataService("[PA_SIS_INS_SolicitudAcceso]"))
            {
                svc.Parameters.Add("SOAC_Email", this.Model.email);
                this.ExecuteAction(svc);
                    
                /*
                //ALWAYS SEND FEEDBACK TO USER
                dynamic email = new Postal.Email(@"RequestAccess\Confirm");
                email.To = Model.email;
                email.Send();
                */
                //RETURN STATUS
                return Task.FromResult<HttpResponseMessage>(
                    new HttpResponseMessage(System.Net.HttpStatusCode.Created)
                );
            }
        }
    }
}