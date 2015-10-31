angular.route('app.notifications/index', function(
    $scope,
    $state,
    $log,
    $Api
)
{

    //---------------------------------------------------
    // Update Data
    var update = function(callback)
    {
        $Api.read("/Notifications").success(function(data)
        {
            //Set Items to List
            $scope.items = data.items;
            if (callback)
            {
                callback();
            }
        });
    }
    update();

    //------------------------------------------------
    // Action's
    $scope.doRefresh = function()
    {
        update(function()
        {
            $scope.$broadcast('scroll.refreshComplete');
        })
    };


});
