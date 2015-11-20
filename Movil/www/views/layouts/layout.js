angular.module('app.layouts').controller('DefaultLayoutController', function(
    $scope,
    $state,
    $log,
    $Configuration,
    $Identity,
    NotificationSynchronizer,
    $cordovaBadge,
    $cordovaLocalNotification
)
{

    //------------------------------------------------------------------------------------
    // Model
    $scope.config = {
        application: $Configuration.get("application"),
        user: $Identity.getCurrent(),
        notifications: 0,
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
            route: "app.ambassadors",
            icon: "ion-ios-people-outline",
            label: "Embajadores"
        },
        {
            route: "app.notifications",
            icon: "ion-ios-bell-outline",
            label: "Notificaciones"
        }, ]
    };

    //------------------------------------------------------------------------------------
    // Get Storage's Notificatons (Not seen yet)
    var updateCounter = function(newCounter)
    {
        $scope.config.notifications = newCounter;

        if (newCounter > 0)
        {

            //ONLY IN DEVICE
            if (ionic.Platform.isWebView())
            {
                //WHEN PLATFORM IS READY!
                ionic.Platform.ready(function()
                {


                    //SET NEW COUNTER
                    $cordovaBadge.set(newCounter).then(function()
                    {

                        //SEND NEW NOTIFICATION'S
                        $cordovaLocalNotification.schedule(
                        {
                            id: (new Date().getTime()),
                            title: 'Tienes Nuevas Notificaciones',
                            text: 'Tienes {0} notificaciones sin leer'.format([newCounter]),
                            data:
                            {
                                type: 'NEW_NOTIFICATIONS'
                            }
                        });

                    });


                });
            }

        }

    };

    NotificationSynchronizer.$on("notifications.update-counter", updateCounter);

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
        $state.go(item.route);

    };
});
