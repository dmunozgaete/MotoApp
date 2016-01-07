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
    /// Share Route to Public
    /// </summary>
    public class Share : Gale.REST.Http.HttpUpdateActionResult<Models.newSharedRoute>
    {
        /// <summary>
        /// Constructor
        /// </summary>
        /// <param name="route">Route to Share</param>
        /// <param name="user">User</param>
        public Share(string route, Models.newSharedRoute shareRoute) : base(route, shareRoute) { }


        /// <summary>
        /// Async Process
        /// </summary>
        /// <param name="token">Route to Share</param>
        /// <param name="cancellationToken"></param>
        /// <returns></returns>
        public override Task<HttpResponseMessage> ExecuteAsync(string token, System.Threading.CancellationToken cancellationToken)
        {
            //------------------------------------------------------------------------------------------------------
            // GUARD EXCEPTIONS
            Gale.Exception.RestException.Guard(() => Model == null, "BODY_EMPTY", API.Errors.ResourceManager);
            Gale.Exception.RestException.Guard(() => Model.name == null, "EMPTY_NAME", API.Errors.ResourceManager);
            //------------------------------------------------------------------------------------------------------

            //------------------------------------------------------------------------------------------------------
            // DB Execution
            try
            {
                using (Gale.Db.DataService svc = new Gale.Db.DataService("PA_MOT_UPD_CompartirRuta"))
                {
                    svc.Parameters.Add("ENTI_Token", HttpContext.Current.User.PrimarySid());
                    svc.Parameters.Add("RUTA_Token", token);

                    svc.Parameters.Add("RUCO_Nombre", Model.name);
                    svc.Parameters.Add("RUCO_Observaciones", Model.observation);

                    this.ExecuteAction(svc);
                }

            }
            catch (Gale.Exception.SqlClient.CustomDatabaseException ex)
            {
                //50001 ROUTE_DONT_EXISTS
                throw new Gale.Exception.RestException(ex.Message, null);
            }
            catch
            {
                throw new Gale.Exception.RestException("CANT_SHARE_ROUTE", null);
            }
            //------------------------------------------------------------------------------------------------------

            HttpResponseMessage response = new HttpResponseMessage(System.Net.HttpStatusCode.PartialContent);
            return Task.FromResult(response);
        }
    }
}