angular.route('nomenu.routes/create/resume', function(
    $scope,
    $state,
    $log,
    $Api,
    trackViewer,
    $http,
    RouteTracker,
    $Configuration,
    $stateParams,
    $cordovaSocialSharing,
    $cordovaFacebook,
    $q,
    $ionicLoading,
    $Identity,
    ShareDialog
)
{
    //---------------------------------------------
    // Model
    $scope.user = $Identity.getCurrent();
    $scope.route = {};
    $scope.resume = RouteTracker.getResume();

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

        //---------------
        // PAINT THE STATIC MAP IMAGE 
        var googleCoords = [];
        angular.forEach($scope.resume.coords, function(point)
        {
            googleCoords.push(
            {
                lat: point.coords.latitude,
                lng: point.coords.longitude
            });
        });
        if (googleCoords.length > 0)
        {
            trackViewer.setPath(googleCoords, function()
            {
                //Try to get a Route Name
                if (hasRouteName())
                {
                    geoCodeRoute(viewer.getTrackData());
                }

            });
        }

    });

    var prepareSharing = function()
    {
        var defer = $q.defer();

        var imageDefer = $q.defer();
        var prepareImage = function()
        {

            var rawUrl = trackViewer.getImage(
            {
                map:
                {
                    width: 1200,
                    height: 1200
                },
                polyline:
                {
                    hex: "ffc107",
                    alpha: "FF",
                    weight: 5
                },
                path: trackViewer.getInstance().getTrackData().coords
            });

            var img = new Image();
            img.crossOrigin = 'Anonymous';
            img.onload = function()
            {
                var canvas = document.createElement('CANVAS');
                var ctx = canvas.getContext('2d');
                var dataURL;
                canvas.height = this.height;
                canvas.width = this.width;
                ctx.drawImage(this, 0, 0);
                dataURL = canvas.toDataURL("image/png");

                imageDefer.resolve(
                {
                    url: rawUrl,
                    dataURL: dataURL
                });

                canvas = null;
            };
            img.onerror = function(err)
            {
                imageDefer.reject(err);
            }
            img.src = rawUrl;
        }

        var urlDefer = $q.defer();
        var prepareURL = function()
        {
            urlDefer.resolve($Configuration.get("GetTheAppUrl"));
        }

        prepareImage();
        prepareURL();

        $q.all([imageDefer.promise, urlDefer.promise]).then(function(resolves)
        {

            var image = resolves[0];
            var url = resolves[1];

            defer.resolve(
            {
                image: image,
                url: url,
                message: "MotoApp: Revisa mi ruta! " + url
            })
        }, function(err)
        {
            defer.reject(err);
        });

        return defer.promise;
    };

    //---------------------------------------------
    // Action's
    $scope.shareRoute = function(route)
    {
        if (route.isShared)
        {
            ShareDialog.share(route).then(function(shareData)
            {
                route.name = shareData.name;
            }, function()
            {
                route.isShared = 0;
            });
        }

    };

    $scope.share = function(type)
    {
        $ionicLoading.show(
        {
            template: 'Preparando...'
        });

        var share = null;
        switch (type)
        {
            case 'facebook':

                share = function(data)
                {
                    var defer = $q.defer();

                    window.plugins.socialsharing.shareViaFacebookWithPasteMessageHint(
                        data.message,
                        data.image.dataURL,
                        null /* url */ ,
                        'si quieres puedes pegar lo que dejamos en el portapapeles (pegar)' /*'Paste it dude!'*/ ,
                        defer.resolve,
                        defer.reject
                    );

                    /*
                    var options = {
                        method: 'feed',
                        caption: data.message,
                        image: data.image.url
                    };
                    return $cordovaFacebook.showDialog(options);
                    */

                    return defer.promise;
                };
                break;
            case 'twitter':
                share = function(data)
                {
                    return $cordovaSocialSharing
                        .shareViaTwitter(data.message, data.image.dataURL);
                };
                break;
            case 'instagram':
                share = function(data)
                {

                    return $cordovaSocialSharing
                        .share(data.message, "MotoApp", data.image.dataURL, null); // Share via native share sheet

                    //return $cordovaInstagram
                    //  .share(data.image, data.message);
                };
                break;
        }


        prepareSharing().then(function(data)
        {
            var onError = function(err)
            {
                $log.error("Can't Share ", type, arguments);
                $ionicLoading.hide();
            };

            try
            {
                var promise = share(data);
                if (promise)
                {
                    promise.then(function(result)
                    {
                        $ionicLoading.hide();
                        // Success!
                    }, onError);
                }
            }
            catch (err)
            {
                onError(err);
            }

        });
    };

    $scope.showGallery = function()
    {
        $state.go("nomenu.routes/create/photos");
    };

    $scope.save = function(route)
    {
        RouteTracker.setData(route);
        $state.go("nomenu.routes/create/upload",
        {
            share: (route.isShared ? 1 : 0)
        });
    };

});
