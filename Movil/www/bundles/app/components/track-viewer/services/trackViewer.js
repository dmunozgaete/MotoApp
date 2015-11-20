angular.module('app.components')

.factory('trackViewer', function($q, $rootScope)
{
    var self = this;
    var components = {};
    var callbacks = [];

    //Entry Point to register
    var $$register = function(component, uniqueID)
    {
        components[uniqueID] = component;

        //Call all then function registered
        angular.forEach(callbacks, function(callback)
        {
            callback.apply(component, [component, uniqueID]);
        });

        callbacks = [];
    };

    //Help to dispose the factory
    var $$unregister = function(uniqueID)
    {
        delete components[uniqueID];
        callbacks = [];
    };

    var _getByHandle = function(uniqueID)
    {
        var identifier = uniqueID;

        if (!identifier)
        {
            var count = Object.keys(components).length;
            if (count === 0)
            {
                throw {
                    message: 'no track-viewer has instantied in the view'
                };
            }

            //Always return the last registered
            // Some caches in IONIC, crap the original method because the 
            // "late destroy event" (for the special caching in IONIC)
            identifier = (function()
            {
                var last = null;
                for (var id in components)
                {
                    last = id;
                }
                return last;
            })();


        }

        var component = components[identifier];
        if (!component)
        {
            throw {
                message: 'no track-viewer has found with id {0}'.format([identifier])
            };
        }
        return component;
    };

    self.then = function(callback)
    {
        callbacks.push(callback);
    };

    self.getInstance = function()
    {
        return _getByHandle();
    };

    var exec = function(method, args)
    {
        var instance = self.getInstance();
        return instance[method].apply(instance, args);
    };

    self.setPath = function()
    {
        exec("setPath", arguments);
    };

    self.addToPath = function()
    {
        exec("addToPath", arguments);
    };

    self.getBounds = function()
    {
        return exec("getBounds", arguments);
    };

    self.getImage = function()
    {
        return exec("getImage", arguments);
    };

    //Internal Use
    self.$$register = $$register;
    self.$$unregister = $$unregister;

    return self;
});
