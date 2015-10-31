angular.route('app.home/index', function(
    $scope,
    $state,
    $log,
    $Api,
    $interval,
    $timeout,
    $Identity,
    $ionicNavBarDelegate
)
{
    //----------------------------------------
    // FIX ISSUE NAVBAR ALIGN LEFT WITHOUT PADDING
    $ionicNavBarDelegate.showBar(false);
    $timeout(function()
    {
        $ionicNavBarDelegate.align("left");
        $ionicNavBarDelegate.showBar(true);

    }, 350);
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
                console.log(points, evt);
            },
            values: [
                values
            ]
        };

    };

    //---------------------------------------------------
    // Get Data
    $Api.read("/Dashboard").success(function(data)
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
