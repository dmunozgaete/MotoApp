angular.route('nomenu.routes/create/share', function(
    $scope,
    $state,
    $log,
    $Api,
    trackViewer,
    $http
)
{
    //---------------------------------------------
    // Model
    $scope.route = {};

    //---------------------------------------------
    // Check if has Route Name 
    var hasRouteName = function()
    {
        var routeName = $scope.route.name;
        if (!routeName || (routeName && routeName.length === 0))
        {
            return true;
        }
        return false;
    };

    //---------------------------------------------
    // Reverse Geocoding , to indicate some Route Name via GOOGLE API
    var geoCodeRoute = function(trackData)
    {
        var geocoder = new google.maps.Geocoder;
        geocoder.geocode(
        {
            location: trackData.center,
            language: 'es'
        }, function(results, status)
        {
            if (hasRouteName())
            {
                if (status === google.maps.GeocoderStatus.OK)
                {
                    if (results[0])
                    {
                        $scope.route.name = results[0].formatted_address;
                    }
                }
                else
                {
                    console.log('Geocoder failed due to: ' + status);
                }
            }
        });
    };

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

            viewer.setPath(googleCoords, function()
            {
                //Try to get a Route Name
                if (hasRouteName())
                {
                    geoCodeRoute(viewer.getTrackData());
                }

            });
            //---------------
        });

    });

    //---------------------------------------------
    // Action's
    $scope.save = function()
    {

        $state.go("app.home");
    };

});
