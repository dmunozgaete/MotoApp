angular.module('app.layouts').controller('DefaultLayoutController', function(
    $scope,
    $state,
    $log,
    $Configuration,
    $timeout
)
{
    //------------------------------------------------------------------------------------
    // Model
    $scope.config = {
        application: $Configuration.get("application"),
        menu:  [
        {
            route: "app.home",
            icon: "ion-ios-speedometer-outline",
            label: "Inicio",
            active: true
        },
        {
            route: "app.routes/list",
            icon: "ion-ios-location-outline",
            label: "Rutas"
        },
        {
            route: "app.profile",
            icon: "ion-ios-person-outline",
            label: "Mi Perfil"
        },
        {
            route: "app.notifications",
            icon: "ion-ios-bell-outline",
            label: "Notificaciones"
        }, ]
    };

    //------------------------------------------------------------------------------------
    // Layout Actions
    $scope.navigateTo = function(item)
    {
        //----------------------------------- 
        //Mark as Active
        angular.forEach($scope.config.menu, function(item)
        {
            item.active = false;
        });
        item.active = true;

        //-----------------------------------
        // Navigate
        $timeout(function()
        {
            $state.go(item.route);
        }, 300);
    };
});
