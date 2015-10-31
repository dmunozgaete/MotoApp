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
            $Api
        )
        {

            //---------------------------------------------------
            // Update Data
            var update = function(callback)
            {
                $Api.read("/Routes/Me").success(function(data)
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

        },

        link: function(scope, element, attrs, ctrl) {

        }
    };
});
