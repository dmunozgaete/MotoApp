angular.route('nomenu.routes/create/gps', function(
    $scope,
    $state,
    $log,
    $Api,
    routeTracker
)
{
    //---------------------------------------------
    // Route Change
    var onRouteChange = function(newCoord)
    {
        //---------------
        if (!$scope.items)
        {
            $scope.items = [];
        }

        //---------------
        $scope.items.splice(0, 0, newCoord)
    };


    var addPointListener = routeTracker.$on("route.addTrackPoint", onRouteChange);
    var autoPausedListener = routeTracker.$on("route.autoPaused", function(){
        $state.go("nomenu.routes/create/pause");
    });
    $scope.$on("$destroy", function()
    {
        //Destroy Listener 
        addPointListener();
        autoPausedListener();
        
    });

    //----------------------------------------
    // Action's
    $scope.back = function()
    {
        $state.go("nomenu.routes/create/map");
    };

});
