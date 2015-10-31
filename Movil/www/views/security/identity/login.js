angular.route('security/identity/login', function(
    $log,
    $Configuration,
    $Localization,
    $state,
    $Identity,
    $scope,
    ionicToast
)
{
    //Application Information
    $scope.signature = $Configuration.get("application");
    $scope.user = {};

    $scope.login = function(loginType)
    {
        var email = function()
        {
            var credentials = {
                username: 'dmunoz@valentys.com',
                password: 'MySuperClave'
            };

            $Identity.authenticate(credentials)
                .success(function(data)
                {
                    $state.go("app.home");
                })
                .error(function(error)
                {
                    var error_message = $Localization.get("ERR.API.UNAVAILABLE");
                    if (error && error.error_description)
                    {
                        error_message = error.error_description;
                    }

                    ionicToast.show(error_message, 'bottom', false, 2500);
                });
        };

        switch (loginType)
        {
            case 'facebook':
            case 'google':
            case 'email':
                email();
                break;
        }

    };

});
