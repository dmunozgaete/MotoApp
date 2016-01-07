/*------------------------------------------------------
 Company:           Valentys Ltda.
 Author:            David Gaete <dmunozgaete@gmail.com> (https://github.com/dmunozgaete)
 
 Description:       Route Synchronizer
------------------------------------------------------*/
angular.module('app.services.synchronizers')
    .service('RouteSynchronizer', function(
        $q,
        BaseEventHandler,
        $LocalStorage,
        pouchDB,
        $Api,
        $Identity,
        $filter,
        Rewards
    )
    {
        // SYNC VARIABLES
        var self = Object.create(BaseEventHandler); //Extend From EventHandler
        var database = {
            name: "routes",
            options:
            {
                size: 50,
                auto_compaction: true
            }
        };
        var label = database.name + "_stamp";

        //----------------------------------------
        // CONFIGURATION STEP (LIKE CONSTRUCTOR)
        self.configure = function()
        {
            var defer = $q.defer();
            //------------------------------------------------
            //If stamp never exists, destroy database to reset
            var stamp = $LocalStorage.get(label);
            if (!stamp)
            {
                pouchDB(database.name).destroy().then(function()
                {

                    //RE-CREATE 
                    var db = pouchDB(database.name, database.options).then(function()
                    {
                        defer.resolve();
                    });


                })
            }
            else
            {
                //Cleaning is finish :P
                defer.resolve();
            }
            //------------------------------------------------

            return defer.promise;
        };

        //----------------------------------------
        // SYNC STEP
        self.synchronize = function()
        {
            var defer = $q.defer();

            //------------------------------------------------
            // ONLY WHEN IS AUTHENTICATED
            if (!$Identity.isAuthenticated())
            {
                defer.resolve();
                return defer.promise;
            }
            //------------------------------------------------

            //------------------------------------------------
            var stamp = $LocalStorage.get(label);
            if (!stamp)
            {
                //If not exists, the first date is now- (3 months)
                stamp = moment().subtract(3, 'M').toDate().toISOString();
            }

            //----------------------------------------
            //Get New's Routes's
            $Api.read("/Routes/Me",
            {
                timestamp: stamp
            }).success(function(data)
            {
                if (data.items.length > 0)
                {
                    //-----------------------------------------
                    //SET key with the date
                    angular.forEach(data.items, function(item)
                    {
                        item._id = item.start + Math.random();
                    });

                    //-----------------------------------------
                    //Bulk all new items's to storage
                    var db = pouchDB(database.name);
                    db.bulkDocs(data.items).then(function()
                    {
                        defer.resolve();

                        //Set new Stamp =)!
                        $LocalStorage.set(label, data.timestamp);

                        //DO SOMETHING??
                        self.$fire("routes.new-routes", [data.items]);

                    });
                }
                else
                {
                    defer.resolve();
                }

            }).error(function()
            {
                defer.reject();
            });

            return defer.promise;
        }

        //-----------------------------------------
        // CUSTOM ACTION'S
        self.paginate = function(limit)
        {
            var db = pouchDB(database.name);
            var options = {
                limit: limit,
                include_docs: true,
                descending: true
            };

            var totalRows = 0;
            var currentRows = 0;

            var hasNext = function hasNext()
            {
                return totalRows > 0 && currentRows < totalRows;
            }

            var nextPage = function nextPage()
            {
                var defer = $q.defer();

                db.allDocs(options).then(function(res)
                {
                    if (res.rows.length > 0)
                    {
                        //Set counter's
                        options.startkey = res.rows[res.rows.length - 1].key;
                        totalRows = res.total_rows;
                        currentRows += res.rows.length;
                        options.skip = 1;
                    }

                    //Return Item's
                    var items = _.pluck(res.rows, 'doc');
                    defer.resolve(items);

                }, defer.reject);

                return defer.promise;
            };

            var defer = nextPage();
            defer.nextPage = nextPage;
            defer.hasNext = hasNext;

            return defer;
        };

        self.findByToken = function(token)
        {
            var defer = $q.defer();
            var db = pouchDB(database.name);
            db.get(token).then(function(res)
            {
                defer.resolve(res);
            }, function(err)
            {
                defer.resolve(err);
            });
            return defer.promise;
        };

        self.remove = function(token)
        {
            var defer = $q.defer();
            var db = pouchDB(database.name);

            db.query(function(doc, emit)
            {
                emit(doc.token);
            },
            {
                key: token,
                include_docs: true,
                limit: 1
            }).then(function(result)
            {
                //Found??
                if (result.rows.length > 0)
                {
                    //Remove the DOC 
                    db.remove(result.rows[0].doc).then(function()
                    {
                        defer.resolve(token);
                    }, function(err)
                    {
                        defer.reject(err);
                    });
                }


            }).catch(function(err)
            {
                defer.reject(err);
            });


            return defer.promise;
        };

        return self;
    });
