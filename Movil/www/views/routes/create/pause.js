angular.route('nomenu.routes/create/pause', function(
    $scope,
    $state,
    $log,
    $Api,
    $interval
)
{

    //----------------------------------------
    // Action's
    $scope.continue = function()
    {
        $state.go("nomenu.routes/create");
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
            animationEasing : 'easeOutBack'
        }
    };
    var currentCounter = null;
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
                    $state.go("nomenu.routes/create/stop");
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
