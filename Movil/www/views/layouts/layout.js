angular.module('app.layouts').controller('DefaultLayoutController', function(
    $scope,
    $state,
    $log,
    $Configuration,
    $Identity,
    NotificationSynchronizer,
    $cordovaBadge,
    $cordovaLocalNotification,
    $ionicHistory
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
                route: "app.routes/discover",
                icon: "ion-ios-star-outline",
                label: "Descubrir"
            },

            {
                route: "app.routes/me",
                icon: "ion-ios-location-outline",
                label: "Mis Rutas"
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
            }
        ]
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
        else
        {

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

    };

    NotificationSynchronizer.$on("notifications.update-counter", updateCounter);

    //------------------------------------------------------------------------------------
    // Layout Actions
    $scope.showNotifications = function()
    {

        var item = _.find($scope.config.menu,
        {
            route: "app.notifications"
        });

        $scope.navigateTo(item);

    };

    //------------------------------------------------------------------------------------

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
        // If the current View is the clicked menu item, do nothing ;)
        if ($ionicHistory.currentView().stateId == item.route)
        {
            return;
        };

        //----------------------------------- 
        // Try to remove the cache from history if view exist's , 
        // (always try to reload if clicked from menu)
        $ionicHistory.clearCache([item.route]).then(function()
        {
            //-----------------------------------
            // Navigate
            $state.go(item.route);
        })

    };
});
