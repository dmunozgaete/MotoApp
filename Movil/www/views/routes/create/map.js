angular.route('nomenu.routes/create/map', function(
    $scope,
    $state,
    $log,
    $Api,
    trackViewer,
    routeTracker
)
{
    var onRouteChange = function(newPoint)
    {
        //---------------
        trackViewer.addToPath(
        {
            lat: newPoint.coords.latitude,
            lng: newPoint.coords.longitude
        });
        //---------------
    };

    //---------------------------------------------
    // trackViewer is a promise.
    // The "then" callback function provides the google.maps object.
    trackViewer.then(function(viewer, uniqueID)
    {
        //---------------
        //Build Current Path
        var resume = routeTracker.getResume();

        var googleCoords = [];
        angular.forEach(resume.coords, function(point)
        {
            googleCoords.push(
            {
                lat: point.coords.latitude,
                lng: point.coords.longitude
            });
        });
        if (googleCoords.length > 0)
        {
            trackViewer.setPath(googleCoords);
        }
        //---------------

    });

    var addPointListener = routeTracker.$on("route.addTrackPoint", onRouteChange);
    $scope.$on("$destroy", function()
    {
        //Destroy Listener 
        addPointListener();
    });

    //----------------------------------------
    // Action's
    $scope.back = function()
    {
        //Check State to navigate
        var resume = routeTracker.getResume();

        //AUTO_PAUSE == 4
        if (resume.state == 4)
        {
            $state.go("nomenu.routes/create/pause",
            {
                autopause: true
            });
        }
        else
        {
            $state.go("nomenu.routes/create/index");
        }

    };


});
