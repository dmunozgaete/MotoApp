using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Net.Mail;
using System.Threading.Tasks;
using System.Web;

namespace API.Endpoints.Routes.Services
{
    /// <summary>
    /// Add New Route
    /// </summary>
    public class Create : Gale.REST.Http.HttpCreateActionResult<Models.NewRoute>
    {
        string _user = null;

        /// <summary>
        /// Constructor
        /// </summary>
        /// <param name="route">New Route</param>
        /// <param name="user">User</param>
        public Create(Models.NewRoute route, string user)
            : base(route)
        {
            _user = user;
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
            Gale.Exception.RestException.Guard(() => Model.altitude == null, "EMPTY_ALTITUDE", API.Errors.ResourceManager);
            Gale.Exception.RestException.Guard(() => Model.calories == null, "EMPTY_CALORIES", API.Errors.ResourceManager);
            Gale.Exception.RestException.Guard(() => Model.distance == null, "EMPTY_DISTANCE", API.Errors.ResourceManager);
            Gale.Exception.RestException.Guard(() => Model.duration == null, "EMPTY_DURATION", API.Errors.ResourceManager);
            Gale.Exception.RestException.Guard(() => Model.pauses == null, "EMPTY_PAUSES", API.Errors.ResourceManager);
            Gale.Exception.RestException.Guard(() => Model.end == null, "EMPTY_DATE_END", API.Errors.ResourceManager);
            Gale.Exception.RestException.Guard(() => Model.lat == null, "EMPTY_LATITUDE", API.Errors.ResourceManager);
            Gale.Exception.RestException.Guard(() => Model.lng == null, "EMPTY_LONGITUDE", API.Errors.ResourceManager);
            Gale.Exception.RestException.Guard(() => Model.speed == null, "EMPTY_SPEED", API.Errors.ResourceManager);
            Gale.Exception.RestException.Guard(() => Model.start == null, "EMPTY_START", API.Errors.ResourceManager);
            Gale.Exception.RestException.Guard(() => Model.coordinates == null, "EMPTY_COORDINATES", API.Errors.ResourceManager);
            Gale.Exception.RestException.Guard(() => Model.coordinates.Count < 2, "AT_LEAST_2_COORDINATES_IS_REQUIRED", API.Errors.ResourceManager);
            //------------------------------------------------------------------------------------------------------

            //------------------------------------------------------------------------------------------------------
            Action<System.Guid> rollback = new Action<Guid>((token) =>
            {
                using (Gale.Db.DataService svc = new Gale.Db.DataService("PA_MOT_DEL_Ruta"))
                {
                    svc.Parameters.Add("ENTI_Token", _user);
                    svc.Parameters.Add("RUTA_Token", token);
                }
            });

            System.Guid routeToken = System.Guid.Empty;

            //---------------------------------------------------------------------
            /*
            byte[] imageBytes = null;
            if (Model.image != null)
            {
                try
                {
                    //Try to download the image
                    var webClient = new WebClient();
                    imageBytes = webClient.DownloadData(Model.image);
                }
                catch
                {

                }
            }
             * */
            //---------------------------------------------------------------------


            //---------------------------------------------------------------------
            // DB Execution
            try
            {
                using (Gale.Db.DataService svc = new Gale.Db.DataService("PA_MOT_INS_Ruta"))
                {
                    svc.Parameters.Add("ENTI_Token", _user);
                    svc.Parameters.Add("RUTA_Inicio", Model.start.ToLocalTime());
                    svc.Parameters.Add("RUTA_Fin", Model.end.ToLocalTime());
                    svc.Parameters.Add("RUTA_Duracion", Model.duration);
                    svc.Parameters.Add("RUTA_Pausas", Model.pauses);
                    svc.Parameters.Add("RUTA_Distancia", Model.distance);
                    svc.Parameters.Add("RUTA_Velocidad", Model.speed);
                    svc.Parameters.Add("RUTA_Calorias", Model.calories);
                    svc.Parameters.Add("RUTA_Latitud", Model.lat);
                    svc.Parameters.Add("RUTA_Longitud", Model.lng);
                    svc.Parameters.Add("RUTA_Altitud", Model.altitude);
                    svc.Parameters.Add("RUTA_Imagen", Model.image);

                    routeToken = (System.Guid)this.ExecuteScalar(svc);
                }

                try
                {
                    Model.coordinates.ForEach((coordinate) =>
                    {
                        //------------------------------------------------------------------------------------------------------
                        // DB Execution
                        using (Gale.Db.DataService coord = new Gale.Db.DataService("PA_MOT_INS_CoordenadaRuta"))
                        {
                            coord.Parameters.Add("ENTI_Token", _user);
                            coord.Parameters.Add("RUTA_Token", routeToken);
                            coord.Parameters.Add("COOR_Fecha", coordinate.createdAt.ToLocalTime());
                            coord.Parameters.Add("COOR_Distancia", coordinate.distance);
                            coord.Parameters.Add("COOR_Velocidad", coordinate.speed);
                            coord.Parameters.Add("COOR_Latitud", coordinate.lat);
                            coord.Parameters.Add("COOR_Longitud", coordinate.lng);
                            coord.Parameters.Add("COOR_Altitud", coordinate.altitude);
                            coord.Parameters.Add("COOR_Duracion", coordinate.duration);

                            this.ExecuteAction(coord);
                        }
                        //------------------------------------------------------------------------------------------------------

                    });
                }
                catch
                {
                    rollback(routeToken);
                    throw new Gale.Exception.RestException("CANT_ASSOCIATE_COORDINATES_TO_ROUTE", null);
                }


            }
            catch
            {
                throw new Gale.Exception.RestException("CANT_CREATE_ROUTE", null);
            }
            //------------------------------------------------------------------------------------------------------

            HttpResponseMessage response = new HttpResponseMessage(System.Net.HttpStatusCode.Created)
            {
                Content = new ObjectContent<Object>(
                        new
                        {
                            token = routeToken
                        },
                        System.Web.Http.GlobalConfiguration.Configuration.Formatters.JsonFormatter
                    )
            };
            return Task.FromResult(response);
        }
    }
}