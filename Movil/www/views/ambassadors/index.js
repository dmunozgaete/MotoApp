angular.route('app.ambassadors/index', function(
    $scope,
    $state,
    $log,
    $filter,
    $Api,
    Rewards
)
{
    //---------------------------------------------------
    // Update Data
    var update = function(callback)
    {
        $Api.read("/Ambassadors").success(function(data)
        {
            //Set URL Image
            angular.forEach(data.items, function(item)
            {
                item.photo = $filter("restricted")(item.photo);
            });

            //Set Items to List
            $scope.items = data.items;
            if (callback)
            {
                callback();
            }
        });
    }
    update();

    //------------------------------------------------
    // Action's
    $scope.doRefresh = function()
    {
        update(function()
        {
            $scope.$broadcast('scroll.refreshComplete');
        })
    };

    $scope.details = function(account)
    {
        $state.go("app.ambassadors/details",
        {
            account: account.token
        });
    };

    $scope.follow = function(item)
    {
        if (item.follow)
        {
            //Unfollow
            $Api.delete("/Ambassadors/{ambassador}/Follow",
            {
                ambassador: item.token
            }).then(function()
            {
                item.followers -= 1;
                item.follow = false;
            });

        }
        else
        {
            //Follow
            $Api.create("/Ambassadors/{ambassador}/Follow",
            {
                ambassador: item.token
            }).then(function()
            {
                item.followers += 1;
                item.follow = true;

                Rewards.check('AMBASSADORS');
            });

        }
        item.follow = null; //Set "meanwhile" value
    }


});
