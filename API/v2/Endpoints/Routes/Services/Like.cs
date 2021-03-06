﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Threading.Tasks;
using System.Web;

namespace API.Endpoints.Routes.Services
{
    /// <summary>
    /// Liked Roue
    /// </summary>
    public class Like : Gale.REST.Http.HttpUpdateActionResult<String>
    {

        /// <summary>
        /// Constructor
        /// </summary>
        /// <param name="user">Current User</param>
        /// <param name="route">Liked Route</param>
        public Like(String user, String route) : base(user, route) { }

        /// <summary>
        /// Async Process
        /// </summary>
        /// <param name="token"></param>
        /// <param name="cancellationToken"></param>
        /// <returns></returns>
        public override Task<HttpResponseMessage> ExecuteAsync(string token, System.Threading.CancellationToken cancellationToken)
        {
            using (Gale.Db.DataService svc = new Gale.Db.DataService("[PA_MOT_INS_MeGustaRuta]"))
            {
                svc.Parameters.Add("ENTI_Token", token);
                svc.Parameters.Add("RUTA_Token", this.Model);

                this.ExecuteAction(svc);

                //----------------------------------------------------------------------------------------------------
                //Create Response
                var response = new HttpResponseMessage(System.Net.HttpStatusCode.Created);

                //Return Task
                return Task.FromResult(response);
                //----------------------------------------------------------------------------------------------------

            }
        }
    }
}