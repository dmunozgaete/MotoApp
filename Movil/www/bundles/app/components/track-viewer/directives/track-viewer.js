angular.module('app.components')

.directive('trackViewer', function()
{
    return {
        restrict: 'E',
        scope:
        {
            path: '=', // Default Message,
            name: '@', // tracker Unique ID,
            static: '=', // Define if the map is image or fully Google Map
        },
        templateUrl: 'bundles/app/components/track-viewer/track-viewer.tpl.html',
        controller: function(
            $scope,
            $element,
            $log,
            trackViewer,
            uiGmapGoogleMapApi,
            $interval,
            BaseEventHandler
        )
        {
            var self = Object.create(BaseEventHandler); //Extend From EventHandler
            var unique_id = ($scope.name || (new Date()).getTime()); //Component Unique ID
            var polylineColor = "ffc107";
            $scope.loadingMap = true;

            //TrackViewer Data
            var trackData = {
                path: [],
                zoom: null,
                center: null
            };

            //---------------------------------------------
            // AddTask is a Class itself xD, but is to encapsulate all complex 
            // data in work with Google Maps 
            //
            // Return function to Add Task when GMap has created
            // (GMap is created when center is setted up for first time)
            //
            // ... But not always the center is setted :/
            // ......so a timer has created , to wait for this event, and fire all callbacks
            var addTask = (function()
            {
                pendingTasks = [];
                var interval = null;

                var executePendings = function(map)
                {
                    angular.forEach(pendingTasks, function(handler)
                    {
                        handler.apply(handler, [map]);
                    });

                    //The map is already loaded(at least one time!)
                    pendingTasks = null;
                };

                var checkGmap = function()
                {
                    var context = $scope.map;
                    if (context.getGMap == null)
                    {
                        if (interval == null)
                        {
                            interval = $interval(function()
                            {
                                checkGmap();
                            }, 250);
                        }
                        return;
                    }
                    $interval.cancel(interval);

                    var map = context.getGMap();

                    executePendings(map);
                    $scope.loadingMap = false;

                };

                //always destroy interval, for whatever reason :P
                $scope.$on('$destroy', function()
                {
                    if (interval)
                    {
                        $interval.cancel(interval);
                    }
                });

                return function(callback)
                {

                    //It means, wich GMAP is not created yet... , 
                    //... so , add task to pending's 
                    if (pendingTasks)
                    {
                        pendingTasks.push(callback);
                        checkGmap();
                    }
                    else
                    {
                        var context = $scope.map;
                        var map = context.getGMap();
                        callback(map);
                    }

                }
            })();
            //---------------------------------------------

            //---------------------------------------------
            // MAYBE STATIC MAPS LONG! LONG! POLYLINES! IN STATIC MAPS
            // There's no way to 'trick' the character limit, but it is possible 
            // to simplify your polyline to bring the encoded polyline string 
            // below the character limit. This may or may not result in a polygon of 
            // suitable fidelity for your needs.
            //
            // One option for simplifying your polyline is the 
            // Douglas Peucker algorithm. Below is an implementation which 
            // extends the google.maps.Polyline object with a simplify method.
            //
            //Ramer–Douglas–Peucker Algorithm
            // URL: http://stackoverflow.com/questions/16517339/static-maps-drawing-polygons-with-many-points-2048-char-limitation
            var simplify_path = function(tolerance)
            {

                var points = this.getPath().getArray(); // An array of google.maps.LatLng objects
                var keep = []; // The simplified array of points

                // Check there is something to simplify.
                if (points.length <= 2)
                {
                    return points;
                }

                function distanceToSegment(p, v, w)
                {

                    function distanceSquared(v, w)
                    {
                        return Math.pow((v.x - w.x), 2) + Math.pow((v.y - w.y), 2)
                    }

                    function distanceToSegmentSquared(p, v, w)
                    {

                        var l2 = distanceSquared(v, w);
                        if (l2 === 0) return distanceSquared(p, v);

                        var t = ((p.x - v.x) * (w.x - v.x) + (p.y - v.y) * (w.y - v.y)) / l2;
                        if (t < 0) return distanceSquared(p, v);
                        if (t > 1) return distanceSquared(p, w);
                        return distanceSquared(p,
                        {
                            x: v.x + t * (w.x - v.x),
                            y: v.y + t * (w.y - v.y)
                        });
                    }

                    // Lat/Lng to x/y
                    function ll2xy(p)
                    {
                        return {
                            x: p.lat(),
                            y: p.lng()
                        };
                    }

                    return Math.sqrt(distanceToSegmentSquared(ll2xy(p), ll2xy(v), ll2xy(w)));
                }

                function dp(points, tolerance)
                {

                    // If the segment is too small, just keep the first point. 
                    // We push the final point on at the very end.
                    if (points.length <= 2)
                    {
                        return [points[0]];
                    }

                    var keep = [], // An array of points to keep
                        v = points[0], // Starting point that defines a segment
                        w = points[points.length - 1], // Ending point that defines a segment
                        maxDistance = 0, // Distance of farthest point
                        maxIndex = 0; // Index of said point

                    // Loop over every intermediate point to find point greatest distance from segment
                    for (var i = 1, ii = points.length - 2; i <= ii; i++)
                    {
                        var distance = distanceToSegment(points[i], points[0], points[points.length - 1]);
                        if (distance > maxDistance)
                        {
                            maxDistance = distance;
                            maxIndex = i;
                        }
                    }

                    // check if the max distance is greater than our tollerance allows 
                    if (maxDistance >= tolerance)
                    {

                        // Recursivly call dp() on first half of points
                        keep = keep.concat(dp(points.slice(0, maxIndex + 1), tolerance));

                        // Then on second half
                        keep = keep.concat(dp(points.slice(maxIndex, points.length), tolerance));

                    }
                    else
                    {
                        // Discarding intermediate point, keep the first
                        keep = [points[0]];
                    }
                    return keep;
                };

                // Push the final point on
                keep = dp(points, tolerance);
                keep.push(points[points.length - 1]);
                return keep;
            };
            //---------------------------------------------

            //---------------------------------------------
            // uiGmapGoogleMapApi is a promise.
            // The "then" callback function provides the google.maps object.
            uiGmapGoogleMapApi.then(function(maps)
            {

                //http://www.christianengvall.se/phonegap-and-google-maps/
                //Zomming all point and marks
                $scope.map = {
                    options:
                    {
                        overviewMapControl: false,
                        mapTypeControl: false,
                        streetViewControl: false,
                        mapTypeId: google.maps.MapTypeId.HYBRID,
                        zoomControl: false,
                        panControl: false,
                        disableDefaultUI: true
                    }
                };

                addTask(function(map)
                {
                    self.$fire("gmaps.mapLoaded", map);
                });

                //-------------------------------------------------
                //Add simplify method to gmap polyline class
                if (!google.maps.Polyline.simplify)
                {
                    google.maps.Polyline.prototype.simplify = simplify_path;
                }
                //-------------------------------------------------

                //-------------------------------------------------
                //Register for Service Interaction
                trackViewer.$$register(self, unique_id);
                //-------------------------------------------------

            });

            var isInStaticMode = function()
            {
                return $scope.static;
            };

            var setStaticMode = function(callback)
            {

                var staticURL = self.getImage(trackData.path);

                var image = new Image();
                image.onload = function()
                {
                    //------------------------------------------
                    $scope.image = trackData.image = staticURL;
                    $scope.loadingMap = false;
                    //------------------------------------------

                    //Call $apply beacuse the loading is Async and
                    //AngularJs doesn't know which the image is already loading
                    try
                    {
                        $scope.$apply();
                    }
                    catch (e)
                    {}
                };
                image.onerror = function()
                {
                    //Do Something?, MAYBE IS BECAUSE INTERNET ERROR!!
                };
                image.src = staticURL;

                //Call callback :P
                if (callback)
                {
                    callback(staticURL);
                }
            };

            //-------------------------------------------------
            //--[ GLOBAL FUNCTION'S
            self.setPath = function(coords, callback)
            {

                //--------------------------------------------------------
                // Check Coords
                if (!coords || coords.length == 0)
                {
                    throw {
                        message: 'No existen datos para generar'
                    };
                }
                //--------------------------------------------------------

                //--------------------------------------------------------
                // DRAW THE PATH IN THE MAPS, AND GET CENTER AND FIT ZOOM
                var polyline = new google.maps.Polyline(
                {
                    path: coords,
                    geodesic: true,
                    strokeColor: '#' + polylineColor,
                    strokeWeight: 4
                });

                var bounds = new google.maps.LatLngBounds();
                polyline.getPath().forEach(function(e)
                {
                    bounds.extend(e);
                })

                //Get center and fit zoom
                var center = bounds.getCenter();

                //--------------------------------------------------------
                // Set in Static Mode (Google Static Image)
                if (isInStaticMode())
                {
                    trackData = {
                        path: coords,
                        center: center
                    };
                    setStaticMode(callback);
                    return;
                }
                //--------------------------------------------------------



                $scope.map.center = {
                    latitude: center.lat(),
                    longitude: center.lng()
                };

                //Wait for the Map , or not... 
                addTask(function(map)
                {
                    //Set the polyline to Map
                    polyline.setMap(map);

                    //Set Zoom and Center Map
                    map.fitBounds(bounds);
                });
                //--------------------------------------------------------

                var firstPoint = coords[0];

                //--------------------------------------------------------
                //ADD A RACE START FLAG
                var startFlag = new google.maps.Marker(
                {
                    position: firstPoint,
                    icon:
                    {
                        url: 'bundles/app/components/track-viewer/images/flag-race-start.png',
                        // Image Real Size
                        size: new google.maps.Size(97, 97),
                        // Origin Point
                        origin: new google.maps.Point(0, 0),
                        // Anchor for the Image
                        anchor: new google.maps.Point(0, 20),
                        //New Scaled Size
                        scaledSize: new google.maps.Size(20, 20)
                    }
                });
                addTask(function(map)
                {
                    startFlag.setMap(map);
                });
                //--------------------------------------------------------

                //--------------------------------------------------------
                //Set Data to Model 
                addTask(function(map)
                {

                    trackData = {
                        path: coords,
                        zoom: map.getZoom(),
                        center:
                        {
                            lat: center.lat(),
                            lng: center.lng()
                        }
                    };

                    self.$fire("gmaps.pathLoaded", map, trackData);

                    //Callback when all Path is Complete
                    if (callback)
                    {
                        callback(map, trackData);
                    }
                });
                //--------------------------------------------------------

            };


            self.getImage = function(conf)
            {
                //--------------------------------------------------------
                // Static Configuration
                var conf = angular.extend(
                {
                    map:
                    {
                        width: 600,
                        height: 600
                    },
                    polyline:
                    {
                        hex: polylineColor,
                        alpha: "FF",
                        weight: 5
                    }
                }, conf);

                //--------------------------------------------------------
                // Check Data
                if (!trackData)
                {
                    throw {
                        message: 'No existen datos para generar'
                    };
                }

                //--------------------------------------------------------
                // Encode Polyline Path 
                var latlngs = []
                for (var j = 0; j < trackData.path.length; j++)
                {
                    var coord = trackData.path[j];
                    var lat = coord.lat.toFixed(3);
                    var lng = coord.lng.toFixed(3);

                    latlngs.push(new google.maps.LatLng(lat, lng));
                }

                var line = new google.maps.Polyline(
                {
                    path: latlngs
                });
                var encoded = google.maps.geometry.encoding.encodePath(line.getPath());
                var tol = 0.0001;
                while (encoded.length > 1800)
                {
                    path = line.simplify(tol);
                    line = new google.maps.Polyline(
                    {
                        path: path
                    });
                    encoded = google.maps.geometry.encoding.encodePath(path);
                    tol += .005;
                }

                //--------------------------------------------------------
                // Build URL for Static Maps
                //  https://developers.google.com/maps/documentation/static-maps/intro#Paths
                var url = (function()
                {
                    var fullUrl = ["http://maps.google.com/maps/api/staticmap?sensor=false"];

                    //----------------------------------------------------
                    //--[ Size
                    fullUrl.push("&size=");
                    // Width & height
                    fullUrl.push("{0}x{1}".format([conf.map.width, conf.map.height]));
                    //----------------------------------------------------

                    //----------------------------------------------------
                    //--[ Custom Marker
                    var start = latlngs[0]; //First Coord
                    fullUrl.push("&markers=color:green|");
                    fullUrl.push(start.toUrlValue());

                    var end = latlngs[latlngs.length - 1]; //First Coord
                    fullUrl.push("&markers=color:red|");
                    fullUrl.push(end.toUrlValue());
                    //----------------------------------------------------

                    //----------------------------------------------------
                    //--[ Map Type
                    fullUrl.push("&maptype=");
                    fullUrl.push(google.maps.MapTypeId.HYBRID);
                    //----------------------------------------------------

                    //----------------------------------------------------
                    //--[ Path
                    fullUrl.push("&path=");
                    // Color
                    fullUrl.push("color:0x{0}{1}|".format([conf.polyline.hex, conf.polyline.alpha]));
                    //Weight
                    fullUrl.push("weight:{0}|".format([conf.polyline.weight]));
                    // Path
                    fullUrl.push("enc:" + encoded);
                    //----------------------------------------------------

                    return fullUrl.join("");
                })();

                return url;
            };

            self.getTrackData = function(coords)
            {
                return trackData;
            };

            self.setCenter = function(coords) {

            };

            self.getName = function(coords)
            {
                return unique_id;
            };
            //-------------------------------------------------

            //-------------------------------------------------
            //UnRegister for Service Interaction
            $scope.$on('$destroy', function()
            {
                //Garbage Collector Destroy
                trackViewer.$$unregister(unique_id); //UnRegister for Service Interaction
            });
            //-------------------------------------------------
        },

        link: function(scope, element, attrs, ctrl) {

        }
    };
});
