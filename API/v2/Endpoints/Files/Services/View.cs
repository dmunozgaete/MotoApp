using System;
using System.Collections.Generic;
using System.Drawing.Imaging;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web;

namespace API.Endpoints.Files.Services
{
    /// <summary>
    /// Authentication API
    /// </summary>
    public class View : Gale.REST.Http.HttpBaseActionResult
    {
        string _token;

        /// <summary>
        /// Constructor
        /// </summary>
        /// <param name="token">Token del Archivo</param>
        public View(String token)
        {
            _token = token;
        }

        /// <summary>
        /// Obtiene la foto del usuario
        /// </summary>
        /// <param name="cancellationToken"></param>
        /// <returns></returns>
        public override Task<HttpResponseMessage> ExecuteAsync(System.Threading.CancellationToken cancellationToken)
        {
            //------------------------------------------------------------------------------------------------------
            // DB Execution
            using (Gale.Db.DataService svc = new Gale.Db.DataService("PA_MAE_OBT_ArchivoBinario"))
            {
                svc.Parameters.Add("ARCH_Token", _token);

                Gale.Db.EntityRepository rep = this.ExecuteQuery(svc);

                Models.FileData file = rep.GetModel<Models.FileData>().FirstOrDefault();

                if (file == null)
                {
                    return Task.FromResult(new HttpResponseMessage(System.Net.HttpStatusCode.NotFound));
                }

                //Create Response
                var response = new HttpResponseMessage(System.Net.HttpStatusCode.OK)
                {
                    Content = new StreamContent(new System.IO.MemoryStream(file.binary.ToArray())),

                };

                response.Headers.CacheControl = new System.Net.Http.Headers.CacheControlHeaderValue()
                {
                    MaxAge = TimeSpan.FromMinutes(30)
                };

                //Add Content-Type Header
                response.Content.Headers.ContentType = new System.Net.Http.Headers.MediaTypeHeaderValue(file.contentType);

                return Task.FromResult(response);
            }
            //------------------------------------------------------------------------------------------------------

        }

    }
}