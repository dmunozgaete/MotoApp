using System;
using System.Collections.Generic;
using System.Linq;
using System.Net.Http;
using System.Net.Mail;
using System.Threading.Tasks;
using System.Web;

namespace API.Endpoints.Accounts.Services
{
    /// <summary>
    /// Add User to DB
    /// </summary>
    public class Create : Gale.REST.Http.HttpCreateActionResult<Models.Create>
    {
        private string _host;

        /// <summary>
        /// Constructor
        /// </summary>
        /// <param name="user">New User Information</param>
        /// <param name="host">Application URL</param>
        public Create(Models.Create user, string host)
            : base(user)
        {
            this._host = host;
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
            Gale.Exception.RestException.Guard(() => String.IsNullOrEmpty(Model.fullname), "NAME_EMPTY", API.Errors.ResourceManager);
            Gale.Exception.RestException.Guard(() => String.IsNullOrEmpty(Model.email), "EMAIL_EMPTY", API.Errors.ResourceManager);
            //------------------------------------------------------------------------------------------------------

            //------------------------------------------------------------------------------------------------------
            // DB Execution
            using (Gale.Db.DataService svc = new Gale.Db.DataService("PA_MAE_INS_Usuario"))
            {
                svc.Parameters.Add("ENTI_Token", HttpContext.Current.User.PrimarySid());
                svc.Parameters.Add("ENTI_Nombre", Model.fullname);
                svc.Parameters.Add("ENTI_Identificador", Model.email);
                svc.Parameters.Add("ENTI_Email", Model.email);
                svc.Parameters.Add("USUA_Contrasena", Gale.Security.Cryptography.MD5.GenerateHash(System.Web.Security.Membership.GeneratePassword(20, 3)));
                svc.Parameters.Add("PRF_Tokens", (Model.profiles == null ? null : String.Join(",", Model.profiles)));

                try
                {
                    this.ExecuteAction(svc);
                }
                catch (Gale.Exception.SqlClient.CustomDatabaseException ex)
                {
                    //50001 = USER_ALREADY_EXISTS
                    throw new Gale.Exception.RestException(System.Net.HttpStatusCode.BadRequest, ex.Message, null);
                }
            }
            //------------------------------------------------------------------------------------------------------

            //----------------------------------------------------------------------
            //Send an Activation Email

            // REPLICATES A BASIC TOKEN AND 2 HOURS EXPIRATION
            List<System.Security.Claims.Claim> claims = new List<System.Security.Claims.Claim>();

            claims.Add(new System.Security.Claims.Claim(System.Security.Claims.ClaimTypes.Email, Model.email));
            claims.Add(new System.Security.Claims.Claim(System.Security.Claims.ClaimTypes.PrimarySid, Model.email));
            claims.Add(new System.Security.Claims.Claim(System.Security.Claims.ClaimTypes.Name, Model.fullname));
            var token = Gale.Security.Oauth.Jwt.Manager.CreateToken(claims, DateTime.Now.AddMinutes(60 * 2));  //2 Horas		

            //Wrap the Message
            MailMessage message = new MailMessage()
            {
                IsBodyHtml = true,
                From = new MailAddress(System.Configuration.ConfigurationManager.AppSettings["Mail:Account"]),
                Subject = API.Templates.Mail.Account.Register.Subject,
                Body = API.Templates.Engine.Render(@"Mail\Account\Register", new
                        {
                            Nombre = Model.fullname,
                            Url = String.Format("{0}#/account/register/{1}", this._host, token.access_token)
                        })
            };
            message.To.Add(new MailAddress(Model.email));
            SmtpClient client = new SmtpClient();
            client.Send(message);
            //----------------------------------------------------------------------

            HttpResponseMessage response = new HttpResponseMessage(System.Net.HttpStatusCode.Created);
            return Task.FromResult(response);
        }
    }
}