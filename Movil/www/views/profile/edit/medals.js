angular.route('app.profile/edit/medals/:user', function(
    $scope,
    $state,
    $log,
    $cordovaBadge,
    $Api,
    $q,
    $stateParams
)
{

    //---------------------------------------------------
    // Update Data
    var update = function()
    {
        var defers = [];

        defers.push(
            $Api.kql("/Medals",
            {
                limit: 1000
            })
        );

        defers.push(
            $Api.read("/Accounts/{user}",
            {
                user: $stateParams.user
            })
        );

        $q.all(defers).then(function(resolves)
        {
            var medals = resolves[0].items;
            var profile = resolves[1];

            angular.forEach(profile.medals, function(medal)
            {
                var _medal = _.find(medals,
                {
                    token: medal.token
                });

                if (_medal)
                {
                    _medal.acquired = true;
                    _medal.acquiredAt = medal.acquiredAt;
                }
            });

            $scope.items = medals;
            $scope.$broadcast('scroll.refreshComplete');
        });

    }
    update();

    //------------------------------------------------
    // Action's
    $scope.back = function()
    {
        history.back();
    };

    $scope.view = function(item)
    {
        $state.go("app.routes/view/index",
        {
            route: item.token
        });
    };

    $scope.doRefresh = function()
    {
        update();
    };


});
