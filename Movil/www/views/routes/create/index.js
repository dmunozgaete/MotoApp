angular.route('nomenu.routes/create/index/:autostart', function(
    $scope,
    $state,
    $log,
    $Api,
    routeTracker,
    $stateParams,
    ionicToast,
    $ionicHistory
)
{

    //---------------------------------------------
    // Resume 
    var updateCounters = function(resume)
    {
        //---------------
        $scope.resume = resume;
        //---------------
    };

    var resumeListener = routeTracker.$on("route.resumeChanged", updateCounters);
    var autoPausedListener = routeTracker.$on("route.autoPaused", function()
    {
    
        var view  = $ionicHistory.currentView();
        if(view.stateId == "nomenu.routes/create/gps"){
            //Do Nothing, because is the tracker Log
            return;
        }

        $state.go("nomenu.routes/create/pause",
        {
            autopause: true
        });
    });

    $scope.$on("$destroy", function()
    {
        //Destroy Listener 
        resumeListener();
        autoPausedListener();

    });

    //----------------------------------------
    //Launch from Auto-Start
    if ($stateParams.autostart)
    {
        ionicToast.show("Se ha reanudado la ruta", 'top', true, 5000);
    }

    //----------------------------------------
    // Action's
    $scope.pause = function()
    {
        routeTracker.pause();
        $state.go("nomenu.routes/create/pause");
    };

    $scope.map = function()
    {
        $state.go("nomenu.routes/create/map");
    };

});
