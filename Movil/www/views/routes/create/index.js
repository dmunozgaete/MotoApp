angular.route('nomenu.routes/create/index', function(
    $scope,
    $state,
    $log,
    $Api
)
{
 

	//----------------------------------------
    // Action's
    $scope.pause = function()
    {
        $state.go("nomenu.routes/create/pause");
    };

    $scope.map = function()
    {
        $state.go("nomenu.routes/create/map");
    };

});
