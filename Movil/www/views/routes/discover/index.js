angular.route('app.routes/discover/index', function(
    $scope,
    $state,
    $log,
    $Api,
    $filter,
    $timeout,
    FilterDialog,
    $q,
    Gps
)
{
    var pagination = null; //DISCOVER FUNCTION , RETURN A PAGINABLE OBJECT :P
    var filters = {
        distance: 100 // DEFAULT DISTANCE VALUE
    };

    //---------------------------------------------------
    //Wait for a short delay until side menu , close.
    var delay = $timeout(function()
    {
        $timeout.cancel(delay);
        $scope.doRefresh();
    }, 1000);

    //Get the Location! , before discover ^
    var discover = function()
    {
        var lastGps = null;
        var offset = 0;
        var limit = 5;
        var totalRows = 0;

        var paginate = function(coords)
        {
            return $Api.read("/Routes/@{latitude},{longitude},{distance}km/Discover",
            {
                latitude: coords.latitude,
                longitude: coords.longitude,
                distance: filters.distance,
                limit: limit,
                offset: offset
            }).success(function(data)
            {
                //UPDATE OFFSET COUNTER
                offset += data.items.length;
                totalRows = data.total;


            }).error(function()
            {
                //CANT ADQUIRE ITEMS (INTERNET CONNECTION??)
                failure("INTERNET_CONNECTION");
            });
        };

        //FAILURE FUNCTION :/
        var failure = function(error)
        {
            switch (error)
            {
                case "INTERNET_CONNECTION":
                    break;
                case "CANT_LOCATE":
                    break;
            }
        };

        var geo_deferred = $q.defer();
        geo_deferred.promise.then(function(coords)
        {

            //---------------------------------------------------
            offset = 0;
            paginate(coords)
                .success(function(data)
                {
                    //Set Items to List (RESETING)
                    $scope.items = data.items;
                })
                .finally(function()
                {
                    $scope.$broadcast('scroll.refreshComplete');
                });
            //---------------------------------------------------

        });

        //---------------------------------------------------
        //Get Current Position to update =)!
        // 10.000  = 10 seconds - timeout
        // 420.000 = 7 minutes for maximunAge GPS , Lag
        Gps.getCurrentPosition(10000, 420000).then(function(data)
        {
            //Set Last Position
            lastGps = {
                latitude: data.coords.latitude,
                longitude: data.coords.longitude
            };

            //Resolve GEO
            geo_deferred.resolve(lastGps);

        }, function(err)
        {

            //Cant locate Gps, but can we use the last location =)!
            if (lastGps)
            {
                //Resolve GEO
                geo_deferred.resolve(lastGps);
            }
            else
            {
                //Can't Locate GPS And is the first time :P
                failure("CANT_LOCATE");
            }
        });

        return {
            nextPage: function()
            {
                return paginate(lastGps);
            },
            hasNext: function()
            {
                return totalRows > 0 && offset < totalRows;
            }
        };
    };

    //------------------------------------------------
    // Action's
    $scope.nextPage = function()
    {
        pagination.nextPage().success(function(data)
        {

            $scope.items = $scope.items.concat(data.items);
            $scope.$broadcast('scroll.infiniteScrollComplete');
        });
    };
    $scope.hasNext = function()
    {
        return pagination.hasNext();
    };


    $scope.filter = function()
    {
        FilterDialog.show(
        {
            distance: filters.distance
        }).then(function(data)
        {
            //Set New Values
            filters.distance = data.distance;
            pagination = discover();
        });
    };

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
        pagination = discover();
    };


});
