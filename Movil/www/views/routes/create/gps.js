angular.route('nomenu.routes/create/gps', function(
    $scope,
    $state,
    $log,
    $Api,
    RouteTracker,
    Gps
)
{
    //---------------------------------------------
    // Get Items
    var getItems = function()
    {
        if (!$scope.items)
        {
            $scope.items = [];
        }
        return $scope.items;
    };

    //---------------------------------------------
    // Route Change
    var onRouteChange = function(newCoord)
    {
        getItems().splice(0, 0, newCoord)
    };
    var eventTracker = function(eventType)
    {
        return function()
        {
            var event = {
                type: eventType,
                timestamp: ((new Date()).getTime())
            };
            getItems().splice(0, 0, event);
        };
    };

    //Tracker Listener && GPs Listener's
    var listeners = [];
    listeners.push(RouteTracker.$on("route.addTrackPoint", onRouteChange));

    listeners.push(Gps.$on("gps.pointDiscarded", eventTracker('gps-discard-point')));
    listeners.push(Gps.$on("gps.error", eventTracker('gps-timeout-error')));

    //Event Listener's
    listeners.push(RouteTracker.$on("route.autoStart", eventTracker('route-autostart')));
    listeners.push(RouteTracker.$on("route.started", eventTracker('route-started')));
    listeners.push(RouteTracker.$on("route.paused", eventTracker('route-paused')));
    listeners.push(RouteTracker.$on("route.stopped", eventTracker('route-stopped')));
    listeners.push(RouteTracker.$on("route.autoPaused", eventTracker('route-autopause')));
    listeners.push(RouteTracker.$on("route.tooClosePoint", eventTracker('route-closepoint')));

    $scope.$on("$destroy", function()
    {
        //Destroy Listener's
        angular.forEach(listeners, function(listener)
        {
            listener(); //Destroy Function
        });
    });

    //----------------------------------------
    // Action's
    $scope.back = function()
    {
        $state.go("nomenu.routes/create/map");
    };

});
