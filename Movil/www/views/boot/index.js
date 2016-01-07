angular.route('boot/index', function(
    $state,
    $log,
    $Configuration,
    $location,
    $LocalStorage,
    $q,
    Synchronizer,
    $Identity,
    Gps,
    $cordovaSplashscreen,
    ApplicationCleanse
)
{
    //Wait for Platform Ready
    ionic.Platform.ready(function()
    {

        var stamps = $Configuration.get("localstorageStamps");
        var new_version_defer = $q.defer();

        var onBooted = function()
        {
            Synchronizer.start().then(function()
            {
                // --------------------------------
                //FIRST TIME???, CONFIGURE!!
                if (!$LocalStorage.get(stamps.personal_data))
                {
                    $state.go("nomenu.firstRun/configure");
                    return;
                }
                // --------------------------------


                // --------------------------------
                // MANUAL BOOT
                Gps.start();

                //Extend Personal Data
                $Identity.extend("personal", $LocalStorage.getObject(stamps.personal_data));

                var url = $Configuration.get("application");
                $location.url(url.home);
                // --------------------------------
            });

        };

        //When all Process are Checked, run APP
        $q.all([
            new_version_defer.promise
        ]).then(onBooted, function(err)
        {

            $log.error(err);

        });


        // ---------------------------------------------------------
        // NEW VERSION SECTION! (ONLY WHEN NEW VERSION IS ACQUIRED)
        if ($LocalStorage.get(stamps.new_version))
        {

            ApplicationCleanse.clean(true).then(function()
            {
                new_version_defer.resolve();
            }, function(err)
            {
                new_version_defer.reject(err);
            });

            //Remove new Version Flag
            $LocalStorage.remove(stamps.new_version);

        }
        else
        {
            new_version_defer.resolve();
        }
        // ---------------------------------------------------------



        //Hide Splash Screen 
        if (ionic.Platform.isWebView())
        {
            $cordovaSplashscreen.hide();
        }
    });

});
