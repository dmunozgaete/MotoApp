/*------------------------------------------------------
 Company:           Valentys Ltda.
 Author:            David Gaete <dmunozgaete@gmail.com> (https://github.com/dmunozgaete)
 
 Description:       Notification Synchronizer
------------------------------------------------------*/
angular.module('app.services.synchronizers')
    .service('NotificationSynchronizer', function(
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
        var database = {
            name: "notifications",
            options:
            {}
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
                    var db = pouchDB(database.name, database.options);

                    //CREATE VIEW'S FOR FASTER RETRIEVAL
                    var ddoc = {
                        _id: '_design/queries',
                        views:
                        {
                            //GET ALL NOTIFICATIONS
                            all:
                            {
                                map: function(doc)
                                {
                                    emit(doc);
                                }.toString()
                            },

                            //GET UNREADED DOCUMENT'S
                            unreaded:
                            {
                                map: function(doc)
                                {
                                    if (doc.readed == false)
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

            //--------------------------------
            //Get Current Notifications Counter when ready
            defer.promise.then(function()
            {
                updateCount();
            });

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
                //If not exists, the first date is now- (1 months)
                stamp = moment().subtract(1, 'M').toDate().toISOString();
            }

            //----------------------------------------
            //Get New's Notification's
            $Api.read("/Notifications",
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

                        //Decode Context
                        switch (item.type.identifier)
                        {
                            case "INFO":
                                item.image = $filter("restricted")(item.image);
                                break;
                        }

                    });

                    //-----------------------------------------
                    //Bulk all new notification's to storage
                    var db = pouchDB(database.name);
                    db.bulkDocs(data.items).then(function()
                    {

                        defer.resolve();

                        //Set new Stamp =)!
                        $LocalStorage.set(label, data.timestamp);


                        //Call to update the notification's counter's
                        updateCount();
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
        };


        //-----------------------------------------
        // CUSTOM ACTION'S
        var updateCount = function()
        {
            var db = pouchDB(database.name);

            var promise = db.query('queries/unreaded',
            {
                include_docs: false
            });

            promise.then(function(res)
            {
                self.$fire("notifications.update-counter", [res.total_rows]);
            })

            return promise;
        };

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

                db.query('queries/all', options).then(function(res)
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

        self.getItems = function()
        {
            var defer = $q.defer();
            var db = pouchDB(database.name);
            db.query('queries/all',
            {
                include_docs: true,
                descending: true,
                limit: 10
            }).then(function(res)
            {

                //Return Item's
                var items = _.pluck(res.rows, 'doc');
                defer.resolve(items);

            }, function(err)
            {
                defer.reject(err);
            });

            return defer.promise;
        };

        self.markAllAsReaded = function()
        {
            var defer = $q.defer();
            var db = pouchDB(database.name);
            db.query('queries/unreaded',
            {
                include_docs: true
            }).then(function(res)
            {
                //Mark all unreaded item's as READED
                var items = _.pluck(res.rows, 'doc');
                angular.forEach(items, function(item)
                {
                    item.readed = true;
                })
                db.bulkDocs(items).then(function()
                {

                    var stamp = $LocalStorage.get(label);
                    $Api.update("/Notifications/MarkAsReaded",
                    {
                        timestamp: stamp
                    }).then(defer.resolve, defer.reject);

                    updateCount();

                }, defer.reject);

            }, defer.reject);

            return defer.promise;
        };

        return self;
    });
