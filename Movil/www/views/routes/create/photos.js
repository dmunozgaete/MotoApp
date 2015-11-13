angular.route('nomenu.routes/create/photos', function(
    $scope,
    $state,
    $log,
    RouteTracker,
    $ionicHistory
)
{
    //----------------------------------------
    // Model
    $scope.items = [];

    var ordinal = 0;
    angular.forEach(RouteTracker.getResume().photos, function(photo)
    {
        $scope.items.push(
        {
            key: (new Date()).getTime(),
            photo: "data:image/jpg;base64," + photo,
            ordinal: ordinal
        });

        ordinal++;
    });



    //----------------------------------------
    // Action's
    $scope.removePicture = function(item) {

    };

    $scope.back = function()
    {

        $ionicHistory.goBack();

    };

    //Garbage Collector Destroy
    $scope.$on('$destroy', function()
    {
        $scope.images = [];
    });

});
