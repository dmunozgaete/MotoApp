angular.route('app.routes/view/index/:route', function(
    $scope,
    $state,
    $log,
    $Api,
    $stateParams,
    trackViewer,
    $q,
    $ionicHistory,
    Rewards
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


    $q.all(defers).then(function(resolves)
    {
        var route = resolves[0];

        //---------------------------------------------
        // trackViewer is a promise.
        // The "then" callback function provides the google.maps object.
        trackViewer.then(function(viewer, uniqueID)
        {

            //---------------
            var googleCoords = [];
            angular.forEach(route.coordinates, function(coord)
            {
                googleCoords.push(
                {
                    lat: coord.lat,
                    lng: coord.lng
                });
            });
            //---------------
            trackViewer.setPath(googleCoords);

        });

        //---------------------------------------------
        // Set Detail's
        var details = route.details;
        details.photos = route.photos;
        details.social = route.social;

        $scope.data = details;
    });

    //------------------------------------------------
    // Action's
    $scope.back = function()
    {
        $state.go("app.routes/list");
    };

    $scope.like = function()
    {
        var data = $scope.data;

        if (data.social.like)
        {
            //Unlike
            $Api.delete("/Routes/{route}/Unlike",
            {
                route: data.token
            }).then(function()
            {

                data.social.like = false;
            });

        }
        else
        {
            //Like
            $Api.create("/Routes/{route}/Like",
            {
                route: data.token
            }).then(function()
            {
                Rewards.check('ROUTES');
                data.social.like = true;
            });

        }
        data.social.like = null; //Set "meanwhile" value
    };

    $scope.photos = function()
    {
        $state.go("app.routes/view/photos",
        {
            route: $stateParams.route
        });
    };


});
