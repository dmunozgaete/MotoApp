angular.route('nomenu.routes/create/stop', function(
    $scope,
    $state,
    $log,
    $Api,
    $interval,
    RouteTracker,
    $ionicLoading,
    $cordovaDialogs,
    Camera
)
{
    //---------------------------------------------
    // Model
    $scope.model = {};

    //---------------------------------------------
    // Resume Tracker
    $scope.resume = RouteTracker.getResume();


    //----------------------------------------
    // Action's
    $scope.discard = function()
    {

        $cordovaDialogs
            .confirm(
                '¿Estás seguro de descartar la ruta?',
                'Descartar Ruta', [
                    'Cancelar',
                    'Descartar'
                ])
            .then(function(buttonIndex)
            {
                if (buttonIndex == 2)
                {
                    $state.go("app.home");
                }
            });

    };

    $scope.save = function()
    {
        $state.go("nomenu.routes/create/resume");
    };

    $scope.takePicture = function()
    {
        Camera.takePicture().then(function(image)
        {

            //Save Picture in Temporal DB
            RouteTracker.addPhoto(image);

        }, function(err)
        {

            $ionicLoading.show(
            {
                template: 'No se pudo tomar la foto',
                duration: 3000
            });
            $log.error(err);

        });
    };

});
