angular.route('nomenu.firstRun/configure/index', function(
    $scope,
    $state,
    $log
)
{
    //---------------------------------------------------
    //New Slider (Ionic 1.2)
    var slider = null;
    $scope.$watch("slider", function(value)
    {
        if (value)
        {
            slider = value;
        }
    });
    //---------------------------------------------------

    $scope.next = function(id)
    {
        switch (id)
        {
            case "BACKGROUND_GPS":
            case "PUSH_NOTIFICATIONS":
                slider.slideNext();
                break;
            case "SPORT_SELECTOR":
                $state.go("app.home");
                break;
        }
    };
});
