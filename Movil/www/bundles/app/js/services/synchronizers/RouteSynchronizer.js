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
        $filter)
    {
        // SYNC VARIABLES
        var self = Object.create(BaseEventHandler); //Extend From EventHandler
        var label = "$_route_stamp";
        var database = {
            name: "routes",
            options:
            {
                size: 50
            }
        };

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
                    var db = pouchDB(database.name, database.options);

                    //CREATE VIEW'S FOR FASTER RETRIEVAL
                    var ddoc = {
                        _id: '_design/queries',
                        views:
                        {
                            //GET ALL ROUTES
                            all:
                            {
                                map: function(doc)
                                {
                                    emit(doc);
                                }.toString()
                            },

                            //GET LOCAL ROUTES
                            locals:
                            {
                                map: function(doc)
                                {
                                    if (doc.isShared === 0)
                                    {
                                        emit(doc);
                                    };
                                }.toString()
                            },

                            //GET SHARED ROUTES
                            shared:
                            {
                                map: function(doc)
                                {
                                    if (doc.isShared === 1)
                                    {
                                        emit(doc);
                                    };
                                }.toString()
                            }
                        }
                    };
                    db.put(ddoc).then(function()
                    {
                        defer.resolve();
                    }).catch(function(err)
                    {
                        throw err;
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
            }

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
                    //SET key with the date
                    angular.forEach(data.items, function(item)
                    {
                        item._id = item.createdAt;
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
        var query = function(name)
        {
            var defer = $q.defer();

            var db = pouchDB(database.name);

            db.query("queries/{0}".format([name]),
            {
                include_docs: true,
                descending: true
            }).then(function(res)
            {
                var items = _.pluck(res.rows, 'doc');
                defer.resolve(items);
            });

            return defer.promise;
        };

        self.getItems = function()
        {
            return query("all");
        };

        self.getLocals = function()
        {
            return query("locals");
        };

        self.getShared = function()
        {
            return query("shared");
        };


        return self;
    });
