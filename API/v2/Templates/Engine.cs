using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using RazorTemplates.Core;

namespace API.Templates
{
    /// <summary>
    /// Template Manager
    /// </summary>
    public class Engine
    {

        /// <summary>
        /// Compile Template
        /// </summary>
        /// <param name="template">Resouce Name for the template embedded in the project</param>
        /// <param name="model">Model to bind</param>
        /// <returns>Compiled Template</returns>
        public static string Render(string template, dynamic model){

            //----------------------------------
            var assembly = typeof(API.Templates.Engine).Assembly;
            String resourcePath = String.Format(
                "API.Templates.{0}.cshtml",
                template.Replace("\\", ".")
            );

            using (System.IO.Stream stream = assembly.GetManifestResourceStream(resourcePath))
            {

                //------------------------------------------------------------------------------------------------------
                // GUARD EXCEPTIONS
                Gale.Exception.RestException.Guard(() => stream == null, "TEMPLATE_DONT_EXIST", API.Errors.ResourceManager);
                //------------------------------------------------------------------------------------------------------

                using (System.IO.StreamReader reader = new System.IO.StreamReader(stream))
                {
                    var view = Template.Compile(reader.ReadToEnd());
                    return view.Render(model);
                }
            }
            //----------------------------------

        }
    }
}