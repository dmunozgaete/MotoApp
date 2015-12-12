using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web;

namespace API.Endpoints.Accounts.Services.Medals
{
    /// <summary>
    /// Check when a medal or medals are won
    /// </summary>
    public class Check : Gale.REST.Http.HttpReadActionResult<String>
    {
        /// <summary>
        /// Category
        /// </summary>
        String _category = null;

        /// <summary>
        /// Constructor
        /// </summary>
        /// <param name="user">User</param>
        /// <param name="category">Category to Check</param>
        public Check(String user, String category)
            : base(user)
        {
            this._category = category;
        }

        /// <summary>
        /// Async Process
        /// </summary>
        /// <param name="cancellationToken"></param>
        /// <returns></returns>
        public override System.Threading.Tasks.Task<System.Net.Http.HttpResponseMessage> ExecuteAsync(System.Threading.CancellationToken cancellationToken)
        {
            using (Gale.Db.DataService svc = new Gale.Db.DataService("PA_MOT_CHK_Medallas"))
            {
                svc.Parameters.Add("USUA_Token", this.Model);
                svc.Parameters.Add("MECA_Identificador", _category);

                var rep = this.ExecuteQuery(svc);
                var details = rep.GetModel<Models.NewDetails>().FirstOrDefault();
                var newMedals = rep.GetModel<Models.NewMedal>(1);
                
                //----------------------------------------------------------------------------------------------------
                //Create Response
                var response = new HttpResponseMessage(System.Net.HttpStatusCode.OK)
                {
                    Content = new ObjectContent<Object>(
                        new
                        {
                            details = details,
                            medals = newMedals
                        },
                        System.Web.Http.GlobalConfiguration.Configuration.Formatters.KqlFormatter()
                    )
                };

                //Return Task
                return Task.FromResult(response);
                //----------------------------------------------------------------------------------------------------

            }
        }
    }
}