angular.route('nomenu.routes/create/upload/:share', function(
    $scope,
    $state,
    $log,
    $Api,
    $stateParams,
    trackViewer,
    RouteTracker,
    PendingRouteSynchronizer,
    $q
)
{
    //---------------------------------------------
    // Model
    $scope.currentEvent = "";

    //WE NEED THE GOOGLE MAPS GEOMETRY LIBRARY (NOT UI, JUST LIBRARY)
    trackViewer.then(function(component)
    {
        //---------------------------------------------
        // Resume Tracker
        var resume = RouteTracker.getResume();

        //---------------------------------------------
        // Parse the GeoCoord to Google Coord  {lat,lng}
        // And add the complete information
        var coords = []
        angular.forEach(resume.coords, function(geoCoord)
        {
            //Get Complete Geo Coordinate
            coords.push(
            {
                lat: geoCoord.coords.latitude,
                lng: geoCoord.coords.longitude,
                altitude: geoCoord.coords.altitude,
                speed: geoCoord.speed,
                distance: geoCoord.distance,
                duration: geoCoord.duration,
                createdAt: new Date(geoCoord.timestamp)
            });

        });

        //---------------------------------------------
        // Build a Google Static Maps
        var googleImageURL = trackViewer.getImage(
        {
            path: coords
        });

        //---------------------------------------------
        // Get the current Center for the route
        var bounds = trackViewer.getBounds(coords);
        var center = bounds.getCenter();

        //---------------------------------------------
        // Re-organize the data =)
        var route = {
            start: resume.startAt,
            end: resume.stopAt,
            duration: resume.seconds,
            pauses: resume.pauses,
            distance: resume.distance,
            speed: resume.speed,
            calories: resume.calories,
            sensation: resume.data.sensation,
            lat: center.lat(),
            lng: center.lng(),
            altitude: resume.altitude,
            image: googleImageURL,
            coordinates: coords,
            name: resume.data.name,
            observation: resume.data.observation,
            isShared: ($stateParams.share == "1" ? true : false),
            photos: resume.photos
        };

        //---------------------------------------------
        // Send to the API , to create the Route
        PendingRouteSynchronizer.upload(route).notify(function(event)
        {

            //Add Event notification
            $scope.currentEvent = event;

        }).then(function()
        {
            //ALL IT'S OK!
            $state.go("app.home");

        }, function()
        {
            //SAVE IN PENDING
            $state.go("nomenu.routes/create/saveForLater");

        })
    });

});
