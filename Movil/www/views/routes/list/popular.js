angular.module('app.components')

.directive('popularRoutes', function()
{
    return {
        restrict: 'E',
        scope:
        {},
        templateUrl: 'views/routes/list/popular.html',
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
                $Api.read("/Routes/Popular").success(function(data)
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

        }
    };
});
