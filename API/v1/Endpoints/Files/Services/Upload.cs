using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Web;

namespace API.Endpoints.Files.Services
{

    /// <summary>
    /// File Upload
    /// </summary>
    public class Upload : Gale.REST.Http.HttpActionFileResult
    {
        string _userID = null;

        /// <summary>
        /// Constructor
        /// </summary>
        /// <param name="request">Http Request</param>
        /// <param name="userID">User ID</param>
        public Upload(HttpRequestMessage request, string userID)
            : base(request)
        {
            _userID = userID;
        }

        /// <summary>
        /// Save Files into DB
        /// </summary>
        /// <param name="files"></param>
        /// <returns></returns>
        public override System.Net.Http.HttpResponseMessage SaveFiles(List<System.Net.Http.HttpContent> files)
        {

            List<Object> _files = new List<object>();

            foreach (HttpContent file in files)
            {
                // You would get hold of the inner memory stream here
                System.IO.Stream stream = file.ReadAsStreamAsync().Result;

                using (Gale.Db.DataService svc = new Gale.Db.DataService("PA_MAE_INS_Archivo"))
                {
                    string name = file.Headers.ContentDisposition.FileName.Replace("\"", "");

                    svc.Parameters.Add("ARCH_Nombre", name);
                    svc.Parameters.Add("ARCH_Tamano", file.Headers.ContentLength);
                    svc.Parameters.Add("ARCH_ContentType", file.Headers.ContentType.MediaType);
                    svc.Parameters.Add("ARCH_Temporal", 1);
                    svc.Parameters.Add("ARCH_Binario", stream);
                    svc.Parameters.Add("ENTI_Token", _userID);

                    System.Guid token = (System.Guid)this.ExecuteScalar(svc);

                    _files.Add(new
                    {
                        token = token,
                        name = name,
                        length = file.Headers.ContentLength,
                        md5 = Gale.Security.Cryptography.MD5.GenerateHash(stream),
                        contentType = file.Headers.ContentType.MediaType,
                        createdAt = DateTime.Now.ToString("s")
                    });
                }

            }

            //----------------------------------------------------------------------------
            return new HttpResponseMessage(System.Net.HttpStatusCode.OK)
            {
                Content = new ObjectContent<Object>(
                    _files,
                    System.Web.Http.GlobalConfiguration.Configuration.Formatters.JsonFormatter
                )
            };
            //----------------------------------------------------------------------------
        }
    }
}