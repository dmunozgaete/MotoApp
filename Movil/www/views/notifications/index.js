angular.route('app.notifications/index', function(
    $scope,
    $state,
    $log,
    NotificationSynchronizer,
    $cordovaBadge
)
{
    //------------------------------------------------------------------------------------
    // Get Storage's Notificatons
    var pagination = null;
    var update = function()
    {
        pagination = NotificationSynchronizer.paginate(10);
        pagination.then(function(items)
        {
            $scope.items = items;

            //Sync refresh
            $scope.$broadcast('scroll.refreshComplete');
        });
    }
    update();

    //Mark All as readed :P
    NotificationSynchronizer.markAllAsReaded();

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


});
