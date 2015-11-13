angular.route('nomenu.routes/create/pause/:autopause', function(
    $scope,
    $state,
    $log,
    $Api,
    $interval,
    RouteTracker,
    $stateParams,
    ionicToast,
    Camera,
    $cordovaSocialSharing
)
{

    //---------------------------------------------
    // Resume Tracker
    $scope.resume = RouteTracker.getResume();


    //---------------------------------------------
    // Resume Tracker when Auto-Started
    var autoStartListener = RouteTracker.$on("route.autoStart", function()
    {
        $state.go("nomenu.routes/create/index",
        {
            autostart: true
        });
    });
    $scope.$on("$destroy", function()
    {
        //Destroy Listener 
        autoStartListener();
    });


    //----------------------------------------
    //Launch from Auto-Start
    if ($stateParams.autopause)
    {
        ionicToast.show("Se ha pausado la ruta", 'top', true, 5000);
    }

    //----------------------------------------
    // Action's
    $scope.continue = function()
    {
        RouteTracker.start();
        $state.go("nomenu.routes/create/index");
    };

    $scope.takePicture = function()
    {
        Camera.takePicture().then(function(image)
        {

            //Save Picture in Temporal DB
            RouteTracker.addPhoto(image);

        }, function(err)
        {

            ionicToast.show("No se pudo tomar la foto", 'top', true, 2000);
            $log.error(err);

        });
    };


    //---------------------------------------------
    // COUNTER PIE CHART AROUND STOP BUTTON
    $scope.chart = {
        data: [0, 0],
        labels: ['&nbsp'],
        colours: ['#ffc107'],
        options:
        {
            segmentShowStroke: false,
            animateScale: false,
            percentageInnerCutout: 80,
            showTooltips: false,
            //http://api.jqueryui.com/easings/
            animationEasing: 'easeOutBack'
        }
    };
    var currentCounter = null;

    $scope.emergency = function()
    {
        return $cordovaSocialSharing
            .shareViaSMS(message, '+56968987440,+56993020558')
    };
    $scope.stop = function(start)
    {
        if (start)
        {
            var addTick = function()
            {
                var tick = $scope.chart.data[0];
                $scope.chart.data[0] = tick += 1;
                if (tick == 2)
                {
                    $interval.cancel(currentCounter);
                    RouteTracker.stop();
                    ionicToast.hide();

                    //If Coords is minor to Two , Discard inmediately :S
                    if ($scope.resume.coords.length <= 2)
                    {
                        $state.go("app.home");
                    }
                    else
                    {
                        $state.go("nomenu.routes/create/stop");
                    }

                }
            };

            currentCounter = $interval(function()
            {
                addTick();
            }, 720);

            addTick();
        }
        else
        {
            if (currentCounter)
            {
                $scope.chart.data = [0, 0];
                $interval.cancel(currentCounter);
            }
        }
    };
    $scope.$on("$destroy", function()
    {
        if (currentCounter)
        {
            $interval.cancel(currentCounter);
        }
    });
    //---------------------------------------------

});
