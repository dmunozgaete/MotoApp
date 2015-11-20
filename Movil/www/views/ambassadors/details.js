angular.route('app.ambassadors/details/:account', function(
    $scope,
    $state,
    $log,
    $Api,
    $stateParams,
    $ionicHistory
)
{

    //---------------------------------------------------
    // Get Data
    $Api.read("/Accounts/{account}",
    {
        account: $stateParams.account
    }).success(function(data)
    {
        //Set Profile
        $scope.profile = data;
        $log.debug(data);
    });

    //------------------------------------------------
    // Action's
    $scope.back = function()
    {
        history.back();
    };




});
