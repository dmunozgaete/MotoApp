angular.route('app.home/index', function(
    $scope,
    $state,
    $log,
    $Api,
    $interval,
    $timeout,
    $Identity,
    $ionicNavBarDelegate,
    Rewards
)
{
    //----------------------------------------
    // Models
    $scope.model = {
        range: 'S'
    };

    //----------------------------------------
    // FIX ISSUE NAVBAR ALIGN LEFT WITHOUT PADDING
    $ionicNavBarDelegate.showBar(false);
    var delay = $timeout(function()
    {
        $ionicNavBarDelegate.align("left");
        $ionicNavBarDelegate.showBar(true);

    }, 350);
    $scope.$on("$destroy", function()
    {
        $timeout.cancel(delay);
    });
    //----------------------------------------
    
    //----------------------------------------
    // Charts Data
    //  http://jtblin.github.io/angular-chart.js/
    //  http://www.chartjs.org/docs/
    var drawGraph = function(data)
    {
        var labels = [];
        var values = [];

        angular.forEach(data.graph, function(item)
        {
            labels.push(item.label);
            values.push(item.value);
        });

        $scope.graph = {
            labels: labels,
            series: ['Stats'],
            colours: ["#493C2A"],
            options:
            {
                showTooltips: false
            },
            onClick: function(points, evt)
            {
                
            },
            values: [
                values
            ]
        };

    };

    //---------------------------------------------------
    // Get Data
    var start = new Date();
    var end = new Date();

    switch ($scope.model.range)
    {
        case "S":
            //-7 Dias (Week)
            start.setDate(end.getDate() - 7);
            break;
    };

    $Api.read("/Dashboard/{range}",
    {
        range: $scope.model.range,
        start: start,
        end: end
    }).success(function(data)
    {
        //Set Items to List
        drawGraph(data);
        $scope.dashboard = data;

    });

    //----------------------------------------
    // Action's
    $scope.create = function()
    {
        $state.go("nomenu.routes/create/start");
    };

});
