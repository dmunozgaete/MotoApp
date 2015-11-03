/*------------------------------------------------------
 Company:           Valentys Ltda.
 Author:            David Gaete <dmunozgaete@gmail.com> (https://github.com/dmunozgaete)
 
 Description:       GPS tracking Service 
 Github:            http://ngcordova.com/docs/plugins/geolocation/
------------------------------------------------------*/
(function()
{
    var _autoStart = false;
    var _debug = false;

    angular.module('app.services')
        .provider('Gps', function()
        {
            var $ref = this;

            //---------------------------------------------------
            //Configurable Variable on .config Step
            var _timeout = 15000;
            var _highAccuracy = false;
            var _accuracyThreshold = 150;   //Web Acuracy Default
            var _testRoute = null;


            this.frequency = function(timeout)
            {
                if (timeout > 0)
                {
                    _timeout = timeout;
                };
                return $ref;
            };

            this.enableDeviceGPS = function()
            {
                _highAccuracy = true;
                return $ref;
            };

            this.autoStart = function()
            {
                _autoStart = true;
                return $ref;
            };

            this.debug = function()
            {
                _debug = true;
                return $ref;
            };

            this.accuracyThreshold = function(threshold)
            {
                if (threshold > 0)
                {
                    _accuracyThreshold = threshold;
                }
                return $ref;
            };

            //Only for Debug Purpose , create a test route
            this.addTestRoute = function(url)
            {
                _testRoute = url;
            };

            this.$get = function($log, $q, BaseEventHandler, $interval, $http)
            {
                var self = Object.create(BaseEventHandler); //Extend From EventHandler
                var watcher = null;
                var callbacks = [];
                var isPlatformReady = false;
                var options = {
                    timeout: 10000,
                    maximumAge: 3000,
                    enableHighAccuracy: _highAccuracy
                };

                var executeOnLoad = function(callback)
                {
                    if (isPlatformReady)
                    {
                        //Execute Inmeditely 
                        callback();
                    }
                    else
                    {
                        callbacks.push(callback); //Add to Queue
                    }
                };

                var _lastSuccessGPS = new Date();
                var _updateLocation = _.throttle(function(position)
                {

                    if (_debug)
                    {
                        $log.info("GPS: update location ", position);
                    }

                    _lastSuccessGPS = new Date();
                    self.$fire("gps.update", [position]);

                }, _timeout);

                var onUpdateLocation = function(position)
                {
                    var isDiscarded = false;

                    //Over acuracy Threshold meters (Threshold/2 = radius)
                    if (position.coords.accuracy > _accuracyThreshold)
                    {
                        isDiscarded = true;
                    }

                    //Discard Location??
                    if (isDiscarded)
                    {
                        $log.warn("GPS: location discarded ", position);
                        return;
                    }

                    //Check the Acuracy and accepto only "realistic" acuracy 
                    _updateLocation(position);
                };

                var onFailureLocation = function(error)
                {
                    if (_debug)
                    {
                        $log.error("GPS: can't get location ", error);
                    }

                    self.$fire("gps.error", [error]);

                };

                //Retrieve the Current Location 
                self.getCurrentPosition = function(timeout)
                {
                    var deferred = $q.defer();
                    var current_options = {
                        timeout: (timeout || options.timeout),
                        enableHighAccuracy: _highAccuracy,
                        maximumAge: 0
                    };

                    if (_debug)
                    {
                        $log.warn("GPS: getting current position...", current_options);
                    }

                    navigator.geolocation.getCurrentPosition(
                        function(position)
                        {
                            onUpdateLocation(position);
                            deferred.resolve(position);
                        },
                        function(error)
                        {
                            onFailureLocation(error);
                            deferred.reject(error);
                        },
                        current_options
                    );

                    return deferred.promise;
                }

                //Start Tracking GPS accord to initial setup
                self.start = function()
                {
                    if (watcher)
                    {
                        //If already a Watcher , Do Nothing!
                        return;
                    }

                    executeOnLoad(function()
                    {

                        //Not Send Error, fails :S
                        //http://stackoverflow.com/questions/20239846/android-geolocation-using-phonegap-code-3-error
                        /*
                        watcher = $cordovaGeolocation.watchPosition(options);
                        watcher.then(null, null, onUpdateLocation);
                        */

                        watcher = navigator.geolocation.watchPosition(onUpdateLocation, onFailureLocation, options);
                    })
                };

                //Stop the GPS Tracking 
                self.stop = function()
                {
                    if (watcher)
                    {
                        executeOnLoad(function()
                        {
                            navigator.geolocation.clearWatch(watcher);

                            //Clear Event Listeners
                            self.$clear("gps.update");
                            self.$clear("gps.error");
                        });
                    }
                }

                //------------------------------------------------
                // CHECKER FUNCTION, TO ENSURE THAT GPS IS ACTIVE
                var isInProcess = false;
                $interval(function()
                {
                    if (!isInProcess)
                    {
                        var dif = (new Date() - _lastSuccessGPS);

                        if (dif > _timeout)
                        {
                            // MEANS GPS IS NOT WORK AT TIMEOUT LIMIT
                            // ...help , calling manually current position
                            if (_debug)
                            {
                                $log.warn("GPS: too long wait... try getting position...", dif);
                            }

                            var stopProcess = function()
                            {
                                isInProcess = false;
                            }

                            isInProcess = true;
                            self.getCurrentPosition(_timeout).then(stopProcess, stopProcess);
                        }
                    }

                }, (_timeout + 500));

                //------------------------------------------------
                // Only for Testing Purpose!
                if (_testRoute)
                {
                    if (_debug)
                    {
                        $log.info("GPS: Test Route Enable ", _testRoute);
                    }

                    var interval = null;

                    self.start = function()
                    {
                        $http.get(_testRoute).success(function(data)
                        {
                            $log.info("GPS: Test Route Loaded ({0} points) ".format([data.length]));

                            var index = 0;
                            interval = $interval(function()
                            {
                                if (index < data.length)
                                {
                                    var position = data[index];

                                    //transclude to Geo Coord
                                    onUpdateLocation(
                                    {
                                        timestamp: (new Date()).getTime(),
                                        coords:
                                        {
                                            accuracy: 10,
                                            latitude: position[1],
                                            longitude: position[0]
                                        }
                                    });

                                    index++;
                                }

                            }, _timeout);

                        }).error(function(error)
                        {
                            if (_debug)
                            {
                                $log.error("GPS: Can't get test route ", error);
                            }
                        });

                    };

                    self.stop = function()
                    {
                        if (interval)
                        {
                            $interval.cancel(interval);
                        }
                    };
                }

                // will execute when device is ready, or 
                // immediately if the device is already ready.
                //    (Mobile and Web)
                ionic.Platform.ready(function()
                {
                    isPlatformReady = true;

                    //Execute the Queue
                    angular.forEach(callbacks, function(callback)
                    {
                        callback();
                    });

                    callbacks = null; //Clear Cached Callbacks
                });

                return self;
            };

        })
        .run(function(Gps, $log)
        {
            //Auto Start
            if (_autoStart)
            {
                if (_debug)
                {
                    $log.info("GPS: autostart");
                }

                Gps.start();
            }
        });

})();
