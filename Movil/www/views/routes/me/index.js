angular.route('app.routes/me/index', function(
    $scope,
    $state,
    $log,
    $Api,
    $filter,
    RouteSynchronizer,
    $timeout
)
{

    //---------------------------------------------------
    // Get Storage's Routes
    var pagination = null;
    var update = function()
    {
        pagination = RouteSynchronizer.paginate(3);
        pagination.then(function(items)
        {
            $scope.items = items;

            //Sync refresh
            $scope.$broadcast('scroll.refreshComplete');
        });
    }

    //Wait for a short delay until side menu , close.
    var delay = $timeout(function()
    {
        $timeout.cancel(delay);
        update();
    }, 1000);



    //------------------------------------------------
    // Action's
    $scope.doRefresh = update;

    $scope.nextPage = function()
    {
        pagination.nextPage().then(function(items)
        {
            $scope.items = $scope.items.concat(items);
            $scope.$broadcast('scroll.infiniteScrollComplete');
        });
    };
    $scope.hasNext = function()
    {
        return pagination.hasNext();
    };

    $scope.view = function(item)
    {
        $state.go("app.routes/view/index",
        {
            route: item.token
        });
    };

    $scope.create = function()
    {
        $state.go("app.home");
    };
    


});
