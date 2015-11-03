angular.route('nomenu.routes/create/start', function(
    $scope,
    $state,
    $log,
    $Api,
    $interval,
    ngAudio,
    routeTracker
)
{
    //----------------------------------------
    // Preload Beep Sound
    var audio =  ngAudio.load("bundles/app/sounds/beep-soft.wav");

    //----------------------------------------
    // Count Down
    $scope.counter = 5
    var delay = $interval(function()
    {

        $scope.counter -= 1;

        //Check Counter
        if ($scope.counter == 0)
        {
            $state.go("nomenu.routes/create/index");
            $interval.cancel(delay); //Stop Counter
            routeTracker.start();
            return;
        }

        //Play Sound
        audio.play();

    }, 1000);

    $scope.$on("$destroy", function()
    {
        $interval.cancel(delay);
    });
    //----------------------------------------

    //----------------------------------------
    // Action's
    $scope.stop = function()
    {
        $state.go("app.home");
    };

});
