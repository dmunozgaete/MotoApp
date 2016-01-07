angular.module('App', [
        'gale' //ANGULAR-GALE LIBRARY
        , 'ionic' //IONIC
        , 'app' //CUSTOM PROJECT LIBRARY

        , 'ngCordova' //CORDOVA LIBRARI
        , 'pouchdb' //POUCH DB (FOR DATA STORAGE)
        , 'ngAudio' //HTMl5 Audio
        , 'uiGmapgoogle-maps' //GOOGLE MAPS
        , 'chart.js' //AREA CHART
        , 'angularMoment' //ANGULAR MOMENT JS 

        , 'mocks' //Mocks Only for Testing, Remove in PRD

        , 'ngIOS9UIWebViewPatch' //IOS 9 FICKLERING PATCH (https://gist.github.com/IgorMinar/863acd413e3925bf282c)
    ])
    .run(function($location, $Configuration, $log, uiGmapGoogleMapApi)
    {
        //uiGmapGoogleMapApi Preload Gmaps script :P (before is better ^)
        $location.url("boot");
    })
    //CHANGE STATUS BAR TO LIGHT CONTENT
    .run(function($ionicPlatform)
    {
        //IOS, SET Light Background in Fullscreen mode
        $ionicPlatform.ready(function()
        {
            if (window.StatusBar)
            {
                // org.apache.cordova.statusbar required
                StatusBar.styleLightContent();
            }
        });
    })
    // GOOGLE ANALITYCS
    .run(function($rootScope, $cordovaGoogleAnalytics, CONFIGURATION, $ionicPlatform)
    {
        //Native?
        $ionicPlatform.ready(function()
        {
            if (ionic.Platform.isWebView())
            {
                //DEBUGGING??
                if (CONFIGURATION.debugging)
                {
                    $cordovaGoogleAnalytics.debugMode();
                }

                $cordovaGoogleAnalytics.startTrackerWithId('UA-46328608-6');
                $rootScope.$on('$stateChangeStart', function(e, toState, toParams, fromState, fromParams)
                {
                    $cordovaGoogleAnalytics.trackView(toState.name);
                });
            }
        });
    })
    .config(function($cordovaFacebookProvider)
    {
        //Faceboook Login , -> Native Support, otherwise browser
        if (!ionic.Platform.isWebView())
        {
            var init = function()
            {
                var appID = 975485019185433;
                var version = "v2.5";
                $cordovaFacebookProvider.browserInit(appID, version);
            };

            //if FB (Facebook Plugin)
            if (typeof FB !== "undefined")
            {
                init();
            }
            else
            {
                //Wait for the FB
                window.fbAsyncInit = init;
            }

        }
    })
    .config(function(GpsProvider, RouteTrackerProvider, SynchronizerProvider, BackgroundProvider, MocksProvider)
    {
        //GPS Configuration
        GpsProvider
            .enableDeviceGPS() //Enable GPS Tracking
            //.autoStart() //Auto Start
            .accuracyThreshold(70) //Real GPS Aproximaty (aprox 65)
            .frequency(5000); //Try to get GPS Track each 5 seconds

        //Route Tracker Configuration
        // - Auto Pause: Minimun Distance (in Meters)
        //               Beetween Point's to Set Auto-Pause
        RouteTrackerProvider
            .autoPause(5);

        //Background Mode For still getting GPS in background
        BackgroundProvider
            .enable()
            .notifyText('MotoApp seguirá enviando las coordenadas del GPS');

        //Synchronizer Manager
        SynchronizerProvider
            .autoLoadSynchronizers() //Auto Load Synchronizer via Reflection
            .frequency(15000); //Frequency between sync process

        //Mocking Module (While the API is in Construction)
        //MocksProvider
        //.enable()
        //.setDelay(700); //Simulate a Short Delay ^^, (More 'Real' experience)

        //If is a Web Broser, add test route!
        if (!ionic.Platform.isWebView())
        {
            GpsProvider
                .frequency(700)
                .addTestRoute('bundles/mocks/js/gps/+250.json'); //Simulate a Route
        }

    })
    .config(function(
        GpsProvider,
        RouteTrackerProvider,
        MocksProvider,
        BackgroundProvider,
        SynchronizerProvider,
        ApplicationCleanseProvider,
        CONFIGURATION)
    {
        //Enable Debug for GPS and RouteTracker
        if (CONFIGURATION.debugging)
        {
            //Debugger Information
            RouteTrackerProvider.debug();
            GpsProvider.debug();
            MocksProvider.debug();
            BackgroundProvider.debug();
            SynchronizerProvider.debug();
            ApplicationCleanseProvider.debug();
        }

    })
    .config(function(uiGmapGoogleMapApiProvider, trackViewerProvider)
    {
        //Maps Configuration
        var googleKey = 'AIzaSyANyXwrXOkNgp9RPOAuebclIHLU2FWmPAA';
        uiGmapGoogleMapApiProvider.configure(
        {
            key: googleKey,
            libraries: 'visualization,geometry',
            sensor: false
        });

        //Track Viewer Config
        trackViewerProvider
            .googleMapApiKey(googleKey);
    })
    .config(function($ApiProvider, FileProvider, CONFIGURATION)
    {
        //API Base Endpoint
        var API_ENDPOINT = CONFIGURATION.API_EndPoint;
        var FILE_ENDPOINT = CONFIGURATION.API_EndPoint + "/Files/";

        $ApiProvider.setEndpoint(API_ENDPOINT);
        FileProvider.setEndpoint(FILE_ENDPOINT);
    })
    .config(function($IdentityProvider)
    {
        $IdentityProvider
            .enable() //Enable
            .setIssuerEndpoint("/Security/Authorize")
            .setLogInRoute("security/identity/login");

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
    .config(function($stateProvider, $urlRouterProvider, $ionicConfigProvider)
    {
        $ionicConfigProvider.views.swipeBackEnabled(false);
        //remaining code in config
    })
    .config(function($logProvider, CONFIGURATION)
    {
        $logProvider.debugEnabled(CONFIGURATION.debugging || false);
    });
