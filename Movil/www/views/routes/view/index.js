angular.route('app.routes/view/index/:route', function(
    $scope,
    $state,
    $log,
    $Api,
    $stateParams,
    trackViewer,
    $q,
    $ionicHistory,
    $ionicLoading,
    Rewards,
    $cordovaDialogs,
    $filter,
    $Identity,
    RouteSynchronizer
)
{
    var user = $Identity.getCurrent();
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

        //---------------------------------------------
        // Set Detail's
        var details = route.details;
        details.photos = route.photos;
        details.social = route.social;

        //Add the Creator File URL
        details.creator.photo = $filter("restricted")(details.creator.photo);
        angular.forEach(details.photos, function(item)
        {
            item.photo = $filter("restricted")(item.photo);
        });
        $scope.data = details;
        //---------------------------------------------
    });

    //------------------------------------------------
    // Action's
    $scope.canDelete = function(data)
    {
        if (data)
        {
            return data.creator.token == user.primarysid;
        }
        return false;
    };

    $scope.back = function()
    {

        $ionicHistory.goBack();
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
                data.social.totalLikes -= 1;
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
                data.social.totalLikes += 1;
            });

        }
        data.social.like = null; //Set "meanwhile" value
    };

    $scope.showGallery = function()
    {
        $state.go("app.routes/view/photos",
        {
            route: $stateParams.route
        });
    };

    $scope.showFullImage = function(item)
    {
        var defer = $q.defer();

        $ionicLoading.show(
        {
            template: 'Cargando Imagen...',
            duration: 3000
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

            dataURL = dataURL.replace("data:image/png;base64,", "");
            defer.resolve(dataURL);

            canvas = null;
        };
        img.onerror = function(err)
        {
            defer.reject(err);
        }
        img.src = item.photo;

        //Show Image Dialog
        defer.promise.then(function(base64)
        {
            $ionicLoading.hide();
            FullScreenImage.showImageBase64(
                base64,
                "MotoApp",
                "png"
            );

        }, function()
        {
            $ionicLoading.hide();
        });
    };

    $scope.showMap = function()
    {
        $state.go("app.routes/view/map",
        {
            route: $stateParams.route
        });
    };

    $scope.delete = function(data)
    {

        $cordovaDialogs
            .confirm(
                '¿Estás seguro de eliminar la ruta?',
                'Eliminar Ruta', [
                    'Cancelar',
                    'Eliminar'
                ])
            .then(function(buttonIndex)
            {
                if (buttonIndex == 2)
                {
                    $ionicLoading.show(
                    {
                        template: 'Eliminando Ruta...'
                    });

                    //Unlike
                    $Api.delete("/Routes/{route}",
                        {
                            route: data.token
                        })
                        .then(function()
                        {
                            //-------------------
                            //Go back or FORCE RELOAD
                            var backView = $ionicHistory.backView();
                            if (backView.stateName.indexOf("app.routes/") >= 0)
                            {

                                //NOW REMOVE THE ROUTE IF HIS LOCAL FROM THE DB
                                RouteSynchronizer.remove(data.token).then(function(res)
                                {

                                    //Force To Reload
                                    $state.go(backView.stateName,
                                    {},
                                    {
                                        reload: true
                                    });

                                });
                            }
                            else
                            {
                                $scope.back();
                            }
                            //-------------------

                        })
                        .finally(function()
                        {
                            $ionicLoading.hide();
                        });
                }
            });


        return false;
    };

});
