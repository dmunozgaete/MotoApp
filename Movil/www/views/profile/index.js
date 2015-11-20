angular.route('app.profile/index', function(
    $scope,
    $state,
    $log,
    $Api,
    $Identity,
    $LocalStorage
)
{

    //---------------------------------------------------
    // Get Data
    $Api.read("/Accounts/Me").success(function(data)
    {
        //Set Profile
        $scope.profile = data;

    });


    //------------------------------------------------
    // Action's
    $scope.logOut = function()
    {
        $LocalStorage.clear();
        $Identity.logOut();
    };

});
