/*------------------------------------------------------
 Company:           Valentys Ltda.
 Author:            David Gaete <dmunozgaete@gmail.com> (https://github.com/dmunozgaete)
 
 Description:       Pending Route Synchronizer
------------------------------------------------------*/
angular.module('app.services.synchronizers')
    .service('PendingRouteSynchronizer', function(
        $q,
        BaseEventHandler,
        $LocalStorage,
        pouchDB,
        $Api,
        $Identity,
        $filter,
        $cordovaLocalNotification,
        Rewards
    )
    {
        // SYNC VARIABLES
        var self = Object.create(BaseEventHandler); //Extend From EventHandler
        var database = {
            name: "pending_routes",
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
            var db = pouchDB(database.name, database.options);

            //CREATE VIEW'S FOR FASTER RETRIEVAL
            var ddoc = {
                _id: '_design/queries',
                views:
                {
                    //GET ALL PENDING ROUTES
                    pendings:
                    {
                        map: function(doc)
                        {
                            emit(doc);
                        }.toString()
                    }
                }
            };
            db.put(ddoc);

            defer.resolve();
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

            self.getItems().then(function(items)
            {

                var defers = [];
                angular.forEach(items, function(route)
                {

                    //SYNC ROUTE (PROMISE RETURNED)
                    var promise = self.upload(route);
                    defers.push(promise);

                });

                //WHEN ALL ROUTE ARE SYNC OR NOT... 
                $q.all(defers).then(function(resolvers)
                {

                    defer.resolve();

                    //ALL OK?, SHOW UPLOAD NOTIFICATION!!!
                    if (defers.length > 0 && ionic.Platform.isWebView())
                    {

                        //SHARED ROUTE
                        $cordovaLocalNotification.schedule(
                        {
                            id: (new Date().getTime()),
                            title: 'Rutas actualizadas',
                            text: 'Ya se encuentran enviadas tus rutas pendientes',
                            data:
                            {
                                type: 'SYNC_NOTIFICATIONS'
                            }
                        });

                    };

                }, function()
                {
                    defer.reject();
                });


            }, defer.reject);

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
            return query("pendings");
        };

        self.upload = function(route)
        {
            var photos = route.photos;
            delete route.photos; //Remove property , it other services
            //---------------------------------------------
            // Defer's
            var process_defer = $q.defer();

            var save_defer = $q.defer();
            var photo_defer = $q.defer();
            var share_defer = $q.defer();

            var notify = function(event) {};
            process_defer.promise.notify = function(callback)
            {
                notify = callback;
                return process_defer.promise;
            };

            //Sharing??
            if (route.isShared)
            {
                $q.all([save_defer.promise, photo_defer.promise]).then(function()
                {
                    Share();
                });
            }
            else
            {
                //Resolve insted
                share_defer.resolve();
            }

            //all right??
            $q.all([
                save_defer.promise,
                photo_defer.promise,
                share_defer.promise
            ]).then(function(resolves)
            {

                var db = pouchDB(database.name, database.options);
                db.remove(route); //REMOVE THE PENDING ROUTE WHEN SYNC!

                Rewards.check('ROUTES');

                process_defer.resolve();

            }, function(err)
            {
                //ADD AGAIN THE VARIABLE FOR PENDING!
                route.photos = photos;

                //SAVE OR UPDATE! FOR ASYNC UPLOAD
                var db = pouchDB(database.name, database.options);
                var db_promise = (route._id ? db.put(route) : db.post(route));

                //PROMISE
                return db_promise.then(function()
                {
                    process_defer.reject();
                });

            });

            var Save = function()
            {
                //LOG
                notify("Guardando Ruta...");

                $Api.create("/Routes", route)
                    .success(function(data)
                    {
                        route.token = data.token;

                        //LOG
                        notify("Ruta Guardada...");

                        save_defer.resolve(); //Resolve Save Step

                        Photos();

                    }).error(function(err)
                    {
                        //LOG
                        notify("Error al Guardar la ruta...");
                        save_defer.reject(err);
                    });
            };

            var Photos = function()
            {
                //LOG
                notify("Guardando Fotos...");

                var defers = [];

                angular.forEach(photos, function(image, index)
                {
                    var photo = $q.defer();

                    $Api.create("/Routes/Photo/{route}",
                        {
                            route: route.token,
                            image:
                            {
                                photo: image
                            }
                        })
                        .success(function()
                        {

                            //TODO: REMOVE PHOTO FROM PENDING!
                            photos.splice(index, 1);
                            photo.resolve();

                        })
                        .error(photo.reject);

                    defers.push(photo.promise);
                });

                $q.all(defers).then(function(resolvers)
                {
                    //LOG
                    notify("Fotos Guardadas...");
                    photo_defer.resolve();

                }, function()
                {
                    //LOG
                    notify("Error al Guardar las fotos...");
                    photo_defer.reject(err, 'Photos');
                });
            };

            var Share = function()
            {
                //LOG
                notify("Compartiendo Ruta...");

                //---------------------------------------------
                // Send to the API , to create the Route
                $Api.create("/Routes/Share/{route}",
                    {
                        route: route.token,
                        data:
                        {
                            name: route.name,
                            observation: route.observation
                        }
                    })
                    .success(function(data)
                    {

                        //LOG
                        notify("Finalizando...");
                        share_defer.resolve(); //Resolve Share Step


                    }).error(function(err)
                    {
                        //LOG
                        notify("Error al Compartir la ruta...");
                        share_defer.reject(err, 'Share');
                    });
            };


            //CHECK FOR A STATE =)!
            setTimeout(function()
            {
                //LOG
                notify("Preparando Ruta...");

                Save(route);
            }, 0)

            return process_defer.promise;

        };

        return self;
    });
