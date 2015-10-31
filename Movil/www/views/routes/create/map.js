angular.route('nomenu.routes/create/map', function(
    $scope,
    $state,
    $log,
    $Api,
    trackViewer,
    $http
)
{

    //---------------------------------------------
    // trackViewer is a promise.
    // The "then" callback function provides the google.maps object.
    trackViewer.then(function(viewer, uniqueID)
    {

        $http.get('bundles/mocks/js/gps/+150.json').success(function(data)
        {

            //---------------
            var googleCoords = [];
            angular.forEach(data, function(coord)
            {
                googleCoords.push(
                {
                    lat: coord[1],
                    lng: coord[0]
                });
            });

            viewer.setPath(googleCoords);
            //---------------
        });

    });

    //----------------------------------------
    // Action's
    $scope.back = function()
    {
        $state.go("nomenu.routes/create");
    };


});
