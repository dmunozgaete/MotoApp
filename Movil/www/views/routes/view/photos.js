angular.route('app.routes/view/photos/:route', function(
    $scope,
    $state,
    $log,
    $ionicHistory,
    $Api,
    $stateParams,
    $q,
    $filter,
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


    $q.all(defers).then(function(resolves)
    {
        var route = resolves[0];

        var photos = [];
        angular.forEach(route.photos, function(photo)
        {
            photos.push(photo);
        });

        $scope.items = photos;

    });



    //----------------------------------------
    // Action's
    $scope.back = function()
    {
        $ionicHistory.goBack();
    };

    $scope.showFullImage = function(item)
    {
        var defer = $q.defer();
        var src = $filter('restricted')(item.photo);

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
        img.src = src;

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

    //Garbage Collector Destroy
    $scope.$on('$destroy', function()
    {
        $scope.images = [];
    });

});
