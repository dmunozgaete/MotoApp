angular.route('app.routes/view/map/:route', function(
    $scope,
    $state,
    $log,
    $Api,
    $stateParams,
    trackViewer,
    $q,
    $ionicHistory,
    $ionicLoading
)
{
    var defers = [];

    //---------------------------------------------------
    // Get Data
    defers.push(
        $Api.read("/Routes/{route}",
        {
            route: $stateParams.route
        })
    );

    //---------------------------------------------
    // trackViewer is a promise.
    // The "then" callback function provides the google.maps object.
    trackViewer.then(function(viewer, uniqueID)
    {
        $q.all(defers).then(function(resolves)
        {
            var route = resolves[0];

            //---------------------------------------------
            // Set Google Path
            var googleCoords = [];
            angular.forEach(route.coordinates, function(coord)
            {
                googleCoords.push(
                {
                    lat: coord.lat,
                    lng: coord.lng
                });
            });
            trackViewer.setPath(googleCoords);
            //---------------------------------------------

        });
    });

    //------------------------------------------------
    // Action's
    $scope.back = function()
    {
        $ionicHistory.goBack();
    };

});
