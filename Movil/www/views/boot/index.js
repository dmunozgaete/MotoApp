angular.route('boot/index', function(
    $scope,
    $state,
    $log,
    $Api,
    $Configuration,
    $location,
    $LocalStorage,
    pouchDB,
    $q,
    Synchronizer
)
{

    //INITIALIZE THE SYNCRONIZER MANAGER
    var defer  = Synchronizer.start();  

    //When all Process are Checked, run APP
    $q.all([defer]).then(function()
    {
        var url = $Configuration.get("application");
        $location.url(url.home);
    });

});
