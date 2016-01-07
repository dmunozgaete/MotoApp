angular.module("config", []).constant("GLOBAL_CONFIGURATION",
{
    application:
    {
        version: "1.2.0-rc.1",
        environment: "production",
        language: "es",
        home: "app/home"
    },

    on_build_new_version: function(newVersion, oldVersion)
    {

        //When has new Version , set the mark in the localstoage 
        localStorage.setItem("$_new_version", 1);
    },

    localstorageStamps:
    {
        personal_data: "$_personal_data",
        new_version: "$_new_version"
    },

    //Custom Collections
    collections:
    {
        sportTypes: [
        {
            name: 'Enduro',
            identifier: 'ENDUR'
        },
        {
            name: 'MotoCross',
            identifier: 'CROSS'
        },
        {
            name: 'Big Trail',
            identifier: 'BTRAI'
        },
        {
            name: 'Pista',
            identifier: 'PISTA'
        },
        {
            name: 'Trial',
            identifier: 'TRIAL'
        },
        {
            name: 'ATV',
            identifier: 'MTATV'
        },
        {
            name: 'UTV',
            identifier: 'MTUTV'
        }]
    }
});
