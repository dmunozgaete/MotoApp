angular.route('nomenu.routes/create/start', function(
    $scope,
    $state,
    $log,
    $Api,
    $interval,
    ngAudio,
    RouteTracker
)
{
    //---------------------------------------------
    // Resume Tracker
    $scope.resume = RouteTracker.getResume();

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
            RouteTracker.start();
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
