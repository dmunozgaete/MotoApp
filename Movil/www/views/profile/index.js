angular.route('app.profile/index', function(
    $scope,
    $state,
    $log,
    $Api,
    $Identity
)
{

    //---------------------------------------------------
    // Get Data
    $Api.read("/Profile").success(function(data)
    {
        //Set Profile
        $scope.profile = data;

    });


    //------------------------------------------------
    // Action's
    $scope.logOut = function()
    {
        $Identity.logOut();
    };

});
