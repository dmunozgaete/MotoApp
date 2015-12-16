angular.route('boot/index', function(
    $scope,
    $state,
    $log,
    $Api,
    $Configuration,
    $location,
    $LocalStorage,
    pouchDB,
    $q,
    Synchronizer,
    $Identity,
    $cordovaBadge,
    $cordovaSplashscreen
)
{
    //Hide Splash Screen 
    if (ionic.Platform.isWebView())
    {
        $cordovaSplashscreen.hide();
    }

    //INITIALIZE THE SYNCRONIZER MANAGER
    var defer = Synchronizer.start();

    //When all Process are Checked, run APP
    $q.all([defer]).then(function()
    {
        //Get if user is the first time!!
        var label = $Configuration.get("localstorageStamps").personal_data;
        var isFirstTime = $LocalStorage.get(label) == null;
        if (isFirstTime)
        {
            $state.go("nomenu.firstRun/configuration/step-1");
            return;
        }
        else
        {
            //Extend Personal Data
            $Identity.extend("personal", $LocalStorage.getObject(label));
        }


        var url = $Configuration.get("application");
        $location.url(url.home);
    });

    //ONLY IN DEVICE
    if (ionic.Platform.isWebView())
    {
        //PROMOT FOR NOTIFICATION ACCESS
        $cordovaBadge.hasPermission().then(function() {}, function()
        {
            //ASK FOR PERMISSION
            window.plugin.notification.local.promptForPermission();
        });
    }
});
