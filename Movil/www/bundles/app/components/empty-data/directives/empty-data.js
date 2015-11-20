angular.module('app.components')

.directive('emptyData', function()
{
    return {
        restrict: 'E',
        scope:
        {
            title: '@', // Title While loading
            legend: '@' // Legend While loading
        },
        templateUrl: 'bundles/app/components/empty-data/empty-data.tpl.html',
        controller: function(
            $scope,
            $element
        )
        {
            $scope.title = ($scope.title || "Lo sentimos =(");
            $scope.legend = ($scope.legend || "No tenemos nada que mostrar...");
        }
    };
});
