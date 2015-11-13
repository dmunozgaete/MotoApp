angular.module("config", []).constant("GLOBAL_CONFIGURATION",
{
    application:
    {
        version: "1.0.2-rc.3",
        environment: "production",
        language: "es",
        home: "app/home"
    },

    on_build_new_version: function(newVersion, oldVersion)
    {
        if(localStorage){
            localStorage.clear();   //Reset App
        }
    }
});
