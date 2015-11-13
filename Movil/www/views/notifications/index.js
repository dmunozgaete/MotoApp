angular.route('app.notifications/index', function(
    $scope,
    $state,
    $log,
    NotificationSynchronizer
)
{
    //------------------------------------------------------------------------------------
    // Get Storage's Notificatons
    var update = function()
    {
        NotificationSynchronizer.getItems().then(function(items)
        {
            $scope.items = items;
            
            //Sync refresh
            $scope.$broadcast('scroll.refreshComplete');
        });
    }
    update();


    var listener = NotificationSynchronizer.$on("notifications.update-counter", update);
    $scope.$on("$destroy", function()
    {
        //Destroy Listener's
        listener(); //Destroy Function
    });


    //------------------------------------------------
    // Action's
    $scope.doRefresh = update;


});
