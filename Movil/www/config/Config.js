angular.module("config", []).constant("GLOBAL_CONFIGURATION",
{
    application:
    {
        version: "1.0.3-rc.1",
        environment: "development",
        language: "es",
        home: "app/home"
    },

    on_build_new_version: function(newVersion, oldVersion)
    {

        //When has new Version , destroy the pending routes database
        PouchDB("pending_routes").destroy();

        if (localStorage)
        {
            localStorage.clear(); //Reset App
        }
    },

    localstorageStamps:
    {
        personal_data: "$_personal_data"
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
