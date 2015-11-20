angular.route('nomenu.routes/create/index/:autostart', function(
    $scope,
    $state,
    $log,
    $Api,
    RouteTracker,
    $stateParams,
    $ionicLoading,
    $ionicHistory,
    Camera
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

    var resumeListener = RouteTracker.$on("route.resumeChanged", updateCounters);
    var autoPausedListener = RouteTracker.$on("route.autoPaused", function()
    {

        var view = $ionicHistory.currentView();
        if (view.stateId == "nomenu.routes/create/gps")
        {
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
        $ionicLoading.show(
        {
            template: 'Se ha reanudado la ruta',
            duration: 3000
        });
    }

    //----------------------------------------
    // Action's
    $scope.pause = function()
    {
        RouteTracker.pause();
        $ionicLoading.hide();
        $state.go("nomenu.routes/create/pause");
    };

    $scope.map = function()
    {
        $ionicLoading.hide();
        $state.go("nomenu.routes/create/map");
    };

    $scope.takePicture = function()
    {
        Camera.takePicture().then(function(image)
        {

            //Save Picture in Temporal DB
            RouteTracker.addPhoto(image);

        }, function(err)
        {

            $ionicLoading.show(
            {
                template: 'No se pudo tomar la foto',
                duration: 3000
            });
            $log.error(err);

        });
    };

});
