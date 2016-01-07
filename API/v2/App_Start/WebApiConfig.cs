using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Web.Http;
using System.Web.Http.Routing;
using System.Web.Services.Description;
using Swashbuckle.Application;


namespace API
{

	/// <summary>
	/// WEB API Global Configuration
	/// </summary>
	public static class WebApiConfig
	{
        /// <summary>
        /// Roles with Administrator Privileges
        /// </summary>
        public const string RootRoles = "ROOT";

		/// <summary>
		/// Register Config Variables
		/// </summary>
		/// <param name="config"></param>
		public static void Register (HttpConfiguration config)
		{
			//--------------------------------------------------------------------------------------------------------------------------------------------
			// Web API routes
            config.EnableGaleRoutes();    //No Version Route (Manual Versioning)
            config.EnableSwagger();
            config.SetJsonDefaultFormatter();   //Google Chrome Fix (default formatter is xml :/)
			//--------------------------------------------------------------------------------------------------------------------------------------------
		}
	}
}
