using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web;

namespace API.Endpoints.Routes.Services
{
    /// <summary>
    /// Discover new routes =)!
    /// </summary>
    public class Discover : Gale.REST.Http.HttpBaseActionResult
    {
        decimal _latitude;
        decimal _longitude;
        int _distance;
        string _route;
        int _limit;
        int _offset;

        /// <summary>
        /// Constructor
        /// </summary>
        /// <param name="latitude">Current Latitude to discover</param>
        /// <param name="longitude">Current Longitude to discover</param>
        /// <param name="distance">Distance to match</param>
        /// <param name="route">Route Name to match</param>
        /// <param name="limit">Records limit (Pagination)</param>
        /// <param name="offset">Records Offset (Pagination)</param>
        public Discover(decimal latitude, decimal longitude, int distance, String route, int limit, int offset)
        {
            _latitude = latitude;
            _longitude = longitude;
            _distance = distance;
            _route = route;
            _limit = limit;
            _offset = offset;
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
            Gale.Exception.RestException.Guard(() => _latitude == null, "LATITUDE_EMPTY", API.Errors.ResourceManager);
            Gale.Exception.RestException.Guard(() => _longitude == null, "LONGITUDE_EMPTY", API.Errors.ResourceManager);
            Gale.Exception.RestException.Guard(() => _distance == null, "DISTANCE_EMPTY", API.Errors.ResourceManager);
            //------------------------------------------------------------------------------------------------------

            using (Gale.Db.DataService svc = new Gale.Db.DataService("[PA_MOT_OBT_DescubrirRutas]"))
            {
                svc.Parameters.Add("USUA_Token", HttpContext.Current.User.PrimarySid());
                svc.Parameters.Add("Nombre", _route);
                svc.Parameters.Add("Distancia", _distance);
                svc.Parameters.Add("Latitud", _latitude);
                svc.Parameters.Add("Longitud", _longitude);
                svc.Parameters.Add("RegistrosPorPagina", _limit);
                svc.Parameters.Add("RegistrosSaltados", _offset);

                Gale.Db.EntityRepository rep = this.ExecuteQuery(svc);

                Models.Pagination pagination = rep.GetModel<Models.Pagination>(0).FirstOrDefault();
                List<Models.DiscoveredRoute> routes = rep.GetModel<Models.DiscoveredRoute>(1);
                //----------------------------------------------------------------------------------------------------
                //Create Response
                var response = new HttpResponseMessage(System.Net.HttpStatusCode.OK)
                {
                    Content = new ObjectContent<Object>(
                        new
                        {
                            offset = _offset,
                            limit = _limit,
                            total = pagination.total,
                            items = routes
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