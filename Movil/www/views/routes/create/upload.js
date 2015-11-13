angular.route('nomenu.routes/create/upload/:share', function(
    $scope,
    $state,
    $log,
    $Api,
    $stateParams,
    trackViewer,
    RouteTracker,
    $q
)
{
    //---------------------------------------------
    // Model
    $scope.events = [];

    var defer = $q.defer();
    defer.promise.then(function()
    {
        $state.go("app.home");
    }, function(err, step)
    {
        //DO SOMETHING??
        $scope.error = {
            error: err,
            step: step
        };
    });

    var addEvent = function(event)
    {
        $scope.events.push(event);
    };

    var Share = function()
    {
        var route = $scope.route;

        addEvent("Compartiendo Ruta...");

        //---------------------------------------------
        // Send to the API , to create the Route
        $Api.create("/Routes/Share/{route}",
            {
                route: route.token,
                data:
                {
                    name: route.name,
                    observation: route.observation
                }
            })
            .success(function(data)
            {

                addEvent("Finalizando...");

                Photos();

            }).error(function(err)
            {
                defer.reject(err, 'Share');
            });
    };

    var Photos = function()
    {
        addEvent("Guardando Fotos...");

        var resume = RouteTracker.getResume();
        var route = $scope.route.token;

        var defers = [];

        angular.forEach(resume.photos, function(photo)
        {
            var defer_photo = $q.defer();

            $Api.create("/Routes/Photo/{route}",
                {
                    route: route,
                    image: {
                        photo: photo
                    }
                })
                .success(function(data)
                {

                    defer_photo.resolve()

                }).error(function(err)
                {
                    defer_photo.reject(err);
                });

            defers.push(defer_photo.promise);
        });

        $q.all(defers).then(function(resolvers)
        {
            defer.resolve();
        }, function(){
            defer.reject(err, 'Photos');
        });
    };

    var Save = function()
    {
        addEvent("Guardando Ruta...");

        $Api.create("/Routes", $scope.route)
            .success(function(data)
            {
                $scope.route.token = data.token;

                addEvent("Ruta Guardada...");


                if ($stateParams.share)
                {
                    Share();
                }
                else
                {
                    Photos();
                }

            }).error(function(err)
            {
                defer.reject(err, 'Save');
            });
    };

    addEvent("Preparando Ruta...");

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
            observation: resume.data.observation
        };

        $scope.route = route; //SAVE IF EXISTS ERROR

        //---------------------------------------------
        // Send to the API , to create the Route
        Save($scope.route);
    });


    //---------------------------------------------
    // Action's
    $scope.retry = function()
    {
        var last_error = $scope.error;

        $scope.events = ["Reintentando..."];

        switch (last_error.step)
        {
            case "Save":
                Save($scope.route);
                break;
            case "Share":
                Share();
                break;
            case "Photos":
                Photos();
                break;
        }
    }

});
