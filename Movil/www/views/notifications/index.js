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
    var update = function()
    {
        NotificationSynchronizer.getItems().then(function(items)
        {
            $scope.items = items;

            //Sync refresh
            $scope.$broadcast('scroll.refreshComplete');
        });



        //ONLY IN DEVICE
        if (ionic.Platform.isWebView())
        {

            //WHEN PLATFORM IS READY!
            ionic.Platform.ready(function()
            {
                //HAS PERMISSION TO PUT BADGE??
                $cordovaBadge.hasPermission().then(function()
                {
                    //RESET BADGE COUNTER
                    $cordovaBadge.clear();

                });
            });
        }


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
