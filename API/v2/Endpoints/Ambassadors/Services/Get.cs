using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web;

namespace API.Endpoints.Ambassadors.Services
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
        public Get( String user):base(user){}

        /// <summary>
        /// Async Process
        /// </summary>
        /// <param name="cancellationToken"></param>
        /// <returns></returns>
        public override System.Threading.Tasks.Task<System.Net.Http.HttpResponseMessage> ExecuteAsync(System.Threading.CancellationToken cancellationToken)
        {
            using (Gale.Db.DataService svc = new Gale.Db.DataService("[PA_MOT_OBT_Embajadores]"))
            {
                svc.Parameters.Add("USUA_Token", this.Model);

                Gale.Db.EntityRepository rep = this.ExecuteQuery(svc);
                List<Models.Ambassador> items = rep.GetModel<Models.Ambassador>();

                //----------------------------------------------------------------------------------------------------
                //Create Response
                var response = new HttpResponseMessage(System.Net.HttpStatusCode.OK)
                {
                    Content = new ObjectContent<Object>(
                        new
                        {
                            total = items.Count,
                            items = items
                        },
                        System.Web.Http.GlobalConfiguration.Configuration.Formatters.KqlFormatter()    //-> CAMEL_CASING RETRIEVE DIFERENT OBJECT =)
                    )
                };

                //Return Task
                return Task.FromResult(response);
                //----------------------------------------------------------------------------------------------------

            }
        }
    }
}