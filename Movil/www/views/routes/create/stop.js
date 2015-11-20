angular.route('nomenu.routes/create/stop', function(
    $scope,
    $state,
    $log,
    $Api,
    $interval,
    RouteTracker,
    $ionicLoading,
    Camera
)
{
    //---------------------------------------------
    // Model
    $scope.model = {
        sensation: null
    };

    //---------------------------------------------
    // Resume Tracker
    $scope.resume = RouteTracker.getResume();

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
    $scope.discard = function(start)
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

                    //Discard Sesión =(
                    $state.go("app.home");
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

    //----------------------------------------
    // Action's
    $scope.share = function()
    {
        $state.go("nomenu.routes/create/share",
        {
            sensation: $scope.model.sensation
        });
    };

    $scope.save = function()
    {
        RouteTracker.setData($scope.model);
        $state.go("nomenu.routes/create/upload");
    };

    $scope.takePicture = function()
    {
        Camera.takePicture().then(function(image)
        {

            //Save Picture in Temporal DB
            RouteTracker.addPhoto(image);

        }, function(err)
        {

            $ionicLoading.show(
            {
                template: 'No se pudo tomar la foto',
                duration: 3000
            });
            $log.error(err);

        });
    };

});
