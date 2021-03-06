angular.module('app.services')
    .provider('RouteTracker', function()
    {
        var $ref = this;

        //---------------------------------------------------
        //Configurable Variable on .config Step
        var _debug = false;
        var _enableAutoPause = false;
        var _threshold = 0;
        var trackState = {
            START: 1,
            PAUSE: 2,
            STOP: 3,
            AUTO_PAUSE: 4
        };

        this.debug = function()
        {
            _debug = true;
            return $ref;
        };

        // Minimun Distance (in Meters) Beetween 
        // Current Point and Last Point , to discard
        this.autoPause = function(meters)
        {
            _enableAutoPause = true;
            _threshold = meters;
            return $ref;
        };

        this.$get = function($log, $q, BaseEventHandler, Gps, $interval, pouchDB)
        {
            var self = Object.create(BaseEventHandler); //Extend From EventHandler
            var interval = null;

            var resume = {
                coords: [],
                state: trackState.STOP,
                photos: [],
                pauses: 0,
                seconds: 0, //in Seconds
                distance: 0, //in KM
                calories: 0, //in Kcal (0.1 * kg * min)
                data:
                {} //EMPTY DATA (SET DATA WHEN FINISH ROUTE)
            };

            //--------------------------------------------------------
            //Speed Algorithm
            var calculateSpeedAndDistance = (function()
            {
                var toRadians = function(value)
                {
                    return value * (Math.PI / 180);
                };

                return function(coord1, coord2)
                {
                    //http://www.movable-type.co.uk/scripts/latlong.html
                    // HAVERSINE FORMULA
                    var actualTime = new Date(coord2.timestamp);
                    var lastCoodTime = new Date(coord1.timestamp);

                    // Coordinates
                    var lat1 = coord1.coords.latitude;
                    var lon1 = coord1.coords.longitude;
                    var lat2 = coord2.coords.latitude;
                    var lon2 = coord2.coords.longitude;

                    // Calculate Speed
                    var R = 6371; // km
                    var dLat = toRadians(lat2 - lat1);
                    var dLon = toRadians(lon2 - lon1);
                    var rlat1 = toRadians(lat1);
                    var rlat2 = toRadians(lat2);

                    // Formula
                    var a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
                        Math.sin(dLon / 2) * Math.sin(dLon / 2) * Math.cos(rlat1) * Math.cos(rlat2);
                    var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
                    var distance = R * c;
                    var elapsed = ((actualTime - lastCoodTime) / 1000);
                    var speed_kph = (distance / elapsed) * 3600;

                    return {
                        distance: distance,
                        speed: speed_kph,
                        elapsed: elapsed
                    };
                };

            })();

            //--------------------------------------------------
            // CHECKER FOR THE AUTO-PAUSE!
            //Check if the distance is lower than the treshold
            var isTooClose = (function()
            {
                //AUTO PAUSE CONFIGURATION
                var nearPoints = {
                    at: 0, //Second which set the first Near Point 
                    counter: 0, //Near Point Counter
                    pointThreshold: 3, //Max Acumulation of Near Point before Auto-Pause
                    distanceThreshold: _threshold / 1000 //Max Distance to ensure is a Near Point
                };

                return function(calcs, point)
                {
                    if (calcs.distance <= nearPoints.distanceThreshold)
                    {

                        self.$fire("route.tooClosePoint", [point]);


                        //If Lower than treshold, Count +1 to nearPointer (with 3 ,set to auto-pause)
                        if (nearPoints.counter == 0)
                        {
                            //Set First Reached Point Second
                            nearPoints.at = resume.seconds;
                        }
                        nearPoints.counter++;

                        if (_debug)
                        {
                            $log.debug("RouteTracker: too close point, set +1 to auto-pause", nearPoints, point);
                        }

                        if (nearPoints.counter >= nearPoints.pointThreshold)
                        {
                            //Set AutoPause
                            resume.seconds = nearPoints.at;
                            nearPoints.at = 0;
                            nearPoints.counter = 0;
                            autoPause();
                        }

                        return true;
                    }
                    else
                    {
                        nearPoints.counter = 0; //Set Counter to 0
                    }

                    return false;
                }
            })();
            //--------------------------------------------------


            var last_coord = null;
            var onTrack = function(position)
            {
                //ONLY PASS IF AUTO PAUSE WAS ENABLED AND ACTIVATED
                if (resume.state == trackState.AUTO_PAUSE && last_coord)
                {
                    var distanceThreshold = _threshold / 1000; //IN KM
                    var calcs = calculateSpeedAndDistance(last_coord, position);
                    if (calcs.distance > distanceThreshold)
                    {
                        //Always Set Start
                        resume.state = trackState.START;

                        if (_debug)
                        {
                            $log.info("RouteTracker: auto-start-session", resume);
                        }

                        self.$fire("route.autoStart", [resume]);

                    }
                }

                //ONLY TRACK IF STATE IS IN START
                if (resume.state == trackState.START)
                {
                    if (_debug)
                    {
                        $log.info("RouteTracker: add-track-point", position);
                    }

                    //-------------------------------------------
                    // Set Speed and Distance BeetWeen Point's
                    if (last_coord)
                    {
                        var calcs = calculateSpeedAndDistance(last_coord, position);

                        //-------------------------------------------
                        // CHECK IF THE USER IS STILL
                        if (_enableAutoPause)
                        {
                            if (isTooClose(calcs, position))
                            {
                                return; //Discard Point
                            }
                        }
                        //-------------------------------------------

                        position.distance = calcs.distance; //DISTANCE IN KM
                        position.speed = calcs.speed; //SPEED IN KM/HR
                        position.duration = calcs.elapsed; //TIME ELAPSED (SECONDS)

                        //Set Instant Speed
                        resume.currentSpeed = calcs.speed;

                        //Add the Distance to the Total 
                        resume.distance += calcs.distance;

                        //Add the Calories Counter
                        resume.calories += 1;

                        //-------------------------------------------
                        // UPDATE AVERAGES
                        var averageSpeed = (resume.distance / resume.seconds) * 3600; //in KM/H
                        resume.speed = averageSpeed;
                        //-------------------------------------------

                    }
                    else
                    {
                        //FIRST COORD , OF FIRST COORD AFTER PAUSE
                        position.distance = 0; //DISTANCE IN KM
                        position.speed = 0; //SPEED IN KM/HR
                        position.duration = 0; //TIME ELAPSED (SECONDS)
                    }
                    //-------------------------------------------

                    //-------------------------------------------
                    // FINALLY ADD THE POINT AND CALL THE EVENT
                    resume.coords.push(position);
                    self.$fire("route.addTrackPoint", [position]);
                    //-------------------------------------------
                }

                //SET LAST POSITION
                last_coord = position;
            };
            Gps.$on("gps.update", onTrack);


            var onTick = function()
            {
                //ONLY TRACK IF STATE IS IN START
                if (resume.state == trackState.START)
                {
                    if (_debug)
                    {
                        $log.debug("RouteTracker: resume-changed", resume);
                    }

                    resume.seconds++;
                    self.$fire("route.resumeChanged", [resume]);
                }

                if (resume.state == trackState.AUTO_PAUSE || resume.state == trackState.PAUSE)
                {
                    resume.pauses++;
                }
            };

            var reset = function()
            {
                resume.seconds = 0;
                resume.coords = [];
                resume.speed = 0;
                resume.currentSpeed = 0;
                resume.distance = 0;
                resume.data = {};
                resume.photos = [];
                resume.startAt = new Date();

                last_coord = null;
            };

            var autoPause = function()
            {
                resume.state = trackState.AUTO_PAUSE;

                if (_debug)
                {
                    $log.info("RouteTracker: auto-pause-session", resume);
                }

                self.$fire("route.autoPaused", [resume]);
            };

            self.start = function()
            {
                //Check Last State to know if Started or Resume
                var wasPaused = (resume.state == trackState.PAUSE);

                //If last State is Stopped, clear the resume
                if (resume.state == trackState.STOP)
                {
                    reset();
                }

                //Always Set Start
                resume.state = trackState.START;

                //CHECK IF THE INTERVAL HAS DESTROYED PREVIOUSLY
                // .... MAYBE IT WAS STOPPED
                if (!interval)
                {
                    interval = $interval(onTick, 1000);
                }

                if (wasPaused)
                {
                    //RESUME SESSION
                    if (_debug)
                    {
                        $log.info("RouteTracker: resume-session", resume);
                    }

                    self.$fire("route.resume", [resume]);

                }
                else
                {
                    //START A NEW SESSION
                    if (_debug)
                    {
                        $log.info("RouteTracker: start-session", resume);
                    }

                    self.$fire("route.started", [resume]);
                }

            };

            self.pause = function()
            {
                resume.state = trackState.PAUSE;

                if (_debug)
                {
                    $log.info("RouteTracker: pause-session", resume);
                }

                self.$fire("route.paused", [resume]);
            };

            self.stop = function()
            {
                resume.state = trackState.STOP;
                resume.stopAt = new Date();

                //------------------------------------------------
                //GET AVERAGE ALTITUDE (DO IT HERE , FOR OPTIMIZATION ONLY...)
                var totalAltitude = 0;
                angular.forEach(resume.coords, function(coord)
                {
                    totalAltitude += (coord.coords.altitude || 0)
                });
                var averageAltitude = (totalAltitude / resume.coords.length);
                resume.altitude = averageAltitude;
                //------------------------------------------------

                try
                {
                    if (_debug)
                    {
                        $log.info("RouteTracker: stop-session", resume);
                    }

                    self.$fire("route.stopped", [resume]);
                }
                finally
                {
                    //RESET STAT's
                    if (interval)
                    {
                        $interval.cancel(interval);
                        interval = null;
                    }
                }
            };

            self.getCurrentState = function()
            {
                return resume.state;
            };

            self.addPhoto = function(image)
            {

                resume.photos.push(image);

            };

            self.setData = function(data)
            {
                resume.data = data;
            };

            self.getResume = function()
            {
                return resume;
            };

            return self;
        };

    })
