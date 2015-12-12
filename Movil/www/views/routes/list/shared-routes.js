angular.module('app.components')

.directive('sharedRoutes', function()
{
    return {
        restrict: 'E',
        scope:
        {},
        templateUrl: 'views/routes/list/shared-routes.html',
        controller: function(
            $scope,
            $element,
            $log,
            RouteSynchronizer,
            $state
        )
        {

            //------------------------------------------------------------------------------------
            // Get Storage's Notificatons
            var update = function()
            {
                RouteSynchronizer.getShared().then(function(items)
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
            $scope.view = function(item)
            {
                $state.go("app.routes/view/index",
                {
                    route: item.token
                });
            };
            
            $scope.doRefresh = update;

        }
    };
});
