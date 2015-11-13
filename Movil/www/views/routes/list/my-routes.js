angular.module('app.components')

.directive('myRoutes', function()
{
    return {
        restrict: 'E',
        scope:
        {},
        templateUrl: 'views/routes/list/my-routes.html',
        controller: function(
            $scope,
            $element,
            $log,
            RouteSynchronizer
        )
        {

            //------------------------------------------------------------------------------------
            // Get Storage's Notificatons
            var update = function()
            {
                RouteSynchronizer.getLocals().then(function(items)
                {
                    $scope.items = items;

                    //Sync refresh
                    $scope.$broadcast('scroll.refreshComplete');
                });
            }
            update();


            var listener = RouteSynchronizer.$on("routes.new-routes", update);
            $scope.$on("$destroy", function()
            {
                //Destroy Listener's
                listener(); //Destroy Function
            });


            //------------------------------------------------
            // Action's
            $scope.doRefresh = update;

        }
    };
});
