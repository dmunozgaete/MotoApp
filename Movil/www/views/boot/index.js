angular.route('boot/index', function(
    $scope,
    $state,
    $log,
    $Api,
    $Configuration,
    $location
)
{
    //---------------------------------------------------
    // Get Data
    $Api.read("/Configuration/State").success(function(data)
    {
        if (data.state == "sync")
        {
            var url = $Configuration.get("application");
            $location.url(url.home);
        }
        
    });

});
