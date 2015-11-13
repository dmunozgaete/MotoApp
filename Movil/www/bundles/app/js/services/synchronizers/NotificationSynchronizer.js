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
        var label = "$_notification_stamp";
        var database = {
            name: "notifications",
            options:
            {}
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
            }

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
                include_docs: true
            });

            promise.then(function(res)
            {
                self.$fire("notifications.update-counter", [res.total_rows]);
            })

            return promise;
        };

        self.getItems = function()
        {
            var defer = $q.defer();

            var db = pouchDB(database.name);
            db.query("queries/all".format([name]),
            {
                include_docs: true,
                descending: true
            }).then(function(res)
            {
                var items = _.pluck(res.rows, 'doc');

                //Update Notification's if exist's
                if (res.rows.length > 0)
                {
                    hasUnreaded = false;

                    //UPDATE ALL Notifications to readed
                    angular.forEach(items, function(item)
                    {
                        //First Seen??!
                        if (!item.readed)
                        {
                            hasUnreaded = true;

                            //Decode Context
                            switch (item.type.identifier)
                            {
                                case "INFO":
                                    item.image = $filter("restricted")(item.image);
                                    break;
                            }
                        }

                        item.readed = true;
                    });

                    if (hasUnreaded)
                    {
                        self.markAllAsReaded().then(function()
                        {
                            //Update Doc's
                            db.bulkDocs(items).then(function()
                            {
                                //<- event
                                updateCount();
                            });
                        });
                    }
                }

                defer.resolve(items);

            });

            return defer.promise;
        };


        self.markAllAsReaded = function()
        {
            var stamp = $LocalStorage.get(label);
            return $Api.update("/Notifications/MarkAsReaded",
            {
                timestamp: stamp
            });
        };

        return self;
    });
