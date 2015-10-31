angular.module('app.services')

.factory('$GeoLocation', function(
    $log,
    $rootScope,
    $cordovaGeolocation,
    $q
)
{
    var geo_options = {
        timeout: 20000,
        enableHighAccuracy: true
    };
    
    var last_coordinates = {
        latitude: 0,
        longitude: 0
    };
    var watch = null;

    var updateLocation = function(location)
    {
        if (location.coords.latitude != 0 && location.coords.longitude != 0)
        {
            last_coordinates = {
                latitude: location.coords.latitude,
                longitude: location.coords.longitude
            };

            $log.info("[GeoLocation Update:] " + angular.toJson(last_coordinates));
            $rootScope.$broadcast('geolocation.update', last_coordinates);
        }
    }

    var onFailureLocation = function(error)
    {
        $log.error(error);
    }


    var getCurrentPosition = function()
    {
        var deferred = $q.defer();

        $cordovaGeolocation.getCurrentPosition(geo_options).then(
            function(position)
            {
                updateLocation(position);
                deferred.resolve(position);
            },
            function(error)
            {
                onFailureLocation(error);
                deferred.reject(error);
            }
        );

        return deferred.promise;

    }

    var startWatch = function()
    {
        //WATCH POSITION
        navigator.geolocation.watchPosition(updateLocation, onFailureLocation, geo_options);

        //GET POSITION RIGHT NOW!!!
        getCurrentPosition();
    }

    var clearWatch = function()
    {
        if (watch)
        {
            watch.clearWatch();
        }
    };

    var getLastCoordinates = function()
    {
        return last_coordinates;
    };

    if (ionic.Platform.isWebView())
    {
        document.addEventListener("deviceready", function()
        {
            startWatch();
        });
    }
    else
    {
        startWatch();
    }

    return {
        clearWatch: clearWatch,
        startWatch: startWatch,
        getLastCoordinates: getLastCoordinates,
        getCurrentPosition: getCurrentPosition
    }

});
