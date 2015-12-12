using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web;

namespace API.Endpoints.Routes.Services
{
    /// <summary>
    /// Retrieve a Target Route
    /// </summary>
    public class Get : Gale.REST.Http.HttpReadActionResult<String>
    {
        /// <summary>
        /// Constructor
        /// </summary>
        /// <param name="token"></param>
        public Get(String route) : base(route) { }

        /// <summary>
        /// Async Process
        /// </summary>
        /// <param name="cancellationToken"></param>
        /// <returns></returns>
        public override System.Threading.Tasks.Task<System.Net.Http.HttpResponseMessage> ExecuteAsync(System.Threading.CancellationToken cancellationToken)
        {
            using (Gale.Db.DataService svc = new Gale.Db.DataService("[PA_MOT_OBT_Ruta]"))
            {
                svc.Parameters.Add("USUA_Token", HttpContext.Current.User.PrimarySid());
                svc.Parameters.Add("RUTA_Token", this.Model);

                Gale.Db.EntityRepository rep = this.ExecuteQuery(svc);

                Models.Route route = rep.GetModel<Models.Route>().FirstOrDefault();
                Models.SocialRoute socialRoute = rep.GetModel<Models.SocialRoute>().FirstOrDefault();
                List<Models.Coordinates> coords = rep.GetModel<Models.Coordinates>(1);
                List<Models.RoutePhoto> photos = rep.GetModel<Models.RoutePhoto>(2);
                //----------------------------------------------------------------------------------------------------
                //Create Response
                var response = new HttpResponseMessage(System.Net.HttpStatusCode.OK)
                {
                    Content = new ObjectContent<Object>(
                        new
                        {
                            details = route,
                            coordinates = coords,
                            social = socialRoute,
                            photos = photos
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