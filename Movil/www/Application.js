angular.module('App', [
        'gale' //ANGULAR-GALE LIBRARY
        , 'ionic' //IONIC
        , 'app' //CUSTOM PROJECT LIBRARY

        , 'ngCordova' //CORDOVA LIBRARIES
        , 'ngAudio' //HTMl5 Audio
        , 'uiGmapgoogle-maps' //GOOGLE MAPS
        , 'chart.js' //AREA CHART
        , 'ionic-toast' //IONIC TOAST LIBRARY (WORK IN WEB ENVIRONMENT)
        , 'angularMoment' //ANGULAR MOMENT JS 

        , 'mocks' //Mocks Only for Testing, Remove in PRD

        , 'ngIOS9UIWebViewPatch' //IOS 9 FICKLERING PATCH (https://gist.github.com/IgorMinar/863acd413e3925bf282c)
    ])
    .run(function($location, $Configuration, $log, uiGmapGoogleMapApi)
    {
        //uiGmapGoogleMapApi Preload Gmaps script :P (before is better ^)
        var application = $Configuration.get("application");
        $log.info("application start... ;)!",
        {
            env: application.environment,
            version: application.version
        });
        $location.url("boot");
    })
    .config(function(mockProvider)
    {
        //Mocking Module (While the API is in Construction)
        mockProvider
            .enable()
            .setDelay(700); //Simulate a Short Delay ^^, (More 'Real' experience)
    })
    .config(function(GpsProvider, routeTrackerProvider, backgroundModeProvider)
    {
        //GPS Configuration
        GpsProvider
            .frequency(5000) //Try to get GPS Track each 5 seconds
            .enableDeviceGPS() //Enable GPS Tracking
            .autoStart() //Auto Start
            .accuracyThreshold(70) //Real GPS Aproximaty (aprox 65)
            //.addTestRoute('bundles/mocks/js/gps/+250.json'); //Simulate a Route

        //Route Tracker Configuration
        // - Auto Pause: Minimun Distance (in Meters)
        //               Beetween Point's to Set Auto-Pause
        routeTrackerProvider
            .autoPause(5);

        //Background Mode For still getting GPS in background
        backgroundModeProvider
            .enable()
            .notifyText('MotoApp seguirá enviando las coordenadas del GPS');

    })
    .config(function(GpsProvider, routeTrackerProvider, mockProvider, backgroundModeProvider, CONFIGURATION)
    {
        //Enable Debug for GPS and RouteTracker
        if (CONFIGURATION.debugging)
        {
            //Debugger Information
            routeTrackerProvider.debug();
            GpsProvider.debug();
            mockProvider.debug();
            backgroundModeProvider.debug();
        }

    })
    .config(function(uiGmapGoogleMapApiProvider)
    {
        uiGmapGoogleMapApiProvider.configure(
        {
            key: 'AIzaSyANyXwrXOkNgp9RPOAuebclIHLU2FWmPAA',
            v: '3.22',
            libraries: 'visualization,geometry'
        });
    })
    .config(function($ApiProvider)
    {
        //API Base Endpoint
        var API_ENDPOINT = 'http://valentys.motoApp.com/API/v1';
        $ApiProvider.setEndpoint(API_ENDPOINT);
    })
    .config(function($IdentityProvider)
    {
        $IdentityProvider
            .enable() //Enable
            .setIssuerEndpoint("/Security/Authorize")
            .setLogInRoute("security/identity/login");

    })
    .run(function($ionicPlatform)
    {
        $ionicPlatform.ready(function()
        {
            if (window.StatusBar)
            {
                // org.apache.cordova.statusbar required
                StatusBar.styleLightContent();
            }
        });
    })
    .config(function($stateProvider, $urlRouterProvider)
    {
        $stateProvider
            .state('app',
            {
                url: "/app",
                abstract: true,
                // ---------------------------------------------
                // ONE-PAGE COLUMNS TEMPLATE
                // ---------------------------------------------
                templateUrl: "views/layouts/layout.html",
                controller: "DefaultLayoutController"
            })
            .state('nomenu',
            {
                url: "/nomenu",
                abstract: true,
                // ---------------------------------------------
                // ONE-PAGE COLUMNS TEMPLATE
                // ---------------------------------------------
                templateUrl: "views/layouts/no-menu.html",
                controller: "NoMenuLayoutController"
            })
            .state('exception',
            {
                url: "/exception",
                abstract: true,
                // ---------------------------------------------
                // EXCEPTION TEMPLATE
                // ---------------------------------------------
                templateUrl: "views/layouts/exception.html",
                controller: "ExceptionLayoutController"
            });

        $urlRouterProvider.otherwise(function($injector, $location)
        {
            if ($location.path() !== "/")
            {
                var $state = $injector.get("$state");
                $state.go("exception.error/404");
            }
        });
    })
    .config(function($logProvider, CONFIGURATION)
    {
        $logProvider.debugEnabled(CONFIGURATION.debugging || false);
    });
