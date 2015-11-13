using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Net.Mail;
using System.Threading.Tasks;
using System.Web;

namespace API.Endpoints.Routes.Services
{
    /// <summary>
    /// Add New Route
    /// </summary>
    public class SavePhoto : Gale.REST.Http.HttpCreateActionResult<Models.RoutePhoto>
    {
        string _route = null;

        /// <summary>
        /// Constructor
        /// </summary>
        /// <param name="route">New Route</param>
        /// <param name="user">User</param>
        public SavePhoto(Models.RoutePhoto photo, string route)
            : base(photo)
        {
            _route = route;
        }

        /// <summary>
        /// Async Process
        /// </summary>
        /// <param name="cancellationToken"></param>
        /// <returns></returns>
        public override System.Threading.Tasks.Task<System.Net.Http.HttpResponseMessage> ExecuteAsync(System.Threading.CancellationToken cancellationToken)
        {
            //------------------------------------------------------------------------------------------------------
            // GUARD EXCEPTIONS
            Gale.Exception.RestException.Guard(() => Model == null, "BODY_EMPTY", API.Errors.ResourceManager);
            Gale.Exception.RestException.Guard(() => Model.photo == null, "IMAGE_EMPTY", API.Errors.ResourceManager);
            //------------------------------------------------------------------------------------------------------

            System.Guid imageToken = System.Guid.Empty;
            byte[] data = System.Convert.FromBase64String(Model.photo);

            //------------------------------------------------------------------------------------------------------
            // DB Execution
            using (Gale.Db.DataService svc = new Gale.Db.DataService("PA_MOT_INS_ImagenRuta"))
            {
                svc.Parameters.Add("ENTI_Token", HttpContext.Current.User.PrimarySid());
                svc.Parameters.Add("RUTA_Token", _route);
                svc.Parameters.Add("ARCH_Binario", data);
                svc.Parameters.Add("ARCH_Tamano", data.Length);

                imageToken = (System.Guid)this.ExecuteScalar(svc);
            }

            //------------------------------------------------------------------------------------------------------
            HttpResponseMessage response = new HttpResponseMessage(System.Net.HttpStatusCode.Created)
            {
                Content = new ObjectContent<Object>(
                        new
                        {
                            token = imageToken
                        },
                        System.Web.Http.GlobalConfiguration.Configuration.Formatters.JsonFormatter
                    )
            };
            return Task.FromResult(response);
        }
    }
}