angular.route('nomenu.routes/create/saveForLater', function(
    $scope,
    $state,
    $log
)
{
    
    //----------------------------------------
    // Action's
    $scope.continue = function()
    {

        $state.go("app.home");

    };

});
