angular.route('app.profile/index', function(
    $scope,
    $state,
    $log,
    $Api,
    $Identity,
    $LocalStorage,
    $Configuration,
    ApplicationCleanse
)
{
    var user = $Identity.getCurrent();

    //---------------------------------------------------
    // Get Data
    $Api.read("/Accounts/Me").success(function(data)
    {
        //Set Profile
        $scope.profile = data;

    });


    //------------------------------------------------
    // Action's
    $scope.getProgress = function(exp)
    {
        if (exp.total == 0)
        {
            return 0;
        }
        return exp.total * 100 / exp.level;
    };

    $scope.edit = function()
    {
        $state.go("app.profile/edit");
    };

    $scope.medals = function()
    {
        $state.go("app.profile/edit/medals",
        {
            user: user.primarysid
        });
    };

    $scope.logOut = function()
    {

        // CLEAN OLD STUFF
        ApplicationCleanse.clean().then(function(){
            $Identity.logOut();
        });
        
    };

});
